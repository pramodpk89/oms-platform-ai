param([string]$Environment, [string]$ConfigDir)
. "$PSScriptRoot/shared/Common.ps1"
$c = Get-OmsContext $Environment $ConfigDir
Write-JsonResult @{ environment = $c.Name; settings = $c.Settings; credentialFile = (Join-Path $c.ConfigDir 'credentials.json') }
