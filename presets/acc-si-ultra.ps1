# SI ULTRA - Assetto Corsa Competizione (PC) - by SI NEWS, MIT.
# The game's own override file: %LOCALAPPDATA%\AC2\Saved\Config\WindowsNoEditor\Engine.ini, section [ConsoleVariables]. No game file touched.
# Keys and values from the ACC Engine.ini block shared by Unionjackstar on Steam (steamcommunity.com/app/805550/discussions/0/1734343065616409741).
# Left out on purpose: r.Tonemapper.Sharpen (the video menu's sharpening slider drives it), r.Streaming.* and the VR-only lines.
# Only ever cheaper: a value already cheaper than ours stays. Every other line of your file stays. Check AC2.log to see what the game took.
# Backup first (Engine.ini.sigame.bak; no file before = Engine.ini.sigame.none); -Undo puts it back exactly.
param(
    [switch]$Undo
)

$Dir = if ($env:SIGAME_ACC_CFG) { $env:SIGAME_ACC_CFG } else { Join-Path $env:LOCALAPPDATA 'AC2\Saved\Config\WindowsNoEditor' }
$Cfg = Join-Path $Dir 'Engine.ini'
$Bak = "$Cfg.sigame.bak"
$Non = "$Cfg.sigame.none"
if (Get-Process -Name 'AC2-Win64-Shipping' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Assetto Corsa Competizione is running: close the game first, then APPLY.'
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

if (-not (Test-Path -LiteralPath $Dir)) {
    Write-Output '[FAIL] AC2 config folder not found: start Assetto Corsa Competizione once, close it, then apply again.'
    exit 2
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
# key, value, label
$Keys = @(
    , @('r.MotionBlurQuality', '0', 'motion blur')
    , @('r.DepthOfFieldQuality', '0', 'depth of field')
    , @('r.LensFlareQuality', '1', 'lens flares')
    , @('r.SceneColorFringeQuality', '0', 'colour fringe')
    , @('r.SSR.Quality', '0', 'screen space reflections')
    , @('r.AmbientOcclusionLevels', '1', 'ambient occlusion levels')
    , @('r.BloomQuality', '2', 'bloom')
    , @('r.FastBlurThreshold', '0', 'fast blur')
    , @('r.TranslucencyVolumeBlur', '0', 'translucency blur')
    , @('r.TranslucencyLightingVolumeDim', '4', 'translucency lighting volume')
)
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
    $Sec = [regex]::Match($Txt, '(?im)^\[ConsoleVariables\][ \t]*(\r?\n|\z)')
    if ($Sec.Success) {
        $At = $Sec.Index + $Sec.Length
        if ($Sec.Groups[1].Length -eq 0) { $Block = $Nl + $Block }
        $Txt = $Txt.Insert($At, $Block)
    } else {
        if ($Txt.Length -and -not $Txt.EndsWith("`n")) { $Txt += $Nl }
        if ($Txt.Length) { $Txt += $Nl }
        $Txt += '[ConsoleVariables]' + $Nl + $Block
    }
}
[IO.File]::WriteAllText($Cfg, $Txt, (New-Object System.Text.UTF8Encoding($Bom)))
Write-Output '[OK]   SI ULTRA applied, free. Undo = APPLY, Yes.'
exit 0
