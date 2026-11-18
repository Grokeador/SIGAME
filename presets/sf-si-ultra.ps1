# SI ULTRA - Starfield (PC) - by SI NEWS, MIT.
# The game's own override file: StarfieldCustom.ini in Documents\My Games\Starfield (it does not exist until someone creates it). No game file touched, no mod.
# Key names, sections and defaults: DoubleYou's list on STEP, strings dumped from the executable, defaults read with getini (stepmodifications.org/forum/topic/19019). Values from players' posts and files; not from Bethesda.
# fMipBiasOffset (default 0.0, no slider in the menu) follows YOUR render scale read from StarfieldPrefs.ini: -0.5 at about 67%, -1.0 at about 58% (r/nvidia, igorslab); near native it stays yours.
# bDisableStreaming in [Terrain] (default 0): Nexus configs say less stutter and more video memory, so only from 12 GB of VRAM (our limit). bEnableMultiFrameAsyncCompute (default 0): a player's real file (Tekunogosu's gist), only from 8 threads (our limit).
# Left out: shadow lines (STEP: Renderer Quality settings cannot be set in this file), VRS and job threads (no source names a value and what it does).
# Backup first (StarfieldCustom.ini.sigame.bak, or a marker when you had no file); -Undo puts your file back exactly, or removes the one we created.
param(
    [switch]$Undo
)

$Dir = if ($env:SIGAME_SF_CFG) { $env:SIGAME_SF_CFG } else { Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'My Games\Starfield' }
if (-not (Test-Path -LiteralPath $Dir)) {
    Write-Output '[FAIL] Starfield settings folder not found: start the game once, close it, then apply again.'
    exit 2
}
$Cfg = Join-Path $Dir 'StarfieldCustom.ini'
$Prefs = Join-Path $Dir 'StarfieldPrefs.ini'
$Bak = "$Cfg.sigame.bak"
$New = "$Cfg.sigame.new"
if (Get-Process -Name 'Starfield' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Starfield is running: close the game first, then APPLY.'
    exit 4
}

if ($Undo) {
    if (Test-Path -LiteralPath $Bak) {
        Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
        Remove-Item -LiteralPath $Bak -Force
        Write-Output '[OK]   StarfieldCustom.ini restored from the backup.'
        exit 0
    }
    if (Test-Path -LiteralPath $New) {
        Remove-Item -LiteralPath $Cfg -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $New -Force
        Write-Output '[OK]   StarfieldCustom.ini removed: you had none before.'
        exit 0
    }
    Write-Output '[FAIL] No .sigame.bak backup to restore.'
    exit 3
}

if (-not (Test-Path -LiteralPath $Prefs)) {
    Write-Output '[FAIL] StarfieldPrefs.ini not found: start the game once, close it, then apply again.'
    exit 2
}
if ((Test-Path -LiteralPath $Cfg) -and (Get-Item -LiteralPath $Cfg).IsReadOnly) {
    Write-Output '[FAIL] StarfieldCustom.ini is read-only: untick Read-only in its properties, then apply again.'
    exit 5
}

$Threads = if ($env:SIGAME_TEST_CPU) { [int]$env:SIGAME_TEST_CPU } else { [Environment]::ProcessorCount }
$VramMb = 0
if ($env:SIGAME_TEST_VRAM_MB) {
    $VramMb = [int]$env:SIGAME_TEST_VRAM_MB
} else {
    foreach ($g in (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue)) {
        $q = (Get-ItemProperty -Path $g.PSPath -Name 'HardwareInformation.qwMemorySize' -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize'
        if ($q -and ([int64]$q / 1MB) -gt $VramMb) { $VramMb = [int]([int64]$q / 1MB) }
    }
}

$Inv = [Globalization.CultureInfo]::InvariantCulture
function Num($S) { $n = 0.0; if ([double]::TryParse($S, [Globalization.NumberStyles]::Float, $Inv, [ref]$n)) { $n } else { $null } }

$Scale = $null
$Sm = [regex]::Match([IO.File]::ReadAllText($Prefs), '(?im)^\s*fRenderResolutionScaleFactor\s*=\s*([0-9.]+)')
if ($Sm.Success) { $Scale = Num $Sm.Groups[1].Value }

$Had = Test-Path -LiteralPath $Cfg
$Bom = $false
$Txt = ''
if ($Had) {
    $Raw = [IO.File]::ReadAllBytes($Cfg)
    $Bom = ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF)
    $Txt = [IO.File]::ReadAllText($Cfg)
    if (-not ((Test-Path -LiteralPath $Bak) -or (Test-Path -LiteralPath $New))) { Copy-Item -LiteralPath $Cfg -Destination $Bak }
    Write-Output '[OK]   backup saved, every other line of your file stays'
} else {
    if (-not (Test-Path -LiteralPath $New)) { [IO.File]::WriteAllText($New, '') }
    Write-Output '[OK]   no StarfieldCustom.ini yet: this creates it, Undo removes it'
}

