# SI ULTRA - Zelda: Tears of the Kingdom (totk-pc-recomp native PC port, valentderah, MIT) - by SI NEWS, MIT.
# The port's settings menu (F1, runtime/ui/menu.cpp) offers fixed lists only: Game resolution 1920x1080, 2560x1440,
# 3200x1800, 3840x2160 (16:9 only, row_output_res), 3D render scale up to 200 % (row_render_scale) and a frame limit of
# 30, 60, 120, 144 or display (row_fps_limit). The engine reads more from totk.ini (totk.ini.example):
#   output_res   any size 1280x720..7680x4320 (runtime/resolution.c decide())
#   render_scale any percentage 25..400; the scene is fitted to 4096 px a side (SCENE_MAX), above 100 = supersampling
#   fps_limit    any whole rate 30..360 (runtime/frame_rate.c LIMIT_MAX_HZ), above 60 with realtime = 1
# The README lists custom aspect ratios (ultrawide) as planned, so the output stays 16:9.
# This writes, for YOUR monitor (read from Windows):
#   output_res = WxH          the largest 16:9 size inside your monitor (5K and 8K too), fullscreen = 1
#   render_scale = P          set for your GPU: RTX x080/x090 and RX x800/x900 = the largest scene the port draws
#                             (4096 px a side, 213 % on 1080p, past the menu's 200 %); RTX x060/x070, RX x600/x700
#                             and Arc = up to 150 %; other cards = 100 %; integrated = 100 %, at most 1920x1080, 60 fps
#   fps_limit = Hz            your monitor's refresh rate, 30..360
#   realtime = 1  cloth_realtime = 1  highfps_fix = 1  (the port's high frame rate keys)
#   prewarm_xlate / lib_prebuild_threads = your CPU threads / half of them (shaders ready sooner, less stutter)
#   timer_1ms = 1  vk_present = mailbox  perf_overlay = fps
# Backup first (totk.ini.sigame.bak); -Undo puts it back, or SI ULTRAWIDE's settings while that one is still applied.
param(
    [switch]$Undo
)

$ExeName = 'totk.exe'

# The games the player added to SIGAME by hand (SI-GAME-boost.json, next to the presets folder).
function Get-ListedExes {
    $file = Join-Path (Split-Path -Parent $PSScriptRoot) 'SI-GAME-boost.json'
    if (-not (Test-Path -LiteralPath $file)) { return @() }
    try { $state = [IO.File]::ReadAllText($file) | ConvertFrom-Json } catch { return @() }
    return @(foreach ($g in @($state.Games)) {
        $exe = if ($g -is [string]) { $g } else { [string]$g.Exe }
        if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) { $exe }
    })
}

function Find-TotkRoot {
    foreach ($exe in (Get-ListedExes)) { if ((Split-Path -Leaf $exe) -ieq $ExeName) { return (Split-Path -Parent $exe) } }
    $roots = @()
    foreach ($d in 'Downloads', 'Desktop', 'Documents', 'Games') { $roots += , @((Join-Path $env:USERPROFILE $d), 3) }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'Games', 'Jogos', 'Giochi', 'Juegos', 'TotK', 'totk-pc') { $roots += , @((Join-Path $drv.RootDirectory.FullName $d), 3) }
        $roots += , @($drv.RootDirectory.FullName, 1)
    }
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r[0])) { continue }
        if (Test-Path -LiteralPath (Join-Path $r[0] 'totk-install.json')) { return $r[0] }
        $hit = Get-ChildItem -LiteralPath $r[0] -Filter 'totk-install.json' -File -Recurse -Depth $r[1] -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.DirectoryName $ExeName) } | Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    return $null
}

$Root = if ($env:SIGAME_TOTK_ROOT) { $env:SIGAME_TOTK_ROOT } else { Find-TotkRoot }
if (-not $Root -or -not (Test-Path -LiteralPath (Join-Path $Root $ExeName))) {
    Write-Output "[FAIL] totk-pc-recomp install folder not found ($ExeName + totk-install.json). Set SIGAME_TOTK_ROOT to it, then apply again."
    exit 2
}
$Ini = Join-Path $Root 'totk.ini'
$Bak = "$Ini.sigame.bak"

