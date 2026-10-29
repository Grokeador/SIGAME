# SI ULTRA - Red Dead Redemption 2: AI NPCs (Parley) + Vulkan frame generation - by SI NEWS, MIT.
# Vulkan Frame Generation (mor3a/rdr2-vulkan-frame-generation, MIT) reads more keys from RDR2VulkanFG.ini than its
# in-game menu shows: the menu has "FPS limit" (FPSCap) only, while src/config.cpp also loads OutputFPSCap (a cap on the
# frames that reach the screen, src/experiment_policy.h FrameBudgetUs), ReflexMode (1=On, 2=On + Boost) and PresentPacing
# (src/vkhooks.cpp paces presents while frame generation is on). Both mods need the game on Vulkan (system.xml <API>).
# This writes, for YOUR PC (read from Windows):
#   system.xml          <API>kSettingAPI_Vulkan</API>
#   RDR2VulkanFG.ini    [fgvk] OutputFPSCap = your monitor Hz - 3, ReflexMode=2, PresentPacing=1, DLSSGFrames=1 (2x, the author's start)
#   Parley.ini          AiService=player2 (the free Player2 app, no paid key) + Language = your Windows language when Parley has it
# Mods not installed are skipped. HAGS (needed by DLSS-G) is only checked, never changed. Backups first (*.sigame.bak); -Undo restores them.
param(
    [switch]$Undo
)

function Find-Rdr2Dir {
    $cands = @()
    foreach ($pf in $env:ProgramFiles, ${env:ProgramFiles(x86)}) {
        if (-not $pf) { continue }
        $cands += Join-Path $pf 'Rockstar Games\Red Dead Redemption 2'
        $cands += Join-Path $pf 'Epic Games\RedDeadRedemption2'
        $cands += Join-Path $pf 'Steam\steamapps\common\Red Dead Redemption 2'
    }
    $vdf = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $cands += Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common\Red Dead Redemption 2'
        }
    }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'Games', 'Jogos', 'Giochi', 'Juegos', 'SteamLibrary\steamapps\common', 'Epic Games') {
            $cands += Join-Path $drv.RootDirectory.FullName "$d\Red Dead Redemption 2"
            $cands += Join-Path $drv.RootDirectory.FullName "$d\RedDeadRedemption2"
        }
    }
    foreach ($c in $cands) { if (Test-Path -LiteralPath (Join-Path $c 'RDR2.exe')) { return $c } }
    return $null
}

function Set-IniKey([string]$Text, [string]$Key, [string]$Value) {
    $rx = '(?m)^(\s*' + [regex]::Escape($Key) + '\s*=).*$'
    if ([regex]::IsMatch($Text, $rx)) { return [regex]::Replace($Text, $rx, { param($m) $m.Groups[1].Value + $Value }) }
    return $Text.TrimEnd() + "`r`n$Key=$Value`r`n"
}

function Backup([string]$Path) {
    if (-not (Test-Path -LiteralPath "$Path.sigame.bak")) { Copy-Item -LiteralPath $Path -Destination "$Path.sigame.bak" }
}

$GameDir  = if ($env:SIGAME_RDR2_DIR) { $env:SIGAME_RDR2_DIR } else { Find-Rdr2Dir }
$Settings = if ($env:SIGAME_RDR2_SETTINGS) { $env:SIGAME_RDR2_SETTINGS } else { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rockstar Games\Red Dead Redemption 2\Settings' }
$SysXml   = Join-Path $Settings 'system.xml'
if (-not $GameDir -and -not (Test-Path -LiteralPath $SysXml)) {
    Write-Output '[FAIL] Red Dead Redemption 2 not found (RDR2.exe and Documents\Rockstar Games\Red Dead Redemption 2\Settings\system.xml). Start the game once, then apply again.'
    exit 2
}
$FgIni     = if ($GameDir) { Join-Path $GameDir 'RDR2VulkanFG.ini' } else { $null }
$ParleyIni = if ($GameDir) { Join-Path $GameDir 'Parley.ini' } else { $null }
$Files     = @($SysXml, $FgIni, $ParleyIni) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

if ($Undo) {
    $n = 0
    foreach ($f in @($SysXml, $FgIni, $ParleyIni)) {
        if ($f -and (Test-Path -LiteralPath "$f.sigame.bak")) {
            Copy-Item -LiteralPath "$f.sigame.bak" -Destination $f -Force
            Write-Output "[OK]   $(Split-Path $f -Leaf) restored from the backup."; $n++
        }
    }
    if (-not $n) { Write-Output '[FAIL] No *.sigame.bak backup to restore.'; exit 3 }
    exit 0
}

if (Get-Process -Name 'RDR2' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Red Dead Redemption 2 is running: close the game first (it saves system.xml on exit).'
    exit 4
}

$vc = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentVerticalResolution -gt 0 } | Select-Object -First 1
$Gpu = if ($env:SIGAME_TEST_GPU) { $env:SIGAME_TEST_GPU } elseif ($vc) { [string]$vc.Name } else { '' }
$Hz  = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } elseif ($vc -and $vc.CurrentRefreshRate -gt 0) { [int]$vc.CurrentRefreshRate } else { 60 }
$OutCap = [Math]::Max(57, $Hz - 3)
$Rtx = if ($Gpu -match 'RTX\s*([2-9])0\d0') { [int]$Matches[1] } else { 0 }
Write-Output "[INFO] GPU: $Gpu | monitor $Hz Hz -> output cap $OutCap FPS"

