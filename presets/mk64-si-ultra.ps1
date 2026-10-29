# SI ULTRA - MarioKart 64: Recompiled (Native PC Port, RT64 engine v0.9.2) - by SI NEWS, MIT.
# In the port's Graphics menu (assets/config_menu/graphics.rml + src/ui/ui_config.cpp), selecting Resolution = Auto
# disables the Downsampling Quality buttons (data-attrif-disabled="res_option == 'Auto'") and forces ds_option = 1.
# Meanwhile, selecting Original2x (480p) with 4x Downsampling renders in 4K (1920p) in RT64 (src/main/rt64_render_context.cpp:
# resolutionMultiplier = 2.0 * ds_option = 8x), AND the Anti-Aliasing menu only displays radio buttons up to 4x
# (assets/config_menu/graphics.rml lines 830-859: None, MSAA2X, MSAA4X) even though the C++ serializer and RT64 engine
# (ultramodern/config.hpp line 122 + src/main/rt64_render_context.cpp line 65) accept and run "MSAA8X"!
# Furthermore, the General menu (assets/config_menu/general.rml) only exposes Joystick Deadzone and Background Input,
# leaving gyro_sensitivity, mouse_sensitivity, rumble_strength, and debug_mode hidden inside general.json (src/game/config.cpp).
# This writes, for YOUR monitor (read from Windows):
#   res_option = "Original2x"     ds_option = 4 (internal 8x = 4K RT64 supersampling, vs 2x for lower spec)
#   msaa_option = "MSAA8X"        hidden 8x MSAA hardware sample positions (menu only shows up to 4x)
#   ar_option = "Expand"          hr_option = "Clamp16x9" on 21:9/32:9 ultrawide (or "Full" on 16:9)
#   wm_option = "Fullscreen"      rr_option = "Display"   rr_manual_value = your monitor's Hz   api_option = "Auto"
#   joystick_deadzone = 3         background_input_mode = "On"   rumble_strength = 80   gyro_sensitivity = 50
# Backups first (.sigame.bak); -Undo restores graphics.json and general.json byte-for-byte.
param(
    [switch]$Undo
)

$ExeName = 'MarioKart64Recompiled.exe'

function Find-Mk64ConfigDir {
    $appDataDir = Join-Path $env:LOCALAPPDATA 'MarioKart64Recompiled'
    $roots = @()
    foreach ($d in 'Downloads', 'Desktop', 'Documents', 'Games') { $roots += , @((Join-Path $env:USERPROFILE $d), 3) }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'Games', 'Jogos', 'Giochi', 'Juegos') { $roots += , @((Join-Path $drv.RootDirectory.FullName $d), 3) }
        $roots += , @($drv.RootDirectory.FullName, 1)
    }
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r[0])) { continue }
        $exe = Join-Path $r[0] $ExeName
        if (Test-Path -LiteralPath $exe) {
            if (Test-Path -LiteralPath (Join-Path $r[0] 'portable.txt')) { return $r[0] }
            return $appDataDir
        }
        $hit = Get-ChildItem -LiteralPath $r[0] -Filter $ExeName -File -Recurse -Depth $r[1] -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) {
            if (Test-Path -LiteralPath (Join-Path $hit.DirectoryName 'portable.txt')) { return $hit.DirectoryName }
            return $appDataDir
        }
    }
    if (Test-Path -LiteralPath $appDataDir) { return $appDataDir }
    return $null
}

$CfgDir = if ($env:SIGAME_MK64_DIR) { $env:SIGAME_MK64_DIR } else { Find-Mk64ConfigDir }
if (-not $CfgDir) {
    Write-Output "[FAIL] MarioKart 64: Recompiled not found ($ExeName or %LOCALAPPDATA%\MarioKart64Recompiled). Extract and start it once, then apply again."
    exit 2
}
[void][IO.Directory]::CreateDirectory($CfgDir)
$GfxPath = Join-Path $CfgDir 'graphics.json'
$GenPath = Join-Path $CfgDir 'general.json'
$GfxBak  = "$GfxPath.sigame.bak"
$GenBak  = "$GenPath.sigame.bak"