# A better value stays. The line goes inside its own section, the section is added if your file has none.
function Set-Ini($Sec, $Key, $Val, $Label, [scriptblock]$Better) {
    $H = ([regex]('(?im)^[ \t]*\[' + [regex]::Escape($Sec) + '\][ \t]*(\r?\n|\z)')).Match($Script:Txt)
    if (-not $H.Success) {
        $Sep = if ($Script:Txt.Length -and -not $Script:Txt.EndsWith("`n")) { "`r`n" } else { '' }
        $Script:Txt += "$Sep[$Sec]`r`n$Key=$Val`r`n"
        Write-Output "[SET]  ${Label}: new line, $Val"
        return
    }
    $Start = $H.Index + $H.Length
    $Nx = ([regex]'(?m)^[ \t]*\[').Match($Script:Txt, $Start)
    $End = if ($Nx.Success) { $Nx.Index } else { $Script:Txt.Length }
    $Body = $Script:Txt.Substring($Start, $End - $Start)
    $Rg = [regex]('(?im)^([ \t]*' + [regex]::Escape($Key) + '[ \t]*=[ \t]*)([^\r\n]*)')
    $M = $Rg.Match($Body)
    if ($M.Success) {
        $Cur = $M.Groups[2].Value.Trim()
        if (& $Better $Cur) { Write-Output "[KEEP] ${Label}: $Cur, already there"; return }
        $Body = $Rg.Replace($Body, [Text.RegularExpressions.MatchEvaluator]{ param($x) $x.Groups[1].Value + $Val }, 1)
        Write-Output "[SET]  ${Label}: $Cur -> $Val"
    } else {
        $Lead = if ($H.Value.EndsWith("`n")) { '' } else { "`r`n" }
        $Body = "$Lead$Key=$Val`r`n" + $Body
        Write-Output "[SET]  ${Label}: new line, $Val"
    }
    $Script:Txt = $Script:Txt.Substring(0, $Start) + $Body + $Script:Txt.Substring($End)
}

if ($null -eq $Scale) {
    Write-Output '[SKIP] texture bias: no render scale in StarfieldPrefs.ini, it stays yours'
} elseif ($Scale -ge 0.9) {
    Write-Output '[SKIP] texture bias: render scale near native, it stays yours'
} else {
    $Pct = [int][math]::Round($Scale * 100)
    $Mip = if ($Scale -ge 0.63) { -0.5 } else { -1.0 }
    $MipS = $Mip.ToString('0.0', $Inv)
    Set-Ini 'Display' 'fMipBiasOffset' $MipS "texture bias for your $Pct% render scale" { param($c) $n = Num $c; ($null -ne $n) -and $n -le $Mip }
}
if ($VramMb -ge 12288) {
    Set-Ini 'Terrain' 'bDisableStreaming' '1' 'terrain texture streaming off' { param($c) $c -eq '1' }
} else {
    Write-Output '[SKIP] terrain streaming: under 12 GB of VRAM it stays yours'
}
if ($Threads -ge 8) {
    Set-Ini 'Display' 'bEnableMultiFrameAsyncCompute' '1' 'multi-frame async compute' { param($c) $c -eq '1' }
} else {
    Write-Output '[SKIP] multi-frame async compute: under 8 threads it stays yours'
}

[IO.File]::WriteAllText($Cfg, $Txt, (New-Object System.Text.UTF8Encoding($Bom)))
Write-Output '[OK]   Changed the render scale in the menu? APPLY again.'
Write-Output '[OK]   SI ULTRA applied, free. Undo = APPLY, Yes.'
exit 0
