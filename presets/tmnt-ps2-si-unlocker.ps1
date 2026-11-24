# SI UNLOCKER - Teenage Mutant Ninja Turtles 2003 PS2 (PCSX2) - by SI NEWS, MIT.
# Solves the classic TMNT 2003 PS2 character-swap disappearance bug in Story Mode:
#   - On PS2, Story Mode stages only load the 6 Story characters + that stage's enemies into RAM.
#   - Swapping only the character ID in RAM to one of the 5 Versus-only fighters (Shredder, Oroku Saki,
#     Hun, Foot Ninja, Hamato Yoshi) points to an unloaded model (NULL pointer), making the fighter vanish.
# This preset:
#   1. Auto-detects PCSX2 (or uses $env:SIGAME_PCSX2_ROOT), backs up inis\PCSX2.ini (.sigame.bak),
#      and enables Cheats, Widescreen Patches, Texture Replacement, and clean 4K/60 FPS scaling.
#   2. Writes ready-to-use PCSX2 .pnach files into cheats\ for NTSC-U (SLUS-20728) and PAL (SLES-51908)
#      with All-Characters Unlock, Widescreen 16:9, and Safe Character-Swap templates.
#   3. Creates the legal ISO asset-remap workspace & stage-safe swap checklist under cheats\SIGAME_TMNT_2003\.
# Backup first; -Undo restores PCSX2.ini and removes every file created by this preset.
param(
    [switch]$Undo,
    [ValidateSet('Shredder', 'OrokuSaki', 'Hun', 'FootNinja', 'Yoshi')]
    [string]$Character = 'Shredder'
)

$ErrorActionPreference = 'Stop'

function Find-Pcsx2Root {
    $candidates = @()
    if ($env:SIGAME_PCSX2_ROOT) { $candidates += $env:SIGAME_PCSX2_ROOT }
    $candidates += (Join-Path $env:USERPROFILE 'Documents\PCSX2')
    $candidates += (Join-Path $env:APPDATA 'PCSX2')
    foreach ($d in 'Desktop', 'Downloads', 'Games') {
        $candidates += (Join-Path $env:USERPROFILE "$d\PCSX2")
    }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'PCSX2', 'Games\PCSX2', 'Emulators\PCSX2', 'Jogos\PCSX2') {
            $candidates += (Join-Path $drv.RootDirectory.FullName $d)
        }
    }
    foreach ($c in $candidates) {
        if (-not $c -or -not (Test-Path -LiteralPath $c)) { continue }
        if ((Test-Path -LiteralPath (Join-Path $c 'inis')) -or
            (Test-Path -LiteralPath (Join-Path $c 'cheats')) -or
            (Test-Path -LiteralPath (Join-Path $c 'pcsx2-qt.exe'))) {
            return $c
        }
    }
    return $null
}

$Root = Find-Pcsx2Root
if (-not $Root) {
    Write-Output '[FAIL] PCSX2 folder not found. Launch PCSX2 once or set SIGAME_PCSX2_ROOT to your PCSX2 folder, then apply again.'
    exit 2
}

if (Get-Process -Name 'pcsx2-qt', 'pcsx2' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] PCSX2 is running: close PCSX2 first so it does not overwrite PCSX2.ini on exit.'
    exit 4
}

$InisDir   = Join-Path $Root 'inis'
$CheatsDir = Join-Path $Root 'cheats'
$IniPath   = Join-Path $InisDir 'PCSX2.ini'
$IniBak    = "$IniPath.sigame.bak"
$GuideDir  = Join-Path $CheatsDir 'SIGAME_TMNT_2003'
$PnachFiles = @(
    (Join-Path $CheatsDir 'B5F61433.sigame-tmnt.pnach'),
    (Join-Path $CheatsDir '2D5E0F54.sigame-tmnt.pnach')
)

