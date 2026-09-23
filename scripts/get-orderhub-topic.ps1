param(
    [Parameter(Mandatory=$true)][string]$TopicId,
    [string]$Contains,
    [ValidateRange(0,10000000)][int]$Offset = 0,
    [ValidateRange(200,12000)][int]$MaxChars = 3500,
    [switch]$Refresh,
    [string]$CacheDir = "$PSScriptRoot/../.local/orderhub-docs"
)
$ErrorActionPreference = 'Stop'
$index = Get-Content -LiteralPath "$PSScriptRoot/../.github/skills/oms-orderhub/references/topics.json" -Raw | ConvertFrom-Json
$page = @($index.pages | Where-Object { $TopicId -in $_.routes.id })
if ($page.Count -ne 1) { throw 'Unknown/ambiguous topic ID. Select a topicId returned by find-orderhub.ps1.' }
$page = $page[0]
$route = @($page.routes | Where-Object { $_.id -eq $TopicId })[0]
$sha = [Security.Cryptography.SHA256]::Create()
try { $key = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($page.path)))).Replace('-','').ToLowerInvariant() }
finally { $sha.Dispose() }
$cache = Join-Path $CacheDir "$key.json"
if ($Refresh -or !(Test-Path -LiteralPath $cache)) {
    if ($page.path -notmatch '^SSGTJF/[A-Za-z0-9_./-]+\.html?$' -or $page.path.Contains('..')) { throw 'Invalid indexed IBM source path.' }
    $uri = 'https://1.www.s81c.com/docs/api/v1/content/' + [Uri]::EscapeDataString($page.path) + '?parsebody=true&lang=en'
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 30
    $article = [regex]::Match($response.Content, '(?is)<article\b[^>]*>(.*?)</article>')
    if (!$article.Success) { throw 'IBM returned no article. Open the browser URL; cached content was not replaced.' }
    # Plain-text excerpts are for reading, not for faithfully rendering HTML tables/code.
    $text = [regex]::Replace($article.Groups[1].Value, '(?is)<(script|style)\b[^>]*>.*?</\1>', '')
    $text = [regex]::Replace($text, '(?is)<[^>]+>', ' ')
    $text = [regex]::Replace([Net.WebUtility]::HtmlDecode($text), '\s+', ' ').Trim()
    if (!$text) { throw 'IBM article was empty.' }
    $record = [ordered]@{ retrievedAt=[DateTime]::UtcNow.ToString('o'); text=$text }
    $null = New-Item -ItemType Directory -Force -Path $CacheDir
    $record | ConvertTo-Json | Set-Content -LiteralPath $cache -Encoding UTF8
} else { $record = Get-Content -LiteralPath $cache -Raw | ConvertFrom-Json }
$start = $Offset
$matched = $null
if ($Contains) {
    $position = $record.text.IndexOf($Contains, [StringComparison]::OrdinalIgnoreCase)
    $matched = $position -ge 0
    if ($matched) { $start = [Math]::Max(0,$position-200) + $Offset }
}
$start = [Math]::Min($start,$record.text.Length)
$length = [Math]::Min($MaxChars,$record.text.Length-$start)
$next = $start+$length
[ordered]@{
    topicId=$TopicId; title=$route.title
    url="https://www.ibm.com/docs/en/order-management?topic=$TopicId"
    retrievedAt=$record.retrievedAt; containsMatched=$matched
    offset=$start; totalChars=$record.text.Length
    truncated=($start -gt 0 -or $next -lt $record.text.Length)
    nextOffset=$(if ($next -lt $record.text.Length) { $next } else { $null })
    continuation='Use nextOffset as -Offset without -Contains.'
    text=$record.text.Substring($start,$length)
} | ConvertTo-Json -Depth 4
