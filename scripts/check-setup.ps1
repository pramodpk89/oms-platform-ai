param([string]$Environment, [string]$ConfigDir, [switch]$Connect)
. "$PSScriptRoot/shared/Common.ps1"
$c = Get-OmsContext $Environment $ConfigDir
$checks = [ordered]@{ environment = $c.Name; powershell = $PSVersionTable.PSVersion.ToString(); javaAvailable = $false; driverAvailable = $false; helperAvailable = $false; dbReadOnlyVerified = $c.Settings.db2.readOnlyAccountVerified }
try { $null = Get-Command $c.Config.javaPath -ErrorAction Stop; $checks.javaAvailable = $true } catch {}
$checks.driverAvailable = Test-Path -LiteralPath (Resolve-RepoPath $c.Config.driverPath) -PathType Leaf
$checks.helperAvailable = Test-Path -LiteralPath (Join-Path $script:RepoRoot 'tools/db2-client/oms-db2.jar')
if ($Connect) {
    $tcp = New-Object Net.Sockets.TcpClient
    try { $task = $tcp.ConnectAsync($c.Settings.db2.host, [int]$c.Settings.db2.port); $checks.dbPortReachable = $task.Wait(3000) -and $tcp.Connected }
    catch { $checks.dbPortReachable = $false } finally { $tcp.Dispose() }
}
Write-JsonResult $checks
