# SI ULTRA - Marvel's Spider-Man Remastered (PC) - by SI NEWS, MIT.
# The game has no config file: it reads REG_DWORD values under HKCU\Software\Insomniac Games\Marvel's Spider-Man Remastered. No game file touched.
# Names and values from two public tools (names only, no code): IlyaMez/SpidyVR tools/vr_display.py (VSync, DOFQuality, Sharpness, RTReflections)
#   and NIWDOGLEOJ/ludus WineBottleService.swift (RTShadows, RTAmbientOcclusion, RTInteriors, ShowLauncher).
# A value the game never saved is skipped, never created. Only ever cheaper: a value already at or below ours stays.
# The first old numbers go to a JSON backup; -Undo writes those exact numbers back.
param(
    [switch]$Undo
)

$Root = if ($env:SIGAME_SMR_KEY) { $env:SIGAME_SMR_KEY } else { 'HKCU:\Software\Insomniac Games\Marvel''s Spider-Man Remastered' }
$BakDir = Join-Path $env:LOCALAPPDATA 'SI-GAME'
$Bak = Join-Path $BakDir 'smr-si-ultra.bak.json'
if (Get-Process -Name 'Spider-Man' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Spider-Man Remastered is running: close the game first, then APPLY.'
    exit 4
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No backup to restore.'; exit 3 }
    foreach ($e in (Get-Content -LiteralPath $Bak -Raw | ConvertFrom-Json)) {
        $Key = if ($e.Sub) { Join-Path $Root $e.Sub } else { $Root }
        Set-ItemProperty -LiteralPath $Key -Name $e.Name -Value ([int]$e.Value) -Type DWord
        Write-Output "[OK]   $($e.Name): back to $($e.Value)"
    }
    Remove-Item -LiteralPath $Bak -Force
    Write-Output '[OK]   your exact old values are back.'
    exit 0
}

if (-not (Test-Path -LiteralPath (Join-Path $Root 'Graphics'))) {
    Write-Output '[FAIL] Spider-Man Remastered registry key not found: start the game once, close it, then apply again.'
    exit 2
}

# subkey, value, ours, label
$Keys = @(
    , @('Graphics', 'RTReflections', 0, 'ray-traced reflections off')
    , @('Graphics', 'RTShadows', 0, 'ray-traced shadows off')
    , @('Graphics', 'RTAmbientOcclusion', 0, 'ray-traced ambient occlusion off')
    , @('Graphics', 'RTInteriors', 0, 'ray-traced interiors off')
    , @('Graphics', 'DOFQuality', 0, 'depth of field off')
    , @('Graphics', 'Sharpness', 1, 'sharpening at its lowest')
    , @('Graphics', 'VSync', 0, 'vertical sync off')
    , @('', 'ShowLauncher', 0, 'launcher popup off')
    , @('Input', 'ShowLauncher', 0, 'launcher popup off')
)
$Saved = @()
if (Test-Path -LiteralPath $Bak) { foreach ($e in (Get-Content -LiteralPath $Bak -Raw | ConvertFrom-Json)) { $Saved += $e } }
Write-Output '[OK]   old values saved first, every other value stays'
foreach ($k in $Keys) {
    $Key = if ($k[0]) { Join-Path $Root $k[0] } else { $Root }
    $Item = Get-Item -LiteralPath $Key -ErrorAction SilentlyContinue
    if (-not $Item -or $Item.GetValueNames() -notcontains $k[1] -or $Item.GetValueKind($k[1]) -ne 'DWord') {
        if ($k[1] -ne 'ShowLauncher') { Write-Output "[SKIP] $($k[3]): your game has not saved it" }
        continue
    }
    $Cur = [int]$Item.GetValue($k[1])
    if ($Cur -le $k[2]) { Write-Output "[KEEP] $($k[3]): $Cur, already there"; continue }
    if (-not @($Saved | Where-Object { $_.Sub -eq $k[0] -and $_.Name -eq $k[1] }).Count) {
        $Saved += [pscustomobject]@{ Sub = $k[0]; Name = $k[1]; Value = $Cur }
    }
    if (-not (Test-Path -LiteralPath $BakDir)) { New-Item -ItemType Directory -Path $BakDir | Out-Null }
    Set-Content -LiteralPath $Bak -Value (ConvertTo-Json -InputObject @($Saved)) -Encoding UTF8
    Set-ItemProperty -LiteralPath $Key -Name $k[1] -Value $k[2] -Type DWord
    Write-Output "[SET]  $($k[3]): $Cur -> $($k[2])"
}
Write-Output '[OK]   SI ULTRA applied, free. Changed a graphics option in the game? APPLY, No, Yes. Undo = APPLY, Yes.'
exit 0
