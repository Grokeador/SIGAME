# SI ULTRA - Subnautica 2 (Unreal Engine 5, Steam, Early Access) - by SI NEWS, MIT.
# These values go past the game's top graphics level (Cinematic). Levels read from the game's own config, dumped in
# github.com/Kein/Subnautica2 Config/DefaultScalability.ini (MIT, May 2026):
#   [TextureQuality@Cine]      r.MaxAnisotropy=8, r.Streaming.PoolSize=3000, r.Streaming.LimitPoolSizeToVRAM=0
#   [PostProcessQuality@Cine]  r.Upscale.Quality=3
#   [FoliageQuality@Cine]      foliage.CullDistanceScale=2, grass.CullDistanceScale=2
#   [ShadowQuality@Cine]       r.Shadow.Virtual.ResolutionLodBiasDirectional=-1.5
# The game reads %LOCALAPPDATA%\Subnautica2\Saved\Config\Windows\Engine.ini; the mod authors keep it read-only or the game
# deletes it (curseforge.com/subnautica-2/blueprints/custom-fov-field-of-view). 21:9 and wider also get
# AspectRatioAxisConstraint (guide: allthings.how/how-to-change-fov-in-subnautica-2-config-edit-and-mod-options).
# Backup first (Engine.ini.sigame.bak); -Undo puts it back.
param(
    [switch]$Undo
)

$Dir = if ($env:SIGAME_SN2_CFG) { $env:SIGAME_SN2_CFG } else { Join-Path $env:LOCALAPPDATA 'Subnautica2\Saved\Config\Windows' }
if (-not (Test-Path -LiteralPath $Dir)) {
    Write-Output '[FAIL] Subnautica 2 config folder not found: start the game once, close it, then apply again.'
    exit 2
}
if (Get-Process -Name 'Subnautica2-Win64-Shipping', 'Subnautica2' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Subnautica 2 is running: close the game first, then APPLY.'
    exit 4
}
$Cfg = Join-Path $Dir 'Engine.ini'

function Set-Writable {
    if (Test-Path -LiteralPath $Cfg) { Set-ItemProperty -LiteralPath $Cfg -Name IsReadOnly -Value $false }
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath "$Cfg.sigame.bak")) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    Set-Writable
    if ((Get-Item -LiteralPath "$Cfg.sigame.bak").Length -eq 0) {
        Remove-Item -LiteralPath $Cfg -Force -ErrorAction SilentlyContinue
    } else {
        Copy-Item -LiteralPath "$Cfg.sigame.bak" -Destination $Cfg -Force
    }
    Write-Output '[OK]   Engine.ini restored from the backup.'
    exit 0
}

# --- Your screen and your video memory ---
Add-Type -AssemblyName System.Windows.Forms
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$W = if ($env:SIGAME_TEST_W) { [int]$env:SIGAME_TEST_W } else { $b.Width }
$H = if ($env:SIGAME_TEST_H) { [int]$env:SIGAME_TEST_H } else { $b.Height }
$Ar = [math]::Round($W / [math]::Max(1, $H), 2)
$Wide = $Ar -ge 2.0
Write-Output "[PC]   screen $W x $H (aspect $Ar)"

$Vram = 0
if ($env:SIGAME_TEST_VRAM_MB) {
    $Vram = [int]$env:SIGAME_TEST_VRAM_MB
} else {
    foreach ($k in (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
        $q = (Get-ItemProperty -LiteralPath $k.PSPath -Name 'HardwareInformation.qwMemorySize' -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize'
        if ($q) { $Vram = [math]::Max($Vram, [int]([int64]$q / 1MB)) }
    }
}

# section, key, value, what it does (empty = not printed)
$Set = @(
    , @('SystemSettings', 'r.MaxAnisotropy', '16', 'texture filtering 16 (Cinematic stops at 8)')
    , @('SystemSettings', 'r.Upscale.Quality', '5', 'upscale filter 5 (Cinematic stops at 3)')
    , @('SystemSettings', 'foliage.CullDistanceScale', '3', 'foliage distance x3 (Cinematic stops at x2)')
    , @('SystemSettings', 'grass.CullDistanceScale', '3', '')
    , @('SystemSettings', 'r.Shadow.Virtual.ResolutionLodBiasDirectional', '-2', 'sun shadow detail -2 (Cinematic stops at -1.5)')
)
if ($Vram -gt 0) {
    $Pool = [math]::Min(8000, [int][math]::Floor($Vram * 0.6 / 100) * 100)
    Write-Output "[PC]   video memory $Vram MB"
    $Set += , @('SystemSettings', 'r.Streaming.PoolSize', "$Pool", "texture pool $Pool MB, 60% of your video memory (Cinematic: fixed 3000)")
    $Set += , @('SystemSettings', 'r.Streaming.LimitPoolSizeToVRAM', '1', '')
} else {
    Write-Output '[INFO] Video memory not readable: texture pool left as it is.'
}
if ($Wide) {
    $Set += , @('/Script/Engine.LocalPlayer', 'AspectRatioAxisConstraint', 'AspectRatio_MaintainYFOV', "keeps the height on your $Ar screen, adds width")
}

if (Test-Path -LiteralPath $Cfg) {
    if (-not (Test-Path -LiteralPath "$Cfg.sigame.bak")) { Copy-Item -LiteralPath $Cfg -Destination "$Cfg.sigame.bak" -Force }
    Set-ItemProperty -LiteralPath "$Cfg.sigame.bak" -Name IsReadOnly -Value $false
    Set-Writable
    $lines = [System.Collections.Generic.List[string]]::new([string[]][IO.File]::ReadAllLines($Cfg))
} else {
    $lines = [System.Collections.Generic.List[string]]::new()
    Set-Content -LiteralPath "$Cfg.sigame.bak" -Value $null -Encoding ascii
}

foreach ($s in $Set) {
    $head = "[$($s[0])]"
    $at = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -ieq $head) { $at = $i; break } }
    if ($at -lt 0) {
        if ($lines.Count -and $lines[$lines.Count - 1].Trim()) { $lines.Add('') }
        $lines.Add($head)
        $lines.Add("$($s[1])=$($s[2])")
        continue
    }
    $hit = $false
    for ($i = $at + 1; $i -lt $lines.Count -and $lines[$i] -notmatch '^\s*\['; $i++) {
        if ($lines[$i] -match "^\s*$([regex]::Escape($s[1]))\s*=") { $lines[$i] = "$($s[1])=$($s[2])"; $hit = $true }
    }
    if (-not $hit) { $lines.Insert($at + 1, "$($s[1])=$($s[2])") }
}
[IO.File]::WriteAllText($Cfg, ($lines -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
Set-ItemProperty -LiteralPath $Cfg -Name IsReadOnly -Value $true
Write-Output '[OK]   Engine.ini updated, set to read-only so the game keeps it'
foreach ($s in $Set) {
    if ($s[3]) { Write-Output ('[SET]  {0,-46} {1}' -f "$($s[1])=$($s[2])", $s[3]) }
}
Write-Output '[OK]   SI ULTRA applied, free. Start Subnautica 2. These values are heavy: lower your level in the menu if you need more FPS. APPLY again and Yes = Undo.'
exit 0
