# SI ULTRA - Marvel Ultimate Alliance Recompiled (PC port, MUA 1 / Gold / MUA 2) - by SI NEWS, MIT.
# The port's launcher offers Upscaling Off or AMD FSR 1 only. Its runtime (ReXGlue SDK v0.10.0 + the port's patch
# 0127-presenter-spatial-upscalers) also accepts present_effect = "cas" (AMD CAS, no FidelityFX SDK needed) and
# present_cas_additional_sharpness in [0, 1], and the launcher leaves present_effect alone while Upscaling is Off
# (src/upscaling.h, PresentEffectFor). The game loads user_data\settings.toml over the shipped
# marvel_ultimate_alliance.toml (src/settings.cpp, LoadPlayerSettings), and the launcher keeps lines it does not own.
# This writes, for YOUR monitor (read from Windows):
#   resolution_scale = N     smallest launcher step that draws >= 2x your monitor's height (720 lines x N, max 4)
#   present_effect = "cas"   CAS scales that picture down to the window and sharpens it (hidden: not in the launcher)
#   present_cas_additional_sharpness = 0.5   (hidden, range 0-1, SDK default 0)
#   anisotropic_override = 5 (16x)   swap_post_effect = "none" (the 2x+ supersampled picture needs no FXAA blur)
#   mua_aspect_ratio = your monitor's shape   mua_upscaler = "off"   fullscreen = true
# Backups first (.sigame.bak); -Undo puts them back.
param(
    [switch]$Undo
)

$ExeName = 'marvel_ultimate_alliance_bundle.exe'
$Keys = 'resolution_scale|present_effect|present_cas_additional_sharpness|anisotropic_override|swap_post_effect|mua_aspect_ratio|mua_upscaler|fullscreen'
$GameKeys = 'mua_aspect_ratio|mua_upscaler'

# The port is portable (extracted anywhere): look in the usual places, three folders deep.
function Find-MuaRoot {
    # (folder, depth): user folders and Games folders 3 deep, a drive root only 1 deep (C:\<folder>\the exe).
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

$Root = if ($env:SIGAME_MUA_ROOT) { $env:SIGAME_MUA_ROOT } else { Find-MuaRoot }
if (-not $Root -or -not (Test-Path -LiteralPath (Join-Path $Root $ExeName))) {
    Write-Output "[FAIL] Marvel Ultimate Alliance PC port not found ($ExeName). Extract it in Downloads, Desktop, Documents or a Games folder, then apply again."
    exit 2
}
$UserData = Join-Path $Root 'user_data'
$Main = Join-Path $UserData 'settings.toml'
$GameFiles = foreach ($g in 'mua1', 'mua1_gold', 'mua2') {
    $f = Join-Path $UserData "$g\game_settings.toml"
    if (Test-Path -LiteralPath $f) { $f }
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath "$Main.sigame.bak")) { Write-Output '[FAIL] No backup settings.toml.sigame.bak to restore.'; exit 3 }
    foreach ($f in @($Main) + @($GameFiles)) {
        if (Test-Path -LiteralPath "$f.sigame.bak") {
            Copy-Item -LiteralPath "$f.sigame.bak" -Destination $f -Force
            Write-Output "[OK]   $(Split-Path $f -Leaf) restored from the backup ($(Split-Path (Split-Path $f) -Leaf))."
        }
    }
    exit 0
}

if (Get-Process -Name 'marvel_ultimate_alliance*' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Marvel Ultimate Alliance is running: close the game and the launcher, then apply again.'
    exit 4
}

# Your monitor, in real pixels (the video card's current mode, not the DPI-scaled desktop).
$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$W = if ($vc) { [int]$vc.CurrentHorizontalResolution } else { 1920 }
$H = if ($vc) { [int]$vc.CurrentVerticalResolution } else { 1080 }
$Scale = [Math]::Min(4, [Math]::Max(2, [int][Math]::Ceiling(2 * $H / 720)))
$shapes = [ordered]@{ '16:9' = 16 / 9; '16:10' = 16 / 10; '21:9' = 21 / 9; '32:9' = 32 / 9; '4:3' = 4 / 3; '5:4' = 5 / 4 }
$Aspect = ($shapes.Keys | Sort-Object { [Math]::Abs($shapes[$_] - $W / $H) } | Select-Object -First 1)
Write-Output "[INFO] Monitor $W x $H -> render $([int](720 * $Scale)) lines (resolution_scale $Scale), aspect $Aspect"

$Ours = [ordered]@{
    resolution_scale                 = "$Scale"
    present_effect                   = '"cas"'
    present_cas_additional_sharpness = '0.5'
    anisotropic_override             = '5'
    swap_post_effect                 = '"none"'
    mua_aspect_ratio                 = "`"$Aspect`""
    mua_upscaler                     = '"off"'
    fullscreen                       = 'true'
}

# Keep the first backups: applying twice must not overwrite the player's originals.
# No settings.toml yet = an empty one is the original (the launcher creates it when missing).
[void][IO.Directory]::CreateDirectory($UserData)
foreach ($f in @($Main) + @($GameFiles)) {
    if (-not (Test-Path -LiteralPath "$f.sigame.bak")) {
        if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination "$f.sigame.bak" -Force }
        else { [IO.File]::WriteAllText("$f.sigame.bak", '') }
    }
}

# Rewrite one file: drop the old lines of the keys we set (and our old header), add ours at the top.
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function Set-MuaKeys([string]$File, [string]$Pattern, [string]$Header) {
    $old = @(if (Test-Path -LiteralPath $File) { [IO.File]::ReadAllLines($File) } else { @() })
    $kept = foreach ($line in $old) {
        if ($line -match "^\s*#?\s*($Pattern)\s*=" -or $line -match '^# SI ULTRA by SI NEWS') { continue }
        $line
    }
    $new = @($Header)
    foreach ($k in $Ours.Keys) { if ($k -match "^($Pattern)$") { $new += "$k = $($Ours[$k])" } }
    [IO.File]::WriteAllText($File, (($new + @($kept)) -join "`r`n") + "`r`n", $Utf8)
}

$hdr = '# SI ULTRA by SI NEWS (SIGAME): supersampling + hidden CAS sharpening + 16x textures, for this monitor'
Set-MuaKeys -File $Main -Pattern $Keys -Header $hdr
foreach ($k in $Ours.Keys) { Write-Output "[SET]  $k = $($Ours[$k])" }
# A game's own file is loaded over settings.toml: its Upscaling and Aspect Ratio lines must agree.
foreach ($f in $GameFiles) {
    Set-MuaKeys -File $f -Pattern $GameKeys -Header $hdr
    Write-Output "[SET]  $(Split-Path (Split-Path $f) -Leaf): mua_upscaler = off, mua_aspect_ratio = $Aspect"
}

Write-Output "[OK]   SI ULTRA applied. Start the launcher and press PLAY: $([int](720 * $Scale)) lines scaled down with CAS, 16x textures."
exit 0
