# SI FPS - Call of Duty: Modern Warfare 4 (PC) - by SI NEWS, MIT.
# MW4 keeps its PC settings in %LOCALAPPDATA%\Activision\Call of Duty\players\s.1.0.cod26.txt. Every line of that
# file carries the game's own description and allowed values ("// one of ..." or "// a to b"). This preset:
#   - reads your PC (physical CPU cores, video memory, GPU maker, monitor refresh rate) and sets the keys that
#     depend on it: RendererWorkerCount, VideoMemoryScaleMP, MaxFpsInGame, low-latency mode for your GPU maker;
#   - sets hidden keys the graphics menu does not have (corpse limit, blood interval, reflection relighting stages,
#     surface subdivision, shader pre-load CPU usage, background FPS, power-saving drops, cloud sync, HW reset);
#   - sets the heavy graphics options to their lowest value;
#   - writes ONLY keys already in your file and ONLY values the file itself allows (anything else is skipped).
# The file is backed up first (.sigame.bak); -Undo puts it back.
param(
    [switch]$Undo,
    [string]$PlayersPath = (Join-Path $env:LOCALAPPDATA 'Activision\Call of Duty\players')
)

$cfg = Join-Path $PlayersPath 's.1.0.cod26.txt'
$bak = "$cfg.sigame.bak"

if ($Undo) {
    if (-not (Test-Path -LiteralPath $bak)) { Write-Output '[FAIL] No backup s.1.0.cod26.txt.sigame.bak to restore.'; exit 3 }
    Copy-Item -LiteralPath $bak -Destination $cfg -Force
    Write-Output '[OK]   s.1.0.cod26.txt restored from the backup.'
    exit 0
}

if (-not (Test-Path -LiteralPath $cfg)) {
    Write-Output '[FAIL] s.1.0.cod26.txt not found: start Call of Duty once, reach the main menu, close it, then apply again.'
    exit 2
}
if (Get-Process -Name 'cod' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Call of Duty is running: close the game, then apply again.'
    exit 4
}

