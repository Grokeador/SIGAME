# SI CO-OP - Hollow Knight: Silksong co-op mod (Nirok85/silksong-coop-mod, MIT, BepInEx) - by SI NEWS, MIT.
# The mod's F10 menu (src/SilksongCoop.Mod/UI/CoopMenuUI.cs) has sliders for tick rate (20-60 Hz), Player 2 hue and
# revive cooldown (15-30 s) only. The plugin reads more from BepInEx\config\com.silksong.coop.cfg (SilksongCoopPlugin.cs):
#   ReviveHealthPercent          0.1..1.0  (no menu row; clamped in the revive code)
#   ReviveInvulnerabilitySeconds 0..10     (no menu row; was hard-coded 2.5 s, the code allows 10)
#   MaxReconnectAttempts         1..10     (no menu row)
# And a trap: [Quality] Preset = Medium (the default) rewrites TickRateHz to 30 at every start (QualityPresetManager.cs);
# only Preset = Custom keeps your own values. The network engine stops at 60 Hz (AdaptiveTickRate.cs _maxTickHz).
# This writes: Preset = Custom, TickRateHz = 60, ReviveCooldownSeconds = 15, ReviveHealthPercent = 1.0,
#   ReviveInvulnerabilitySeconds = 10, AutoReconnect = true, MaxReconnectAttempts = 10.
# Backup first (com.silksong.coop.cfg.sigame.bak); -Undo puts it back.
param(
    [switch]$Undo
)

$ExeName = 'Hollow Knight Silksong.exe'
$CfgName = 'com.silksong.coop.cfg'

function Find-SilksongDir {
    $cands = @()
    foreach ($pf in $env:ProgramFiles, ${env:ProgramFiles(x86)}) {
        if (-not $pf) { continue }
        $cands += Join-Path $pf 'Steam\steamapps\common\Hollow Knight Silksong'
        $cands += Join-Path $pf 'GOG Galaxy\Games\Hollow Knight Silksong'
    }
    $vdf = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $cands += Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common\Hollow Knight Silksong'
        }
    }
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        foreach ($d in 'Games', 'Jogos', 'Giochi', 'Juegos', 'GOG Games', 'SteamLibrary\steamapps\common') {
            $cands += Join-Path $drv.RootDirectory.FullName "$d\Hollow Knight Silksong"
        }
    }
    foreach ($c in $cands) { if (Test-Path -LiteralPath (Join-Path $c $ExeName)) { return $c } }
    return $null
}

$Root = if ($env:SIGAME_SILKSONG_ROOT) { $env:SIGAME_SILKSONG_ROOT } else { Find-SilksongDir }
if (-not $Root -or -not (Test-Path -LiteralPath (Join-Path $Root $ExeName))) {
    Write-Output "[FAIL] Hollow Knight Silksong folder not found ($ExeName). Set SIGAME_SILKSONG_ROOT to it, then apply again."
    exit 2
}
if (-not (Test-Path -LiteralPath (Join-Path $Root 'BepInEx\plugins'))) {
    Write-Output '[FAIL] BepInEx is not installed: unpack the co-op mod release zip next to the game exe first.'
    exit 2
}
$Cfg = Join-Path $Root "BepInEx\config\$CfgName"
$Bak = "$Cfg.sigame.bak"

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output "[FAIL] No backup $CfgName.sigame.bak to restore."; exit 3 }
    if ((Get-Item -LiteralPath $Bak).Length -eq 0) { Remove-Item -LiteralPath $Cfg -Force -ErrorAction SilentlyContinue }
    else { Copy-Item -LiteralPath $Bak -Destination $Cfg -Force }
    Write-Output "[OK]   $CfgName restored from the backup."
    exit 0
}

if (Get-Process -Name 'Hollow Knight Silksong' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Silksong is running: close the game first (BepInEx rewrites the config while it runs).'
    exit 4
}

New-Item -ItemType Directory -Force -Path (Split-Path $Cfg) | Out-Null
if (-not (Test-Path -LiteralPath $Bak)) {
    if (Test-Path -LiteralPath $Cfg) { Copy-Item -LiteralPath $Cfg -Destination $Bak -Force }
    else { [IO.File]::WriteAllText($Bak, '') }
}

# section, key, value, why
$Ours = @(
    @('Quality', 'Preset', 'Custom', 'Medium rewrites TickRateHz to 30 at every start'),
    @('Network', 'TickRateHz', '60', 'the network engine maximum (60 Hz)'),
    @('Network', 'AutoReconnect', 'true', ''),
    @('Network', 'MaxReconnectAttempts', '10', 'HIDDEN: no menu row (default 5)'),
    @('Gameplay', 'ReviveCooldownSeconds', '15', 'the shortest wait the code allows'),
    @('Gameplay', 'ReviveHealthPercent', '1', 'HIDDEN: no menu row, full mask on revive (default 0.5)'),
    @('Gameplay', 'ReviveInvulnerabilitySeconds', '10', 'HIDDEN: no menu row, code max 10 s (default 2.5)')
)

$lines = [Collections.Generic.List[string]]::new()
if (Test-Path -LiteralPath $Cfg) { foreach ($l in [IO.File]::ReadAllLines($Cfg)) { $lines.Add($l) } }
foreach ($o in $Ours) {
    $sec, $key, $val = $o[0], $o[1], $o[2]
    $in = $false; $done = $false; $end = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[(.+)\]\s*$') {
            if ($in) { break }
            $in = ($Matches[1] -eq $sec); if ($in) { $end = $i + 1 }
            continue
        }
        if (-not $in) { continue }
        if ($lines[$i].Trim()) { $end = $i + 1 }
        if ($lines[$i] -match ('^\s*' + [regex]::Escape($key) + '\s*=')) { $lines[$i] = "$key = $val"; $done = $true; break }
    }
    if (-not $done) {
        if ($end -lt 0) {
            if ($lines.Count -and $lines[$lines.Count - 1].Trim()) { $lines.Add('') }
            $lines.Add("[$sec]"); $lines.Add('')
            $end = $lines.Count
        }
        $lines.Insert($end, "$key = $val")
    }
    Write-Output ('[SET]  {0,-29} {1,-7} {2}' -f $key, $val, $o[3])
}
$Utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($Cfg, ($lines -join "`r`n") + "`r`n", $Utf8)

Write-Output '[INFO] Do not pick Low, Medium or High in the F10 menu afterwards: a preset there rewrites the tick rate.'
Write-Output '[OK]   SI CO-OP applied, free. Start Silksong: 60 Hz sync, full-mask revive with 10 s of i-frames. APPLY again and Yes = Undo.'
exit 0
