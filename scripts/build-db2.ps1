param([string]$Javac = 'javac', [string]$Jar = 'jar')
. "$PSScriptRoot/shared/Common.ps1"
$build = Join-Path $script:RepoRoot 'work/classes'
$null = New-Item -ItemType Directory -Path $build -Force
& $Javac --release 8 -d $build (Join-Path $script:RepoRoot 'tools/db2-client/OmsDb2.java')
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed (build requires JDK 9+).' }
& $Jar cf (Join-Path $script:RepoRoot 'tools/db2-client/oms-db2.jar') -C $build OmsDb2.class
if ($LASTEXITCODE -ne 0) { throw 'JAR packaging failed.' }
