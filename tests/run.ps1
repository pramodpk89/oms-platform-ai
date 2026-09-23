param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
$temp = Join-Path ([IO.Path]::GetTempPath()) ('oms-toolkit-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $temp
$script:checks = 0
function Assert([bool]$Value, [string]$Message) { if (!$Value) { throw "FAILED: $Message" }; $script:checks++ }
function Expect-Failure([scriptblock]$Action, [string]$Message) {
    $failed = $false; try { $null = & $Action } catch { $failed = $true }; Assert $failed $Message
}
function Save-Json($Object, [string]$Path) { $Object | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $Path -Encoding UTF8 }
$server = $null
try {
    # Parse every PowerShell file without executing it.
    foreach ($file in Get-ChildItem $repo -Filter '*.ps1' -Recurse | Where-Object { $_.FullName -notmatch '[\\/]work[\\/]' }) {
        $tokens = $null; $errors = $null
        $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
        Assert ($errors.Count -eq 0) "Parse $($file.Name)"
    }
    & "$repo/scripts/build-db2.ps1"
    & javac --release 8 -cp "$repo/tools/db2-client/oms-db2.jar" -d $temp "$PSScriptRoot/OmsDb2Test.java" "$PSScriptRoot/MockServer.java" "$PSScriptRoot/DB2Driver.java"
    Assert ($LASTEXITCODE -eq 0) 'Compile fixtures'
    & java -cp ("$repo/tools/db2-client/oms-db2.jar" + [IO.Path]::PathSeparator + $temp) OmsDb2Test
    Assert ($LASTEXITCODE -eq 0) 'JDBC and SQL tests'

    $null = & "$repo/scripts/init.ps1" -NonInteractive -ConfigDir $temp
    $cfgPath = Join-Path $temp 'environments.json'
    $credsPath = Join-Path $temp 'credentials.json'
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    $cfg.defaultEnvironment = 'local'
    Save-Json $cfg $cfgPath
    $before = [IO.File]::ReadAllText($cfgPath)
    $null = & "$repo/scripts/init.ps1" -NonInteractive -ConfigDir $temp
    Assert ([IO.File]::ReadAllText($cfgPath) -eq $before) 'Setup preserves existing config'
    $envResult = & "$repo/scripts/get-environment.ps1" -ConfigDir $temp | ConvertFrom-Json
    Assert ($envResult.environment -eq 'local') 'Default selection'
    Expect-Failure { & "$repo/scripts/get-environment.ps1" -Environment qa -ConfigDir $temp } 'Disabled environment'
    Expect-Failure { & "$repo/scripts/get-environment.ps1" -Environment unknown -ConfigDir $temp } 'Missing environment'
    Expect-Failure { & "$repo/scripts/get-environment.ps1" -Environment '../local' -ConfigDir $temp } 'Invalid environment'

    $creds = Get-Content $credsPath -Raw | ConvertFrom-Json
    $creds.local.db2.username = 'fixture'; $creds.local.db2.password = 'fixture-password'
    Save-Json $creds $credsPath
    $fakeJar = Join-Path $temp 'fake-driver.jar'
    & jar cf $fakeJar -C $temp OmsDb2Test.class -C $temp com
    Assert ($LASTEXITCODE -eq 0) 'Package fake JDBC driver'
    $cfg.driverPath = $fakeJar
    Save-Json $cfg $cfgPath
    $queryPath = Join-Path $temp 'query.sql'
    'SELECT * FROM {{schema}}.T WHERE ID = ?' | Set-Content $queryPath
    $paramPath = Join-Path $temp 'params.json'
    '[{"type":"string","value":"Unicode Ω and quote ''"}]' | Set-Content $paramPath -Encoding UTF8
    Expect-Failure { & "$repo/scripts/invoke-db2.ps1" -ConfigDir $temp -SqlFile $queryPath -ParametersFile $paramPath } 'Wrapper blocks unverified query'
    $cfg.environments.local.db2.readOnlyAccountVerified = $true; Save-Json $cfg $cfgPath
    $r = & "$repo/scripts/invoke-db2.ps1" -ConfigDir $temp -SqlFile $queryPath -ParametersFile $paramPath -Limit 2 | ConvertFrom-Json
    Assert ($r.rowCount -eq 2 -and $r.truncated -and $r.environment -eq 'local') 'PowerShell to JDBC round trip'
    $r = & "$repo/scripts/invoke-db2.ps1" -ConfigDir $temp -Probe | ConvertFrom-Json
    Assert (!$r.queryExecuted -and $r.status -eq 'connected') 'Wrapper probe'
    $spaceDir = Join-Path $temp 'paths with spaces'
    $null = New-Item -ItemType Directory -Path $spaceDir
    Copy-Item $fakeJar (Join-Path $spaceDir 'driver with spaces.jar')
    $cfg.driverPath = Join-Path $spaceDir 'driver with spaces.jar'; Save-Json $cfg $cfgPath
    $r = & "$repo/scripts/invoke-db2.ps1" -ConfigDir $temp -Probe | ConvertFrom-Json
    Assert ($r.status -eq 'connected') 'Driver path with spaces'

    $portFile = Join-Path $temp 'port'
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = 'java'; $start.Arguments = '-cp "' + $temp + '" MockServer "' + $portFile + '"'; $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $server = [Diagnostics.Process]::Start($start)
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (!(Test-Path $portFile) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
    Assert (Test-Path $portFile) 'Mock server start'
    $port = Get-Content $portFile -Raw
    $cfg.environments.local.rest.baseUrl = "http://127.0.0.1:$port/api/"
    Save-Json $cfg $cfgPath
    $creds = Get-Content $credsPath -Raw | ConvertFrom-Json
    $creds.local.rest.username = 'fixture'; $creds.local.rest.password = 'fixture-password'
    Save-Json $creds $credsPath
    $reqPath = Join-Path $temp 'request.json'
    $req = [ordered]@{ method = 'GET'; path = 'echo'; effect = 'read' }
    Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.status -eq 200 -and $r.body.Contains('ok')) 'REST success'
    Assert (!$r.body.Contains('fixture-password') -and !$r.body.Contains([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('fixture:fixture-password')))) 'Secret redaction'
    $req.method = 'POST'; $req.path = 'write'; $req.effect = 'write'; Save-Json $req $reqPath
    Expect-Failure { & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath } 'Unconfirmed write blocked'
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath -ConfirmedWrite | ConvertFrom-Json
    Assert ($r.body.Contains('changed')) 'Confirmed mock write'
    $req.method = 'GET'; $req.path = 'redirect'; $req.effect = 'read'; Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.status -eq 302) 'Redirect not followed'
    $req.path = 'count'; Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.body -eq '1') 'Only the confirmed write reached server'
    $req.path = 'error'; Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.status -eq 400 -and !$r.httpSuccess) 'HTTP error preserved'
    $req.path = 'large'; Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.truncated -and $r.body.Length -lt 4000) 'Bounded response'
    $req.path = 'empty'; Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.body -eq '') 'Empty response'
    $cfg.environments.qa.enabled = $true
    $cfg.environments.qa.rest.baseUrl = "http://127.0.0.1:$port/api/"
    $cfg.environments.qa.rest.auth = 'bearer'
    $creds.qa.rest.token = 'qa-fixture-token'
    Save-Json $cfg $cfgPath; Save-Json $creds $credsPath
    $req.path = 'echo'; Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -Environment qa -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.environment -eq 'qa' -and $r.body.Contains('Bearer [REDACTED]') -and !$r.body.Contains('qa-fixture-token')) 'QA uses its own bearer credentials'
    $cfg.environments.qa.rest.auth = 'headers'
    $creds.qa.rest.headers | Add-Member -NotePropertyName 'Authorization' -NotePropertyValue 'Custom qa-fixture-token'
    Save-Json $cfg $cfgPath; Save-Json $creds $credsPath
    $r = & "$repo/scripts/invoke-rest.ps1" -Environment qa -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.body.Contains('[REDACTED]') -and !$r.body.Contains('qa-fixture-token')) 'Custom auth headers'
    $req.path = 'payload'; $req.method = 'POST'; $req.bodyFile = 'payload.xml'; $req.contentType = 'application/xml'
    '<Order OrderNo="TEST-1"/>' | Set-Content (Join-Path $temp 'payload.xml') -Encoding UTF8
    Save-Json $req $reqPath
    $r = & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath | ConvertFrom-Json
    Assert ($r.body.Contains('TEST-1')) 'Read-only POST payload'
    $req.Remove('bodyFile'); $req.Remove('contentType'); $req.method = 'GET'
    $req.path = 'slow'; Save-Json $req $reqPath
    Expect-Failure { & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath -TimeoutSeconds 1 } 'Slow response times out'
    foreach ($path in @('../write','https://example.com','//example.com','%2e%2e/write')) {
        $req.path = $path; Save-Json $req $reqPath
        Expect-Failure { & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath } 'Endpoint confinement'
    }
    $req.path = 'write'; $req.method = 'DELETE'; $req.effect = 'read'; Save-Json $req $reqPath
    Expect-Failure { & "$repo/scripts/invoke-rest.ps1" -ConfigDir $temp -RequestFile $reqPath } 'DELETE cannot claim read effect'

    foreach ($skill in Get-ChildItem "$repo/.github/skills" -Filter 'SKILL.md' -Recurse) {
        $text = Get-Content $skill.FullName -Raw
        Assert ($text -match '(?s)^---\r?\nname: ([a-z0-9-]+)\r?\ndescription: [^\r\n]+\r?\n---') "Frontmatter $($skill.Directory.Name)"
        Assert ($Matches[1] -eq $skill.Directory.Name) 'Skill folder matches name'
        Assert (($text -split '\s+').Count -lt 450) "Skill budget $($skill.Directory.Name)"
        foreach ($link in [regex]::Matches($text, '\]\(([^)]+)\)')) {
            if ($link.Groups[1].Value -notmatch '^https?://') { Assert (Test-Path (Join-Path $skill.DirectoryName $link.Groups[1].Value)) 'Skill reference exists' }
        }
    }
    $globalText = Get-Content "$repo/.github/copilot-instructions.md" -Raw
    Assert (($globalText -split '\s+').Count -lt 250) 'Always-loaded budget'
    foreach ($template in Get-ChildItem "$repo/config" -Filter '*.json') { $null = Get-Content $template.FullName -Raw | ConvertFrom-Json; $script:checks++ }
    Write-Output "PowerShell checks passed: $script:checks"
} finally {
    if ($server) { if (!$server.HasExited) { $server.Kill(); $server.WaitForExit() }; $server.Dispose() }
    # Only the freshly created fixture directory is removed.
    if ($temp -and (Split-Path -Leaf $temp) -match '^oms-toolkit-[a-f0-9]{32}$') { Remove-Item -LiteralPath $temp -Recurse -Force }
}
