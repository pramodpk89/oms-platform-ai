param(
    [Parameter(Mandatory = $true)][string]$ZipPath,
    [Parameter(Mandatory = $true)][string]$FixPack,
    [string]$OutputDir = (Join-Path $PSScriptRoot '../documentation/bundle'),
    [ValidateRange(1, 50331648)][int]$PartBytes = 50331648
)
. "$PSScriptRoot/shared/Erd.ps1"
Assert-ErdVersion $FixPack
if (Test-Path -LiteralPath $OutputDir) { throw 'Output directory already exists. Package into a new directory, then replace the tracked bundle after review.' }
$inputFile = (Resolve-Path -LiteralPath $ZipPath).Path
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($inputFile)
try { if (!@($archive.Entries | Where-Object { $_.FullName -match '(?i)(^|/)ERD/HTML/' }).Count) { throw 'ZIP has no ERD/HTML directory.' } } finally { $archive.Dispose() }
$null = New-Item -ItemType Directory -Path $OutputDir
$source = [IO.File]::OpenRead($inputFile)
$parts = @()
try {
    $buffer = New-Object byte[] ([Math]::Min(1MB, $PartBytes))
    $number = 1
    while ($source.Position -lt $source.Length) {
        $name = 'xapidocs.zip.part{0:d3}' -f $number
        $target = [IO.File]::Create((Join-Path $OutputDir $name))
        try {
            $remaining = $PartBytes
            while ($remaining -gt 0) {
                $count = $source.Read($buffer, 0, [Math]::Min($buffer.Length, $remaining))
                if (!$count) { break }
                $target.Write($buffer, 0, $count); $remaining -= $count
            }
        } finally { $target.Dispose() }
        $parts += $name; $number++
    }
} finally { $source.Dispose() }
Write-ErdJson ([ordered]@{ fixPack = $FixPack; fileName = 'xapidocs.zip'; sha256 = (Get-FileHash -LiteralPath $inputFile -Algorithm SHA256).Hash.ToLowerInvariant(); parts = $parts }) (Join-Path $OutputDir 'manifest.json')
Write-Output "Packaged $($parts.Count) parts in $OutputDir"
