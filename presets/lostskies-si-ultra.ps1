# SI ULTRA - Lost Skies (PC, Steam) - by SI NEWS, MIT.
# Lost Skies is a Unity IL2CPP game (mods: github.com/kruftt/LostSkiesMods). Its Steam folder is "Wild Skies", data folder LostSkies_Data, exe LostSkies.exe
# (github.com/thunderstore-io/ecosystem-schema, games/data/generated/lost-skies.yml). Saves: LocalLow\Bossa Games\LostSkies (github.com/tempusthales/gaming_scripts),
# so Unity's registry folder is HKCU\Software\Bossa Games\LostSkies (docs.unity.com, PlayerPrefs: Software\CompanyName\ProductName).
# Keys:
#   boot.config, read by the Unity player at launch: gfx-enable-gfx-jobs=1 (docs.unity.com, Windows Player settings, Graphics Jobs: offloads render loops to
#     worker threads, less main-thread time in Camera.Render), gc-max-time-slice=3 ms per frame (gist.github.com/spongeyperson/869ed83f72d51b029bc41e62d906688a).
#   registry, Unity's own screen keys: Screenmanager Fullscreen mode = 1 FullScreenWindow (docs.unity.com, FullScreenMode: Unity warns exclusive mode can hurt
#     performance and advises this one), Screenmanager Resolution Width/Height = your monitor. The _h number is Unity's hash of the key name.
#   registry, Windows: HKCU\Software\Microsoft\DirectX\UserGpuPreferences, GpuPreference=2 = high performance GPU (Windows Settings, Graphics).
# Steam updates or Verify can put boot.config back: APPLY, No, Yes. Backups first (boot.config.sigame.bak, LostSkies-registry.sigame.json); -Undo restores the exact old values.
param(
    [switch]$Undo
)

$Reg = if ($env:SIGAME_LS_REG) { $env:SIGAME_LS_REG } else { 'HKCU:\Software\Bossa Games\LostSkies' }
$Gpu = if ($env:SIGAME_LS_GPUREG) { $env:SIGAME_LS_GPUREG } else { 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' }

function Find-Data {
    if ($env:SIGAME_LS_DIR) { return $env:SIGAME_LS_DIR }
    $Steam = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $Steam) { return $null }
    $Libs = @($Steam)
    $Vdf = Join-Path $Steam 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $Vdf) {
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($Vdf), '"path"\s+"([^"]+)"')) { $Libs += $m.Groups[1].Value.Replace('\\', '\') }
    }
    foreach ($l in $Libs) {
        $d = Join-Path $l 'steamapps\common\Wild Skies\LostSkies_Data'
        if (Test-Path -LiteralPath $d) { return $d }
    }
    return $null
}

if (Get-Process -Name 'LostSkies' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Lost Skies is running: close the game first, then APPLY.'
    exit 4
}
$Data = Find-Data
if (-not $Data -or -not (Test-Path -LiteralPath $Data)) {
    Write-Output '[FAIL] LostSkies_Data not found: Lost Skies must be installed with Steam (its folder is called Wild Skies).'
    exit 2
}
$Boot = Join-Path $Data 'boot.config'
$BootBak = "$Boot.sigame.bak"
$RegBak = Join-Path $Data 'LostSkies-registry.sigame.json'
$Exe = Join-Path (Split-Path -Parent $Data) 'LostSkies.exe'

if ($Undo) {
    if (-not (Test-Path -LiteralPath $BootBak) -or -not (Test-Path -LiteralPath $RegBak)) { Write-Output '[FAIL] No .sigame backup to restore.'; exit 3 }
    Copy-Item -LiteralPath $BootBak -Destination $Boot -Force
    Remove-Item -LiteralPath $BootBak -Force
    Write-Output '[OK]   boot.config restored from the backup.'
    $Saved = [IO.File]::ReadAllText($RegBak) | ConvertFrom-Json   # Windows PowerShell pipes a JSON array as ONE object: assign first, then foreach
    foreach ($o in $Saved) {
        if ($o.Absent) {
            Remove-ItemProperty -LiteralPath $o.Path -Name $o.Name -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -LiteralPath $o.Path -Name $o.Name -Value $o.Value -Type $o.Kind
        }
    }
    Remove-Item -LiteralPath $RegBak -Force
    Write-Output '[OK]   registry values restored, exactly as they were.'
    exit 0
}

