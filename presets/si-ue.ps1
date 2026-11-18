# SI UE - one preset for Unreal Engine 4/5 games - by SI NEWS, MIT.
# Writes five Epic engine console variables into the game's OWN user override file:
#   %LOCALAPPDATA%\<project>\Saved\Config\Windows (or WindowsNoEditor)\Engine.ini, section [SystemSettings]
# (Epic docs, "Configuration Files" + "Console Variables Reference"). No game file is touched.
# The project folder comes from the game itself: SIGAME gives the exe of the game card, this script finds the
# Unreal "<Project>-Win64-Shipping.exe" next to it, and refuses any game that has none (= not an Unreal game).
# Only ever cheaper: a value already lower than ours stays. Every other line of your file stays.
# Backup first (Engine.ini.sigame.bak; no file before = Engine.ini.sigame.none); -Undo puts it back exactly.
param(
    [switch]$Undo,
    [string]$GameExe = '',     # given by SIGAME from the game card
    [string]$Name = 'the game',
    [string]$CfgDir = ''       # test only: the config folder
)

function Get-Norm([string]$s) { ($s.ToLowerInvariant() -replace '[^a-z0-9]', '') }

$Dir = $CfgDir
$Proc = ''
if (-not $Dir) {
    if (-not $GameExe -or -not (Test-Path -LiteralPath $GameExe)) {
        Write-Output "[FAIL] $Name not found on this PC: open SIGAME's game list, check the game is there, then APPLY."
        exit 2
    }
    $Root = Split-Path -Parent $GameExe
    # only this game's own folder: the exe's folder, or the game folder when the card points inside Binaries\Win64
    if ($Root -match '\\Binaries\\Win(64|GDK)$') { $Root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Root)) }
    $Ship = Get-ChildItem -LiteralPath $Root -Filter '*-Win64-Shipping.exe' -Recurse -Depth 3 -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $Ship) {
        Write-Output "[FAIL] No Unreal Engine *-Win64-Shipping.exe in the folder of $Name`: this preset is only for Unreal games."
        exit 6
    }
    $Proc = $Ship.BaseName
    $Project = $Proc -replace '-Win64-Shipping$', ''
    # <Project>\Binaries\Win64\<exe>: the game folder above the project folder
    $GameDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Ship.DirectoryName))
    $Want = @((Get-Norm $Project), (Get-Norm (Split-Path -Leaf $GameDir)), (Get-Norm $Name)) | Where-Object { $_ } | Select-Object -Unique
    $Hits = @()
    foreach ($d in (Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Directory -ErrorAction SilentlyContinue)) {
        if ($Want -notcontains (Get-Norm $d.Name)) { continue }
        foreach ($p in 'Windows', 'WindowsNoEditor', 'WinGDK') {
            $c = Join-Path $d.FullName "Saved\Config\$p"
            if (Test-Path -LiteralPath (Join-Path $c 'GameUserSettings.ini')) { $Hits += $c }
        }
    }
    if ($Hits.Count -eq 0) {
        Write-Output "[FAIL] Config folder of $Name not found: start the game once, close it, then APPLY again."
        exit 2
    }
    $Dir = @($Hits | Sort-Object { (Get-Item -LiteralPath (Join-Path $_ 'GameUserSettings.ini')).LastWriteTime } -Descending)[0]
}
$Cfg = Join-Path $Dir 'Engine.ini'
$Bak = "$Cfg.sigame.bak"
$Non = "$Cfg.sigame.none"
if ($Proc -and (Get-Process -Name $Proc -ErrorAction SilentlyContinue)) {
    Write-Output "[FAIL] $Name is running: close the game first, then APPLY."
    exit 4
}

if ($Undo) {
    if (Test-Path -LiteralPath $Non) {
        Remove-Item -LiteralPath $Cfg -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $Non -Force
        Write-Output '[OK]   Engine.ini removed: you had none before.'
        exit 0
    }
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
    Remove-Item -LiteralPath $Bak -Force
    Write-Output '[OK]   Engine.ini restored from the backup.'
    exit 0
}

$Had = Test-Path -LiteralPath $Cfg
if ($Had -and (Get-Item -LiteralPath $Cfg).IsReadOnly) {
    Write-Output '[FAIL] Engine.ini is read-only: untick Read-only in its properties, then apply again.'
    exit 5
}
$Txt = ''
$Bom = $false
if ($Had) {
    $Raw = [IO.File]::ReadAllBytes($Cfg)
    $Bom = ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF)
    $Txt = [IO.File]::ReadAllText($Cfg)
    if (-not ((Test-Path -LiteralPath $Bak) -or (Test-Path -LiteralPath $Non))) { Copy-Item -LiteralPath $Cfg -Destination $Bak }
} elseif (-not (Test-Path -LiteralPath $Bak)) {
    [IO.File]::WriteAllText($Non, '')
}
$Nl = if ($Txt -match "`r`n") { "`r`n" } elseif ($Txt -match "`n") { "`n" } else { "`r`n" }

$Inv = [Globalization.CultureInfo]::InvariantCulture
# key, value, label (Epic console variables; an engine without one of them ignores that line)
$Keys = @(
    , @('r.MotionBlurQuality', '0', 'motion blur')
    , @('r.DepthOfFieldQuality', '0', 'depth of field')
    , @('r.SceneColorFringeQuality', '0', 'chromatic aberration')
    , @('r.Tonemapper.GrainQuantization', '0', 'grain quantization')
    , @('r.FilmGrain', '0', 'film grain (UE5)')
)
Write-Output "[OK]   $Dir"
Write-Output '[OK]   backup saved, every other line of your file stays'
$Add = @()
foreach ($k in $Keys) {
    $Rx = [regex]('(?im)^(\s*' + [regex]::Escape($k[0]) + '\s*=\s*)([^\r\n]*)')
    $M = $Rx.Match($Txt)
    if (-not $M.Success) {
        $Add += "$($k[0])=$($k[1])"
        Write-Output "[SET]  $($k[2]): not in your file -> $($k[1])"
        continue
    }
    $Cur = $M.Groups[2].Value.Trim()
    $C = 0.0
    if ([double]::TryParse($Cur, [Globalization.NumberStyles]::Float, $Inv, [ref]$C) -and $C -le [double]::Parse($k[1], $Inv)) {
        Write-Output "[KEEP] $($k[2]): $Cur, already there or cheaper"
        continue
    }
    $Val = $k[1]
    $Txt = $Rx.Replace($Txt, { param($x) $x.Groups[1].Value + $Val })
    Write-Output "[SET]  $($k[2]): $Cur -> $Val"
}
if ($Add.Count) {
    $Block = ($Add -join $Nl) + $Nl
    $Sec = [regex]::Match($Txt, '(?im)^\[SystemSettings\][ \t]*(\r?\n|\z)')
    if ($Sec.Success) {
        $At = $Sec.Index + $Sec.Length
        if ($Sec.Groups[1].Length -eq 0) { $Block = $Nl + $Block }
        $Txt = $Txt.Insert($At, $Block)
    } else {
        if ($Txt.Length -and -not $Txt.EndsWith("`n")) { $Txt += $Nl }
        if ($Txt.Length) { $Txt += $Nl }
        $Txt += '[SystemSettings]' + $Nl + $Block
    }
}
try { [IO.File]::WriteAllText($Cfg, $Txt, (New-Object System.Text.UTF8Encoding($Bom))) }
catch { Write-Output "[FAIL] Engine.ini not written: $($_.Exception.Message)"; exit 7 }
Write-Output '[OK]   SI UE applied, free. Undo = APPLY, Yes.'
exit 0
