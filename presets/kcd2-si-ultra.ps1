# SI ULTRA - Kingdom Come: Deliverance II (PC) - by SI NEWS, MIT.
# The route: user.cfg in the install folder (steamapps\common\KingdomComeDeliverance2), loaded by the Steam launch option +exec user.cfg (github.com/smo0ths/KCD2-CFG-ECT). No game file touched, no mod.
# Key names and values from players' published configs, not from Warhorse: e_LodRatio, e_ViewDistRatioVegetation, e_ViewDistRatioLights = ThunderMG's user.cfg (steamcommunity.com/workshop/filedetails/?id=3450924599).
# e_ViewDistRatio=200 and e_MergedMeshesViewDistRatio=250: a comment on nexusmods.com/kingdomcomedeliverance2/mods/392 lists 180 and 200 as the Experimental defaults and recommends these.
# VRAM gates are our limit: from 12 GB all lines, from 8 GB the two distance lines, under 8 GB nothing is written.
# Left out: e_ViewDistMin (players on the same page blame it together with e_ViewDistRatio for shadow flicker), picture taste, every gameplay key.
# Players report the graphics menu replaces these values until the next start. Measure with your own FPS counter.
# Your own user.cfg: backup first (user.cfg.sigame.bak), only our keys change. No user.cfg: it is created. -Undo puts your exact file back, or removes the one we created.
param(
    [switch]$Undo
)

function Find-Kcd2 {
    $Roots = @()
    $Sp = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
    if ($Sp) {
        $Roots += $Sp
        $Vdf = Join-Path $Sp 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $Vdf) {
            foreach ($m in [regex]::Matches([IO.File]::ReadAllText($Vdf), '"path"\s+"([^"]+)"')) { $Roots += $m.Groups[1].Value.Replace('\\', '\') }
        }
    }
    $Roots += (Join-Path ${env:ProgramFiles(x86)} 'Steam')
    foreach ($r in $Roots) {
        $d = Join-Path $r 'steamapps\common\KingdomComeDeliverance2'
        if (Test-Path -LiteralPath $d) { return $d }
    }
    return $null
}

$Dir = if ($env:SIGAME_KCD2_CFG) { $env:SIGAME_KCD2_CFG } else { Find-Kcd2 }
if (-not $Dir) {
    Write-Output '[FAIL] Kingdom Come Deliverance 2 folder not found: install it with Steam, then apply again.'
    exit 2
}
$Cfg = Join-Path $Dir 'user.cfg'
$Bak = "$Cfg.sigame.bak"
$New = "$Cfg.sigame.new"
if (Get-Process -Name 'KingdomCome' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Kingdom Come Deliverance 2 is running: close the game first, then APPLY.'
    exit 4
}

if ($Undo) {
    if (Test-Path -LiteralPath $Bak) {
        Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
        Remove-Item -LiteralPath $Bak -Force
        Write-Output '[OK]   user.cfg restored from the backup.'
        exit 0
    }
    if (Test-Path -LiteralPath $New) {
        Remove-Item -LiteralPath $Cfg -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $New -Force
        Write-Output '[OK]   the user.cfg we created is gone.'
        exit 0
    }
    Write-Output '[FAIL] No .sigame.bak backup to restore.'
    exit 3
}

if ((Test-Path -LiteralPath $Cfg) -and (Get-Item -LiteralPath $Cfg).IsReadOnly) {
    Write-Output '[FAIL] user.cfg is read-only: untick Read-only in its properties, then apply again.'
    exit 5
}

$VramMb = 0
if ($env:SIGAME_TEST_VRAM_MB) {
    $VramMb = [int]$env:SIGAME_TEST_VRAM_MB
} else {
    foreach ($g in (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
        $q = (Get-ItemProperty -Path $g.PSPath -Name 'HardwareInformation.qwMemorySize' -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize'
        if ($q -and ([int64]$q / 1MB) -gt $VramMb) { $VramMb = [int]([int64]$q / 1MB) }
    }
}
if ($VramMb -lt 8192) {
    Write-Output '[SKIP] under 8 GB of VRAM these lines stay out: nothing written'
    exit 0
}

$Lines = @(
    @('e_ViewDistRatio', 200, 'object distance, past Experimental'),
    @('e_MergedMeshesViewDistRatio', 250, 'grass distance, past Experimental')
)
if ($VramMb -ge 12288) {
    $Lines += ,@('e_LodRatio', 285, 'model detail distance')
    $Lines += ,@('e_ViewDistRatioVegetation', 160, 'vegetation distance')
    $Lines += ,@('e_ViewDistRatioLights', 36, 'light distance')
} else {
    Write-Output '[SKIP] detail, vegetation, lights: under 12 GB they stay out'
}

$Txt = ''
$Bom = $false
if (Test-Path -LiteralPath $Cfg) {
    $Raw = [IO.File]::ReadAllBytes($Cfg)
    $Bom = ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF)
    $Txt = [IO.File]::ReadAllText($Cfg)
    if (-not (Test-Path -LiteralPath $Bak) -and -not (Test-Path -LiteralPath $New)) { Copy-Item -LiteralPath $Cfg -Destination $Bak }
    Write-Output '[OK]   undo is ready, every other line of your file stays'
} else {
    [IO.File]::WriteAllText($New, '')
    Write-Output '[OK]   no user.cfg yet: creating it'
}

# A better value stays.
foreach ($l in $Lines) {
    $Key, $Val, $Label = $l
    $Rg = [regex]('(?im)^(\s*' + [regex]::Escape($Key) + '\s*=\s*)([^\r\n#;]*)')
    $M = $Rg.Match($Txt)
    if (-not $M.Success) {
        if ($Txt.Length -and -not $Txt.EndsWith("`n")) { $Txt += "`r`n" }
        $Txt += "$Key=$Val`r`n"
        Write-Output "[SET]  ${Label}: $Val"
        continue
    }
    $Cur = $M.Groups[2].Value.Trim()
    $N = 0.0
    if ([double]::TryParse($Cur, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$N) -and $N -ge $Val) { Write-Output "[KEEP] ${Label}: $Cur, already there"; continue }
    $Txt = $Rg.Replace($Txt, [Text.RegularExpressions.MatchEvaluator]{ param($x) $x.Groups[1].Value + $Val }, 1)
    Write-Output "[SET]  ${Label}: $Cur -> $Val"
}

[IO.File]::WriteAllText($Cfg, $Txt, (New-Object System.Text.UTF8Encoding($Bom)))
Write-Output '[OK]   Steam launch option needed: +exec user.cfg'
Write-Output '[OK]   Graphics menu replaces these until the next start.'
Write-Output '[OK]   SI ULTRA applied, free. Undo = APPLY, Yes.'
exit 0
