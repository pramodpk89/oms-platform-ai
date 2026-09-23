param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
. "$repo/scripts/shared/Erd.ps1"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$temp = Join-Path ([IO.Path]::GetTempPath()) ('oms-erd-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $temp
$script:erdChecks = 0
function Check([bool]$Value, [string]$Message) { if (!$Value) { throw "ERD FAILED: $Message" }; $script:erdChecks++ }
function Fails([scriptblock]$Action, [string]$Message) {
    $failed = $false
    try { $null = & $Action } catch { $failed = $true }
    Check $failed $Message
}
function Page([string]$Name, [string]$Extra = '', [string]$Type = 'Char (24)') {
    @"
<html><head><title> ERD: Entity Definition ($Name)</title></head><body>
<b>( TRANSACTION Table )</b><p>Stores synthetic orders &amp; references.</p>
<p>Records purged from this table are archived into ${Name}_H</p>
<b>Columns</b><table><thead><tr><td>Column Name</td><td>Data Type</td><td>Description</td></tr></thead><tbody>
<tr><td>ID</td><td>$Type</td><td>The primary key for the $Name table.</td></tr>
<tr><td>OTHER_ID</td><td>Char (24)</td><td>The primary key of the OTHER_TABLE table.<br>A logical foreign key to the following table:<br>OTHER_TABLE</td></tr>
<tr><td>NOTE</td><td>Varchar (100)</td><td>For context see SAMPLE_RULE. &lt;script&gt;literal&lt;/script&gt;</td></tr>
$Extra
</tbody></table><table><tr><td><b>Primary Key</b></td><td>ID</td></tr><tr><td><b>Unique Key</b></td><td>ID, OTHER_ID</td></tr></table></body></html>
"@
}
function Zip([string]$Name, $Pages) {
    $path = Join-Path $temp $Name
    $archive = [IO.Compression.ZipFile]::Open($path, 'Create')
    try {
        foreach ($key in $Pages.Keys) {
            $entry = $archive.CreateEntry("xapidocs/ERD/HTML/$key.html")
            $writer = New-Object IO.StreamWriter($entry.Open())
            try { $writer.Write([string]$Pages[$key]) } finally { $writer.Dispose() }
        }
    } finally { $archive.Dispose() }
    $path
}
try {
    $root = Join-Path $temp 'store with spaces'
    $first = Zip 'one.zip' @{ TEST_TABLE = (Page 'TEST_TABLE'); OLD_TABLE = (Page 'OLD_TABLE') }
    $r = & "$repo/scripts/update-erd.ps1" -ZipPath $first -FixPack fp1 -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.tableCount -eq 2 -and $r.columnCount -eq 6) 'initial inventory'
    $e = Read-ErdJson (Join-Path $root 'versions/fp1/tables/TEST_TABLE.json')
    Check ($e.purpose -eq 'Stores synthetic orders & references.') 'HTML decoded'
    Check ($e.columns[0].primaryKeyDocumented -and !$e.columns[1].primaryKeyDocumented) 'foreign PK mention is not own PK'
    Check ($e.columns[1].logicalForeignKeyTargets.Count -eq 1 -and $e.columns[1].logicalForeignKeyTargets[0] -eq 'OTHER_TABLE') 'explicit logical FK'
    Check ($e.columns[2].logicalForeignKeyTargets.Count -eq 0 -and $e.columns[2].references[0] -eq 'SAMPLE_RULE') 'general mention is not FK'
    Check ($e.keys.Count -eq 2 -and $e.keys[1].columns.Count -eq 2) 'composite unique key'
    Check ($e.archivedTo -eq 'TEST_TABLE_H') 'archive destination'
    $r = & "$repo/scripts/find-erd.ps1" -Query 'synthetic' -Limit 1 -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.totalMatches -eq 2 -and $r.truncated -and $r.results.Count -eq 1) 'bounded search'
    $r = & "$repo/scripts/find-erd.ps1" -Query 'OTHER_ID' -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.totalMatches -eq 2) 'column search'
    $r = & "$repo/scripts/find-erd.ps1" -Query 'nonexistent' -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.totalMatches -eq 0 -and $r.results.Count -eq 0) 'no matches'
    $pointer = [IO.File]::ReadAllText((Join-Path $root 'current.json'))
    $r = & "$repo/scripts/update-erd.ps1" -ZipPath $first -FixPack fp1 -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.status -eq 'alreadyImported') 'idempotent import'
    $extra = '<tr><td>NEW_COLUMN</td><td>Number (5,0)</td><td>New value.</td></tr>'
    $second = Zip 'two.zip' @{ TEST_TABLE = ((Page 'TEST_TABLE' $extra 'Char (40)') -replace '<tr><td>NOTE</td>.*?</tr>', ''); NEW_TABLE = (Page 'NEW_TABLE') }
    $r = & "$repo/scripts/update-erd.ps1" -ZipPath $second -FixPack fp2 -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.added -eq 1 -and $r.removed -eq 1 -and $r.changed -eq 1) 'table delta'
    $changes = Read-ErdJson (Join-Path $root 'versions/fp2/changes.json')
    Check ($changes.changedTables[0].addedColumns[0] -eq 'NEW_COLUMN' -and $changes.changedTables[0].removedColumns[0] -eq 'NOTE') 'column additions/removals'
    Check ($changes.changedTables[0].changedColumns[0].fields -contains 'dataType') 'type delta'
    $r = & "$repo/scripts/find-erd.ps1" -Table TEST_TABLE -FixPack fp1 -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.entity.columns[0].dataType -eq 'Char (24)') 'retained snapshot lookup'
    $r = & "$repo/scripts/find-erd.ps1" -Table TEST_TABLE -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.fixPack -eq 'fp2' -and $r.entity.columns[0].dataType -eq 'Char (40)') 'current snapshot lookup'
    Fails { & "$repo/scripts/update-erd.ps1" -ZipPath $second -FixPack fp1 -KnowledgeRoot $root } 'version collision'
    $broken = Zip 'broken.zip' @{ TEST_TABLE = '<title>ERD: Entity Definition (TEST_TABLE)</title><p>damaged</p>' }
    Fails { & "$repo/scripts/update-erd.ps1" -ZipPath $broken -FixPack fp3 -KnowledgeRoot $root } 'malformed page rejected'
    $empty = Zip 'empty.zip' @{ index = '<title>ERD index</title>' }
    Fails { & "$repo/scripts/update-erd.ps1" -ZipPath $empty -FixPack fp3 -KnowledgeRoot $root } 'empty ERD rejected'
    Check ((Read-ErdJson (Join-Path $root 'current.json')).fixPack -eq 'fp2') 'failed imports preserve current'
    Check (!(Test-Path -LiteralPath (Join-Path $root 'versions/fp3'))) 'failed imports do not publish snapshot'
    Fails { & "$repo/scripts/find-erd.ps1" -Table MISSING -KnowledgeRoot $root } 'unknown table'
    Fails { & "$repo/scripts/find-erd.ps1" -Table TEST_TABLE -FixPack '../fp1' -KnowledgeRoot $root } 'unsafe label'
    Fails { & "$repo/scripts/find-erd.ps1" -Query 'order' -KnowledgeRoot (Join-Path $temp 'missing') } 'missing import'
    $custom = Join-Path $root 'custom'; $null = New-Item -ItemType Directory -Path $custom
    [IO.File]::WriteAllText((Join-Path $custom 'notes.txt'), 'custom reference')
    $third = Zip 'three.zip' @{ TEST_TABLE = (Page 'TEST_TABLE') }
    $null = & "$repo/scripts/update-erd.ps1" -ZipPath $third -FixPack fp3 -KnowledgeRoot $root
    Check ([IO.File]::ReadAllText((Join-Path $custom 'notes.txt')) -eq 'custom reference') 'custom references preserved'
    $cfgDir = Join-Path $temp 'config'; $null = New-Item -ItemType Directory -Path $cfgDir
    Write-ErdJson @{ defaultEnvironment = 'local'; environments = @{ local = @{ enabled = $true; erdFixPack = 'fp1' }; qa = @{ enabled = $true } } } (Join-Path $cfgDir 'environments.json')
    $r = & "$repo/scripts/find-erd.ps1" -Environment local -ConfigDir $cfgDir -Table TEST_TABLE -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.fixPack -eq 'fp1') 'environment mapping overrides current'
    Fails { & "$repo/scripts/find-erd.ps1" -Environment local -ConfigDir $cfgDir -FixPack fp2 -Table TEST_TABLE -KnowledgeRoot $root } 'conflicting environment version'
    Fails { & "$repo/scripts/find-erd.ps1" -Environment qa -ConfigDir $cfgDir -Table TEST_TABLE -KnowledgeRoot $root } 'unmapped environment'
    $history = (Page 'TEST_TABLE_H').Replace(' ERD:', 'Sterling ERD:').Replace('<b>( TRANSACTION Table )</b>', '<p>This is a history table used when records are purged from the main table.</p>')
    $h = Get-ErdEntity $history 'ERD/HTML/TEST_TABLE_H.html'
    Check ($h.classification -eq 'HISTORY') 'legacy history page'
    $mixed = (Page 'TEST_TABLE').Replace('TRANSACTION Table', 'MASTER / CONFIGURATION Table')
    Check ((Get-ErdEntity $mixed 'ERD/HTML/TEST_TABLE.html').classification -eq 'MASTER / CONFIGURATION') 'mixed classification'
    $legacy = (Page 'TEST_TABLE').Replace('<b>( TRANSACTION Table )</b>', '<div class="protectedtext">Legacy purpose.</div>')
    Check ((Get-ErdEntity $legacy 'ERD/HTML/TEST_TABLE.html').classification -eq 'UNSPECIFIED') 'missing classification stays unknown'
    $bad = (Page 'TEST_TABLE').Replace('<td>ID, OTHER_ID</td>', '<td>NOT_A_COLUMN</td>')
    Fails { Get-ErdEntity $bad 'ERD/HTML/TEST_TABLE.html' } 'invalid index rejected'
    $brokenRow = (Page 'TEST_TABLE').Replace('<tr><td>NOTE', '<tr><td>MISSING</td><tr><td>NOTE')
    Fails { Get-ErdEntity $brokenRow 'ERD/HTML/TEST_TABLE.html' } 'malformed rows rejected'
    $r = & "$repo/scripts/update-erd.ps1" -ZipPath $third -FixPack fp4 -KnowledgeRoot $root | ConvertFrom-Json
    Check ($r.changed -eq 0 -and $r.added -eq 0 -and $r.removed -eq 0) 'identical schema has no spurious changes'
    Check (Test-Path -LiteralPath $r.report) 'browser report exists'
    $lock = [IO.File]::Open((Join-Path $root '.update.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    try { Fails { & "$repo/scripts/update-erd.ps1" -ZipPath $third -FixPack fp5 -KnowledgeRoot $root } 'concurrent import rejected' } finally { $lock.Dispose() }
    $null = & "$repo/scripts/update-erd.ps1" -ZipPath $first -FixPack fp1 -KnowledgeRoot $root
    Check ((Read-ErdJson (Join-Path $root 'current.json')).fixPack -eq 'fp4') 'older reimport does not switch current'
    Write-Output "ERD checks passed: $script:erdChecks"
} finally {
    if ($temp -and (Split-Path -Leaf $temp) -match '^oms-erd-[a-f0-9]{32}$') { Remove-Item -LiteralPath $temp -Recurse -Force }
}
