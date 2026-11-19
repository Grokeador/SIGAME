# Builds SIGAME.exe from SIGAME.cs with the C# compiler that ships with Windows (.NET Framework 4).
# Then makes the release zip: SIGAME.exe + the files SIGAME needs to run (no docs/tests/tools).
param([string]$Out = (Join-Path $PSScriptRoot 'out'))
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$ver = (Get-Content (Join-Path $repo 'version.json') -Raw | ConvertFrom-Json).Version
New-Item -ItemType Directory -Force $Out | Out-Null
$exe = Join-Path $Out 'SIGAME.exe'
& $csc /nologo /target:winexe /optimize+ /platform:anycpu "/win32icon:$(Join-Path $repo 'SI-GAME.ico')" "/out:$exe" /r:System.Windows.Forms.dll (Join-Path $PSScriptRoot 'SIGAME.cs')
if ($LASTEXITCODE) { throw "csc failed ($LASTEXITCODE)" }
$stage = Join-Path $Out 'SIGAME'
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory $stage | Out-Null
Push-Location $repo
try {
    foreach ($f in @(git ls-files) | Where-Object { $_ -notmatch '^(docs|tests|tools|winget|launcher|\.github)/' -and $_ -ne '.gitignore' }) {
        $to = Join-Path $stage $f
        New-Item -ItemType Directory -Force (Split-Path -Parent $to) | Out-Null
        Copy-Item -LiteralPath $f -Destination $to
    }
} finally { Pop-Location }
Copy-Item $exe $stage
$zip = Join-Path $Out "SIGAME-$ver.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip)
"$zip  SHA256 $((Get-FileHash $zip -Algorithm SHA256).Hash)"
