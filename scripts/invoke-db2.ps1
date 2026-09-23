param([string]$Environment, [string]$ConfigDir, [string]$SqlFile, [string]$ParametersFile,
      [ValidateRange(1,1000)][int]$Limit = 50, [ValidateRange(1,300)][int]$TimeoutSeconds = 30, [switch]$Probe)
. "$PSScriptRoot/shared/Common.ps1"
$c = Get-OmsContext $Environment $ConfigDir
$credential = Get-OmsCredential $c 'db2'
$db = $c.Settings.db2
if ($db.readOnlyAccountVerified -isnot [bool]) { throw 'readOnlyAccountVerified must be a JSON boolean.' }
$inputValues = [ordered]@{ host = $db.host; port = $db.port; database = $db.database; schema = $db.schema; username = $credential.username; password = $credential.password; limit = $Limit; timeout = $TimeoutSeconds; readOnlyAccountVerified = $db.readOnlyAccountVerified.ToString().ToLowerInvariant() }
if ($Probe) { $inputValues.operation = 'probe' }
else {
    if (!$SqlFile) { throw 'Supply -SqlFile or -Probe.' }
    if ($db.schema -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'Invalid schema.' }
    $inputValues.sql = (Get-Content -LiteralPath $SqlFile -Raw -Encoding UTF8).Replace('{{schema}}', $db.schema)
    if ($ParametersFile) {
        $parameters = @(Read-JsonFile $ParametersFile)
        $inputValues.parameterCount = $parameters.Count
        for ($i = 0; $i -lt $parameters.Count; $i++) {
            $inputValues["parameter.$i.type"] = $parameters[$i].type
            $inputValues["parameter.$i.value"] = $parameters[$i].value
        }
    }
}
$driver = Resolve-RepoPath $c.Config.driverPath
if (!(Test-Path -LiteralPath $driver -PathType Leaf)) { throw 'DB2 driver missing. Set driverPath to your approved JDBC JAR.' }
$jar = Join-Path $script:RepoRoot 'tools/db2-client/oms-db2.jar'
$lines = foreach ($key in $inputValues.Keys) { "$key=$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$inputValues[$key])))" }
$cp = $jar + [IO.Path]::PathSeparator + $driver
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName = $c.Config.javaPath
$start.Arguments = '-cp "' + $cp + '" OmsDb2'
$start.UseShellExecute = $false
$start.RedirectStandardInput = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
$start.CreateNoWindow = $true
$process = New-Object Diagnostics.Process
$process.StartInfo = $start
try {
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
    # Send exact UTF-8 bytes: Windows PowerShell/.NET may otherwise emit a BOM.
    $wire = [Text.Encoding]::UTF8.GetBytes(($lines -join "`n") + "`n")
    $process.StandardInput.BaseStream.Write($wire, 0, $wire.Length)
    $process.StandardInput.BaseStream.Flush(); $process.StandardInput.BaseStream.Close()
    if (!$process.WaitForExit(($TimeoutSeconds + 15) * 1000)) { $process.Kill(); throw 'DB2 helper timed out; no automatic retry.' }
    $result = $stdout.GetAwaiter().GetResult()
    if (!$result) { throw 'DB2 helper failed to start. Verify Java 8+ and driver paths.' }
    $parsed = $result | ConvertFrom-Json
    $parsed | Add-Member -NotePropertyName environment -NotePropertyValue $c.Name
    Write-JsonResult $parsed
    if ($process.ExitCode -ne 0) { throw ('DB2 helper: ' + $parsed.error) }
} finally { $process.Dispose(); $lines = $null; $inputValues = $null }
