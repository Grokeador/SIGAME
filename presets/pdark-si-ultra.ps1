# SI ULTRA - Perfect Dark Native PC Port (fgsfdsfgs/perfect_dark, fast3d OpenGL engine) - by SI NEWS, MIT.
# In the port's Extended Video Options menu (port/src/optionsmenu.c), Anisotropic Filtering starts with its slider range
# set to 8, while MipmapFilter, AllowHiDpi, MemorySize, SkipIntro, MaxExplosions, and FovAffectsZoom are registered in
# port/src/video.c (lines 574-585) and port/src/main.c (lines 163-176) but NEVER exposed in any menu dialog.
# Furthermore, enabling Uncap Tickrate (Game.TickRateDivisor = 0) unlocks up to 240 FPS, but as the port's README warns
# (line 35), running faster than ~165 FPS causes physics/gameplay issues unless FramerateLimit caps it safely.
# This writes, for YOUR monitor (read from Windows):
#   [Video] DefaultFullscreen=1, DefaultWidth/Height=your monitor, AllowHiDpi=1, VSync=1, FramerateLimit=min(Hz, 165)
#   [Video] MSAA=8, TextureFilter=1 (Bilinear), DetailTextures=1, MipmapFilter=2 (Trilinear), AnisotropicFilter=16
#   [Game]  MemorySize=32 (32 MB heap vs 16 MB default), CenterHUD=2 (Wide), TickRateDivisor=0, SkipIntro=1, MaxExplosions=48
#   [Game.Player1] FovY=75.000000, FovAffectsZoom=1, ExtendedControls=1, MouseAimMode=0
# Preserves all your existing [Input] and keybind sections untouched. Backups first (pd.ini.sigame.bak); -Undo restores byte-for-byte.
param(
    [switch]$Undo
)

$ExeName = 'pd.x86_64.exe'

function Find-PdDir {
    $appDataDir = Join-Path $env:APPDATA 'perfectdark'
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
        if (Test-Path -LiteralPath $exe) { return $r[0] }
        $hit = Get-ChildItem -LiteralPath $r[0] -Filter $ExeName -File -Recurse -Depth $r[1] -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }
    if (Test-Path -LiteralPath $appDataDir) { return $appDataDir }
    return $null
}

$PdDir = if ($env:SIGAME_PD_DIR) { $env:SIGAME_PD_DIR } else { Find-PdDir }
if (-not $PdDir) {
    Write-Output "[FAIL] Perfect Dark PC port not found ($ExeName). Extract pd-x86_64-windows.zip into a writable folder, then apply again."
    exit 2
}
[void][IO.Directory]::CreateDirectory($PdDir)
$IniPath = Join-Path $PdDir 'pd.ini'
$IniBak  = "$IniPath.sigame.bak"

if ($Undo) {
    if (-not (Test-Path -LiteralPath $IniBak)) { Write-Output '[FAIL] No backup pd.ini.sigame.bak to restore.'; exit 3 }
    Copy-Item -LiteralPath $IniBak -Destination $IniPath -Force
    Write-Output '[OK]   pd.ini restored from the backup.'
    exit 0
}

if (Get-Process -Name 'pd.x86_64*', 'pd.i686*' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Perfect Dark is running: close the game first (it saves pd.ini on exit).'
    exit 4
}

$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$W = if ($env:SIGAME_TEST_W) { [int]$env:SIGAME_TEST_W } elseif ($vc) { [int]$vc.CurrentHorizontalResolution } else { 1920 }
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } elseif ($vc) { [int]$vc.CurrentVerticalResolution } else { 1080 }
$Hz = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } elseif ($vc -and $vc.CurrentRefreshRate -gt 0) { [int]$vc.CurrentRefreshRate } else { 60 }
$FpsCap = [Math]::Min(165, [Math]::Max(60, $Hz))
$IsUltrawide = (($W / [double]$H) -gt 1.85)
$FovVal = if ($IsUltrawide) { '80.000000' } else { '75.000000' }