# 1. system.xml: Vulkan (needed by both mods)
if (Test-Path -LiteralPath $SysXml) {
    Backup $SysXml
    $x = [IO.File]::ReadAllText($SysXml)
    if ($x -match '<API>[^<]*</API>') {
        $x = [regex]::Replace($x, '<API>[^<]*</API>', '<API>kSettingAPI_Vulkan</API>')
        [IO.File]::WriteAllText($SysXml, $x)
        Write-Output '[SET]  system.xml <API>kSettingAPI_Vulkan</API>'
    } else { Write-Output '[WARN] system.xml has no <API> line: choose Vulkan in Settings > Graphics > Advanced.' }
} else { Write-Output '[WARN] system.xml not found: start the game once and choose Vulkan in Settings > Graphics > Advanced.' }

# 2. RDR2VulkanFG.ini: the keys the menu does not show
if ($FgIni -and (Test-Path -LiteralPath $FgIni)) {
    if ($Gpu -match 'AMD|Radeon') { Write-Output '[WARN] AMD GPU: the author says AMD is not supported and the mod stops the game. Remove its files.' }
    elseif ($Rtx -eq 2) { Write-Output '[WARN] RTX 20: the author keeps this route experimental and off by default (EnableExperimentalRTX20=0 left as it is).' }
    Backup $FgIni
    $t = [IO.File]::ReadAllText($FgIni)
    foreach ($kv in @(@('OutputFPSCap', "$OutCap"), @('ReflexMode', '2'), @('PresentPacing', '1'), @('DLSSGFrames', '1'))) { $t = Set-IniKey $t $kv[0] $kv[1] }
    [IO.File]::WriteAllText($FgIni, $t)
    Write-Output "[SET]  RDR2VulkanFG.ini [fgvk] OutputFPSCap=$OutCap ReflexMode=2 PresentPacing=1 DLSSGFrames=1 (2x; End cycles more in game)"
    $hags = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name HwSchMode -ErrorAction SilentlyContinue).HwSchMode
    if ($hags -ne 2) { Write-Output '[WARN] Hardware-accelerated GPU scheduling is OFF: DLSS-G needs it (Settings > System > Display > Graphics), then restart Windows.' }
} else { Write-Output '[SKIP] Vulkan Frame Generation not installed (RDR2VulkanFG.ini beside RDR2.exe).' }

# 3. Parley.ini: the free AI path
if ($ParleyIni -and (Test-Path -LiteralPath $ParleyIni)) {
    Backup $ParleyIni
    $p = [IO.File]::ReadAllText($ParleyIni)
    $p = Set-IniKey $p 'AiService' 'player2'
    $lang = (Get-Culture).TwoLetterISOLanguageName.ToUpper()
    if ($lang -in 'EN', 'FR', 'ES', 'DE', 'IT') { $p = Set-IniKey $p 'Language' $lang }
    [IO.File]::WriteAllText($ParleyIni, $p)
    Write-Output "[SET]  Parley.ini AiService=player2 (free, no key) Language=$(if ($lang -in 'EN','FR','ES','DE','IT') { $lang } else { 'unchanged' })"
    Write-Output '[INFO] Open the Player2 app, log in and leave it open while you play.'
} else { Write-Output '[SKIP] Parley not installed (Parley.ini beside RDR2.exe).' }

Write-Output '[OK]   SI ULTRA applied. In game: enable DLSS in Settings > Graphics, load Story Mode, Insert = frame generation menu, hold N = talk.'
exit 0