if (-not (Test-Path -LiteralPath $Boot)) {
    Write-Output '[FAIL] boot.config not found: in Steam, Lost Skies, Properties, Installed Files, Verify, then apply again.'
    exit 5
}

# --- Your monitor decides the resolution ---
$W = 0; $H = 0
if ($env:SIGAME_TEST_W) {
    $W = [int]$env:SIGAME_TEST_W; $H = [int]$env:SIGAME_TEST_H
} else {
    Add-Type -AssemblyName System.Windows.Forms
    $B = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $W = $B.Width; $H = $B.Height
}
$Pref = 'GpuPreference=2;'
$Vals = @(
    , @($Reg, 'Screenmanager Fullscreen mode_h3630240806', 1, 'DWord')
    , @($Reg, 'Screenmanager Resolution Width_h182942802', $W, 'DWord')
    , @($Reg, 'Screenmanager Resolution Height_h2627697771', $H, 'DWord')
    , @($Gpu, $Exe, $Pref, 'String')
)

# --- Backups first: a second APPLY never overwrites them, so Undo always gets your real old values ---
if (-not (Test-Path -LiteralPath $BootBak)) { Copy-Item -LiteralPath $Boot -Destination $BootBak }
if (-not (Test-Path -LiteralPath $RegBak)) {
    $Old = foreach ($v in $Vals) {
        $Key = Get-Item -LiteralPath $v[0] -ErrorAction SilentlyContinue
        if ($Key -and ($Key.GetValueNames() -contains $v[1])) {
            [pscustomobject]@{ Path = $v[0]; Name = $v[1]; Absent = $false; Value = $Key.GetValue($v[1]); Kind = [string]$Key.GetValueKind($v[1]) }
        } else {
            [pscustomobject]@{ Path = $v[0]; Name = $v[1]; Absent = $true; Value = $null; Kind = $v[3] }
        }
    }
    [IO.File]::WriteAllText($RegBak, (ConvertTo-Json -InputObject @($Old) -Depth 3), (New-Object System.Text.UTF8Encoding($false)))
}
Write-Output '[OK]   backups saved: boot.config and the registry values'

# --- boot.config: change or add our 2 lines, every other line stays, same line endings ---
$Txt = [IO.File]::ReadAllText($Boot)
$Nl = if ($Txt -match "`r`n") { "`r`n" } else { "`n" }
$Lines = @(
    , @('gfx-enable-gfx-jobs', '1', 'graphics jobs ON: render loops go to the other CPU cores')
    , @('gc-max-time-slice', '3', 'garbage collector: 3 ms per frame, at most')
)
foreach ($k in $Lines) {
    $Line = "$($k[0])=$($k[1])"
    $Rx = '(?m)^' + [regex]::Escape($k[0]) + '=[^\r\n]*'
    if ($Txt -match $Rx) {
        $Txt = [regex]::Replace($Txt, $Rx, $Line)
    } else {
        if ($Txt.Length -and -not $Txt.EndsWith("`n")) { $Txt += $Nl }
        $Txt += $Line + $Nl
    }
    Write-Output "[SET]  $($k[2])"
}
[IO.File]::WriteAllText($Boot, $Txt, (New-Object System.Text.UTF8Encoding($false)))

# --- Registry ---
foreach ($v in $Vals) {
    if (-not (Test-Path -LiteralPath $v[0])) { New-Item -Path $v[0] -Force | Out-Null }
    Set-ItemProperty -LiteralPath $v[0] -Name $v[1] -Value $v[2] -Type $v[3]
}
Write-Output '[SET]  full screen window, the mode Unity advises over exclusive'
Write-Output "[SET]  resolution $W x $H, your monitor"
Write-Output '[SET]  Windows runs LostSkies.exe on the high performance GPU'
Write-Output '[OK]   SI ULTRA applied, free. Start Lost Skies. APPLY again and Yes = Undo.'
exit 0
