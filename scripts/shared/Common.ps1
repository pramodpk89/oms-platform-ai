Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))

function Read-JsonFile([string]$Path) {
    if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing configuration. Run scripts/init.ps1." }
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Get-OmsContext([string]$Environment, [string]$ConfigDir) {
    if (!$ConfigDir) { $ConfigDir = Join-Path $script:RepoRoot '.local' }
    $config = Read-JsonFile (Join-Path $ConfigDir 'environments.json')
    if (!$Environment) { $Environment = $config.defaultEnvironment }
    if ($Environment -notmatch '^[a-z][a-z0-9-]*$') { throw 'Invalid environment name.' }
    $property = $config.environments.PSObject.Properties[$Environment]
    if (!$property -or $property.Value.enabled -isnot [bool] -or !$property.Value.enabled) { throw "Environment '$Environment' is unconfigured or disabled. Run init.ps1 -Environment $Environment." }
    [pscustomobject]@{ Name = $Environment; Settings = $property.Value; Config = $config; ConfigDir = $ConfigDir }
}
function Get-OmsCredential($Context, [string]$Service) {
    $all = Read-JsonFile (Join-Path $Context.ConfigDir 'credentials.json')
    $envProperty = $all.PSObject.Properties[$Context.Name]
    if (!$envProperty) { throw 'Missing credentials for selected environment.' }
    $envProperty.Value
}
function Resolve-RepoPath([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) { return $Path }
    Join-Path $script:RepoRoot $Path
}
function Write-JsonResult($Value) { $Value | ConvertTo-Json -Depth 16 -Compress }
function Protect-OmsText([string]$Text, $Credential) {
    foreach ($name in @('password','token')) {
        $p = $Credential.PSObject.Properties[$name]
        if ($p -and $p.Value) { $Text = $Text.Replace([string]$p.Value, '[REDACTED]') }
    }
    $h = $Credential.PSObject.Properties['headers']
    if ($h) { foreach ($p in $h.Value.PSObject.Properties) { if ($p.Value) { $Text = $Text.Replace([string]$p.Value, '[REDACTED]') } } }
    $Text
}
