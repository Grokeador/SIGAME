# SI COMFIG - Team Fortress 2 - by SI NEWS, MIT.
# Installs mastercomfig 9.100.1 (github.com/mastercomfig/mastercomfig, MIT, by mastercoms): the TF2 config whose
# docs say its values "are based on TF2's source code". What this script does, as its install page
# (docs.comfig.app/latest/setup/install) says:
#   - downloads the official release asset mastercomfig-base.vpk and uses it only if the SHA-256 matches the one
#     GitHub publishes for it, then puts it in tf\custom;
#   - moves your own autoexec.cfg / listenserver.cfg / class configs into tf\cfg\overrides (mastercomfig runs them
#     from there, so they keep working);
#   - picks the mastercomfig preset for YOUR graphics card (tf\cfg\app\pre_init.cfg, the file mastercomfig reads
#     before its preset): NVIDIA GeForce / AMD Radeon = high, Intel graphics only = low, anything else = medium.
# Config files only (no game file patched). -Undo removes all of it and moves your files back.
param(
    [switch]$Undo,
    [string]$GameExe = '',     # given by SIGAME from the game card
    [string]$TfDir = '',       # test only: the TF2 game folder
    [string]$Vpk = '',         # test only: a local mastercomfig-base.vpk
    [string]$MockGpu = ''      # test only
)

$Url = 'https://github.com/mastercomfig/mastercomfig/releases/download/9.100.1/mastercomfig-base.vpk'
$Sha = 'CDABC8251864A1AB2EF7F7FFED1B44F52810956E476D62183B8D7E3E960D8650'
$Mine = @('autoexec.cfg', 'listenserver.cfg', 'scout.cfg', 'soldier.cfg', 'pyro.cfg', 'demoman.cfg',
          'heavyweapons.cfg', 'engineer.cfg', 'medic.cfg', 'sniper.cfg', 'spy.cfg')

function Find-TF2 {
    if ($TfDir) { return $TfDir }
    if ($GameExe -and (Test-Path -LiteralPath $GameExe)) {
        $d = Split-Path -Parent $GameExe
        foreach ($x in @($d, (Split-Path -Parent $d), (Split-Path -Parent (Split-Path -Parent $d)))) {
            if ($x -and (Test-Path -LiteralPath (Join-Path $x 'tf\gameinfo.txt'))) { return $x }
        }
    }
    $steam = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return $null }
    $libs = @($steam)
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value -replace '\\\\', '\' }
    }
    foreach ($l in $libs) {
        $x = Join-Path $l 'steamapps\common\Team Fortress 2'
        if (Test-Path -LiteralPath (Join-Path $x 'tf\gameinfo.txt')) { return $x }
    }
    return $null
}

$Game = Find-TF2
if (-not $Game) { Write-Output '[FAIL] Team Fortress 2 not found: install it from Steam, start it once, then APPLY.'; exit 2 }
if (Get-Process -Name 'tf_win64', 'tf', 'hl2' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Team Fortress 2 is running: close the game first, then APPLY.'
    exit 4
}
$Custom = Join-Path $Game 'tf\custom'
$CfgDir = Join-Path $Game 'tf\cfg'
$Over = Join-Path $CfgDir 'overrides'
$AppDir = Join-Path $CfgDir 'app'
$Dest = Join-Path $Custom 'mastercomfig-base.vpk'
$Pre = Join-Path $AppDir 'pre_init.cfg'
$Log = Join-Path $Custom 'mastercomfig-base.vpk.sigame.json'

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Log)) { Write-Output '[FAIL] SI COMFIG is not installed (no .sigame.json).'; exit 3 }
    $L = Get-Content -LiteralPath $Log -Raw | ConvertFrom-Json
    foreach ($f in @($L.Moved)) {
        $from = Join-Path $Over $f
        if (Test-Path -LiteralPath $from) { Move-Item -LiteralPath $from -Destination (Join-Path $CfgDir $f) -Force; Write-Output "[OK]   $f moved back to tf\cfg" }
    }
    foreach ($p in @($Dest, $Pre)) {
        Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath "$p.sigame.bak") { Move-Item -LiteralPath "$p.sigame.bak" -Destination $p -Force }
    }
    if ($L.MadeOver -and (Test-Path -LiteralPath $Over) -and -not (Get-ChildItem -LiteralPath $Over -Force)) { Remove-Item -LiteralPath $Over }
    Remove-Item -LiteralPath $Log -Force
    Write-Output '[OK]   mastercomfig removed, your configs are back where they were.'
    exit 0
}

