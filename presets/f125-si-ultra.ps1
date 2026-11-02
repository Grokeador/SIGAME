# SI ULTRA - F1 25 (PC) - by SI NEWS, MIT.
# The game's own settings file: Documents\My Games\F1 25\hardwaresettings\hardware_settings_config.xml. No DLL, no game file touched.
# Attribute names and values from xanpavle/F1-25-RE-Optimization (MIT, reverse-engineered, src/profile.cpp, docs/engineering.md):
#   the file is an engine export: preset-restricted attributes are clamped back at launch, so this preset writes ONLY the ones its author
#   lists as not managed by the preset (SSAO algorithm, SSR quality, cloud RT scale, grass distance, reflection update mode).
# Only ever cheaper: a value already cheaper than ours stays. Changing a graphics option in the menu rewrites the file: APPLY, No, Yes.
# Backup first (hardware_settings_config.xml.sigame.bak); -Undo puts it back.
param(
    [switch]$Undo
)

$Dir = if ($env:SIGAME_F125_CFG) { $env:SIGAME_F125_CFG } else { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'My Games\F1 25\hardwaresettings' }
$Cfg = Join-Path $Dir 'hardware_settings_config.xml'
$Bak = "$Cfg.sigame.bak"
if (Get-Process -Name 'F1_25' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] F1 25 is running: close the game first, then APPLY.'
    exit 4
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
    Remove-Item -LiteralPath $Bak -Force
    Write-Output '[OK]   hardware_settings_config.xml restored from the backup.'
    exit 0
}

if (-not (Test-Path -LiteralPath $Cfg)) {
    Write-Output '[FAIL] hardware_settings_config.xml not found: start F1 25 once, close it, then apply again.'
    exit 2
}
$Txt = [IO.File]::ReadAllText($Cfg)
if ($Txt -notmatch '<hardware_settings_config\b') {
    Write-Output '[FAIL] hardware_settings_config.xml is not the F1 25 settings file: delete it, start F1 25 once, then apply again.'
    exit 5
}
$Raw = [IO.File]::ReadAllBytes($Cfg)
$Bom = ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF)
if (-not (Test-Path -LiteralPath $Bak)) { Copy-Item -LiteralPath $Cfg -Destination $Bak }

$Inv = [Globalization.CultureInfo]::InvariantCulture
# tag, attribute, value, which way is cheaper, label
$Keys = @(
    , @('ssao', 'algorithm', '1', 'low', 'SSAO algorithm')
    , @('ssrt', 'quality', '2', 'low', 'screen space reflections quality')
    , @('weather_effects', 'proceduralCloudRTScale', '2.0', 'high', 'cloud render scale')
    , @('ground_cover', 'drawDistance', '80.0', 'low', 'grass draw distance')
    , @('vehicle_reflections', 'cubeMapUpdateMode', 'oneFacePerFrame', 'text', 'car reflection updates')
)
Write-Output '[OK]   backup saved, your preset and every other value stay'
foreach ($k in $Keys) {
    $Rx = [regex]('(<' + $k[0] + '\b[^>]*?\s' + $k[1] + '=")([^"]*)(")')
    $M = $Rx.Match($Txt)
    if (-not $M.Success) { Write-Output "[SKIP] $($k[4]): not in your file"; continue }
    $Cur = $M.Groups[2].Value
    $Set = $true
    if ($k[3] -ne 'text') {
        $C = 0.0
        if ([double]::TryParse($Cur, [Globalization.NumberStyles]::Float, $Inv, [ref]$C)) {
            $V = [double]::Parse($k[2], $Inv)
            if ($k[3] -eq 'low' -and $C -le $V) { $Set = $false }
            if ($k[3] -eq 'high' -and $C -ge $V) { $Set = $false }
        }
    } elseif ($Cur -eq $k[2]) { $Set = $false }
    if (-not $Set) { Write-Output "[KEEP] $($k[4]): $Cur, already there or cheaper"; continue }
    $Txt = $Rx.Replace($Txt, { param($x) $x.Groups[1].Value + $k[2] + $x.Groups[3].Value })
    Write-Output "[SET]  $($k[4]): $Cur -> $($k[2])"
}
[IO.File]::WriteAllText($Cfg, $Txt, (New-Object System.Text.UTF8Encoding($Bom)))
Write-Output '[OK]   SI ULTRA applied, free. Changed a graphics option in the menu? APPLY, No, Yes. Undo = APPLY, Yes.'
exit 0