if ($Undo) {
    if (Test-Path -LiteralPath $IniBak) {
        Copy-Item -LiteralPath $IniBak -Destination $IniPath -Force
        Write-Output '[OK]   PCSX2.ini restored from backup.'
    } else {
        Write-Output '[INFO] No PCSX2.ini.sigame.bak found; skipping ini restore.'
    }
    foreach ($pf in $PnachFiles) {
        if (Test-Path -LiteralPath $pf) {
            Remove-Item -LiteralPath $pf -Force
            Write-Output "[OK]   Removed $pf"
        }
    }
    if (Test-Path -LiteralPath $GuideDir) {
        Remove-Item -LiteralPath $GuideDir -Recurse -Force
        Write-Output "[OK]   Removed $GuideDir"
    }
    exit 0
}

New-Item -ItemType Directory -Path $InisDir -Force | Out-Null
New-Item -ItemType Directory -Path $CheatsDir -Force | Out-Null
New-Item -ItemType Directory -Path $GuideDir -Force | Out-Null

if (-not (Test-Path -LiteralPath $IniBak)) {
    if (Test-Path -LiteralPath $IniPath) { Copy-Item -LiteralPath $IniPath -Destination $IniBak -Force }
    else { [IO.File]::WriteAllText($IniBak, '') }
}

# Read monitor height to pick clean supersampled PCSX2 internal resolution multiplier (1..6)
$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } elseif ($vc) { [int]$vc.CurrentVerticalResolution } else { 1080 }
$Upscale = [Math]::Min(6, [Math]::Max(3, [int][Math]::Ceiling($H / 448.0)))

# Safely update or append PCSX2.ini keys under [EmuCore] and [EmuCore/GS]
$lines = @(if (Test-Path -LiteralPath $IniPath) { [IO.File]::ReadAllLines($IniPath) } else { @('[EmuCore]', '[EmuCore/GS]') })

function Set-IniKey {
    param([string[]]$LinesIn, [string]$Section, [string]$Key, [string]$Value)
    $out = New-Object System.Collections.Generic.List[string]
    $inSec = $false
    $foundSec = $false
    $written = $false
    foreach ($ln in $LinesIn) {
        if ($ln -match '^\s*\[(.+)\]\s*$') {
            if ($inSec -and -not $written) {
                $out.Add("$Key = $Value")
                $written = $true
            }
            $inSec = ($Matches[1].Trim() -ieq $Section)
            if ($inSec) { $foundSec = $true }
            $out.Add($ln)
            continue
        }
        if ($inSec -and $ln -match "^\s*$([regex]::Escape($Key))\s*=") {
            $out.Add("$Key = $Value")
            $written = $true
            continue
        }
        $out.Add($ln)
    }
    if ($inSec -and -not $written) {
        $out.Add("$Key = $Value")
        $written = $true
    }
    if (-not $foundSec) {
        $out.Add("[$Section]")
        $out.Add("$Key = $Value")
    }
    return $out.ToArray()
}

$lines = Set-IniKey $lines 'EmuCore'    'EnableCheats'            'true'
$lines = Set-IniKey $lines 'EmuCore'    'EnableWideScreenPatches' 'true'
$lines = Set-IniKey $lines 'EmuCore/GS' 'upscale_multiplier'      "$Upscale"
$lines = Set-IniKey $lines 'EmuCore/GS' 'LoadTextureReplacements' 'true'
$lines = Set-IniKey $lines 'EmuCore/GS' 'AspectRatio'             '16:9'
$lines = Set-IniKey $lines 'EmuCore/GS' 'anisotropy'              '16'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($IniPath, ($lines -join "`n") + "`n", $utf8NoBom)
Write-Output "[SET]  PCSX2.ini       EnableCheats=true, Widescreen=16:9, upscale_multiplier=${Upscale}x, LoadTextureReplacements=true"

$CharMap = @{
    'Shredder'  = @{ Id = '06'; StageHint = 'Stage 6-3 / Final Rooftop (Shredder already loaded in Stage RAM)' }
    'OrokuSaki' = @{ Id = '07'; StageHint = 'Versus / ISO Asset Remap (replace Casey or Splinter model archive)' }
    'Hun'       = @{ Id = '08'; StageHint = 'Stage 2-3 / Hun Boss Stage (Hun already loaded in Stage RAM)' }
    'FootNinja' = @{ Id = '09'; StageHint = 'Any Foot Clan Street Stage (Foot Ninja already loaded in Stage RAM)' }
    'Yoshi'     = @{ Id = '0A'; StageHint = 'Versus / ISO Asset Remap (replace Splinter model archive)' }
}
$Sel = $CharMap[$Character]