# --- Your PC ---
$cores = 0
foreach ($p in @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue)) { $cores += [int]$p.NumberOfCores }
if ($cores -lt 1) { $cores = [Environment]::ProcessorCount }
$gpu = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Basic|Remote|Virtual' })
$gpuName = ($gpu | Select-Object -First 1).Name
$hz = [int](($gpu | Measure-Object CurrentRefreshRate -Maximum).Maximum)
# AdapterRAM stops at 4 GB; the driver key qwMemorySize has the real size.
$vramGB = 0
foreach ($k in @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
    $q = (Get-ItemProperty -LiteralPath $k.PSPath -Name 'HardwareInformation.qwMemorySize' -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize'
    if ($q) { $vramGB = [math]::Max($vramGB, [math]::Round([double]$q / 1GB, 1)) }
}
if ($vramGB -eq 0) { $vramGB = [math]::Round((($gpu | Measure-Object AdapterRAM -Maximum).Maximum) / 1GB, 1) }
Write-Output "[PC]   $cores physical cores, $gpuName, $vramGB GB video memory, $hz Hz"

# --- The values ---
$workers = [math]::Max(2, [math]::Min(16, $cores - 1))         # one core left for Windows, audio and Discord
$vram = if ($vramGB -le 4) { '0.650000' } elseif ($vramGB -lt 8) { '0.750000' } else { '0.850000' }
$cap = if ($hz -ge 30) { [math]::Max(30, [math]::Min(300, $hz - 3)) } else { 0 }

$set = [ordered]@{
    'RendererWorkerCount@0'           = "$workers"
    'VideoMemoryScaleMP@0'            = $vram
    'GraphicsQuality@0'               = 'Minimum'
    'ShadowQuality@0'                 = 'Very_Low'
    'ShadowFilteringQuality@0'        = 'Low'
    'ScreenSpaceShadowQuality@0'      = 'Off'
    'ShadingQuality@0'                = 'Low'
    'ModelQuality@0'                  = 'Low Quality'
    'ParticleQuality@0'               = 'very low'
    'TerrainQuality@0'                = 'Very Low'
    'Tessellation@0'                  = '0_Off'
    'VolumetricQuality@0'             = 'QUALITY_LOW'
    'VolumetricQuality@1'             = 'QUALITY_LOW'
    'SSRQuality@0'                    = 'Off'
    'SSRQuality@1'                    = 'Off'
    'AmbientLightingQuality@0'        = 'Off'
    'WeatherGridVolumesQuality@0'     = 'Off'
    'WaterCausticsMode@0'             = 'Off'
    'WaterWaveWetness@0'              = 'false'
    'DeferredPhysics@0'               = 'Low Quality'
    'DxrMode@0'                       = 'Off'
    'DxrMode@1'                       = 'Off'
    'MotionBlur@0'                    = 'Off'
    'WeaponMotionBlur@0'              = 'false'
    'EnableVelocityBasedBlur@0'       = 'false'
    'DofEnable@0'                     = 'Off'
    'VSync@0'                         = 'disabled'
    'DynamicSceneResolution@0'        = 'false'
    # Hidden: not in the graphics menu
    'SubdivisionLevel@0'              = '0'
    'ReflectionProbeRelighting@0'     = '1'
    'ReflectionProbeHalfResolution@0' = 'true'
    'PersistentDamageLayer@0'         = 'false'
    'CorpseLimit@0'                   = '0'
    'CorpsesCullingThreshold@0'       = '0.500000'
    'BloodLimit@0'                    = 'true'
    'BloodLimitInterval@0'            = '2000'
    'ShowBrass@0'                     = 'false'
    'EnableOfflineGameUpdater@0'      = 'true'
    'OfflineGameUpdaterUsage@0'       = 'maximum'
    'MaxFpsOutOfFocus@0'              = '15'
    'SustainabilityMenuSceneResolution@0' = 'off'
    'SustainabilityReduceQualityIdle@0'   = 'off'
    'UserEcoLowBatteryModeUI@0'       = 'false'
    'ConfigCloudStorageEnabled@0'     = 'false'
    'DisableHWChangeDetection@0'      = 'true'
    'SkipIntro@1'                     = 'true'
    'SkipSeasonIntroVideo@0'          = 'true'
}
if ($cap) { $set['CapFps@0'] = 'true'; $set['MaxFpsInGame@0'] = "$cap" }
if ($gpuName -match 'NVIDIA') { $set['NvidiaReflex@0'] = 'Enabled + boost' }
elseif ($gpuName -match 'AMD|Radeon') { $set['AmdAntilag2@0'] = 'true' }
elseif ($gpuName -match 'Intel') { $set['IntelXeLL@0'] = 'true' }

# Is the value allowed by the file's own comment for that line?
function Test-Allowed([string]$cmt, [string]$v) {
    if (-not $cmt) { return ($v -in 'true', 'false') -or ($v -notmatch '\s') }
    if ($cmt -match '//\s*one of (.+)$') { return (($Matches[1].Trim() -split ',\s*') -ccontains $v) }
    if ($cmt -match '//\s*(-?[\d.]+) to (-?[\d.]+)') {
        $lo = [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture)
        $hi = [double]::Parse($Matches[2], [Globalization.CultureInfo]::InvariantCulture)
        if ($v -notmatch '^-?\d+(\.\d+)?$') { return $false }
        $d = [double]::Parse($v, [Globalization.CultureInfo]::InvariantCulture)
        return ($d -ge $lo -and $d -le $hi)
    }
    return $true
}

# Keep the first backup: applying twice must not overwrite the player's original.
if (-not (Test-Path -LiteralPath $bak)) { Copy-Item -LiteralPath $cfg -Destination $bak -Force }

$text = [IO.File]::ReadAllText($cfg)
$nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = $text -split "`r?`n"
$re = '^(?<key>[A-Za-z0-9_]+@\d+)(?<mid>;\d+;\d+\s*=\s*)(?<val>.*?)(?<cmt>\s*//.*)?$'
$done = @{}
$n = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    $m = [regex]::Match($lines[$i], $re)
    if (-not $m.Success) { continue }
    $k = $m.Groups['key'].Value
    if (-not $set.Contains($k)) { continue }
    $v = $set[$k]; $done[$k] = $true
    if (-not (Test-Allowed $m.Groups['cmt'].Value $v)) { Write-Output "[SKIP] $k = $v is not allowed by the game"; continue }
    if ($m.Groups['val'].Value -eq $v) { continue }
    Write-Output "[SET]  $k  $($m.Groups['val'].Value) to $v"
    $lines[$i] = $k + $m.Groups['mid'].Value + $v + $m.Groups['cmt'].Value
    $n++
}
foreach ($k in $set.Keys) { if (-not $done[$k]) { Write-Output "[SKIP] $k is not in your file" } }
# The game writes UTF-8 without BOM; keep its line endings.
[IO.File]::WriteAllText($cfg, ($lines -join $nl), (New-Object Text.UTF8Encoding $false))

Write-Output "[OK]   SI FPS applied: $n values changed. Start Call of Duty as usual."
exit 0
