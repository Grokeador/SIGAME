# SI ULTRA - Dragon Ball Z Budokai Tenkaichi 3 (Tenkaichi3Decomp native PC port, z3xox, AGPL-3.0) - by SI NEWS, MIT.
# The port keeps its settings in bt3_settings.txt next to the game, `name=number` lines (port/src/plat_settings.c).
# Its F1 menu (port/src/gs/ui.cpp) lists five shapes only (4:3, 16:10, 16:9, 21:9 = 2389, 32:9 = 3556), but the file's
# aspect_milli takes ANY shape from 1333 to 4000 (port/src/plat_stub.c Port_AspectMilli). Texture packs are kept in
# memory up to 1024 MB (port/src/gs/gs_texpack.c TEXPACK_BUDGET), a size no menu shows: the variable BT3_PACK_MB moves it.
# This writes, for YOUR PC (read from Windows):
#   aspect_milli = W*1000/H   your monitor's exact shape (2560x1080 = 2370, 3840x1600 = 2400, 1366x768 = 1778 ...)
#   scale = N                 internal resolution: the smallest N with 448*N >= 2x your screen height (max 8)
#   interp = 1..3             smooth motion 60 / 120 / 240 by your monitor's Hz
#   menus_wide = 1            widescreen menus (beta), side_bars = 2 (fighter panels), texture_pack = 1, smooth_2d = 1
#   render_thread = 1         with 4+ CPU threads; skip_logos / skip_intro / skip_copyright = 1 (straight to the menu)
#   BT3_PACK_MB (user)        HD texture pack memory = a quarter of your RAM (512..8192 MB), PAST THE MENU (default 1024)
#   + the port's mod folders next to the game: textures, stages, songs
# Backup first (bt3_settings.txt.sigame.bak); -Undo puts it back and BT3_PACK_MB as it was.
param(
    [switch]$Undo
)

$ExeName = 'Tenkaichi3Decomp.exe'
$Keys = 'aspect_milli|scale|interp|menus_wide|menus_43|side_bars|texture_pack|smooth_2d|render_thread|skip_logos|skip_intro|skip_copyright'

function Find-Bt3Root {
    $roots = @()
    foreach ($d in 'Downloads', 'Desktop', 'Documents', 'Games') { $roots += , @((Join-Path $env:USERPROFILE $d), 3) }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'Games', 'Jogos', 'Giochi', 'Juegos', 'Tenkaichi3Decomp', 'BT3') { $roots += , @((Join-Path $drv.RootDirectory.FullName $d), 3) }
        $roots += , @($drv.RootDirectory.FullName, 1)
    }
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r[0])) { continue }
        if (Test-Path -LiteralPath (Join-Path $r[0] $ExeName)) { return $r[0] }
        $hit = Get-ChildItem -LiteralPath $r[0] -Filter $ExeName -File -Recurse -Depth $r[1] -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    return $null
}

$Root = if ($env:SIGAME_BT3_ROOT) { $env:SIGAME_BT3_ROOT } else { Find-Bt3Root }
if (-not $Root -or -not (Test-Path -LiteralPath (Join-Path $Root $ExeName))) {
    Write-Output "[FAIL] Tenkaichi3Decomp install folder not found ($ExeName). Set SIGAME_BT3_ROOT to it, then apply again."
    exit 2
}
$Cfg = Join-Path $Root 'bt3_settings.txt'
$Bak = "$Cfg.sigame.bak"
$PackBak = "$Cfg.sigame.packmb"

if (Get-Process -Name 'Tenkaichi3Decomp' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Tenkaichi3Decomp.exe is running: close the game first (it writes bt3_settings.txt when it closes a setting).'
    exit 4
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No backup bt3_settings.txt.sigame.bak to restore.'; exit 3 }
    Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
    $was = if (Test-Path -LiteralPath $PackBak) { ([IO.File]::ReadAllText($PackBak)).Trim() } else { '' }
    [Environment]::SetEnvironmentVariable('BT3_PACK_MB', $(if ($was) { $was } else { $null }), 'User')
    Write-Output '[OK]   bt3_settings.txt restored from the backup, BT3_PACK_MB as it was.'
    exit 0
}

$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$W = if ($env:SIGAME_TEST_W) { [int]$env:SIGAME_TEST_W } elseif ($vc) { [int]$vc.CurrentHorizontalResolution } else { 1920 }
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } elseif ($vc) { [int]$vc.CurrentVerticalResolution } else { 1080 }
$Hz = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } elseif ($vc -and $vc.CurrentRefreshRate -gt 0) { [int]$vc.CurrentRefreshRate } else { 60 }
$Cpu = if ($env:SIGAME_TEST_CPU) { [int]$env:SIGAME_TEST_CPU } else { [Environment]::ProcessorCount }
$RamMb = if ($env:SIGAME_TEST_RAM_MB) { [int]$env:SIGAME_TEST_RAM_MB } else {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($cs) { [int]([double]$cs.TotalPhysicalMemory / 1MB) } else { 4096 } }

