param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
$root = "$repo/.github/skills/oms-orderhub/references"
$script:hubChecks = 0
function HubCheck([bool]$Value, [string]$Message) { if (!$Value) { throw "Order Hub FAILED: $Message" }; $script:hubChecks++ }
function HubFails([scriptblock]$Action, [string]$Message) {
    $failed=$false; try { $null = & $Action } catch { $failed=$true }; HubCheck $failed $Message
}
$graph = Get-Content "$root/graph.json" -Raw | ConvertFrom-Json
$index = Get-Content "$root/topics.json" -Raw | ConvertFrom-Json
$ids = @($index.pages | ForEach-Object { $_.routes.id })
HubCheck (@($index.pages.path | Select-Object -Unique).Count -eq $index.pages.Count) 'source paths deduplicated'
HubCheck (@($ids | Select-Object -Unique).Count -eq $ids.Count) 'topic IDs unique'
foreach ($node in $graph.entities) {
    foreach ($topic in $node.topics) { HubCheck ($topic -in $ids) "source for $($node.id): $topic" }
    foreach ($edge in $node.edges) { HubCheck ($edge.to -in $graph.entities.id) "edge target $($edge.to)" }
}
$cases = @{
    'find order 10001'='order'
    'purchase order receipts'='inbound-order'
    'inventory for SKU ABC at a node'='inventory'
    'show stock history for ABC'='inventory-audit'
    'integration errors yesterday'='exception'
    'show tracking for order 10001'='shipment'
    'line statuses and line shipping nodes'='order-line'
    'line statuses'='order-line'
    'release statuses'='order-release'
    'get inbound shipments'='inbound-shipment'
    'refund for return 10001'='return'
    'payment status on order 10001'='order-details'
}
foreach ($query in $cases.Keys) {
    $raw = & "$repo/scripts/find-orderhub.ps1" -Query $query
    $r = $raw | ConvertFrom-Json
    HubCheck ($r.workflow.entity -eq $cases[$query]) "route: $query"
    HubCheck ($r.topics.Count -le 3 -and $raw.Length -lt 6000) 'bounded default output'
}
$r = & "$repo/scripts/find-orderhub.ps1" -Entity order -Branch legacy | ConvertFrom-Json
HubCheck ($r.topics.Count -gt 0 -and @($r.topics | Where-Object { $_.branch -ne 'legacy' }).Count -eq 0) 'legacy route isolation'
$r = & "$repo/scripts/find-orderhub.ps1" -Query 'zxqv987nonexistent' | ConvertFrom-Json
HubCheck ($null -eq $r.workflow -and $r.topics.Count -eq 0) 'no invented match'
$r = & "$repo/scripts/find-orderhub.ps1" -Query 'distribution groups' -Limit 1 | ConvertFrom-Json
HubCheck ($r.topics.Count -eq 1 -and $r.truncated) 'title search outside curated graph and limit'
HubFails { & "$repo/scripts/find-orderhub.ps1" -Entity bogus } 'unknown entity rejected'
HubFails { & "$repo/scripts/find-orderhub.ps1" -Query ' ' } 'empty query rejected'
HubFails { & "$repo/scripts/get-orderhub-topic.ps1" -TopicId '../bad' } 'unindexed fetch rejected'

$temp = Join-Path ([IO.Path]::GetTempPath()) ('oms-hub-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $temp
try {
    # Cached synthetic article: no dependency on network or live OMS.
    $page = @($index.pages | Where-Object { 'orders-searching-outbound' -in $_.routes.id })[0]
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $key = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($page.path)))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
    $body = ('preface ' * 100) + 'Shipping node matches release-level nodes. ' + ('tail ' * 200)
    @{ retrievedAt='2026-01-01T00:00:00Z'; text=$body } | ConvertTo-Json | Set-Content (Join-Path $temp "$key.json") -Encoding UTF8
    $r = & "$repo/scripts/get-orderhub-topic.ps1" -TopicId orders-searching-outbound -Contains 'Shipping node' -MaxChars 300 -CacheDir $temp | ConvertFrom-Json
    HubCheck ($r.containsMatched -and $r.text.Contains('Shipping node') -and $r.text.Length -eq 300 -and $r.truncated) 'focused bounded excerpt'
    $next = & "$repo/scripts/get-orderhub-topic.ps1" -TopicId orders-searching-outbound -Offset $r.nextOffset -MaxChars 300 -CacheDir $temp | ConvertFrom-Json
    HubCheck ($next.offset -eq $r.nextOffset -and $next.text -eq $body.Substring($next.offset,300)) 'continuation has no gap'
    $r = & "$repo/scripts/get-orderhub-topic.ps1" -TopicId orders-searching-outbound -Contains 'absent' -CacheDir $temp | ConvertFrom-Json
    HubCheck (!$r.containsMatched) "literal excerpt miss: $($r.containsMatched)"
    HubCheck (([DateTime]$r.retrievedAt).ToUniversalTime() -eq ([DateTime]'2026-01-01T00:00:00Z').ToUniversalTime()) 'cache timestamp preserved'
    $r = & "$repo/scripts/get-orderhub-topic.ps1" -TopicId orders-searching-outbound -Offset 99999 -CacheDir $temp | ConvertFrom-Json
    HubCheck ($r.text -eq '' -and $null -eq $r.nextOffset) 'offset beyond end terminates'
    # Refresh fixture retains branch aliases but merges shared content and excludes containers.
    $fixture = @{toc=@{topics=@(
        @{topicId='managing-using-order-hub';label='Legacy';topics=@(@{topicId='legacy-x';label='Search';href='SSGTJF/buc/x.html?pos=2'})},
        @{topicId='managing-using-next-generation-order-hub';label='Next';topics=@(@{topicId='next-x';label='Search';href='SSGTJF/buc/x.html'})}
    )}}
    $tocPath = Join-Path $temp 'toc.json'; $indexPath = Join-Path $temp 'index.json'
    $fixture | ConvertTo-Json -Depth 12 | Set-Content $tocPath -Encoding UTF8
    $null = & "$repo/scripts/update-orderhub-index.ps1" -TocFile $tocPath -OutputFile $indexPath
    $r = Get-Content $indexPath -Raw | ConvertFrom-Json
    HubCheck ($r.pages.Count -eq 1 -and $r.pages[0].routes.Count -eq 2) 'refresh deduplicates navigation aliases'
    $before = Get-Content $indexPath -Raw
    '{}' | Set-Content $tocPath
    HubFails { & "$repo/scripts/update-orderhub-index.ps1" -TocFile $tocPath -OutputFile $indexPath } 'bad refresh rejected'
    HubCheck ((Get-Content $indexPath -Raw) -eq $before) 'failed refresh preserves index'
    Write-Output "Order Hub checks passed: $script:hubChecks"
} finally {
    if ((Split-Path -Leaf $temp) -match '^oms-hub-[a-f0-9]{32}$') { Remove-Item -LiteralPath $temp -Recurse -Force }
}
