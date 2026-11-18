# SI FLAGS - Roblox (app from roblox.com) - by SI NEWS, MIT.
# Writes Fast Flags into Roblox's own ClientAppSettings.json (Versions\version-*\ClientSettings), ONLY flags on
# Roblox's official allowlist (devforum.roblox.com/t/3966569, "Allowlist for local client configuration via Fast
# Flags", 29/09/2025): Roblox says flags not on that list are ignored and no action is taken against users.
#   every PC:            FIntFRMMaxGrassDistance 0, FIntFRMMinGrassDistance 0 (no grass), FIntDebugForceMSAASamples 0
#   Intel graphics only: + DFFlagTextureQualityOverrideEnabled True, DFIntTextureQualityOverride 0 (lowest textures)
# Values as the community writes them (Bloxstrap style strings). Every other flag of your file stays.
# A Roblox update makes a new version folder: APPLY again after it. Bloxstrap users: Bloxstrap overwrites this file
# (Roblox's post says so), set the same flags in Bloxstrap's Fast Flag editor instead.
# Backup first (.sigame.bak, or .sigame.none when there was no file); -Undo puts it back exactly.
param(
    [switch]$Undo,
    [string]$Root = '',        # test only: a Roblox folder with Versions\
    [string]$MockGpu = ''      # test only
)

if (Get-Process -Name 'RobloxPlayerBeta' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Roblox is running: close it first, then APPLY.'
    exit 4
}
$Roots = if ($Root) { @($Root) } else { @((Join-Path $env:LOCALAPPDATA 'Roblox'), (Join-Path ${env:ProgramFiles(x86)} 'Roblox')) }
$Vers = @()
foreach ($r in $Roots) {
    $v = Join-Path $r 'Versions'
    if (Test-Path -LiteralPath $v) {
        $Vers += Get-ChildItem -LiteralPath $v -Directory -Filter 'version-*' -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'RobloxPlayerBeta.exe') }
    }
}
if (-not $Vers) {
    Write-Output '[FAIL] Roblox Player (roblox.com app) not found: install it from roblox.com, start it once, then APPLY. The Microsoft Store app has no Versions folder.'
    exit 2
}

$Gpus = if ($MockGpu) { @($MockGpu) } else { @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) }
$IntelOnly = $Gpus -and -not ($Gpus | Where-Object { $_ -notmatch '(?i)intel' })
$Flags = [ordered]@{ FIntFRMMaxGrassDistance = '0'; FIntFRMMinGrassDistance = '0'; FIntDebugForceMSAASamples = '0' }
if ($IntelOnly) { $Flags.DFFlagTextureQualityOverrideEnabled = 'True'; $Flags.DFIntTextureQualityOverride = '0' }

$Code = 0
foreach ($ver in $Vers) {
    $Dir = Join-Path $ver.FullName 'ClientSettings'
    $Cfg = Join-Path $Dir 'ClientAppSettings.json'
    $Bak = "$Cfg.sigame.bak"
    $Non = "$Cfg.sigame.none"
    if ($Undo) {
        if (Test-Path -LiteralPath $Non) { Remove-Item -LiteralPath $Cfg, $Non -Force -ErrorAction SilentlyContinue; Write-Output "[OK]   $($ver.Name): flags file removed, you had none before."; continue }
        if (Test-Path -LiteralPath $Bak) { Move-Item -LiteralPath $Bak -Destination $Cfg -Force; Write-Output "[OK]   $($ver.Name): flags file restored from the backup."; continue }
        Write-Output "[KEEP] $($ver.Name): nothing to undo"
        continue
    }
    $J = [ordered]@{}
    if (Test-Path -LiteralPath $Cfg) {
        try {
            $o = Get-Content -LiteralPath $Cfg -Raw | ConvertFrom-Json
            if ($o) { foreach ($p in $o.PSObject.Properties) { $J[$p.Name] = $p.Value } }
        } catch { Write-Output "[FAIL] $($ver.Name): your ClientAppSettings.json is not valid JSON, nothing changed."; $Code = 5; continue }
        if (-not ((Test-Path -LiteralPath $Bak) -or (Test-Path -LiteralPath $Non))) { Copy-Item -LiteralPath $Cfg -Destination $Bak }
    } else {
        New-Item -ItemType Directory -Force -Path $Dir | Out-Null
        if (-not (Test-Path -LiteralPath $Bak)) { [IO.File]::WriteAllText($Non, '') }
    }
    foreach ($k in $Flags.Keys) {
        $old = if ($J.Contains($k)) { [string]$J[$k] } else { 'not set' }
        $J[$k] = $Flags[$k]
        Write-Output "[SET]  $k`: $old -> $($Flags[$k])"
    }
    [IO.File]::WriteAllText($Cfg, ($J | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "[OK]   $($ver.Name): flags written, your other flags stay"
}
if (-not $Undo -and $Code -eq 0) {
    if (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'Bloxstrap')) { Write-Output '[WARN] Bloxstrap found: it overwrites this file, set the same flags in its Fast Flag editor.' }
    Write-Output "[OK]   SI FLAGS applied ($(if ($IntelOnly) { 'Intel graphics: lowest textures too' } else { 'grass and MSAA off' })), free. After a Roblox update APPLY again. Undo = APPLY, Yes."
}
exit $Code