if ($Undo) {
    if (-not (Test-Path -LiteralPath $GfxBak)) { Write-Output '[FAIL] No backup graphics.json.sigame.bak to restore.'; exit 3 }
    Copy-Item -LiteralPath $GfxBak -Destination $GfxPath -Force
    if (Test-Path -LiteralPath $GenBak) { Copy-Item -LiteralPath $GenBak -Destination $GenPath -Force }
    Write-Output '[OK]   graphics.json and general.json restored from the backup.'
    exit 0
}

if (Get-Process -Name 'MarioKart64Recompiled*' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] MarioKart 64: Recompiled is running: close the game first (it rewrites its JSON files on exit).'
    exit 4
}

$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$W = if ($env:SIGAME_TEST_W) { [int]$env:SIGAME_TEST_W } elseif ($vc) { [int]$vc.CurrentHorizontalResolution } else { 1920 }
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } elseif ($vc) { [int]$vc.CurrentVerticalResolution } else { 1080 }
$Hz = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } elseif ($vc -and $vc.CurrentRefreshRate -gt 0) { [int]$vc.CurrentRefreshRate } else { 60 }
$HzClamp = [Math]::Min(360, [Math]::Max(60, $Hz))
$IsUltrawide = (($W / [double]$H) -gt 1.85)
$HudMode = if ($IsUltrawide) { 'Clamp16x9' } else { 'Full' }

Write-Output "[INFO] Monitor $W x $H @ $Hz Hz -> RT64 4K supersampling (Original2x + ds_option 4 = 1920p), MSAA8X, HUD $HudMode"

foreach ($pair in @(@($GfxPath, $GfxBak), @($GenPath, $GenBak))) {
    if (-not (Test-Path -LiteralPath $pair[1])) {
        if (Test-Path -LiteralPath $pair[0]) { Copy-Item -LiteralPath $pair[0] -Destination $pair[1] -Force }
        else { [IO.File]::WriteAllText($pair[1], '{}') }
    }
}

$Gfx = [ordered]@{
    res_option      = 'Original2x'
    wm_option       = 'Fullscreen'
    hr_option       = $HudMode
    api_option      = 'Auto'
    ds_option       = 4
    ar_option       = 'Expand'
    msaa_option     = 'MSAA8X'
    rr_option       = 'Display'
    rr_manual_value = $HzClamp
    developer_mode  = $false
}

$Gen = [ordered]@{
    targeting_mode            = 'Switch'
    background_input_mode     = 'On'
    rumble_strength           = 80
    gyro_sensitivity          = 50
    mouse_sensitivity         = 0
    joystick_deadzone         = 3
    autosave_mode             = 'On'
    camera_invert_mode        = 'InvertY'
    analog_cam_mode           = 'On'
    analog_camera_invert_mode = 'InvertNone'
    debug_mode                = $false
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($GfxPath, ($Gfx | ConvertTo-Json -Depth 4) + "`r`n", $Utf8)
[IO.File]::WriteAllText($GenPath, ($Gen | ConvertTo-Json -Depth 4) + "`r`n", $Utf8)

Write-Output "[SET]  res_option = Original2x   ds_option = 4  (8x RT64 = 4K internal render)"
Write-Output "[SET]  msaa_option = MSAA8X      (hidden enum in ultramodern/config.hpp)"
Write-Output "[SET]  wm_option = Fullscreen    ar_option = Expand   hr_option = $HudMode"
Write-Output "[SET]  rr_option = Display       rr_manual_value = $HzClamp   api_option = Auto"
Write-Output "[SET]  joystick_deadzone = 3     rumble_strength = 80   gyro_sensitivity = 50"
Write-Output "[OK]   SI ULTRA applied. Start MarioKart64Recompiled.exe: 4K RT64 supersampling, MSAA8X, $HzClamp Hz."
exit 0
