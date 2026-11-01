# SI ULTRA - Call of Duty 4: Modern Warfare (2007, IW 3.0, Steam) - by SI NEWS, MIT.
# CoD4 saves its settings as `seta name "value"` lines in players\profiles\<you>\config.cfg (campaign) and config_mp.cfg
# (multiplayer). Every key below and its allowed range comes from the game's own dvar registrations, as disassembled in
# CoD4x (github.com/callofduty4x/CoD4x_Server, tools/cod4_dasm/src/_r_dvars.asm, _common.asm, _cg_main_mp.asm); all of
# them carry the archive flag (1), so the game reads them back from the file at every start.
# This writes, for YOUR PC (read from Windows):
#   com_maxfps          = your monitor's Hz (0..1000; default 85)
#   cg_fov              = 80 (65..80; default 65)
#   r_lodBiasRigid / r_lodBiasSkinned = -1000 with 4+ GB video memory, else -200 (-1000..0; negative = more detail far away)
#   r_lodScaleRigid / r_lodScaleSkinned = 1 (1..4; larger reduces detail)
#   r_picmip_manual = 1 and r_picmip / _bump / _spec / _water = 0 (full-size colour, normal, specular, water maps)
#   r_texFilterAnisoMax / Min = 16 (1..16), sm_maxLights = 4 (0..4, shadow maps for primary lights)
#   r_aaSamples         = 8 with 6+ GB video memory, 4 with 3+ GB, else 2 (1..16)
# Backup first (<file>.sigame.bak); -Undo puts every file back.
param(
    [switch]$Undo
)

function Find-Cod4Roots {
    $roots = @()
    if ($env:SIGAME_COD4_ROOT) { return @($env:SIGAME_COD4_ROOT) }
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
    $libs = @()
    if ($steam) {
        $libs += $steam
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value -replace '\\\\', '\' }
        }
    }
    foreach ($l in ($libs | Select-Object -Unique)) { $roots += Join-Path $l 'steamapps\common\Call of Duty 4' }
    $roots += Join-Path ${env:ProgramFiles(x86)} 'Activision\Call of Duty 4 - Modern Warfare'
    # Windows may keep the profile in the VirtualStore copy of a Program Files install
    foreach ($r in @($roots)) {
        if ($r -match '^[A-Za-z]:\\(.+)$') { $roots += Join-Path $env:LOCALAPPDATA ('VirtualStore\' + $Matches[1]) }
    }
    return @($roots | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'players') })
}

$Files = @()
foreach ($r in (Find-Cod4Roots)) {
    $Files += @(Get-ChildItem -LiteralPath (Join-Path $r 'players') -Recurse -Depth 2 -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in 'config.cfg', 'config_mp.cfg' } | ForEach-Object { $_.FullName })
}
if (-not $Files) {
    Write-Output '[FAIL] No CoD4 profile found (players\profiles\<you>\config_mp.cfg): start the game once, create a profile, close it, then apply again.'
    exit 2
}
if (Get-Process -Name 'iw3mp', 'iw3sp' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Call of Duty 4 is running: close the game first (it writes its config when it closes).'
    exit 4
}

if ($Undo) {
    $n = 0
    foreach ($f in $Files) {
        if (Test-Path -LiteralPath "$f.sigame.bak") { Copy-Item -LiteralPath "$f.sigame.bak" -Destination $f -Force; $n++ }
    }
    if ($n -eq 0) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    Write-Output "[OK]   $n CoD4 config file(s) restored from the backup."
    exit 0
}

# --- Your PC ---
$gpu = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Basic|Remote|Virtual' })
$Hz = if ($env:SIGAME_TEST_HZ) { [int]$env:SIGAME_TEST_HZ } else { [int](($gpu | Measure-Object CurrentRefreshRate -Maximum).Maximum) }
if ($Hz -lt 30) { $Hz = 60 }
# AdapterRAM stops at 4 GB; the driver key qwMemorySize has the real size.
$VramGB = 0
if ($env:SIGAME_TEST_VRAM_GB) { $VramGB = [double]$env:SIGAME_TEST_VRAM_GB } else {
    foreach ($k in @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
        $q = (Get-ItemProperty -LiteralPath $k.PSPath -Name 'HardwareInformation.qwMemorySize' -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize'
        if ($q) { $VramGB = [math]::Max($VramGB, [math]::Round([double]$q / 1GB, 1)) }
    }
    if ($VramGB -eq 0) { $VramGB = [math]::Round((($gpu | Measure-Object AdapterRAM -Maximum).Maximum) / 1GB, 1) }
}
Write-Output "[PC]   $Hz Hz monitor, $VramGB GB video memory"

$Bias = if ($VramGB -ge 4) { '-1000' } else { '-200' }
$Aa = if ($VramGB -ge 6) { '8' } elseif ($VramGB -ge 3) { '4' } else { '2' }
$Fps = [string][math]::Min(1000, $Hz)

$Set = [ordered]@{
    'com_maxfps'          = @($Fps, "FPS cap = your $Hz Hz (default 85)")
    'cg_fov'              = @('80', 'field of view at the game''s own maximum (default 65)')
    'r_lodBiasRigid'      = @($Bias, 'full-detail models far away (default 0)')
    'r_lodBiasSkinned'    = @($Bias, 'full-detail soldiers far away (default 0)')
    'r_lodScaleRigid'     = @('1', '')
    'r_lodScaleSkinned'   = @('1', '')
    'r_picmip_manual'     = @('1', 'texture size no longer picked automatically')
    'r_picmip'            = @('0', 'full-size colour maps')
    'r_picmip_bump'       = @('0', 'full-size normal maps')
    'r_picmip_spec'       = @('0', 'full-size specular maps')
    'r_picmip_water'      = @('0', 'full-size water maps')
    'r_texFilterAnisoMax' = @('16', '16x anisotropic filtering')
    'r_texFilterAnisoMin' = @('16', '')
    'sm_maxLights'        = @('4', 'shadow maps on all 4 primary lights')
    'r_aaSamples'         = @($Aa, "${Aa}x anti-aliasing (the game accepts 1..16)")
}

foreach ($f in $Files) {
    if (-not (Test-Path -LiteralPath "$f.sigame.bak")) { Copy-Item -LiteralPath $f -Destination "$f.sigame.bak" -Force }
    $lines = [System.Collections.Generic.List[string]]::new([string[]][IO.File]::ReadAllLines($f))
    foreach ($k in $Set.Keys) {
        $v = $Set[$k][0]
        $hit = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^\s*seta\s+$k\s") { $lines[$i] = "seta $k `"$v`""; $hit = $true }
        }
        if (-not $hit) { $lines.Add("seta $k `"$v`"") }
    }
    [IO.File]::WriteAllText($f, ($lines -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "[OK]   $(Split-Path -Leaf (Split-Path -Parent $f))\$(Split-Path -Leaf $f)"
}
foreach ($k in $Set.Keys) {
    if ($Set[$k][1]) { Write-Output ('[SET]  {0,-20} {1,-6} {2}' -f $k, $Set[$k][0], $Set[$k][1]) }
}
Write-Output "[OK]   SI ULTRA applied, free. Start Call of Duty 4: $Fps fps cap, FOV 80, full-detail models and textures. APPLY again and Yes = Undo."
exit 0
