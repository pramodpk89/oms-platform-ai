Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:ErdImporterVersion = '1.0.0'

function Read-ErdJson([string]$Path) {
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Write-ErdJson($Value, [string]$Path) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
}
function Get-ErdText([string]$Html) {
    $text = [regex]::Replace($Html, '(?is)<(script|style)\b[^>]*>.*?</\1>', '')
    $text = [regex]::Replace($text, '(?s)<[^>]+>', ' ')
    # Older Visio exports omit the semicolon on the numeric bullet entity.
    $text = $text.Replace('&#149&nbsp;', ' ')
    ([regex]::Replace([Net.WebUtility]::HtmlDecode($text), '\s+', ' ')).Trim()
}
function Get-ErdEntity([string]$Html, [string]$Source) {
    $title = [regex]::Match($Html, '(?is)<title>\s*(?:Sterling\s+)?ERD:\s*Entity Definition\s*\(([A-Z][A-Z0-9_]*)\)\s*</title>')
    if (!$title.Success) { throw "Unrecognized entity title: $Source" }
    $name = $title.Groups[1].Value
    if ([IO.Path]::GetFileNameWithoutExtension($Source) -cne $name) { throw "Entity name/file mismatch: $Source" }
    $body = [regex]::Match($Html, '(?is)<tbody\b[^>]*>(.*?)</tbody>')
    if (!$body.Success -or $Html -notmatch '(?is)Column Name.*?Data Type.*?Description') { throw "Missing column definition: $Source" }
    $intro = Get-ErdText $Html.Substring(0, $body.Index)
    $kind = [regex]::Match($intro, '\(\s*([A-Z]+(?:\s*/\s*[A-Z]+)*)\s+Table\s*\)')
    $classification = $kind.Groups[1].Value
    if ($kind.Success) { $notes = $intro.Substring($kind.Index + $kind.Length) }
    elseif ($intro -match 'This is a history table') { $classification = 'HISTORY'; $notes = $intro.Substring($intro.IndexOf('This is a history table')) }
    else {
        $legacy = [regex]::Match($Html.Substring(0, $body.Index), '(?is)<div\b[^>]*class="protectedtext"[^>]*>(.*?)</div>')
        if (!$legacy.Success) { throw "Unrecognized table introduction: $Source" }
        $classification = 'UNSPECIFIED'; $notes = Get-ErdText $legacy.Groups[1].Value
    }
    $notes = [regex]::Replace($notes, '\s+Columns.*$', '').Trim()
    $purpose = ([regex]::Split($notes, '(?i)Records purged from|You can extend this table|This table is not extensible|Tables should be accessed', 2))[0].Trim()
    $archive = [regex]::Match($notes, 'Records purged from this table are archived into\s+([A-Z][A-Z0-9_]*)')
    $columns = @()
    $seen = @{}
    if ([regex]::Matches($body.Groups[1].Value, '(?i)<tr\b').Count -ne [regex]::Matches($body.Groups[1].Value, '(?i)</tr>').Count) { throw "Unbalanced column rows: $Source" }
    foreach ($row in [regex]::Matches($body.Groups[1].Value, '(?is)<tr\b[^>]*>(.*?)</tr>')) {
        $cells = [regex]::Matches($row.Groups[1].Value, '(?is)<td\b[^>]*>(.*?)</td>')
        if ($cells.Count -ne 3) { throw "Unexpected column row format: $Source" }
        $col = Get-ErdText $cells[0].Groups[1].Value
        $type = Get-ErdText $cells[1].Groups[1].Value
        $description = Get-ErdText $cells[2].Groups[1].Value
        if ($col -notmatch '^[A-Z][A-Z0-9_]*$' -or !$type -or $seen.ContainsKey($col)) { throw "Invalid/duplicate column: $Source / $col" }
        $seen[$col] = $true
        $references = @([regex]::Matches($description, '\b[A-Z][A-Z0-9]*_[A-Z0-9_]+\b') | ForEach-Object { $_.Value } | Sort-Object -Unique)
        $targets = @()
        # Only the explicit logical-FK list is authoritative. Other mentions remain references.
        $fk = [regex]::Match($cells[2].Groups[1].Value, '(?is)A logical foreign key to the following tables?\s*:(.*)$')
        if ($fk.Success) { $targets = @([regex]::Matches((Get-ErdText $fk.Groups[1].Value), '\b[A-Z][A-Z0-9]*_[A-Z0-9_]+\b') | ForEach-Object { $_.Value } | Sort-Object -Unique) }
        $pk = $description -match ('(?i)\bprimary key (?:for|of) (?:the )?' + [regex]::Escape($name) + '\b')
        $columns += [ordered]@{ name = $col; dataType = $type; description = $description; primaryKeyDocumented = [bool]$pk; logicalForeignKeyTargets = $targets; references = $references }
    }
    if (!$columns.Count) { throw "Entity has no columns: $Source" }
    $keys = @()
    foreach ($m in [regex]::Matches($Html, '(?is)<td\b[^>]*>\s*<b>(Primary Key|Unique Key)</b>\s*</td>\s*<td\b[^>]*>(.*?)</td>')) {
        $keyColumns = @((Get-ErdText $m.Groups[2].Value) -split '\s*,\s*' | Where-Object { $_ })
        foreach ($k in $keyColumns) { if (!$seen.ContainsKey($k)) { throw "Index refers to unknown column: $Source / $k" } }
        $keys += [ordered]@{ kind = $m.Groups[1].Value; columns = $keyColumns }
        if ($m.Groups[1].Value -eq 'Primary Key') { foreach ($c in $columns) { $c.primaryKeyDocumented = $keyColumns -contains $c.name } }
    }
    [ordered]@{ table = $name; classification = $classification; purpose = $purpose; notes = $notes; archivedTo = $(if ($archive.Success) { $archive.Groups[1].Value } else { $null }); keys = $keys; columns = $columns; sourceEntry = $Source }
}
function Get-ErdRoot([string]$KnowledgeRoot) {
    if (!$KnowledgeRoot) { $KnowledgeRoot = Join-Path $PSScriptRoot '../../.local/erd' }
    [IO.Path]::GetFullPath($KnowledgeRoot)
}
function Assert-ErdVersion([string]$FixPack) {
    if ($FixPack -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$' -or $FixPack.EndsWith('.')) { throw 'FixPack must be a simple version label (letters, digits, dots, underscores, hyphens).' }
}
