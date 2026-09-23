param(
    [Parameter(Mandatory = $true)][string]$ZipPath,
    [Parameter(Mandatory = $true)][string]$FixPack,
    [string]$KnowledgeRoot
)
. "$PSScriptRoot/shared/Erd.ps1"
Assert-ErdVersion $FixPack
$root = Get-ErdRoot $KnowledgeRoot
$zipFile = (Resolve-Path -LiteralPath $ZipPath).Path
$sha = (Get-FileHash -LiteralPath $zipFile -Algorithm SHA256).Hash.ToLowerInvariant()
$null = New-Item -ItemType Directory -Force -Path $root
$lock = $null
$zip = $null
$stage = $null
$pointerTemp = $null
try {
    # Exclusive file handle prevents concurrent importers from racing the current pointer.
    $lock = [IO.File]::Open((Join-Path $root '.update.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    $versions = Join-Path $root 'versions'
    $null = New-Item -ItemType Directory -Force -Path $versions
    $destination = Join-Path $versions $FixPack
    if (Test-Path -LiteralPath $destination) {
        $existing = Read-ErdJson (Join-Path $destination 'manifest.json')
        if ($existing.zipSha256 -ne $sha -or $existing.importerVersion -ne $script:ErdImporterVersion) { throw "Version '$FixPack' already exists with different source/importer. Use a new version label." }
        [pscustomobject]@{ status = 'alreadyImported'; fixPack = $FixPack; tableCount = $existing.tableCount; path = $destination } | ConvertTo-Json
        return
    }
    $stage = Join-Path $root ('.staging-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path (Join-Path $stage 'tables')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($zipFile)
    $entities = @{}
    $candidateCount = 0
    foreach ($entry in $zip.Entries) {
        $path = $entry.FullName.Replace('\', '/')
        if ($path -notmatch '(?i)(?:^|/)ERD/HTML/[^/]+\.html?$') { continue }
        # Ignore Visio navigation; every entity-named page must parse successfully.
        $stem = [IO.Path]::GetFileNameWithoutExtension($path)
        $candidate = $stem -cmatch '^[A-Z][A-Z0-9_]*$'
        if ($entry.Length -gt 20MB) { throw "Oversized ERD page: $path" }
        $reader = New-Object IO.StreamReader($entry.Open())
        try { $html = $reader.ReadToEnd() } finally { $reader.Dispose() }
        if (!$candidate -and $html -notmatch '(?i)<title>\s*ERD:\s*Entity Definition') { continue }
        # Diagram launch pages such as OM.htm are not entity candidates.
        if ($path -notmatch '(?i)\.html$' -and $html -notmatch '(?i)ERD:\s*Entity Definition') { continue }
        $candidateCount++
        $entity = Get-ErdEntity $html $path
        if ($entities.ContainsKey($entity.table)) { throw "Duplicate entity: $($entity.table)" }
        $entities[$entity.table] = $entity
    }
    $zip.Dispose(); $zip = $null
    if (!$candidateCount -or $entities.Count -ne $candidateCount) { throw 'No complete ERD entity set found. Expected ERD/HTML entity-definition pages.' }
    $index = @()
    $columnCount = 0
    foreach ($name in @($entities.Keys | Sort-Object)) {
        $e = $entities[$name]
        Write-ErdJson $e (Join-Path $stage "tables/$name.json")
        $columnCount += $e.columns.Count
        $index += [ordered]@{ table = $name; classification = $e.classification; purpose = $e.purpose; columns = @($e.columns | ForEach-Object { $_.name }) }
    }
    $previous = $null
    $old = @{}
    if (Test-Path -LiteralPath (Join-Path $root 'current.json')) {
        $previous = (Read-ErdJson (Join-Path $root 'current.json')).fixPack
        Assert-ErdVersion $previous
        foreach ($e in (Read-ErdJson (Join-Path $versions "$previous/index.json"))) { $old[$e.table] = $e }
    }
    $added = @($entities.Keys | Where-Object { !$old.ContainsKey($_) } | Sort-Object)
    $removed = @($old.Keys | Where-Object { !$entities.ContainsKey($_) } | Sort-Object)
    $changed = @()
    foreach ($name in @($entities.Keys | Where-Object { $old.ContainsKey($_) } | Sort-Object)) {
        $a = Read-ErdJson (Join-Path $versions "$previous/tables/$name.json")
        $b = $entities[$name]
        $metadata = @('classification','purpose','notes','archivedTo','keys' | Where-Object { (ConvertTo-Json -InputObject $a.$_ -Depth 8 -Compress) -cne (ConvertTo-Json -InputObject $b[$_] -Depth 8 -Compress) })
        $ac = @{}; foreach ($c in $a.columns) { $ac[$c.name] = $c }
        $bc = @{}; foreach ($c in $b.columns) { $bc[$c.name] = $c }
        $newColumns = @($bc.Keys | Where-Object { !$ac.ContainsKey($_) } | Sort-Object)
        $lostColumns = @($ac.Keys | Where-Object { !$bc.ContainsKey($_) } | Sort-Object)
        $changedColumns = @()
        foreach ($column in @($bc.Keys | Where-Object { $ac.ContainsKey($_) } | Sort-Object)) {
            $fields = @('dataType','description','primaryKeyDocumented','logicalForeignKeyTargets','references' | Where-Object {
                (ConvertTo-Json -InputObject $ac[$column].$_ -Compress) -cne (ConvertTo-Json -InputObject $bc[$column][$_] -Compress)
            })
            if ($fields.Count) { $changedColumns += [ordered]@{ column = $column; fields = $fields; before = $ac[$column]; after = $bc[$column] } }
        }
        if ($metadata.Count -or $newColumns.Count -or $lostColumns.Count -or $changedColumns.Count) {
            $changed += [ordered]@{ table = $name; metadataFields = $metadata; addedColumns = $newColumns; removedColumns = $lostColumns; changedColumns = $changedColumns }
        }
    }
    $report = [ordered]@{ previousFixPack = $previous; fixPack = $FixPack; addedTables = $added; removedTables = $removed; changedTables = $changed }
    Write-ErdJson $report (Join-Path $stage 'changes.json')
    $summary = "# ERD refresh: $FixPack`n`nPrevious: $previous`n`nTables: $($entities.Count); columns: $columnCount`n`nAdded: $($added.Count); removed: $($removed.Count); changed: $($changed.Count)`n`nFull before/after details: changes.json. Earlier snapshots remain in versions/.`n"
    foreach ($n in $added) { $summary += "`n- Added table: $n" }
    foreach ($n in $removed) { $summary += "`n- Removed table: $n" }
    foreach ($c in $changed) { $summary += "`n- $($c.table): metadata [$($c.metadataFields -join ', ')]; added columns [$($c.addedColumns -join ', ')]; removed columns [$($c.removedColumns -join ', ')]; changed columns [$((@($c.changedColumns | ForEach-Object { $_.column })) -join ', ')]" }
    [IO.File]::WriteAllText((Join-Path $stage 'changes.md'), $summary)
    $reportHtml = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ERD refresh report</title><style>body{max-width:1000px;margin:40px auto;padding:0 24px;font:16px/1.6 system-ui;color:#172b4d}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:inherit}a{color:#145bb8}</style><h1>ERD refresh report</h1><p><a href="changes.json">Detailed changes (JSON)</a> | <a href="manifest.json">Source manifest</a></p><pre>' + [Net.WebUtility]::HtmlEncode($summary) + '</pre></html>'
    [IO.File]::WriteAllText((Join-Path $stage 'changes.html'), $reportHtml)
    Write-ErdJson $index (Join-Path $stage 'index.json')
    Write-ErdJson ([ordered]@{ fixPack = $FixPack; zipSha256 = $sha; sourceFile = [IO.Path]::GetFileName($zipFile); importerVersion = $script:ErdImporterVersion; importedAtUtc = [DateTime]::UtcNow.ToString('o'); tableCount = $entities.Count; columnCount = $columnCount; parsedEntityPages = $candidateCount }) (Join-Path $stage 'manifest.json')
    [IO.Directory]::Move($stage, $destination)
    $stage = $null
    $pointerTemp = Join-Path $root ('.current-' + [guid]::NewGuid().ToString('N') + '.json')
    Write-ErdJson @{ fixPack = $FixPack } $pointerTemp
    $pointer = Join-Path $root 'current.json'
    if (Test-Path -LiteralPath $pointer) { [IO.File]::Replace($pointerTemp, $pointer, [NullString]::Value) } else { [IO.File]::Move($pointerTemp, $pointer) }
    $pointerTemp = $null
    [pscustomobject]@{ status = 'imported'; fixPack = $FixPack; tableCount = $entities.Count; columnCount = $columnCount; added = $added.Count; removed = $removed.Count; changed = $changed.Count; report = (Join-Path $destination 'changes.html') } | ConvertTo-Json
} finally {
    if ($zip) { $zip.Dispose() }
    if ($stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
    if ($pointerTemp -and (Test-Path -LiteralPath $pointerTemp)) { Remove-Item -LiteralPath $pointerTemp -Force }
    if ($lock) { $lock.Dispose() }
}
