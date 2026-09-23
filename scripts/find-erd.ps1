param(
    [string]$Query,
    [ValidatePattern('^[A-Z][A-Z0-9_]*$')][string]$Table,
    [string]$FixPack,
    [string]$Environment,
    [string]$ConfigDir,
    [string]$KnowledgeRoot,
    [ValidateRange(1, 100)][int]$Limit = 10
)
. "$PSScriptRoot/shared/Erd.ps1"
$root = Get-ErdRoot $KnowledgeRoot
if ($Environment) {
    . "$PSScriptRoot/shared/Common.ps1"
    $context = Get-OmsContext $Environment $ConfigDir
    $p = $context.Settings.PSObject.Properties['erdFixPack']
    if (!$p -or !$p.Value) { throw "Environment '$Environment' has no erdFixPack. Set its documentation version in environments.json." }
    if ($FixPack -and $FixPack -ne $p.Value) { throw 'Explicit fix pack conflicts with environment erdFixPack.' }
    $FixPack = $p.Value
}
if (!$FixPack) {
    if (!(Test-Path -LiteralPath (Join-Path $root 'current.json'))) { throw 'No ERD imported. Run scripts/update-erd.ps1 with the fix-pack ZIP.' }
    $FixPack = (Read-ErdJson (Join-Path $root 'current.json')).fixPack
}
Assert-ErdVersion $FixPack
$version = Join-Path $root "versions/$FixPack"
if (!(Test-Path -LiteralPath (Join-Path $version 'manifest.json'))) { throw "ERD version '$FixPack' is not imported." }
if ($Table) {
    $path = Join-Path $version "tables/$Table.json"
    if (!(Test-Path -LiteralPath $path)) { throw "Table '$Table' is not documented in '$FixPack'." }
    [ordered]@{ fixPack = $FixPack; reference = $path; entity = (Read-ErdJson $path) } | ConvertTo-Json -Depth 30
} else {
    if (!$Query.Trim()) { throw 'Provide -Query (business term/column) or -Table (exact name).' }
    $matches = @((Read-ErdJson (Join-Path $version 'index.json')) | Where-Object {
        ($_.table + ' ' + $_.purpose + ' ' + ($_.columns -join ' ')).IndexOf($Query, [StringComparison]::OrdinalIgnoreCase) -ge 0
    })
    $results = @($matches | Select-Object -First $Limit | ForEach-Object { [ordered]@{ table = $_.table; purpose = $_.purpose; reference = (Join-Path $version "tables/$($_.table).json") } })
    [ordered]@{ fixPack = $FixPack; totalMatches = $matches.Count; truncated = ($matches.Count -gt $Limit); results = $results } | ConvertTo-Json -Depth 5
}