$Self = 'ultra'; $Other = 'ultrawide'
$Block = "$Ini.sigame-$Self"; $OtherBlock = "$Ini.sigame-$Other"
$Keys = 'output_res|aspect|fullscreen|window_size|render_scale|fps_limit|fps60|realtime|cloth_realtime|highfps_fix|prewarm_xlate|lib_prebuild_threads|timer_1ms|vk_present|perf_overlay'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
# keys are read wherever they are ([sections] only group lines): ours go first, the rest of the file stays as it was
function Write-Block([string[]]$Lines) {
    $old = @(if (Test-Path -LiteralPath $Ini) { [IO.File]::ReadAllLines($Ini) } else { @() })
    $kept = foreach ($line in $old) {
        if ($line -match "^\s*($Keys)\s*=" -or $line -match '^# SI ULTRA(WIDE)? by SI NEWS') { continue }
        $line
    }
    [IO.File]::WriteAllText($Ini, (($Lines + @('') + @($kept)) -join "`r`n") + "`r`n", $Utf8)
}

if ($Undo) {
    # SI ULTRA and SI ULTRAWIDE write the same keys and share one backup of your own file:
    # undoing one puts the other back while it is still applied, the backup returns only when none is left.
    Remove-Item -LiteralPath $Block -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $OtherBlock) {
        Write-Block ([IO.File]::ReadAllLines($OtherBlock))
        Write-Output "[OK]   SI ULTRA removed. SI ULTRAWIDE is still applied: its settings are in totk.ini."
        exit 0
    }
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[OK]   Nothing to undo: this preset is not in totk.ini.'; exit 0 }
    Move-Item -LiteralPath $Bak -Destination $Ini -Force
    Write-Output '[OK]   totk.ini restored from the backup.'
    exit 0
}

if (Get-Process -Name 'totk' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] totk.exe is running: close the game first (resolution and scale are read at start).'
    exit 4
}

$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$W = if ($env:SIGAME_TEST_W) { [int]$env:SIGAME_TEST_W } elseif ($vc) { [int]$vc.CurrentHorizontalResolution } else { 1920 }
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } elseif ($vc) { [int]$vc.CurrentVerticalResolution } else { 1080 }
$Hz = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } elseif ($vc -and $vc.CurrentRefreshRate -gt 0) { [int]$vc.CurrentRefreshRate } else { 60 }
$Cpu = if ($env:SIGAME_TEST_CPU) { [int]$env:SIGAME_TEST_CPU } else { [Environment]::ProcessorCount }

# What the scene can cost: every adapter counts (a laptop lists its Intel chip first). Set SIGAME_TOTK_SCENE=max to force the largest scene.
$Gpus = if ($env:SIGAME_TEST_GPU) { @($env:SIGAME_TEST_GPU -split ';') } else { @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.Name }) }
$Tier = if (-not $Gpus) { 'mid' } else { 'integrated' }
foreach ($g in $Gpus) {
    if ($g -match '(?i)RTX\s*[2-9]0[89]0|RX\s*\d[89]\d\d') { $Tier = 'top'; break }
    if ($g -match '(?i)RTX\s*[2-9]0[67]0|RX\s*\d[67]\d\d|Arc.*\b[AB]\d{3}\b') { $Tier = 'mid' }
    elseif ($Tier -eq 'integrated' -and $g -match '(?i)NVIDIA|GeForce|Quadro|Radeon\s*(\(TM\)\s*)?(RX\s*\d{3,4}|R[579]\s|Pro\s|HD\s)|RX\s*Vega\s*(56|64)') { $Tier = 'entry' }
}
if ($env:SIGAME_TOTK_SCENE -eq 'max') { $Tier = 'top' }
$MaxScale = @{ top = 400; mid = 150; entry = 100; integrated = 100 }[$Tier]

