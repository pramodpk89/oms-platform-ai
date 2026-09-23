param(
    [string]$DataDir = (Join-Path $PSScriptRoot '../.local'),
    [string]$BundleDir = (Join-Path $PSScriptRoot '../documentation/bundle'),
    [switch]$ArchiveOnly
)
. "$PSScriptRoot/shared/Erd.ps1"
$manifest = Read-ErdJson (Join-Path $BundleDir 'manifest.json')
Assert-ErdVersion $manifest.fixPack
if ($manifest.sha256 -notmatch '^[a-fA-F0-9]{64}$' -or !$manifest.parts.Count) { throw 'Invalid documentation bundle manifest.' }
$docs = Join-Path $DataDir 'docs'
$null = New-Item -ItemType Directory -Force -Path $docs
$zipPath = Join-Path $docs 'xapidocs.zip'
$lock = $null; $temporary = $null
try {
    $lock = [IO.File]::Open((Join-Path $docs '.prepare.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    $valid = (Test-Path -LiteralPath $zipPath) -and ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -eq $manifest.sha256)
    if (!$valid) {
        $temporary = Join-Path $docs ('.archive-' + [guid]::NewGuid().ToString('N') + '.zip')
        $output = [IO.File]::Create($temporary)
        try {
            foreach ($part in $manifest.parts) {
                if ($part -notmatch '^xapidocs\.zip\.part[0-9]+$') { throw 'Invalid archive part name.' }
                $inputPart = [IO.File]::OpenRead((Join-Path $BundleDir $part))
                try { $inputPart.CopyTo($output) } finally { $inputPart.Dispose() }
            }
        } finally { $output.Dispose() }
        if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ne $manifest.sha256) { throw 'Bundled ZIP checksum mismatch. Restore the tracked archive parts from Git.' }
        if (Test-Path -LiteralPath $zipPath) { [IO.File]::Replace($temporary, $zipPath, [NullString]::Value) } else { [IO.File]::Move($temporary, $zipPath) }
        $temporary = $null
    }
    $erdRoot = Join-Path $DataDir 'erd'
    if (!$ArchiveOnly) {
        $snapshot = Join-Path $erdRoot "versions/$($manifest.fixPack)/manifest.json"
        if (!(Test-Path -LiteralPath $snapshot)) {
            $null = & "$PSScriptRoot/update-erd.ps1" -ZipPath $zipPath -FixPack $manifest.fixPack -KnowledgeRoot $erdRoot
        } else {
            $existing = Read-ErdJson $snapshot
            if ($existing.zipSha256 -ne $manifest.sha256) { throw 'Bundled version conflicts with existing ERD source; use a new fix-pack label.' }
        }
    }
    [ordered]@{ archive = [IO.Path]::GetFullPath($zipPath); fixPack = $manifest.fixPack; knowledgeRoot = [IO.Path]::GetFullPath($erdRoot) } | ConvertTo-Json
} finally {
    if ($temporary -and (Test-Path -LiteralPath $temporary)) { Remove-Item -LiteralPath $temporary -Force }
    if ($lock) { $lock.Dispose() }
}
