# SI TACTICAL - S.T.A.L.K.E.R. Anomaly / GAMMA (modded exes 2026.10.11) - by SI NEWS, MIT.
# The modded exes (themrdemonized/xray-monolith, tag 2026.10.11) read about forty AI console keys from appdata\user.ltx.
# Their menu (gamedata/scripts/options_modded_exes_stalkers.script) caps two of them lower than the engine does
# (src/xrGame/console_commands.cpp): ai_enemy_inertia_time_to_somebody menu 60000 / console 120000 and
# ai_hold_position_inertia_random menu 30000 / console 120000. This writes 16 realism keys plus those two past the menu.
# Close the game first (it rewrites user.ltx on exit). Backup first (user.ltx.sigame.bak); -Undo restores it.
param(
    [switch]$Undo
)

function Find-AnomalyDir {
    $cands = @()
    foreach ($drv in [IO.DriveInfo]::GetDrives()) {
        if ($drv.DriveType -ne 'Fixed' -or -not $drv.IsReady) { continue }
        $r = $drv.RootDirectory.FullName
        foreach ($d in 'Anomaly', 'GAMMA\Anomaly', 'Games\Anomaly', 'Games\GAMMA\Anomaly', 'Jogos\Anomaly', 'Giochi\Anomaly',
                       'Juegos\Anomaly', 'STALKER\Anomaly', 'Stalker_GAMMA\Anomaly') {
            $cands += Join-Path $r $d
        }
    }
    foreach ($c in $cands) {
        foreach ($exe in 'AnomalyDX11.exe', 'AnomalyDX11AVX.exe', 'AnomalyDX10.exe', 'AnomalyDX9.exe') {
            if (Test-Path -LiteralPath (Join-Path $c "bin\$exe")) { return $c }
        }
    }
    return $null
}

$Dir = if ($env:SIGAME_ANOMALY_DIR) { $env:SIGAME_ANOMALY_DIR } else { Find-AnomalyDir }
if (-not $Dir) {
    Write-Output '[FAIL] S.T.A.L.K.E.R. Anomaly not found (bin\AnomalyDX11.exe). Set SIGAME_ANOMALY_DIR to the Anomaly folder of your GAMMA install.'
    exit 2
}
$Ltx = Join-Path $Dir 'appdata\user.ltx'

if ($Undo) {
    if (-not (Test-Path -LiteralPath "$Ltx.sigame.bak")) { Write-Output '[FAIL] No user.ltx.sigame.bak backup to restore.'; exit 3 }
    Copy-Item -LiteralPath "$Ltx.sigame.bak" -Destination $Ltx -Force
    Write-Output '[OK]   user.ltx restored from the backup.'
    exit 0
}

if (Get-Process -Name 'Anomaly*' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Anomaly is running: close the game first (it rewrites user.ltx on exit).'
    exit 4
}
if (-not (Test-Path -LiteralPath $Ltx)) {
    Write-Output '[FAIL] appdata\user.ltx not found: start the game once, quit from the main menu, then apply again.'
    exit 5
}

# key, value, what it does (the authors' menu texts, ui_mm_modded_exes.xml)
$Keys = @(
    @('hud_crosshair', 'off', 'no crosshair'),
    @('g_crosshair_show_always', 'off', 'no crosshair while aiming either'),
    @('g_firepos', 'on', 'bullets leave the gun barrel'),
    @('g_firepos_zoom', 'on', 'bullets leave the barrel when aiming'),
    @('g_aimpos', 'on', 'aim along the barrel'),
    @('g_aimpos_zoom', 'on', 'aim along the barrel when aiming'),
    @('g_ai_unlimited_ammo', '0', 'NPCs consume ammo (game: unlimited)'),
    @('ai_move_to_cover_run', '1', 'NPCs run to cover under fire'),
    @('ai_search_inertia_time', '120000', 'NPCs hunt you 2 min after losing sight (game: 15 s)'),
    @('ai_fire_make_sense_interval', '20000', 'suppressing fire on your last spot 20 s (game: 10 s)'),
    @('ai_cover_danger_time', '300000', 'a cover where they got shot stays dangerous 5 min (game: 2 min)'),
    @('ai_danger_attack_sound_mult', '2.000000', 'gunshot sounds x2 urgency'),
    @('ai_danger_corpse_mult', '2.000000', 'fresh corpses x2 urgency'),
    @('ai_danger_entity_death_mult', '2.000000', 'deaths x2 urgency'),
    @('ai_danger_ricochet_mult', '2.000000', 'ricochets x2 urgency'),
    @('npc_dont_drop_weapons_on_death', '1', 'weapons stay in the body inventory (new Oct 11)'),
    @('ai_enemy_inertia_time_to_somebody', '90000', 'PAST THE MENU (max 60000): squads commit to a target 90 s'),
    @('ai_hold_position_inertia_random', '60000', 'PAST THE MENU (max 30000): some NPCs push, some hold up to a minute')
)

if (-not (Test-Path -LiteralPath "$Ltx.sigame.bak")) { Copy-Item -LiteralPath $Ltx -Destination "$Ltx.sigame.bak" }
$t = [IO.File]::ReadAllText($Ltx)
foreach ($k in $Keys) {
    $rx = '(?m)^(\s*' + [regex]::Escape($k[0]) + ')\s+.*$'
    if ([regex]::IsMatch($t, $rx)) { $t = [regex]::Replace($t, $rx, { param($m) $m.Groups[1].Value + ' ' + $k[1] }) }
    else { $t = $t.TrimEnd() + "`r`n$($k[0]) $($k[1])`r`n" }
    Write-Output ('[SET]  {0,-34} {1,-8} {2}' -f $k[0], $k[1], $k[2])
}
[IO.File]::WriteAllText($Ltx, $t)
Write-Output '[INFO] Do not move the two PAST THE MENU sliders in Options, Modded Exes, Stalkers: the menu caps them.'
Write-Output '[OK]   SI TACTICAL applied, free. Backup: user.ltx.sigame.bak, APPLY again and Yes = Undo.'
exit 0
