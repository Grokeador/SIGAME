# SI PHOTOREAL - Cyberpunk 2077 2.5 photorealism, FREE - by SI NEWS, MIT.
# The top photoreal ReShade presets sit behind Patreon; this one is free. It goes on top of Nova LUT 4.0 (AgX, free,
# nexusmods.com/cyberpunk2077/mods/11622) and uses only the free SweetFX shaders that ReShade installs (CeeJayDK/SweetFX,
# MIT): ContrastAdaptiveSharpen, Curves, Vibrance, LiftGammaGain, FilmGrain, Vignette. Values stay inside each shader's
# own ui_min/ui_max (read from the .fx sources).
# This writes, for YOUR PC (read from Windows):
#   bin\x64\SI-PHOTOREAL.ini           the ReShade preset (and PresetPath in ReShade.ini when ReShade is installed)
#   engine\config\platform\pc\user.ini only on RTX x080/x090: [Editor/ReSTIRGI] Enable=false + [RayTracing/Reference]
#                                      RayNumber=3 BounceNumber=3 (game defaults 2/2; Nexus mods 9294 / 21176 document
#                                      the keys). Everything else keeps the game's path tracing.
# DLSS 4.5 (update 2.5) is set in the game menu: the script prints what to pick for your GPU. Backups first
# (*.sigame.bak); -Undo restores them and removes what was new.
param(
    [switch]$Undo
)

function Find-CpDir {
    $cands = @()
    foreach ($pf in $env:ProgramFiles, ${env:ProgramFiles(x86)}) {
        if (-not $pf) { continue }
        $cands += Join-Path $pf 'Steam\steamapps\common\Cyberpunk 2077'
        $cands += Join-Path $pf 'GOG Galaxy\Games\Cyberpunk 2077'
        $cands += Join-Path $pf 'Epic Games\Cyberpunk2077'
    }
    $vdf = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $cands += Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common\Cyberpunk 2077'
        }
    }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'Games', 'Jogos', 'Giochi', 'Juegos', 'GOG Games', 'SteamLibrary\steamapps\common', 'Epic Games') {
            $cands += Join-Path $drv.RootDirectory.FullName "$d\Cyberpunk 2077"
            $cands += Join-Path $drv.RootDirectory.FullName "$d\Cyberpunk2077"
        }
    }
    foreach ($c in $cands) { if (Test-Path -LiteralPath (Join-Path $c 'bin\x64\Cyberpunk2077.exe')) { return $c } }
    return $null
}

function Backup([string]$Path) {
    # a file SIGAME created has no original to keep: Undo removes it instead
    $made = (Test-Path -LiteralPath $Marker) -and ((Get-Content -LiteralPath $Marker) -contains $Path)
    if (-not $made -and (Test-Path -LiteralPath $Path) -and -not (Test-Path -LiteralPath "$Path.sigame.bak")) { Copy-Item -LiteralPath $Path -Destination "$Path.sigame.bak" }
}

# Drops [Section] blocks we own, then appends them again: re-applying never duplicates keys.
function Set-IniSections([string]$Text, [hashtable]$Sections) {
    foreach ($s in $Sections.Keys) {
        $Text = [regex]::Replace($Text, '(?ms)^\[' + [regex]::Escape($s) + '\]\s*\r?\n.*?(?=^\[|\z)', '')
    }
    $Text = $Text.TrimEnd()
    foreach ($s in $Sections.Keys | Sort-Object) {
        $Text += "`r`n`r`n[$s]`r`n" + (($Sections[$s] | ForEach-Object { $_ }) -join "`r`n")
    }
    return $Text.TrimStart() + "`r`n"
}

$GameDir = if ($env:SIGAME_CP_DIR) { $env:SIGAME_CP_DIR } else { Find-CpDir }
if (-not $GameDir) {
    Write-Output '[FAIL] Cyberpunk 2077 not found (bin\x64\Cyberpunk2077.exe). Install it or start it once, then apply again.'
    exit 2
}
$Bin     = Join-Path $GameDir 'bin\x64'
$Preset  = Join-Path $Bin 'SI-PHOTOREAL.ini'
$RsIni   = Join-Path $Bin 'ReShade.ini'
$CfgDir  = Join-Path $GameDir 'engine\config\platform\pc'
$UserIni = Join-Path $CfgDir 'user.ini'
$Marker  = Join-Path $Bin 'SI-PHOTOREAL.sigame.new'   # lists files that did not exist before

if ($Undo) {
    $n = 0
    foreach ($f in @($RsIni, $UserIni)) {
        if (Test-Path -LiteralPath "$f.sigame.bak") {
            Move-Item -LiteralPath "$f.sigame.bak" -Destination $f -Force
            Write-Output "[OK]   $(Split-Path $f -Leaf) restored from the backup."; $n++
        }
    }
    if (Test-Path -LiteralPath $Marker) {
        foreach ($f in Get-Content -LiteralPath $Marker) {
            if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force; Write-Output "[OK]   $(Split-Path $f -Leaf) removed (SIGAME made it)."; $n++ }
        }
        Remove-Item -LiteralPath $Marker -Force
    }
    if (-not $n) { Write-Output '[FAIL] Nothing to undo (no *.sigame.bak backup).'; exit 3 }
    exit 0
}

if (Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Cyberpunk 2077 is running: close the game first.'
    exit 4
}

