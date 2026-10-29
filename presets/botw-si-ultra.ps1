# SI ULTRA - Zelda: Breath of the Wild (Savage Wind Recomp PC port, Alpha 3) - by SI NEWS, MIT.
# In the port's Video menu, Window size only offers sizes up to your desktop (runtime/window_size.c, winsize_list) and
# Upscaler offers Off (1x window) or AMD FSR 1 (which renders smaller: 1.3x to 2.0x smaller). The engine's output scaler
# (runtime/nvn/output_scale.c) also reads SAVAGEWIND_SCALE=<f> (render height = 1080 x f, up to 16384 px) before the
# 10-bit 3D scene is sharpened by AMD CAS (runtime/nvn/vulkan/exec.c, scene_post) and scaled to the window. And while
# the menu's Field of view row steps by 10 (FOV_CHOICES: 70..150), runtime/settings.c accepts any whole percent in
# [50, 200] from savagewind.ini and settings_save() preserves it.
# This writes, for YOUR monitor (read from Windows):
#   SAVAGEWIND_SCALE = N        User env var: smallest integer >= 2 that renders >= 2x your screen height (1080 x N lines)
#   window_size = WxH           your monitor's exact pixel size, fullscreen = 1 (borderless)
#   frame_rate = Hz             highest port step (30/40/60/72/90/120/144/165/240) up to your monitor's refresh rate
#   shadow_resolution = extreme 8192x8192 sun shadow cascades (console default is 896x896)
#   anisotropy = 16x            sharpening = 50 (AMD CAS on the 3D scene before HUD)   antialias = smaa
#   upscaler = off              wide_view = 1 (21:9 / 32:9 world view)                 field_of_view = 115 (hidden step)
#   precompile_shaders = 1      async_shaders = 0 (no skipped terrain tiles)           vsync = fast
# Backups first (.sigame.bak); -Undo puts them back and clears SAVAGEWIND_SCALE.
param(
    [switch]$Undo
)

$ExeName = 'savagewind.exe'
$Keys = 'settings_version|fullscreen|window_size|frame_rate|vsync|upscaler|antialias|anisotropy|sharpening|shadow_resolution|wide_view|field_of_view|precompile_shaders|async_shaders'

function Find-BotwRoot {
    $roots = @()
    foreach ($d in 'Downloads', 'Desktop', 'Documents', 'Games') { $roots += , @((Join-Path $env:USERPROFILE $d), 3) }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'Games', 'Jogos', 'Giochi', 'Juegos') { $roots += , @((Join-Path $drv.RootDirectory.FullName $d), 3) }
        $roots += , @($drv.RootDirectory.FullName, 1)
    }
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r[0])) { continue }
        if (Test-Path -LiteralPath (Join-Path $r[0] $ExeName)) { return $r[0] }
        $hit = Get-ChildItem -LiteralPath $r[0] -Filter $ExeName -File -Recurse -Depth $r[1] -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    return $null
}

$Root = if ($env:SIGAME_BOTW_ROOT) { $env:SIGAME_BOTW_ROOT } else { Find-BotwRoot }
if (-not $Root -or -not (Test-Path -LiteralPath (Join-Path $Root $ExeName))) {
    Write-Output "[FAIL] Savage Wind Recomp not found ($ExeName). Extract it in Downloads, Desktop, Documents or a Games folder, then apply again."
    exit 2
}
$Ini = Join-Path $Root 'savagewind.ini'
$Bak = "$Ini.sigame.bak"
$EnvBak = Join-Path $Root 'savagewind.scale.sigame.bak'

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No backup savagewind.ini.sigame.bak to restore.'; exit 3 }
    Copy-Item -LiteralPath $Bak -Destination $Ini -Force
    if (Test-Path -LiteralPath $EnvBak) {
        $oldScale = ([IO.File]::ReadAllText($EnvBak)).Trim()
        if (-not $env:SIGAME_BOTW_NO_ENV) {
            [Environment]::SetEnvironmentVariable('SAVAGEWIND_SCALE', $(if ($oldScale) { $oldScale } else { $null }), 'User')
        }
        Remove-Item -LiteralPath $EnvBak -Force -ErrorAction SilentlyContinue
    }
    Write-Output '[OK]   savagewind.ini restored from the backup and SAVAGEWIND_SCALE reset.'
    exit 0
}