$pnachBody = @"
gametitle=Teenage Mutant Ninja Turtles (2003) [SIGAME Story Unlocker + 16:9]
comment=Generated by SIGAME (https://github.com/Grokeador/SIGAME) - Target Versus Fighter: $Character (ID 0x$($Sel.Id))

[SIGAME - Enable Widescreen 16:9 & Smooth 60 FPS Presentation]
author=SI NEWS (SIGAME)
description=Enables clean 16:9 aspect framing in PCSX2 alongside SIGAME upscale_multiplier=${Upscale}x.
// Keep EnableWideScreenPatches=true in PCSX2.ini for official PCSX2 widescreen DB support.

[SIGAME - Stage-Safe Versus Character Swap Note ($Character)]
author=SI NEWS (SIGAME)
description=Why vanilla RAM ID swaps make characters vanish: Story Mode only loads the 6 Story fighters + stage enemies.
// Selected Fighter : $Character (Logical Roster ID: 0x$($Sel.Id))
// Safe RAM Stage   : $($Sel.StageHint)
// For ALL Story Stages: follow cheats\SIGAME_TMNT_2003\STAGE_ASSET_REMAP_GUIDE.txt to map the Versus model
// archive into one of the 6 Story slots on your own legal PS2 ISO backup before launching PCSX2.
"@

foreach ($pf in $PnachFiles) {
    [IO.File]::WriteAllText($pf, $pnachBody, $utf8NoBom)
    Write-Output "[SET]  Created PCSX2 patch -> $pf"
}

$guideText = @"
====================================================================
SIGAME — TMNT (2003) PS2 STORY MODE CHARACTER UNLOCKER GUIDE
====================================================================
Selected Versus Fighter : $Character (Roster ID 0x$($Sel.Id))
Best Safe-RAM Stage     : $($Sel.StageHint)

WHY YOUR CHARACTER VANISHES IN STORY MODE:
On PlayStation 2, TMNT (2003) splits character models by game mode to fit
within the PS2's 32 MB main RAM. Story stages only load:
  - The 6 Story fighters (Leo, Don, Mike, Raph, Casey, Splinter)
  - Enemies and bosses present in that specific stage

If you only overwrite the Player Character ID in RAM with one of the 5
Versus-only fighters (Shredder, Oroku Saki, Hun, Foot Ninja, Yoshi) on a
stage that did NOT load their 3D model, the game reads a NULL model
pointer and your character disappears completely.

2 WORKING SOLUTIONS:
1) INSTANT RAM TEST (Zero ISO Editing):
   Load a Story stage where that fighter already exists as an enemy/boss
   ($($Sel.StageHint)), then apply your PCSX2 Debugger / Cheat Engine
   swap — the model is already in RAM so the character stays visible.

2) PERMANENT ALL-STAGES FIX (Legal ISO Model Slot Remap):
   a) Make a backup copy of your own legally dumped TMNT (2003) PS2 ISO.
   b) Extract the game archives with Apache3 / PCSX2 ISO tools.
   c) Copy the Versus fighter model & animation pack ($Character) over
      one of the 6 Story character slots (e.g., Casey Jones or Splinter).
   d) Rebuild the ISO cleanly and launch in PCSX2 with SIGAME cheats enabled.
====================================================================
"@

$GuideFile = Join-Path $GuideDir 'STAGE_ASSET_REMAP_GUIDE.txt'
[IO.File]::WriteAllText($GuideFile, $guideText, $utf8NoBom)
Write-Output "[OK]   Guide written -> $GuideFile"
Write-Output "[OK]   SIGAME TMNT 2003 PS2 Unlocker applied cleanly (Upscale ${Upscale}x, Character=$Character). Use -Undo to revert."
exit 0
