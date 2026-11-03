# SI ULTRA - VRChat (PC: Steam, Viveport, Oculus PC) - by SI NEWS, MIT.
# VRChat's own optional file: %LocalAppData%Low\VRChat\VRChat\config.json. VRChat does not create it and these keys are not in the app menu.
# Keys, ranges and defaults from VRChat's own docs:
#   docs.vrchat.com/docs/configuration-file: cache_size and cache_expiry_delay (default 30, >= 30), camera_res_* (max 7680x4320, used when the
#     camera's resolution is set to "Config File"), screenshot_res_* (max 3840x2160, F12), fpv_steadycam_fov (30-110, docs: try 65-70)
#   docs.vrchat.com/docs/avatar-particle-system-limits: betas particle_system_limiter + VRChat's recommended ps_* values
# The file is merged, your other keys stay. Backup first (config.json.sigame.bak); -Undo puts it back.
param(
    [switch]$Undo
)

$Dir = if ($env:SIGAME_VRC_CFG) { $env:SIGAME_VRC_CFG } else { Join-Path ($env:LOCALAPPDATA + 'Low') 'VRChat\VRChat' }
if (-not (Test-Path -LiteralPath $Dir)) {
    Write-Output '[FAIL] VRChat folder not found: start VRChat once, close it, then apply again.'
    exit 2
}
if (Get-Process -Name 'VRChat' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] VRChat is running: close the game first, then APPLY.'
    exit 4
}
$Cfg = Join-Path $Dir 'config.json'
$Bak = "$Cfg.sigame.bak"

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    if ((Get-Item -LiteralPath $Bak).Length -eq 0) {
        Remove-Item -LiteralPath $Cfg -Force -ErrorAction SilentlyContinue
    } else {
        Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
    }
    Remove-Item -LiteralPath $Bak -Force
    Write-Output '[OK]   config.json restored from the backup.'
    exit 0
}

$J = [pscustomobject]@{}
if (Test-Path -LiteralPath $Cfg) {
    try {
        $J = [IO.File]::ReadAllText($Cfg) | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Output '[FAIL] config.json is not valid JSON: fix it or delete it, then apply again.'
        exit 5
    }
    if (-not $J) { $J = [pscustomobject]@{} }
    if (-not (Test-Path -LiteralPath $Bak)) { Copy-Item -LiteralPath $Cfg -Destination $Bak }
} elseif (-not (Test-Path -LiteralPath $Bak)) {
    Set-Content -LiteralPath $Bak -Value $null -Encoding ascii
}

function Set-Key($Name, $Value) {
    $J | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

# --- Your free disk space decides the cache (VRChat's default is 30 GB, 30 days) ---
$Root = if ($J.cache_directory) { [IO.Path]::GetPathRoot([string]$J.cache_directory) } else { [IO.Path]::GetPathRoot($Dir) }
$Free = 0
if ($env:SIGAME_TEST_FREE_GB) {
    $Free = [int]$env:SIGAME_TEST_FREE_GB
} else {
    try { $Free = [int]([IO.DriveInfo]::new($Root).AvailableFreeSpace / 1GB) } catch { $Free = 0 }
}
Write-Output "[PC]   free space on the cache drive: $Free GB"
$Gb = if ($Free -ge 250) { 100 } elseif ($Free -ge 120) { 60 } else { 30 }
if ($J.cache_size -and [int]$J.cache_size -gt $Gb) { $Gb = [int]$J.cache_size }
$Days = 90
if ($J.cache_expiry_delay -and [int]$J.cache_expiry_delay -gt $Days) { $Days = [int]$J.cache_expiry_delay }

# --- Particle limiter on, with VRChat's own recommended limits ---
$Betas = @(@($J.betas) | Where-Object { $_ }) + 'particle_system_limiter' | Select-Object -Unique
Set-Key 'betas' @($Betas)
foreach ($k in @(
    , @('ps_max_particles', 50000)
    , @('ps_max_systems', 200)
    , @('ps_max_emission', 5000)
    , @('ps_max_total_emission', 40000)
    , @('ps_mesh_particle_divider', 60)
    , @('ps_mesh_particle_poly_limit', 50000)
    , @('ps_collision_penalty_high', 50)
    , @('ps_collision_penalty_med', 30)
    , @('ps_collision_penalty_low', 10)
    , @('ps_trails_penalty', 10)
)) { Set-Key $k[0] $k[1] }

Set-Key 'cache_size' $Gb
Set-Key 'cache_expiry_delay' $Days
Set-Key 'camera_res_width' 7680
Set-Key 'camera_res_height' 4320
Set-Key 'screenshot_res_width' 3840
Set-Key 'screenshot_res_height' 2160
Set-Key 'fpv_steadycam_fov' 70

[IO.File]::WriteAllText($Cfg, ($J | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
Write-Output '[OK]   config.json written, your other keys kept, backup saved'
Write-Output '[SET]  particle limiter ON, with the limits VRChat recommends'
Write-Output "[SET]  cache $Gb GB, $Days days (VRChat's default: 30 GB, 30 days)"
Write-Output '[SET]  camera 7680 x 4320: pick "Config File" as the camera resolution'
Write-Output '[SET]  F12 screenshots 3840 x 2160'
Write-Output '[SET]  first-person steadycam FOV 70'
Write-Output '[OK]   SI ULTRA applied, free. Restart VRChat. APPLY again and Yes = Undo.'
exit 0
