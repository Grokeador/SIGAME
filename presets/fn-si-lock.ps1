# SI LOCK - Fortnite (Epic Games, PC) - by SI NEWS, MIT.
# Keeps YOUR graphics settings when Fortnite resets them.
# Sources:
#   Epic, "What do I do if Fortnite doesn't save my settings?" (epicgames.com/help, article a22311370):
#     %localappdata%\FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini must NOT be read-only.
#     So SI LOCK never locks the file: it keeps a copy and puts it back.
#   Epic launcher manifests (C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests\*.item, AppVersionString) give the
#     installed Fortnite version, so SI LOCK can tell an UPDATE from a change you made in the menu.
# APPLY: clears the read-only flag (Epic's step), saves a copy of your settings, adds the hidden task "SIGAME SI LOCK
#   Fortnite" that checks every 15 minutes and at logon. When Fortnite's version changed AND the file no longer matches
#   your copy, it puts your copy back (the reset file is kept next to it). When only you changed settings in the menu,
#   your copy follows you.
# -Undo removes the task and the copy; -Guard is what the task runs.
param(
    [switch]$Undo,
    [switch]$Guard
)

$Dir = if ($env:SIGAME_FN_CFG) { $env:SIGAME_FN_CFG } else { Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient' }
$Cfg = Join-Path $Dir 'GameUserSettings.ini'
$Lock = if ($env:SIGAME_LOCK_DIR) { $env:SIGAME_LOCK_DIR } else { Join-Path $env:LOCALAPPDATA 'SIGAME\lock\fortnite' }
$Copy = Join-Path $Lock 'GameUserSettings.ini'
$State = Join-Path $Lock 'state.json'
$Task = 'SIGAME SI LOCK Fortnite'
$Manifests = if ($env:SIGAME_EPIC_MANIFESTS) { $env:SIGAME_EPIC_MANIFESTS } else { 'C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests' }

function Get-FnVersion {
    foreach ($f in (Get-ChildItem -LiteralPath $Manifests -Filter '*.item' -ErrorAction SilentlyContinue)) {
        try { $m = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json } catch { continue }
        if ($m.AppName -eq 'Fortnite' -or $m.DisplayName -eq 'Fortnite') { return [string]$m.AppVersionString }
    }
    return ''
}
function Get-Hash([string]$p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }
function Save-State([string]$v) {
    @{ Version = $v; Hash = (Get-Hash $Copy); Saved = (Get-Date).ToString('s') } | ConvertTo-Json | Set-Content -LiteralPath $State -Encoding utf8
}
function Test-FnRunning { [bool](Get-Process -Name 'FortniteClient-Win64-Shipping', 'FortniteLauncher' -ErrorAction SilentlyContinue) }

if ($Guard) {
    if (-not (Test-Path -LiteralPath $State) -or -not (Test-Path -LiteralPath $Cfg) -or (Test-FnRunning)) { exit 0 }
    $s = Get-Content -LiteralPath $State -Raw | ConvertFrom-Json
    $v = Get-FnVersion
    $now = Get-Hash $Cfg
    if ($now -eq $s.Hash) {
        if ($v -and $v -ne $s.Version) { Save-State $v }
        exit 0
    }
    if ($v -and $s.Version -and $v -ne $s.Version) {
        # Fortnite updated and your file changed: the update reset it. Put yours back, keep the reset one.
        Copy-Item -LiteralPath $Cfg -Destination (Join-Path $Lock ("reset-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.ini')) -Force
        Set-ItemProperty -LiteralPath $Cfg -Name IsReadOnly -Value $false
        Copy-Item -LiteralPath $Copy -Destination $Cfg -Force
        Add-Content -LiteralPath (Join-Path $Lock 'si-lock.log') -Value "$(Get-Date -Format s) update $($s.Version) -> $v reset your settings: restored"
        Save-State $v
    } else {
        # Same version: you changed settings in the game menu. Your copy follows you.
        Copy-Item -LiteralPath $Cfg -Destination $Copy -Force
        Save-State $(if ($v) { $v } else { $s.Version })
    }
    exit 0
}

if ($Undo) {
    Unregister-ScheduledTask -TaskName $Task -Confirm:$false -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Lock) { Remove-Item -LiteralPath $Lock -Recurse -Force }
    Write-Output '[OK]   SI LOCK removed: no task, no copy. Your GameUserSettings.ini stays as it is now.'
    exit 0
}

if (-not (Test-Path -LiteralPath $Cfg)) {
    Write-Output '[FAIL] Fortnite settings file not found: start Fortnite once, set your graphics, close it, then apply again.'
    exit 2
}
if (Test-FnRunning) {
    Write-Output '[FAIL] Fortnite is running: close the game first, then APPLY.'
    exit 4
}

# Cause 1 (Epic's own fix): a read-only GameUserSettings.ini cannot be saved.
if ((Get-Item -LiteralPath $Cfg).IsReadOnly) {
    Set-ItemProperty -LiteralPath $Cfg -Name IsReadOnly -Value $false
    Write-Output '[FIX]  GameUserSettings.ini was read-only: cleared (Epic: a read-only file cannot save your settings)'
} else {
    Write-Output '[OK]   GameUserSettings.ini is not read-only'
}

New-Item -ItemType Directory -Path $Lock -Force | Out-Null
Copy-Item -LiteralPath $Cfg -Destination $Copy -Force
$v = Get-FnVersion
Save-State $v
if ($v) { Write-Output "[PC]   Fortnite version $v" } else { Write-Output '[INFO] Epic manifest not found: SI LOCK keeps your copy and restores it when the file changes after an update is detected.' }
Write-Output '[OK]   copy of your settings saved'

# The guard: a copy of this script outside the SIGAME folder, so moving SIGAME does not break it.
$Me = Join-Path $Lock 'fn-si-lock.ps1'
Copy-Item -LiteralPath $PSCommandPath -Destination $Me -Force
if (-not $env:SIGAME_LOCK_NOTASK) {
    $a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Me`" -Guard"
    $t1 = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $t2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
    $st = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
    Register-ScheduledTask -TaskName $Task -Action $a -Trigger $t1, $t2 -Settings $st -Force | Out-Null
}
Write-Output "[OK]   guard task '$Task': every 15 minutes and at logon, hidden"
Write-Output '[OK]   SI LOCK applied, free. Change settings in the menu as usual: your copy follows you. After an update resets them, they come back. APPLY again and Yes = Undo.'
exit 0
