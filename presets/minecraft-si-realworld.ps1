# SI REAL WORLD - RealWorldMC (Teddy563/realworldmc, Apache-2.0, Fabric) - by SI NEWS, MIT.
# The mod's map settings menu (EarthSettingsScreen.java) cycles 4 values only: Fine radius 96-640, Far 4000-24000,
# Max tiles 600-2400, Quality (max SSE) 18-4. Three more keys change the 3D map and have NO menu row:
#   config\realworldmc.json            mapRenderDistance  default 8000 (EarthConfig.java). It is the camera far plane
#                                      (GameRendererMixin.getDepthFar): with Far = 24000 in the menu, every tile past
#                                      8000 blocks is still cut off. No clamp in the code.
#   realworldmc-service\config.json    render.falloff     default 600 (service/src/server.mjs). Allowed error grows as
#                                      maxSse * (1 + distance / falloff) (select.mjs): 1200 keeps far tiles twice as sharp.
#                                      The menu never sends it, so boundedRenderOverrides never clamps it.
#                                      render.viewportHeight default 1080, fixed: detail is computed for 1080 lines even
#                                      on a 1440p or 4K screen. We write your real screen height.
# The tile budget (Max tiles) still caps the cost: coarsenToBudget drops detail far away, never the far side.
# This writes: Far 24000, Max tiles 2400, Quality 8, Fine radius 320 (realworldmc-render.json), mapRenderDistance 24000,
#   falloff 1200, viewportHeight = screen height. Your map keys in config.json are kept as they are.
# Backup first (*.sigame.bak next to each file); -Undo puts everything back.
param(
    [switch]$Undo
)

function Find-RwmcInstances {
    $roots = @(Join-Path $env:APPDATA '.minecraft')
    foreach ($base in (Join-Path $env:APPDATA 'PrismLauncher\instances'), (Join-Path $env:APPDATA 'com.modrinth.theseus\profiles'),
                      (Join-Path $env:USERPROFILE 'curseforge\minecraft\Instances')) {
        if (-not (Test-Path -LiteralPath $base)) { continue }
        foreach ($d in Get-ChildItem -LiteralPath $base -Directory) {
            $roots += $d.FullName
            foreach ($sub in '.minecraft', 'minecraft') { $roots += Join-Path $d.FullName $sub }
        }
    }
    if ($env:SIGAME_MC_DIR) { $roots = @($env:SIGAME_MC_DIR) }
    $out = @()
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r)) { continue }
        $jar = Get-ChildItem -LiteralPath (Join-Path $r 'mods') -Filter 'realworldmc*.jar' -ErrorAction SilentlyContinue
        if ($jar -or (Test-Path -LiteralPath (Join-Path $r 'config\realworldmc.json'))) { $out += $r }
    }
    return $out
}

function Read-Json($path) {
    if (Test-Path -LiteralPath $path) {
        $t = [IO.File]::ReadAllText($path)
        if ($t.Trim()) { return ($t | ConvertFrom-Json) }
    }
    return New-Object PSObject
}

function Set-Key($obj, $name, $value) {
    if ($obj.PSObject.Properties[$name]) { $obj.$name = $value } else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
}

function Save-Json($path, $obj) {
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    $Utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 8), $Utf8)
}

function Backup($path) {
    $bak = "$path.sigame.bak"
    if (Test-Path -LiteralPath $bak) { return }
    if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $bak -Force }
    else { New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null; [IO.File]::WriteAllText($bak, '') }
}

$Instances = @(Find-RwmcInstances)
if ($Instances.Count -eq 0) {
    Write-Output '[FAIL] RealWorldMC not found (mods\realworldmc*.jar). Install the mod, start one RealWorldMC world once, then apply again.'
    Write-Output '       Other folder? Set SIGAME_MC_DIR to the instance folder (the one with mods\ and config\).'
    exit 2
}

if ($Undo) {
    foreach ($inst in $Instances) {
        foreach ($f in 'config\realworldmc.json', 'config\realworldmc-render.json', 'realworldmc-service\config.json') {
            $path = Join-Path $inst $f; $bak = "$path.sigame.bak"
            if (-not (Test-Path -LiteralPath $bak)) { continue }
            if ((Get-Item -LiteralPath $bak).Length -eq 0) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
            else { Copy-Item -LiteralPath $bak -Destination $path -Force }
            Remove-Item -LiteralPath $bak -Force
            Write-Output "[OK]   $f restored ($inst)"
        }
    }
    exit 0
}

$running = Get-Process -Name 'javaw', 'java' -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match 'Minecraft' }
if ($running) {
    Write-Output '[FAIL] Minecraft is running: close the game first (the mod saves its settings on exit and would undo this).'
    exit 4
}

$ScreenH = 1080
try {
    $v = Get-CimInstance Win32_VideoController -ErrorAction Stop | Where-Object { $_.CurrentVerticalResolution } |
         Sort-Object CurrentVerticalResolution -Descending | Select-Object -First 1
    if ($v -and $v.CurrentVerticalResolution -gt $ScreenH) { $ScreenH = [int]$v.CurrentVerticalResolution }
} catch {}

foreach ($inst in $Instances) {
    Write-Output "[INFO] Instance: $inst"

    $render = Join-Path $inst 'config\realworldmc-render.json'
    Backup $render
    $j = Read-Json $render
    if (-not $j.PSObject.Properties['render']) { Set-Key $j 'render' (New-Object PSObject) }
    foreach ($kv in @(@('far', 24000, 'menu max (default 8000)'), @('maxTiles', 2400, 'menu max (default 900)'),
                      @('maxSse', 8, 'sharper than default 12'), @('fineRadius', 320, 'default 160'))) {
        Set-Key $j.render $kv[0] $kv[1]
        Write-Output ('[SET]  {0,-20} {1,-7} {2}' -f $kv[0], $kv[1], $kv[2])
    }
    Save-Json $render $j

    $main = Join-Path $inst 'config\realworldmc.json'
    Backup $main
    $j = Read-Json $main
    Set-Key $j 'mapRenderDistance' 24000
    Save-Json $main $j
    Write-Output ('[SET]  {0,-20} {1,-7} {2}' -f 'mapRenderDistance', 24000, 'HIDDEN: far plane was 8000, cut past 8 km')

    $svc = Join-Path $inst 'realworldmc-service\config.json'
    Backup $svc
    $j = Read-Json $svc
    if (-not $j.PSObject.Properties['render']) { Set-Key $j 'render' (New-Object PSObject) }
    Set-Key $j.render 'falloff' 1200
    Set-Key $j.render 'viewportHeight' $ScreenH
    Save-Json $svc $j
    Write-Output ('[SET]  {0,-20} {1,-7} {2}' -f 'falloff', 1200, 'HIDDEN: no menu row, far tiles 2x sharper (default 600)')
    Write-Output ('[SET]  {0,-20} {1,-7} {2}' -f 'viewportHeight', $ScreenH, 'HIDDEN: no menu row, your screen height (default 1080)')
}

Write-Output '[INFO] Do not touch Far or Quality in the map settings menu afterwards: the menu rewrites realworldmc-render.json.'
Write-Output '[OK]   SI REAL WORLD applied, free. Start Minecraft and fly up: the 3D map now draws to 24,000 blocks. APPLY again and Yes = Undo.'
exit 0