# 1. the official vpk, SHA-256 checked
$Tmp = Join-Path $env:TEMP 'sigame-mastercomfig-base.vpk'
try {
    if ($Vpk) { Copy-Item -LiteralPath $Vpk -Destination $Tmp -Force }
    else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Url -OutFile $Tmp -UseBasicParsing -TimeoutSec 60
    }
} catch { Write-Output "[FAIL] Download failed: $($_.Exception.Message)"; exit 8 }
if ((Get-FileHash -LiteralPath $Tmp -Algorithm SHA256).Hash -ne $Sha) {
    Remove-Item -LiteralPath $Tmp -Force
    Write-Output '[FAIL] SHA-256 of the download does not match the official release: nothing installed.'
    exit 9
}
Write-Output '[OK]   mastercomfig 9.100.1 downloaded, SHA-256 matches the official release'

# 2. state for Undo (first apply only)
$First = -not (Test-Path -LiteralPath $Log)
$L = if ($First) { [pscustomobject]@{ Moved = @(); MadeOver = (-not (Test-Path -LiteralPath $Over)) } } else { Get-Content -LiteralPath $Log -Raw | ConvertFrom-Json }
New-Item -ItemType Directory -Force -Path $Custom, $Over, $AppDir | Out-Null
foreach ($p in @($Dest, $Pre)) {
    if ($First -and (Test-Path -LiteralPath $p) -and -not (Test-Path -LiteralPath "$p.sigame.bak")) { Copy-Item -LiteralPath $p -Destination "$p.sigame.bak" }
}
Copy-Item -LiteralPath $Tmp -Destination $Dest -Force
Remove-Item -LiteralPath $Tmp -Force
Write-Output '[OK]   tf\custom\mastercomfig-base.vpk'

# 3. your configs -> overrides (mastercomfig's install page)
$Moved = @($L.Moved)
foreach ($f in $Mine) {
    $src = Join-Path $CfgDir $f
    if (-not (Test-Path -LiteralPath $src)) { continue }
    if (Test-Path -LiteralPath (Join-Path $Over $f)) { Write-Output "[KEEP] $f`: overrides already has one, yours stays in tf\cfg"; continue }
    Move-Item -LiteralPath $src -Destination (Join-Path $Over $f)
    $Moved += $f
    Write-Output "[SET]  your $f -> tf\cfg\overrides (mastercomfig runs it from there)"
}

# 4. preset for this graphics card
$Gpus = if ($MockGpu) { @($MockGpu) } else { @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) }
$Preset = 'medium'
if ($Gpus | Where-Object { $_ -match '(?i)nvidia|geforce|radeon' }) { $Preset = 'high' }
elseif ($Gpus -and -not ($Gpus | Where-Object { $_ -notmatch '(?i)intel' })) { $Preset = 'low' }
[IO.File]::WriteAllText($Pre, "preset=$Preset`r`n")
Write-Output "[SET]  mastercomfig preset: $Preset (graphics: $($Gpus -join ' + '))"

[pscustomobject]@{ Moved = @($Moved | Select-Object -Unique); MadeOver = [bool]$L.MadeOver } | ConvertTo-Json | Set-Content -LiteralPath $Log -Encoding UTF8
Write-Output '[OK]   SI COMFIG applied, free. Launch options mastercomfig suggests: -novid -nojoy -nosteamcontroller -nohltv -particles 1. Undo = APPLY, Yes.'
exit 0
