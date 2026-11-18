# SI ULTRA - The Witcher 3: Wild Hunt next-gen, for the AMDLSS5 mod 1.6.1 (github.com/Wehaveall/AMDLSS5) - by SI NEWS, MIT.
# The route: dlssnr_on_amd.ini next to bin\x64_dx12\witcher3.exe, section [DlssNrOnAmd]. The mod's own Witcher 3 profile is payload\ini\witcher3.ini in its 1.6.1 package.
# LEIA-ME: "Restore defaults" puts a game with its own profile back on the general defaults, filters off (src/helper/source/implementation/adapter-menu/adapter_menu.cpp).
# This writes back the profile's structure, style and filter keys, same names, same values.
# NeuralPreScalePercent is a value list in the mod's menu ("less % = faster job and less detail"). The author tested only the RX 9070 XT: XT stays at 100, the untested non-XT gets 75 = our limit.
# Only an AMD Radeon RX 9070 / RX 9070 XT is written to: the mod's README supports no other card. Close the game first. The value applies when the game reopens.
# Backup first (dlssnr_on_amd.ini.sigame.bak), every other line stays. -Undo puts your exact file back.
param(
    [switch]$Undo
)

function Find-Witcher3 {
    $Roots = @()
    $Sp = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
    if ($Sp) {
        $Roots += (Join-Path $Sp 'steamapps\common\The Witcher 3')
        $Vdf = Join-Path $Sp 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $Vdf) {
            foreach ($m in [regex]::Matches([IO.File]::ReadAllText($Vdf), '"path"\s+"([^"]+)"')) { $Roots += (Join-Path $m.Groups[1].Value.Replace('\\', '\') 'steamapps\common\The Witcher 3') }
        }
    }
    $Roots += (Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\The Witcher 3')
    $Roots += (Join-Path ${env:ProgramFiles(x86)} 'GOG Galaxy\Games\The Witcher 3 Wild Hunt GOTY')
    $Roots += 'C:\GOG Games\The Witcher 3 Wild Hunt GOTY'
    $Roots += (Join-Path $env:ProgramFiles 'Epic Games\TheWitcher3')
    foreach ($r in $Roots) {
        if (Test-Path -LiteralPath (Join-Path $r 'bin')) { return $r }
    }
    return $null
}

$Dir = if ($env:SIGAME_W3_DIR) { $env:SIGAME_W3_DIR } else { Find-Witcher3 }
if (-not $Dir) {
    Write-Output '[FAIL] The Witcher 3 folder not found: install the game, then apply again.'
    exit 2
}
$Ini = Join-Path $Dir 'bin\x64_dx12\dlssnr_on_amd.ini'
$Bak = "$Ini.sigame.bak"
if (Get-Process -Name 'witcher3' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] The Witcher 3 is running: close the game first, then APPLY.'
    exit 4
}

if ($Undo) {
    if (Test-Path -LiteralPath $Bak) {
        Copy-Item -LiteralPath $Bak -Destination $Ini -Force
        Remove-Item -LiteralPath $Bak -Force
        Write-Output '[OK]   dlssnr_on_amd.ini restored from the backup.'
        exit 0
    }
    Write-Output '[FAIL] No .sigame.bak backup to restore.'
    exit 3
}

$Gpu = ''
if ($env:SIGAME_TEST_GPU) {
    $Gpu = $env:SIGAME_TEST_GPU
} else {
    foreach ($g in (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
        $n = (Get-ItemProperty -Path $g.PSPath -Name 'DriverDesc' -ErrorAction SilentlyContinue).DriverDesc
        if ($n -match 'RX\s*9070') { $Gpu = $n; break }
    }
}
if ($Gpu -notmatch 'RX\s*9070') {
    Write-Output '[SKIP] AMDLSS5 supports only the RX 9070 and RX 9070 XT: nothing written'
    exit 0
}
if (-not (Test-Path -LiteralPath $Ini)) {
    if (Test-Path -LiteralPath (Join-Path $Dir 'bin\x64\dlssnr_on_amd.ini')) {
        Write-Output '[FAIL] AMDLSS5 is in bin\x64, the DirectX 11 folder: remove it, install it on bin\x64_dx12\witcher3.exe.'
        exit 6
    }
    Write-Output '[FAIL] AMDLSS5 not found in bin\x64_dx12: install the mod first, then apply again.'
    exit 7
}
if ((Get-Item -LiteralPath $Ini).IsReadOnly) {
    Write-Output '[FAIL] dlssnr_on_amd.ini is read-only: untick Read-only in its properties, then apply again.'
    exit 5
}

$Pre = if ($Gpu -match 'RX\s*9070\s*XT') { '100' } else { '75' }
$Groups = @(
    @('structure and style', @(@('LocalStructure', '1.500'), @('SkinStructure', '1.250'), @('NeuralStyle', '2'))),
    @('sharpening filters', @(@('NeuralFiltroCas', '1'), @('NeuralFiltroCasForca', '1.00'), @('NeuralFiltroLuma', '1'), @('NeuralFiltroLumaForca', '2.00'))),
    @('local contrast', @(@('NeuralFiltroClarity', '1'), @('NeuralFiltroClarityForca', '2.00'), @('NeuralFiltroClarityMeios', '1.00'), @('NeuralFiltroClarityRaio', '3'), @('NeuralFiltroClarityZona', '1'))),
    @('levels', @(@('NeuralFiltroNiveis', '1'), @('NeuralFiltroNiveisBranco', '210'), @('NeuralFiltroNiveisPreto', '8'))),
    @('color by range', @(@('NeuralFiltroHsl', '1'), @('NeuralFiltroHslAmareloLuz', '-15'), @('NeuralFiltroHslAmareloMatiz', '+6'), @('NeuralFiltroHslAmareloSat', '-45'), @('NeuralFiltroHslVerdeLuz', '0'), @('NeuralFiltroHslVerdeMatiz', '-20'), @('NeuralFiltroHslVerdeSat', '-95'))),
    @('network resolution', @(,@('NeuralPreScalePercent', $Pre)))
)

# The mod reads either encoding: the file keeps the one it has.
$Raw = [IO.File]::ReadAllBytes($Ini)
$Wide = ($Raw.Length -ge 2 -and $Raw[0] -eq 0xFF -and $Raw[1] -eq 0xFE)
$Enc = if ($Wide) { New-Object Text.UnicodeEncoding($false, $true) } else { [Text.Encoding]::GetEncoding(28591) }
$Skip = if ($Wide) { 2 } else { 0 }
$Txt = $Enc.GetString($Raw, $Skip, $Raw.Length - $Skip)
if ($Txt -notmatch '(?im)^\[DlssNrOnAmd\]') {
    Write-Output '[FAIL] dlssnr_on_amd.ini has no [DlssNrOnAmd] section: reinstall the mod, then apply again.'
    exit 8
}
if (-not (Test-Path -LiteralPath $Bak)) { Copy-Item -LiteralPath $Ini -Destination $Bak }
Write-Output '[OK]   undo is ready, every other line of your file stays'

foreach ($g in $Groups) {
    $Changed = 0
    foreach ($kv in $g[1]) {
        $Key = $kv[0]; $Val = $kv[1]
        $Rg = [regex]('(?im)^(\s*' + [regex]::Escape($Key) + '\s*=)([^\r\n]*)')
        $M = $Rg.Match($Txt)
        if ($M.Success) {
            if ($M.Groups[2].Value.Trim() -ceq $Val) { continue }
            $Txt = $Rg.Replace($Txt, [Text.RegularExpressions.MatchEvaluator]{ param($x) $x.Groups[1].Value + $Val }, 1)
        } else {
            $Txt = ([regex]'(?im)^\[DlssNrOnAmd\][^\r\n]*\r?\n?').Replace($Txt, [Text.RegularExpressions.MatchEvaluator]{ param($x) $x.Value.TrimEnd() + "`r`n$Key=$Val`r`n" }, 1)
        }
        $Changed++
    }
    if ($Changed) { Write-Output "[SET]  $($g[0]): $Changed lines" } else { Write-Output "[KEEP] $($g[0]): already there" }
}

$Body = $Enc.GetBytes($Txt)
if ($Wide) { $Body = [byte[]]($Enc.GetPreamble() + $Body) }
[IO.File]::WriteAllBytes($Ini, [byte[]]$Body)
if ($Pre -eq '75') { Write-Output '[OK]   RX 9070: network at 75 percent, the author tested only the XT' }
Write-Output '[OK]   Adrenalin: metrics overlay and recording off, tuning Default'
Write-Output '[OK]   In game: DirectX 12, AMD FSR, F10 = network on and off.'
Write-Output '[OK]   SI ULTRA applied, free. Undo = APPLY, Yes.'
exit 0
