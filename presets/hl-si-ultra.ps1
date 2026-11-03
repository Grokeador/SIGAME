# SI ULTRA - Hogwarts Legacy (PC) - by SI NEWS, MIT.
# The game's own override file: %LOCALAPPDATA%\Hogwarts Legacy\Saved\Config\WindowsNoEditor\Engine.ini. No game file touched.
# Keys and values from the Engine.ini block Hogwarts Legacy players share on Steam (steamcommunity.com/app/990080/discussions/0/3761104682802889062).
# Pool size = half of your video memory, the rule from steamcommunity.com/app/990080/discussions/0/4629233576852913500 (read from Windows, never a fixed number).
# Read-only after writing: players report the game removed their added lines (steamcommunity.com/app/990080/discussions/0/3771239049945571879).
# Backup first (Engine.ini.sigame.bak; no file before = Engine.ini.sigame.none); -Undo puts it back exactly, read-only flag included.
param(
    [switch]$Undo
)

$Dir = if ($env:SIGAME_HL_CFG) { $env:SIGAME_HL_CFG } else { Join-Path $env:LOCALAPPDATA 'Hogwarts Legacy\Saved\Config\WindowsNoEditor' }
$Cfg = Join-Path $Dir 'Engine.ini'
$Bak = "$Cfg.sigame.bak"
$Non = "$Cfg.sigame.none"
if (Get-Process -Name 'HogwartsLegacy', 'Phoenix-Win64-Shipping' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Hogwarts Legacy is running: close the game first, then APPLY.'
    exit 4
}

if ($Undo) {
    if (Test-Path -LiteralPath $Non) {
        if (Test-Path -LiteralPath $Cfg) { Remove-Item -LiteralPath $Cfg -Force }
        Remove-Item -LiteralPath $Non -Force
        Write-Output '[OK]   Engine.ini removed: you had none before.'
        exit 0
    }
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    if (Test-Path -LiteralPath $Cfg) { Set-ItemProperty -LiteralPath $Cfg -Name IsReadOnly -Value $false }
    Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
    Set-ItemProperty -LiteralPath $Bak -Name IsReadOnly -Value $false
    Remove-Item -LiteralPath $Bak -Force
    Write-Output '[OK]   Engine.ini restored from the backup.'
    exit 0
}

if (-not (Test-Path -LiteralPath $Dir)) {
    Write-Output '[FAIL] Hogwarts Legacy config folder not found: start the game once, close it, then apply again.'
    exit 2
}

# Video memory of the biggest card, from the driver's own registry value (Win32 AdapterRAM stops at 4 GB)
$Mb = 0
if ($env:SIGAME_TEST_VRAM_MB) { $Mb = [int]$env:SIGAME_TEST_VRAM_MB } else {
    $Cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
    foreach ($g in @(Get-ChildItem $Cls -ErrorAction SilentlyContinue)) {
        $v = (Get-ItemProperty -LiteralPath $g.PSPath -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize'
        if ($v) { $m = [int]([long]$v / 1MB); if ($m -gt $Mb) { $Mb = $m } }
    }
}
if ($Mb -lt 2048) {
    Write-Output '[FAIL] Could not read your video memory from Windows: nothing was changed.'
    exit 6
}
$Pool = [int][math]::Floor($Mb / 2)

$Had = Test-Path -LiteralPath $Cfg
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

# section, key, value, label
$Keys = @(
    , @('SystemSettings', 'r.Streaming.PoolSize', "$Pool", "texture pool, half of your $Mb MB")
    , @('SystemSettings', 'r.Streaming.LimitPoolSizeToVRAM', '1', 'pool capped to video memory')
    , @('SystemSettings', 'r.TextureStreaming', '1', 'texture streaming')
    , @('SystemSettings', 'r.bForceCPUAccessToGPUSkinVerts', 'True', 'CPU access to skin vertices')
    , @('SystemSettings', 'r.GTSyncType', '1', 'game thread sync')
    , @('SystemSettings', 'r.OneFrameThreadLag', '1', 'one frame thread lag')
    , @('SystemSettings', 'r.FinishCurrentFrame', '0', 'finish current frame')
    , @('ConsoleVariables', 'AllowAsyncRenderThreadUpdates', '1', 'async render thread updates')
)
Write-Output '[OK]   backup saved, every other line of your file stays'
foreach ($k in $Keys) {
    $Rx = [regex]('(?im)^(\s*' + [regex]::Escape($k[1]) + '\s*=\s*)([^\r\n]*)')
    $M = $Rx.Match($Txt)
    if ($M.Success) {
        $Cur = $M.Groups[2].Value.Trim()
        if ($Cur -eq $k[2]) { Write-Output "[KEEP] $($k[3]): $Cur, already there"; continue }
        $Val = $k[2]
        $Txt = $Rx.Replace($Txt, { param($x) $x.Groups[1].Value + $Val })
        Write-Output "[SET]  $($k[3]): $Cur -> $Val"
        continue
    }
    $Line = "$($k[1])=$($k[2])" + $Nl
    $Sec = [regex]::Match($Txt, '(?im)^\[' + $k[0] + '\][ \t]*(\r?\n|\z)')
    if ($Sec.Success) {
        if ($Sec.Groups[1].Length -eq 0) { $Line = $Nl + $Line }
        $Txt = $Txt.Insert($Sec.Index + $Sec.Length, $Line)
    } else {
        if ($Txt.Length -and -not $Txt.EndsWith("`n")) { $Txt += $Nl }
        if ($Txt.Length) { $Txt += $Nl }
        $Txt += "[$($k[0])]" + $Nl + $Line
    }
    Write-Output "[SET]  $($k[3]): not in your file -> $($k[2])"
}
if ($Had) { Set-ItemProperty -LiteralPath $Cfg -Name IsReadOnly -Value $false }
[IO.File]::WriteAllText($Cfg, $Txt, (New-Object System.Text.UTF8Encoding($Bom)))
Set-ItemProperty -LiteralPath $Cfg -Name IsReadOnly -Value $true
Write-Output '[OK]   Engine.ini locked read-only, so the game keeps your lines'
Write-Output '[OK]   SI ULTRA applied, free. Undo = APPLY, Yes.'
exit 0