if (Get-Process -Name 'savagewind*' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Savage Wind is running: close the game and Savage Wind Configuration, then apply again.'
    exit 4
}

$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$W = if ($env:SIGAME_TEST_W) { [int]$env:SIGAME_TEST_W } elseif ($vc) { [int]$vc.CurrentHorizontalResolution } else { 1920 }
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } elseif ($vc) { [int]$vc.CurrentVerticalResolution } else { 1080 }
$Hz = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } elseif ($vc -and $vc.CurrentRefreshRate -gt 0) { [int]$vc.CurrentRefreshRate } else { 60 }

$FpsSteps = @(30, 40, 60, 72, 90, 120, 144, 165, 240)
$Fps = 60
foreach ($s in $FpsSteps) { if ($s -le $Hz) { $Fps = $s } }
if ($Fps -lt 60) { $Fps = 60 }

$Scale = [Math]::Min(4, [Math]::Max(2, [int][Math]::Ceiling(2 * $H / 1080.0)))
$RenderH = 1080 * $Scale
Write-Output "[INFO] Monitor $W x $H @ $Hz Hz -> render $RenderH lines (SAVAGEWIND_SCALE = $Scale), frame_rate $Fps"

if (-not (Test-Path -LiteralPath $Bak)) {
    if (Test-Path -LiteralPath $Ini) { Copy-Item -LiteralPath $Ini -Destination $Bak -Force }
    else { [IO.File]::WriteAllText($Bak, '') }
}
if (-not (Test-Path -LiteralPath $EnvBak)) {
    $curEnv = [Environment]::GetEnvironmentVariable('SAVAGEWIND_SCALE', 'User')
    [IO.File]::WriteAllText($EnvBak, $(if ($curEnv) { $curEnv } else { '' }))
}
if (-not $env:SIGAME_BOTW_NO_ENV) {
    [Environment]::SetEnvironmentVariable('SAVAGEWIND_SCALE', "$Scale", 'User')
}
Write-Output "[SET]  SAVAGEWIND_SCALE = $Scale"

$Order = @(
    'settings_version', 'fullscreen', 'window_size', 'frame_rate', 'vsync',
    'upscaler', 'antialias', 'anisotropy', 'sharpening', 'shadow_resolution',
    'wide_view', 'field_of_view', 'precompile_shaders', 'async_shaders'
)
$Ours = @{
    'settings_version'   = '3'
    'fullscreen'         = '1'
    'window_size'        = "${W}x${H}"
    'frame_rate'         = "$Fps"
    'vsync'              = 'fast'
    'upscaler'           = 'off'
    'antialias'          = 'smaa'
    'anisotropy'         = '16x'
    'sharpening'         = '50'
    'shadow_resolution'  = 'extreme'
    'wide_view'          = '1'
    'field_of_view'      = '115'
    'precompile_shaders' = '1'
    'async_shaders'      = '0'
}

$old = @(if (Test-Path -LiteralPath $Ini) { [IO.File]::ReadAllLines($Ini) } else { @() })
$kept = foreach ($line in $old) {
    if ($line -match "^\s*#?\s*($Keys)\s*=" -or $line -match '^# SI ULTRA by SI NEWS') { continue }
    $line
}
$hdr = '# SI ULTRA by SI NEWS (SIGAME): 4K+ supersampling + 8192 shadows + 10-bit CAS + 16x textures, for this monitor'
$new = @($hdr)
foreach ($k in $Order) {
    $new += "$k = $($Ours[$k])"
    Write-Output "[SET]  $k = $($Ours[$k])"
}
$Utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($Ini, (($new + @($kept)) -join "`r`n") + "`r`n", $Utf8)

Write-Output "[OK]   SI ULTRA applied. Start savagewind.exe: $RenderH lines scaled down with CAS, 8192 shadows, 16x textures."
exit 0
