# SI ULTRA - Rayman 3 HD Recompiled (PC port) - by SI NEWS, MIT.
# The port's Settings app stops at 2160p and has no texture filtering or anti-aliasing option. Its runtime
# (rexglue-sdk, pinned in the port's config/build/toolchain.json) reads bin\r3hd.toml at start, so this writes two
# engine keys the Settings app does not show, both at the highest value the SDK accepts:
#   anisotropic_override = 5            -> 16x anisotropic filtering (the SDK default is 3 = 4x)
#   swap_post_effect     = "fxaa_extreme" (allowed: none, fxaa, fxaa_extreme)
# With -Fast:$true it also stores the Rendering resolution preference 3 (2160p, the top Settings value) in
# settings.json. Both files are backed up first (.sigame.bak); -Undo puts the backups back.
param(
    [switch]$Undo,
    [bool]$Fast = $true
)

# Default folder of the installer ({localappdata}\Rayman3HDRecomp), else the folder chosen at setup (uninstall key).
$Home3 = Join-Path $env:LOCALAPPDATA 'Rayman3HDRecomp'
if (-not (Test-Path -LiteralPath (Join-Path $Home3 'bin\r3hd.exe'))) {
    $key = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{6F2C9A41-7D3B-4E58-B1A2-5841123F0029}_is1'
    foreach ($hive in 'HKCU:', 'HKLM:') {
        $loc = (Get-ItemProperty -Path "$hive\$key" -ErrorAction SilentlyContinue).InstallLocation
        if ($loc -and (Test-Path -LiteralPath (Join-Path $loc 'bin\r3hd.exe'))) { $Home3 = $loc.TrimEnd('\'); break }
    }
}
$exe = Join-Path $Home3 'bin\r3hd.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    Write-Output '[FAIL] Rayman 3 HD Recompiled not found: install it with its setup, then apply again.'
    exit 2
}
$toml = Join-Path $Home3 'bin\r3hd.toml'
$json = Join-Path $Home3 'settings.json'
$tomlBak = "$toml.sigame.bak"
$jsonBak = "$json.sigame.bak"

if ($Undo) {
    if (-not (Test-Path -LiteralPath $tomlBak)) { Write-Output '[FAIL] No backup r3hd.toml.sigame.bak to restore.'; exit 3 }
    Copy-Item -LiteralPath $tomlBak -Destination $toml -Force
    Write-Output '[OK]   r3hd.toml restored from the backup.'
    if (Test-Path -LiteralPath $jsonBak) {
        Copy-Item -LiteralPath $jsonBak -Destination $json -Force
        Write-Output '[OK]   settings.json restored from the backup.'
    }
    exit 0
}

if (Get-Process -Name 'r3hd' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Rayman 3 HD is running: close the game, then apply again.'
    exit 4
}

# Keep the first backups: applying twice must not overwrite the player's originals.
# No r3hd.toml yet = an empty one is the original (an empty TOML file sets nothing).
if (-not (Test-Path -LiteralPath $tomlBak)) {
    if (Test-Path -LiteralPath $toml) { Copy-Item -LiteralPath $toml -Destination $tomlBak -Force }
    else { [IO.File]::WriteAllText($tomlBak, '') }
}

# Top-level keys go before any [table]; drop our keys from the old top level so none is written twice.
$ours = [ordered]@{ anisotropic_override = '5'; swap_post_effect = '"fxaa_extreme"' }
$old = @(if (Test-Path -LiteralPath $toml) { Get-Content -LiteralPath $toml } else { @() })
$top = $true
$kept = foreach ($line in $old) {
    if ($line -match '^\s*\[') { $top = $false }
    if ($top -and $line -match '^\s*(anisotropic_override|swap_post_effect)\s*=') { continue }
    $line
}
$new = @('# SI ULTRA by SI NEWS (SIGAME): 16x anisotropic filtering + FXAA Extreme')
foreach ($k in $ours.Keys) { $new += "$k = $($ours[$k])"; Write-Output "[SET]  $k = $($ours[$k])" }
[IO.File]::WriteAllText($toml, (($new + @($kept)) -join "`r`n") + "`r`n")

if ($Fast) {
    if (-not (Test-Path -LiteralPath $json)) {
        Write-Output '[SKIP] settings.json not found: open Rayman 3 HD Settings once, then pick Rendering resolution 2160p.'
    } else {
        $j = Get-Content -LiteralPath $json -Raw | ConvertFrom-Json
        if ([int]$j.schema -lt 2) {
            Write-Output '[SKIP] Old settings file: in Rayman 3 HD Settings pick Rendering resolution 2160p.'
        } else {
            if (-not (Test-Path -LiteralPath $jsonBak)) { Copy-Item -LiteralPath $json -Destination $jsonBak -Force }
            if (-not $j.preferences) { $j | Add-Member preferences ([pscustomobject]@{}) -Force }
            $j.preferences | Add-Member render_scale '3' -Force
            [IO.File]::WriteAllText($json, ($j | ConvertTo-Json -Depth 20))
            Write-Output '[SET]  Rendering resolution = 2160p (render_scale 3)'
        }
    }
}

Write-Output '[OK]   SI ULTRA applied. Start Rayman 3 HD as usual: 2160p, 16x texture filtering, FXAA Extreme.'
exit 0
