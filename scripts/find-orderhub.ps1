param(
    [string]$Query,
    [string]$Entity,
    [ValidateSet('any','legacy','next_generation')][string]$Branch = 'any',
    [ValidateRange(1,5)][int]$Limit = 3
)
$ErrorActionPreference = 'Stop'
$root = "$PSScriptRoot/../.github/skills/oms-orderhub/references"
$graph = Get-Content -LiteralPath "$root/graph.json" -Raw | ConvertFrom-Json
$index = Get-Content -LiteralPath "$root/topics.json" -Raw | ConvertFrom-Json
function Normalize([string]$Text) {
    # Small lexical normalizer, not an LLM call. Exact live-data IDs are never modified.
    $words = @([regex]::Matches($Text.ToLowerInvariant(), '[a-z0-9]+') | ForEach-Object {
        $w = $_.Value
        if ($w.Length -gt 3 -and $w.EndsWith('s') -and !$w.EndsWith('ss') -and !$w.EndsWith('us')) { $w = $w.Substring(0,$w.Length-1) }
        $w
    })
    return ' ' + ($words -join ' ') + ' '
}
if (!$Entity -and [string]::IsNullOrWhiteSpace($Query)) { throw 'Provide -Query or -Entity.' }
$q = Normalize $Query
$ranked = @()
foreach ($node in $graph.entities) {
    $score = 0
    foreach ($term in $node.terms) {
        $needle = Normalize $term
        if ($q.Contains($needle)) { $score += 10 * @($needle.Trim() -split ' ').Count }
    }
    # A requested attribute such as tracking outranks the generic word 'order'.
    if ($node.id -eq 'order' -and $score -gt 0) { $score-- }
    if ($Entity) { $score = if ($node.id -eq $Entity) { 10000 } else { 0 } }
    if ($score -gt 0) { $ranked += [pscustomobject]@{ score=$score; node=$node } }
}
if ($Entity -and !$ranked.Count) { throw "Unknown entity '$Entity'. Valid: $($graph.entities.id -join ', ')" }
$ranked = @($ranked | Sort-Object @{Expression='score';Descending=$true}, @{Expression={$_.node.id}})
$selected = if ($ranked.Count) { $ranked[0].node } else { $null }
$stop = @('a','an','the','in','on','of','for','to','from','by','at','with','and','or','how','do','i','my','me','show','find','get','fetch','search','searching','please','local','orderhub')
$words = @($q.Trim() -split ' ' | Where-Object { $_ -and $_ -notin $stop } | Select-Object -Unique)
$hits = @()
foreach ($page in $index.pages) {
    $routes = @($page.routes | Where-Object { $Branch -eq 'any' -or $_.branch -eq $Branch })
    if (!$routes.Count) { continue }
    $best = $null; $bestScore = 0
    # Graph topic aliases may use next-generation IDs; shared content maps to legacy routes by path.
    $linked = $selected -and @($page.routes | Where-Object { $_.id -in $selected.topics }).Count -gt 0
    foreach ($route in $routes) {
        $s = if ($linked) { 40 } else { 0 }
        $title = Normalize $route.title
        foreach ($word in $words) { if ($title.Contains(" $word ")) { $s += 5 } }
        if ($s -gt 0 -and $route.title -match '^(Searching|Viewing)\b') { $s += 2 }
        if ($s -gt $bestScore) { $best = $route; $bestScore = $s }
    }
    if ($best) { $hits += [pscustomobject]@{ score=$bestScore; topicId=$best.id; title=$best.title; branch=$best.branch; url="https://www.ibm.com/docs/en/order-management?topic=$($best.id)" } }
}
$hits = @($hits | Sort-Object @{Expression='score';Descending=$true}, topicId)
$workflow = if ($selected) { [ordered]@{ entity=$selected.id; screen=$selected.screen; filters=$selected.filters; read=$selected.read; cautions=$selected.cautions; relations=$selected.edges } } else { $null }
[ordered]@{
    documentationSnapshot=$index.retrievedAt
    branch=$Branch
    workflow=$workflow
    alternatives=@($ranked | Select-Object -Skip 1 -First 2 | ForEach-Object { $_.node.id })
    routing='Lexical suggestions; select the entity and direction from user intent. Not a live search or a confidence score.'
    totalTopicMatches=$hits.Count
    truncated=($hits.Count -gt $Limit)
    topics=@($hits | Select-Object -First $Limit -Property topicId,title,branch,url)
} | ConvertTo-Json -Depth 8
