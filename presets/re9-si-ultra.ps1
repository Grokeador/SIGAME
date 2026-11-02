# SI ULTRA - Resident Evil Requiem (RE Engine, Steam) - by SI NEWS, MIT.
# These keys live outside the game's own options menu. REFramework
# (praydog, MIT, github.com/praydog/REFramework, nightly builds support Requiem) reads them and saves them as key=value lines
# in re2_fw_config.txt next to the game exe (or %APPDATA%\REFramework\<exe>\ when the game folder is read-only;
# src/REFramework.cpp get_persistent_dir, src/mods/REFrameworkConfig.hpp). Every key and its range below is read from
# REFramework's own source (src/mods/Camera.hpp, src/mods/Graphics.hpp):
#   Camera_Enabled / Camera_DisableVignette = true
#   Camera_GlobalFOVEnabled = true, Camera_GlobalFOV = 90 on 16:9-16:10 screens (key range 0..180, REFramework default 81)
#   21:9 and wider: Graphics_UltrawideFix + UltrawideCustomFOV + UltrawideFixVerticalFOV_V2 + UltrawideConstrainUI = true
#   (HUD stays inside 16:9), Graphics_UltrawideFOVMultiplier_V2 = 1.0 (key range 0.01..3.0); no global FOV there.
# REFramework not installed = nothing is written. Backup first (<file>.sigame.bak); -Undo puts it back.
param(
    [switch]$Undo
)

function Find-Re9Roots {
    if ($env:SIGAME_RE9_ROOT) { return @($env:SIGAME_RE9_ROOT) }
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
    $libs = @()
    if ($steam) {
        $libs += $steam
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value -replace '\\\\', '\' }
        }
    }
    $roots = @()
    foreach ($l in ($libs | Select-Object -Unique)) {
        $c = Join-Path $l 'steamapps\common'
        $roots += @(Get-ChildItem -LiteralPath $c -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '(?i)resident.?evil.?requiem|biohazard.?requiem|^re9' } | ForEach-Object { $_.FullName })
    }
    return @($roots | Where-Object { Test-Path -LiteralPath $_ })
}

$Root = @(Find-Re9Roots)[0]
if (-not $Root) {
    Write-Output '[FAIL] Resident Evil Requiem not found in your Steam libraries.'
    exit 2
}
if (-not (Test-Path -LiteralPath (Join-Path $Root 'dinput8.dll'))) {
    Write-Output '[FAIL] REFramework is not installed: put dinput8.dll from REFramework.zip (github.com/praydog/REFramework-nightly) in the game folder, start the game once, close it, then apply again.'
    exit 2
}
$Exe = @(Get-ChildItem -LiteralPath $Root -Filter '*.exe' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch '(?i)crash|report|setup|unins' } | Sort-Object Length -Descending)[0]
if ($Exe -and (Get-Process -Name $Exe.BaseName -ErrorAction SilentlyContinue)) {
    Write-Output '[FAIL] Resident Evil Requiem is running: close the game first (REFramework writes its config when it closes).'
    exit 4
}
$Cfg = Join-Path $Root 're2_fw_config.txt'
if (-not (Test-Path -LiteralPath $Cfg) -and $Exe) {
    $alt = Join-Path $env:APPDATA ('REFramework\' + $Exe.BaseName + '\re2_fw_config.txt')
    if (Test-Path -LiteralPath $alt) { $Cfg = $alt }
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath "$Cfg.sigame.bak")) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    Copy-Item -LiteralPath "$Cfg.sigame.bak" -Destination $Cfg -Force
    Write-Output '[OK]   REFramework config restored from the backup.'
    exit 0
}

# --- Your screen ---
Add-Type -AssemblyName System.Windows.Forms
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$W = if ($env:SIGAME_TEST_W) { [int]$env:SIGAME_TEST_W } else { $b.Width }
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } else { $b.Height }
$Ar = [math]::Round($W / [math]::Max(1, $H), 2)
$Wide = $Ar -ge 2.0
Write-Output "[PC]   screen $W x $H (aspect $Ar)"

$Set = [ordered]@{
    'Camera_Enabled'         = @('true', '')
    'Camera_DisableVignette' = @('true', 'vignette off')
}
if ($Wide) {
    $Set['Camera_GlobalFOVEnabled'] = @('false', '')
    $Set['Graphics_UltrawideFix'] = @('true', "ultrawide fix for your $Ar screen")
    $Set['Graphics_UltrawideCustomFOV'] = @('true', '')
    $Set['Graphics_UltrawideFixVerticalFOV_V2'] = @('true', 'keeps the vertical view, adds width')
    $Set['Graphics_UltrawideConstrainUI'] = @('true', 'HUD stays inside 16:9')
    $Set['Graphics_UltrawideFOVMultiplier_V2'] = @('1.000000', '')
} else {
    $Set['Camera_GlobalFOVEnabled'] = @('true', '')
    $Set['Camera_GlobalFOV'] = @('90.000000', 'field of view 90 (REFramework default 81)')
}

if (Test-Path -LiteralPath $Cfg) {
    if (-not (Test-Path -LiteralPath "$Cfg.sigame.bak")) { Copy-Item -LiteralPath $Cfg -Destination "$Cfg.sigame.bak" -Force }
    $lines = [System.Collections.Generic.List[string]]::new([string[]][IO.File]::ReadAllLines($Cfg))
} else {
    $lines = [System.Collections.Generic.List[string]]::new()
    Set-Content -LiteralPath "$Cfg.sigame.bak" -Value '' -Encoding ascii
}
foreach ($k in $Set.Keys) {
    $v = $Set[$k][0]
    $hit = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*$k\s*=") { $lines[$i] = "$k=$v"; $hit = $true }
    }
    if (-not $hit) { $lines.Add("$k=$v") }
}
[IO.File]::WriteAllText($Cfg, ($lines -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Output "[OK]   $(Split-Path -Leaf $Cfg) (REFramework config) updated"
foreach ($k in $Set.Keys) {
    if ($Set[$k][1]) { Write-Output ('[SET]  {0,-36} {1,-9} {2}' -f $k, $Set[$k][0], $Set[$k][1]) }
}
$what = if ($Wide) { 'ultrawide fix with the HUD in 16:9' } else { 'field of view 90' }
Write-Output "[OK]   SI ULTRA applied, free. Start Resident Evil Requiem: vignette off, $what. APPLY again and Yes = Undo."
exit 0
