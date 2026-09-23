param([string]$TocFile, [string]$OutputFile = "$PSScriptRoot/../.github/skills/oms-orderhub/references/topics.json")
$ErrorActionPreference = 'Stop'
Set-StrictMode -Off # IBM TOC nodes legitimately omit href, topicId or children.
$source = 'https://1.www.s81c.com/docs/api/v1/toc/order-management?lang=en'
if ($TocFile) { $toc = Get-Content -LiteralPath $TocFile -Raw | ConvertFrom-Json }
else { $toc = Invoke-RestMethod -Uri $source -TimeoutSec 60 }
$pages = @{}
$roots = @{'managing-using-order-hub'='legacy'; 'managing-using-next-generation-order-hub'='next_generation'}
$found = @{}
function Visit($Node, [string]$Branch, [string]$ParentId, [string]$Trail) {
    if ($roots.ContainsKey([string]$Node.topicId)) { $Branch = $roots[[string]$Node.topicId]; $found[$Branch] = $true; $Trail = '' }
    if ($Branch) {
        $title = ([string]$Node.label).Trim()
        $Trail = if ($Trail) { "$Trail > $title" } else { $title }
        $href = ([string]$Node.href -split '\?')[0]
        if ($href) {
            if ($href -notmatch '^SSGTJF/[A-Za-z0-9_./-]+\.html?$' -or $href.Contains('..')) { throw "Unexpected IBM source path: $href" }
            if (!$pages.ContainsKey($href)) { $pages[$href] = [ordered]@{ path=$href; routes=(New-Object Collections.ArrayList) } }
            $null = $pages[$href].routes.Add([ordered]@{ id=$Node.topicId; title=$title; branch=$Branch; parent=$ParentId; trail=$Trail })
        }
    }
    foreach ($child in $Node.topics) { Visit $child $Branch ([string]$Node.topicId) $Trail }
}
Visit $toc.toc '' '' ''
if ($found.Count -ne 2 -or $pages.Count -eq 0) { throw 'Both Order Hub branches must exist; existing index was not changed.' }
$result = [ordered]@{ schemaVersion=1; retrievedAt=[DateTime]::UtcNow.ToString('o'); source=$source; scope='Using Order Hub and Using next-generation Order Hub; excludes separate customization/installation branches'; pages=@($pages.Keys | Sort-Object | ForEach-Object { $pages[$_] }) }
$result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $OutputFile -Encoding UTF8
Write-Output "Indexed $($pages.Count) distinct IBM pages into $OutputFile"