# shape: the monitor's own, within the port's 1333..4000 (the menu has 1333, 1600, 1778, 2389, 3556)
$Aspect = [Math]::Min(4000, [Math]::Max(1333, [int][Math]::Floor($W * 1000.0 / $H)))
$MenuAspects = @(1333, 1600, 1778, 2389, 3556)
# internal resolution: 448 lines per step, at least twice the screen's height (supersampling), 1..8 as the port clamps it
$Scale = [Math]::Min(8, [Math]::Max(2, [int][Math]::Ceiling(2.0 * $H / 448)))
$Interp = if ($Hz -ge 240) { 3 } elseif ($Hz -ge 120) { 2 } else { 1 }
$Fps = @(30, 60, 120, 240)[$Interp]
$Thread = if ($Cpu -ge 4) { 1 } else { 0 }
$PackMb = [Math]::Min(8192, [Math]::Max(512, [int][Math]::Floor($RamMb / 4 / 256) * 256))
Write-Output "[INFO] Monitor $W x $H @ $Hz Hz, $Cpu CPU threads, $RamMb MB RAM -> shape $Aspect, ${Scale}x ($(512 * $Scale) x $(448 * $Scale)), $Fps fps motion, pack $PackMb MB"

foreach ($e in 'BT3_SCALE', 'BT3_ASPECT', 'BT3_WIDE', 'BT3_WINDOW', 'BT3_INTERP', 'BT3_TEXTURES', 'BT3_SETTINGS') {
    if ([Environment]::GetEnvironmentVariable($e, 'User') -or [Environment]::GetEnvironmentVariable($e, 'Machine')) {
        Write-Output "[WARN] $e is set in Windows and wins over bt3_settings.txt: remove it to use this preset."
    }
}

if (-not (Test-Path -LiteralPath $Bak)) {
    if (Test-Path -LiteralPath $Cfg) { Copy-Item -LiteralPath $Cfg -Destination $Bak -Force }
    else { [IO.File]::WriteAllText($Bak, '') }
    [IO.File]::WriteAllText($PackBak, [string][Environment]::GetEnvironmentVariable('BT3_PACK_MB', 'User'))
}

$Order = @('aspect_milli', 'scale', 'interp', 'menus_wide', 'menus_43', 'side_bars', 'texture_pack', 'smooth_2d', 'render_thread',
           'skip_logos', 'skip_intro', 'skip_copyright')
$Ours = @{
    'aspect_milli' = $Aspect; 'scale' = $Scale; 'interp' = $Interp; 'menus_wide' = 1; 'menus_43' = 0; 'side_bars' = 2
    'texture_pack' = 1; 'smooth_2d' = 1; 'render_thread' = $Thread; 'skip_logos' = 1; 'skip_intro' = 1; 'skip_copyright' = 1
}
$Why = @{
    'aspect_milli' = $(if ($MenuAspects -notcontains $Aspect) { 'PAST THE MENU (your exact monitor shape)' } else { "your monitor's shape" })
    'scale'        = "internal $(512 * $Scale) x $(448 * $Scale)"
    'interp'       = "smooth motion $Fps fps (your $Hz Hz)"
    'menus_wide'   = 'widescreen menus (beta)'
}

# the file holds `name=number` lines, then `name="text"` lines (online name, language): those stay as they are
$old = @(if (Test-Path -LiteralPath $Cfg) { [IO.File]::ReadAllLines($Cfg) } else { @() })
$kept = @(foreach ($line in $old) { if ($line -match "^\s*($Keys)=" -or $line.Trim() -eq '') { continue }; $line })
$nums = @($kept | Where-Object { $_ -notmatch '="' })
$texts = @($kept | Where-Object { $_ -match '="' })
$new = @()
foreach ($k in $Order) {
    $new += "$k=$($Ours[$k])"
    Write-Output ('[SET]  {0,-15} {1,-6} {2}' -f $k, $Ours[$k], $Why[$k])
}
[IO.File]::WriteAllText($Cfg, ((@($nums) + $new + @($texts)) -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))

[Environment]::SetEnvironmentVariable('BT3_PACK_MB', "$PackMb", 'User')
Write-Output ('[SET]  {0,-15} {1,-6} {2}' -f 'BT3_PACK_MB', $PackMb, 'PAST THE MENU (HD texture packs kept in memory; default 1024)')

foreach ($d in 'textures', 'stages', 'songs') {
    $p = Join-Path $Root $d
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}
Write-Output '[OK]   Mod folders ready next to the game: textures (PCSX2 packs), stages (.unk), songs (.mp3 / .adx).'
Write-Output '[INFO] Do not pick Aspect ratio in the F1 menu: its list cannot hold your exact shape.'
Write-Output "[OK]   SI ULTRA applied, free. Start Tenkaichi3Decomp: ${Scale}x internal, your exact shape, $Fps fps motion. APPLY again and Yes = Undo."
exit 0