$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$Gpu = if ($env:SIGAME_TEST_GPU) { $env:SIGAME_TEST_GPU } elseif ($vc) { [string]$vc.Name } else { '' }
$Hz  = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } elseif ($vc -and $vc.CurrentRefreshRate -gt 0) { [int]$vc.CurrentRefreshRate } else { 60 }
$Gen  = if ($Gpu -match 'RTX\s*([2-9])0(\d)0') { [int]$Matches[1] } else { 0 }
$Tier = if ($Gpu -match 'RTX\s*[2-9]0(\d)0') { [int]$Matches[1] } else { 0 }
Write-Output "[INFO] GPU: $Gpu | monitor $Hz Hz"
$new = @()

# 1. The free ReShade preset (SweetFX shaders, values inside each shader's own range)
if (-not (Test-Path -LiteralPath $Preset)) { $new += $Preset }
$p = @(
    'Techniques=ContrastAdaptiveSharpen@CAS.fx,Curves@Curves.fx,Vibrance@Vibrance.fx,LiftGammaGain@LiftGammaGain.fx,FilmGrain@FilmGrain.fx,Vignette@Vignette.fx',
    'TechniqueSorting=ContrastAdaptiveSharpen@CAS.fx,Curves@Curves.fx,Vibrance@Vibrance.fx,LiftGammaGain@LiftGammaGain.fx,FilmGrain@FilmGrain.fx,Vignette@Vignette.fx',
    '', '[CAS.fx]', 'Contrast=0.250000', 'Sharpening=0.650000',
    '', '[Curves.fx]', 'Contrast=0.120000', 'Formula=4', 'Mode=0',
    '', '[Vibrance.fx]', 'Vibrance=0.100000', 'VibranceRGBBalance=1.000000,1.000000,1.000000', 'Vibrance_Luma=0',
    '', '[LiftGammaGain.fx]', 'RGB_Gain=1.000000,1.000000,1.000000', 'RGB_Gamma=1.000000,1.000000,1.020000', 'RGB_Lift=0.990000,0.990000,1.000000',
    '', '[FilmGrain.fx]', 'Intensity=0.080000', 'Mean=0.500000', 'SignalToNoiseRatio=6', 'Variance=0.400000',
    '', '[Vignette.fx]', 'Amount=-0.350000', 'Center=0.500000,0.500000', 'Radius=1.700000', 'Ratio=1.000000', 'Slope=2', 'Type=0'
)
[IO.File]::WriteAllText($Preset, ($p -join "`r`n") + "`r`n")
Write-Output '[SET]  SI-PHOTOREAL.ini (free ReShade preset: CAS 0.65, Curves 0.12, Vibrance 0.10, cool shadows, grain 0.08, vignette)'
if (Test-Path -LiteralPath $RsIni) {
    Backup $RsIni
    $r = [IO.File]::ReadAllText($RsIni)
    if ($r -match '(?m)^PresetPath=') { $r = [regex]::Replace($r, '(?m)^PresetPath=.*$', 'PresetPath=.\SI-PHOTOREAL.ini') }
    elseif ($r -match '(?m)^\[GENERAL\]') { $r = [regex]::Replace($r, '(?m)^\[GENERAL\]\s*$', "[GENERAL]`r`nPresetPath=.\SI-PHOTOREAL.ini") }
    else { $r = "[GENERAL]`r`nPresetPath=.\SI-PHOTOREAL.ini`r`n" + $r }
    [IO.File]::WriteAllText($RsIni, $r)
    Write-Output '[SET]  ReShade.ini PresetPath=.\SI-PHOTOREAL.ini'
} else { Write-Output '[WARN] ReShade not installed yet: get it free at reshade.me (DirectX 10/11/12, SweetFX shaders), then apply again.' }
Write-Output '[INFO] Tuned on top of Nova LUT 4.0 (free, Nexus mod 11622): install it first for the full look.'

# 2. Path tracing rays and bounces past the game's 2/2, only where the GPU has the headroom
if ($Gen -ge 4 -and $Tier -ge 8) {
    if (-not (Test-Path -LiteralPath $CfgDir)) { New-Item -ItemType Directory -Path $CfgDir -Force | Out-Null }
    if (Test-Path -LiteralPath $UserIni) { Backup $UserIni; $u = [IO.File]::ReadAllText($UserIni) } else { $new += $UserIni; $u = '' }
    $u = Set-IniSections $u @{ 'Editor/ReSTIRGI' = @('Enable = false'); 'RayTracing/Reference' = @('RayNumber = 3', 'BounceNumber = 3') }
    [IO.File]::WriteAllText($UserIni, $u)
    Write-Output '[SET]  user.ini [Editor/ReSTIRGI] Enable=false, [RayTracing/Reference] RayNumber=3 BounceNumber=3 (game: 2/2)'
} else { Write-Output '[SKIP] Path tracing rays/bounces: kept at the game defaults (only RTX x080/x090 get 3/3).' }

# 3. DLSS 4.5 (update 2.5): menu choices for this GPU
if ($Gen -ge 5) { Write-Output "[INFO] Game menu > Graphics: DLSS Frame Generation = Dynamic Multi Frame Generation (new in 2.5, 2X-6X); Ray Reconstruction ON." }
elseif ($Gen -eq 4) { Write-Output '[INFO] Game menu > Graphics: DLSS Frame Generation ON; Ray Reconstruction ON.' }
elseif ($Gen -ge 2) { Write-Output '[INFO] Game menu > Graphics: DLSS Super Resolution ON (frame generation needs RTX 40 or newer).' }
else { Write-Output '[INFO] Not an RTX card: for FSR 4 / XeSS use the SI OPTI preset for Cyberpunk in SIGAME.' }

if ($new) { Add-Content -LiteralPath $Marker -Value $new }
Write-Output '[OK]   SI PHOTOREAL applied, free. In game: Home = ReShade menu.'
exit 0
