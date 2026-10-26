# SI ULTRA - Zelda: Ocarina of Time 3D (Ocarina ReTuned) - by SI NEWS, MIT.
# Saves a user graphics preset "SI ULTRA" in the port's own config: every value is the highest the port's
# settings code accepts (TriAevum graphics_settings.cpp). The active settings are NOT changed: in the game
# open Graphics -> Presets -> SI ULTRA. The config is backed up first (.bak); -Undo puts the backup back.
# With -Fast:$true it also sets Link run +20%, roll +20%, roll recovery -20%, camera 150% (Reframed block).
param(
    [switch]$Undo,
    [bool]$Fast = $true
)

$Root = Join-Path $env:LOCALAPPDATA 'Ocarina ReTuned'
$cfg = Get-ChildItem $Root -Recurse -Filter *.json -ErrorAction SilentlyContinue |
    Where-Object { (Get-Content $_.FullName -Raw) -match '"Graphics"\s*:\s*\{' } | Select-Object -First 1
if (-not $cfg) {
    Write-Output "[FAIL] No Ocarina ReTuned config with Graphics in $Root : start the game once, close it, then apply again."
    exit 2
}
$bak = "$($cfg.FullName).bak"

if ($Undo) {
    if (-not (Test-Path -LiteralPath $bak)) { Write-Output "[FAIL] No backup $($cfg.Name).bak to restore."; exit 3 }
    Copy-Item -LiteralPath $bak -Destination $cfg.FullName -Force
    Write-Output "[OK]   $($cfg.Name) restored from the backup."
    exit 0
}

if (Get-Process -Name '*retuned*', '*ocarina*' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Ocarina ReTuned is running: close the game, then apply again (it rewrites its config on exit).'
    exit 4
}

$j = Get-Content $cfg.FullName -Raw | ConvertFrom-Json
function S($o, $path, $v) {
    $k = $path.Split('.')
    for ($i = 0; $i -lt $k.Count - 1; $i++) {
        if (-not $o.($k[$i])) { $o | Add-Member $k[$i] ([pscustomobject]@{}) -Force }
        $o = $o.($k[$i])
    }
    $o | Add-Member $k[-1] $v -Force
    Write-Output "[SET]  $path = $v"
}

# Start from the player's own Graphics block, then push each value to the validator's maximum.
$g = $j.Graphics | ConvertTo-Json -Depth 50 | ConvertFrom-Json
S $g 'Preset' 'Custom'; S $g 'RenderScale' 2.0; S $g 'AA.Mode' 'TAA'; S $g 'FrameRate.Mode' 'Interpolated3x'
S $g 'Camera.FovMultiplier' 1.5; S $g 'Camera.ExtendedDrawDistance' $true; S $g 'SurfaceLighting' 'PerPixelPBR'
S $g 'Effects.DirectionalShadows.Mode' 'VirtualShadowMaps'; S $g 'Effects.DirectionalShadows.Resolution' 4096
S $g 'Effects.DirectionalShadows.PcfRadius' 2; S $g 'Effects.DirectionalShadows.ContactShadows.Enabled' $true
S $g 'Effects.DirectionalShadows.ContactShadows.HalfResolution' $false; S $g 'Effects.PointShadows.MaxLights' 8
S $g 'Effects.GlobalIllumination.Mode' 'ScreenSpaceGI'; S $g 'Effects.GlobalIllumination.Specular' $true
S $g 'Effects.GlobalIllumination.ScreenSpace.Sections' 4; S $g 'Effects.GlobalIllumination.ScreenSpace.RadialCandidates' 32
S $g 'Effects.GlobalIllumination.ScreenSpace.Sectors' 128; S $g 'Effects.GlobalIllumination.ScreenSpace.FilterLevels' 4
S $g 'Effects.GlobalIllumination.ScreenSpace.WorkScale' 'Half'; S $g 'Effects.AO.Mode' 'MXAO'
S $g 'Effects.Reflections.Mode' 'FidelityFXSSSR'; S $g 'Effects.Reflections.MaxSteps' 64

$lib = [pscustomobject]@{ SchemaVersion = 1; Presets = @() }
if ($j.GraphicsPresets -and $j.GraphicsPresets.Presets) {
    $lib.Presets = @($j.GraphicsPresets.Presets | Where-Object { $_.Name -ne 'SI ULTRA' })
}
$lib.Presets += [pscustomobject]@{ Name = 'SI ULTRA'; Graphics = $g }
$j | Add-Member GraphicsPresets $lib -Force

if ($Fast -and $j.Reframed) {
    $r = $j.Reframed
    $r.movement_speed = 2; $r.roll_speed = 2; $r.roll_recovery = 2; $r.camera_distance = 6
    Write-Output '[SET]  Link: run +20%, roll +20%, roll recovery -20%, camera 150%'
}

# Keep the first backup: applying twice must not overwrite the player's original config.
if (-not (Test-Path -LiteralPath $bak)) { Copy-Item -LiteralPath $cfg.FullName -Destination $bak -Force }
[IO.File]::WriteAllText($cfg.FullName, ($j | ConvertTo-Json -Depth 50))
Write-Output "[OK]   Preset SI ULTRA saved in $($cfg.Name). In the game: Graphics -> Presets -> SI ULTRA."
exit 0