# output: the largest 16:9 size inside the monitor, within the port's 1280x720..7680x4320, even sizes
$OW = [Math]::Min($W, [int][Math]::Floor($H * 16 / 9))
if ($Tier -eq 'integrated') { $OW = [Math]::Min(1920, $OW) }
$OW = [Math]::Min(7680, [Math]::Max(1280, $OW)) -band -16
$OH = [int]($OW * 9 / 16) -band -2
# scene: the largest percentage whose long side stays within the port's 4096 px (25..400)
$Side = [Math]::Max($OW, $OH)
$Scale = [Math]::Min($MaxScale, [Math]::Max(100, [int][Math]::Floor(409600 / $Side)))
$Fit = [Math]::Min(1.0, 4096.0 / ($Side * $Scale / 100.0))   # the port fits the scene the same way (SCENE_MAX)
$SW = [int][Math]::Round($OW * $Scale / 100.0 * $Fit); $SH = [int][Math]::Round($OH * $Scale / 100.0 * $Fit)
$Fps = [Math]::Min(360, [Math]::Max(60, $Hz))
if ($Tier -eq 'integrated') { $Fps = [Math]::Min(60, $Fps) }
$Xlate = [Math]::Min(64, [Math]::Max(1, $Cpu))
$Lib = [Math]::Min(64, [Math]::Max(1, [int][Math]::Floor($Cpu / 2)))
Write-Output "[INFO] GPU class $Tier. Monitor $W x $H @ $Hz Hz, $Cpu CPU threads -> game $OW x $OH, scene $SW x $SH ($Scale %), limit $Fps fps"

foreach ($e in 'TOTK_OUTPUT_RES', 'TOTK_RENDER_SCALE', 'TOTK_FPS_LIMIT') {
    if ([Environment]::GetEnvironmentVariable($e, 'User') -or [Environment]::GetEnvironmentVariable($e, 'Machine')) {
        Write-Output "[WARN] $e is set in Windows and overrides totk.ini: remove it to use this preset."
    }
}

if (-not (Test-Path -LiteralPath $Bak)) {
    if (Test-Path -LiteralPath $Ini) { Copy-Item -LiteralPath $Ini -Destination $Bak -Force }
    else { [IO.File]::WriteAllText($Bak, '') }
}

$Order = @(
    'output_res', 'fullscreen', 'render_scale', 'fps_limit', 'realtime', 'cloth_realtime', 'highfps_fix',
    'prewarm_xlate', 'lib_prebuild_threads', 'timer_1ms', 'vk_present', 'perf_overlay'
)
$Ours = @{
    'output_res'           = "${OW}x${OH}"
    'fullscreen'           = '1'
    'render_scale'         = "$Scale"
    'fps_limit'            = "$Fps"
    'realtime'             = '1'
    'cloth_realtime'       = '1'
    'highfps_fix'          = '1'
    'prewarm_xlate'        = "$Xlate"
    'lib_prebuild_threads' = "$Lib"
    'timer_1ms'            = '1'
    'vk_present'           = 'mailbox'
    'perf_overlay'         = 'fps'
}
$Why = @{
    'output_res'   = $(if (@(1920, 2560, 3200, 3840) -notcontains $OW) { 'PAST THE MENU (1920x1080 to 3840x2160 only)' } else { 'largest 16:9 on your monitor' })
    'render_scale' = $(if ($Scale -gt 200) { 'PAST THE MENU (max 200 %)' } elseif ($Tier -eq 'top') { 'scene at the 4096 px maximum' } else { "set for your GPU ($Tier)" })
    'fps_limit'    = $(if ($Fps -lt $Hz) { 'capped at 60 for integrated graphics' } else { 'your monitor Hz' })
}

$new = @('# SI ULTRA by SI NEWS (SIGAME): 16:9 output for this monitor, scene set for your GPU, frame limit = your Hz')
foreach ($k in $Order) {
    $new += "$k = $($Ours[$k])"
    Write-Output ('[SET]  {0,-21} {1,-10} {2}' -f $k, $Ours[$k], $Why[$k])
}
[IO.File]::WriteAllLines($Block, [string[]]$new, $Utf8)
Write-Block $new

Write-Output '[INFO] Do not change Game resolution, 3D render scale or Frame limit in the F1 menu: its lists cannot hold these values.'
Write-Output "[OK]   SI ULTRA applied, free. Start totk.exe: $SW x $SH scene on a $OW x $OH screen, up to $Fps fps. APPLY again and Yes = Undo."
exit 0
