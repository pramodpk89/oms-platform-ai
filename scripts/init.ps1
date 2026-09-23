param([string]$Environment = 'local', [switch]$NonInteractive, [string]$ConfigDir, [string]$BundleDir = (Join-Path $PSScriptRoot '../documentation/bundle'))
. "$PSScriptRoot/shared/Common.ps1"
if ($Environment -notmatch '^[a-z][a-z0-9-]*$') { throw 'Invalid environment name.' }
if (!$ConfigDir) { $ConfigDir = Join-Path $script:RepoRoot '.local' }
$null = New-Item -ItemType Directory -Path $ConfigDir -Force
foreach ($file in @('environments','credentials')) {
    $target = Join-Path $ConfigDir "$file.json"
    if (!(Test-Path -LiteralPath $target)) { Copy-Item -LiteralPath (Join-Path $script:RepoRoot "config/$file.example.json") -Destination $target }
}
$documentation = & "$PSScriptRoot/prepare-docs.ps1" -DataDir $ConfigDir -BundleDir $BundleDir | ConvertFrom-Json
if ($NonInteractive) { Write-JsonResult @{ status = 'templates-ready'; configDir = $ConfigDir; documentation = $documentation }; return }
$config = Read-JsonFile (Join-Path $ConfigDir 'environments.json')
$creds = Read-JsonFile (Join-Path $ConfigDir 'credentials.json')
if (!$config.environments.PSObject.Properties[$Environment]) {
    $template = Read-JsonFile (Join-Path $script:RepoRoot 'config/environments.example.json')
    $config.environments | Add-Member -NotePropertyName $Environment -NotePropertyValue $template.environments.dev
    $template = Read-JsonFile (Join-Path $script:RepoRoot 'config/credentials.example.json')
    $creds | Add-Member -NotePropertyName $Environment -NotePropertyValue $template.dev
}
$settings = $config.environments.$Environment
function Read-Setting([string]$Label, [string]$Current) {
    $answer = Read-Host "$Label [$Current] (Enter keeps current)"
    if ($answer) { return $answer }; return $Current
}
$config.javaPath = Read-Setting 'Java executable or full path' $config.javaPath
$config.driverPath = Read-Setting 'DB2 JDBC JAR path (copy from DBeaver if available)' $config.driverPath
$settings.orderHubUrl = Read-Setting 'Order Hub URL' $settings.orderHubUrl
$settings.apiTesterUrl = Read-Setting 'API Tester URL' $settings.apiTesterUrl
$settings.rest.baseUrl = Read-Setting 'REST base URL (leave blank if unknown)' $settings.rest.baseUrl
$settings.rest.auth = Read-Setting 'REST auth: basic, bearer, headers, none' $settings.rest.auth
if ($settings.rest.auth -notin @('basic','bearer','headers','none')) { throw 'Unsupported REST authentication.' }
$settings.db2.host = Read-Setting 'DB2 host (use working DBeaver connection)' $settings.db2.host
$settings.db2.port = [int](Read-Setting 'DB2 port' $settings.db2.port)
$settings.db2.database = Read-Setting 'DB2 database' $settings.db2.database
$settings.db2.schema = Read-Setting 'DB2 schema' $settings.db2.schema
Write-Host 'DB2 requires a SELECT-only account. An instance administrator is not read-only.'
$answer = Read-Host 'Have its read-only database grants been verified? yes/no (Enter preserves setting)'
if ($answer) { $settings.db2.readOnlyAccountVerified = ($answer -eq 'yes') }
foreach ($service in @('db2','orderhub','apiTester','rest')) {
    $credential = $creds.$Environment.$service
    $credential.username = Read-Setting "$service username" $credential.username
    $secret = Read-Host "$service password (Enter preserves setting)" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
    try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr); if ($plain) { $credential.password = $plain } }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr); $plain = $null }
}
if ($settings.rest.auth -eq 'bearer') {
    $secret = Read-Host 'REST bearer token (Enter preserves setting)' -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
    try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr); if ($plain) { $creds.$Environment.rest.token = $plain } }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr); $plain = $null }
}
if ($settings.rest.auth -eq 'headers') { Write-Host 'Set deployment-specific auth headers in this environment''s rest.headers credential object.' }
$settings.enabled = $true
if ((Read-Host "Make $Environment the default? yes/no") -eq 'yes') { $config.defaultEnvironment = $Environment }
$config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $ConfigDir 'environments.json') -Encoding UTF8
$creds | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $ConfigDir 'credentials.json') -Encoding UTF8
Write-JsonResult @{ status = 'configured'; environment = $Environment; next = 'Run scripts/check-setup.ps1' }