Write-Output "[INFO] Monitor $W x $H @ $Hz Hz -> Fullscreen $W x $H, safe $FpsCap FPS cap, 8x MSAA, 16x Anisotropic, 32 MB heap"

if (-not (Test-Path -LiteralPath $IniBak)) {
    if (Test-Path -LiteralPath $IniPath) { Copy-Item -LiteralPath $IniPath -Destination $IniBak -Force }
    else { [IO.File]::WriteAllText($IniBak, '') }
}

$Sections = [ordered]@{}
$CurSec = ''
if (Test-Path -LiteralPath $IniPath) {
    foreach ($ln in [IO.File]::ReadAllLines($IniPath)) {
        $t = $ln.Trim()
        if ($t -match '^\[(.+)\]$') {
            $CurSec = $Matches[1]
            if (-not $Sections.Contains($CurSec)) { $Sections[$CurSec] = [ordered]@{} }
        } elseif ($CurSec -and $t -match '^([^=;]+)=(.*)$') {
            $Sections[$CurSec][$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
}

foreach ($s in @('Video', 'Game', 'Game.Player1')) {
    if (-not $Sections.Contains($s)) { $Sections[$s] = [ordered]@{} }
}

$VideoKeys = [ordered]@{
    DefaultFullscreen   = '1'
    DefaultMaximize     = '0'
    DefaultWidth        = "$W"
    DefaultHeight       = "$H"
    ExclusiveFullscreen = '0'
    CenterWindow        = '1'
    AllowHiDpi          = '1'
    VSync               = '1'
    FramebufferEffects  = '1'
    FramerateLimit      = "$FpsCap"
    DisplayFPS          = '0'
    MSAA                = '8'
    TextureFilter       = '1'
    TextureFilter2D     = '1'
    DetailTextures      = '1'
    MipmapFilter        = '2'
    AnisotropicFilter   = '16'
}
foreach ($k in $VideoKeys.Keys) { $Sections['Video'][$k] = $VideoKeys[$k] }

$GameKeys = [ordered]@{
    MemorySize           = '32'
    CenterHUD            = '2'
    MenuMouseControl     = '1'
    TickRateDivisor      = '0'
    ExtraSleep           = '1'
    SkipIntro            = '1'
    GEMuzzleFlashes      = '1'
    MaxExplosions        = '48'
}
foreach ($k in $GameKeys.Keys) { $Sections['Game'][$k] = $GameKeys[$k] }

$P1Keys = [ordered]@{
    FovY             = $FovVal
    FovAffectsZoom   = '1'
    MouseAimMode     = '0'
    ExtendedControls = '1'
}
foreach ($k in $P1Keys.Keys) { $Sections['Game.Player1'][$k] = $P1Keys[$k] }

$OutLines = New-Object System.Collections.Generic.List[string]
foreach ($sec in $Sections.Keys) {
    if ($OutLines.Count -gt 0) { $OutLines.Add('') }
    $OutLines.Add("[$sec]")
    foreach ($k in $Sections[$sec].Keys) {
        $OutLines.Add("$k=$($Sections[$sec][$k])")
    }
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($IniPath, ($OutLines -join "`r`n") + "`r`n", $Utf8)

Write-Output "[SET]  [Video] DefaultWidth=$W DefaultHeight=$H Fullscreen=1 AllowHiDpi=1"
Write-Output "[SET]  [Video] MSAA=8 AnisotropicFilter=16 MipmapFilter=2 DetailTextures=1"
Write-Output "[SET]  [Video] FramerateLimit=$FpsCap VSync=1  (safe high-FPS ceiling <= 165)"
Write-Output "[SET]  [Game]  MemorySize=32 TickRateDivisor=0 SkipIntro=1 MaxExplosions=48 CenterHUD=2"
Write-Output "[SET]  [Game.Player1] FovY=$FovVal FovAffectsZoom=1 ExtendedControls=1"
Write-Output "[OK]   SI ULTRA applied. Start pd.x86_64.exe: $W x $H @ $FpsCap FPS, 8x MSAA, 16x Anisotropic, 32 MB heap."
exit 0
