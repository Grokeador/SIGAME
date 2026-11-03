# SI ULTRA - Monster Hunter Wilds (PC) - by SI NEWS, MIT.
# The game's own file: config.ini in the install folder (steamapps\common\MonsterHunterWilds). No game file touched, no mod, no REFramework.
# Key names and sections read from a real config.ini (github.com/pblocz/mhwilds-config). Values from players' posts on Steam and ResetEra; not from Capcom.
# ParallelBuildProcessorCount = your logical processors, only ever raised (Steam, thegamepost). RenderWorkerThreadPriorityAboveNormal=Enable from 8 threads up (same posts; below 8 it stays yours).
# StreamingTextureLoadLevelBias=-1 is past the menu's 0 (Romax069 on Steam; ResetEra: the menu's texture option maps to this key): only from 12 GB of VRAM (our limit), every other card keeps its value.
# Repair: the famous "typo fix" renames MinimumStreamingTextureResoltuion_N, but the engine's own name has that spelling (a real file + a mod's list of the game's settings): a file with the "fixed" name goes back to the engine's.
# Left out: FOV and the menu's own switches. Opening the game's graphics options rewrites this file (Lemon King, ResetEra): APPLY again after that.
# Backup first (config.ini.sigame.bak); -Undo puts it back exactly.
param(
    [switch]$Undo
)

function Find-Wilds {
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
        $d = Join-Path $r 'steamapps\common\MonsterHunterWilds'
        if (Test-Path -LiteralPath $d) { return $d }
    }
    return $null
}

$Dir = if ($env:SIGAME_MHW_CFG) { $env:SIGAME_MHW_CFG } else { Find-Wilds }
if (-not $Dir) {
    Write-Output '[FAIL] Monster Hunter Wilds folder not found: install it with Steam, then apply again.'
    exit 2
}
$Cfg = Join-Path $Dir 'config.ini'
$Bak = "$Cfg.sigame.bak"
if (Get-Process -Name 'MonsterHunterWilds' -ErrorAction SilentlyContinue) {
    Write-Output '[FAIL] Monster Hunter Wilds is running: close the game first, then APPLY.'
    exit 4
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath $Bak)) { Write-Output '[FAIL] No .sigame.bak backup to restore.'; exit 3 }
    Copy-Item -LiteralPath $Bak -Destination $Cfg -Force
    Remove-Item -LiteralPath $Bak -Force
    Write-Output '[OK]   config.ini restored from the backup.'
    exit 0
}

if (-not (Test-Path -LiteralPath $Cfg)) {
    Write-Output '[FAIL] config.ini not found: start the game once, change any graphics setting, close it, then apply again.'
    exit 2
}
if ((Get-Item -LiteralPath $Cfg).IsReadOnly) {
    Write-Output '[FAIL] config.ini is read-only: untick Read-only in its properties, then apply again.'
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

$Raw = [IO.File]::ReadAllBytes($Cfg)
$Bom = ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF)
$Txt = [IO.File]::ReadAllText($Cfg)
if (-not (Test-Path -LiteralPath $Bak)) { Copy-Item -LiteralPath $Cfg -Destination $Bak }
Write-Output '[OK]   backup saved, every other line of your file stays'

function Rx($Key) { [regex]('(?im)^(\s*' + [regex]::Escape($Key) + '\s*=\s*)([^\r\n]*)') }

# A better value stays. Every copy of the line in the file gets the new one (the texture bias sits in two sections).
function Set-Key($Key, $Val, $Label, [scriptblock]$Better) {
    $Rg = Rx $Key
    $Ms = $Rg.Matches($Script:Txt)
    if ($Ms.Count -eq 0) { Write-Output "[SKIP] ${Label}: not in your file"; return }
    $Cur = $Ms[0].Groups[2].Value.Trim()
    if (& $Better $Cur) { Write-Output "[KEEP] ${Label}: $Cur, already there"; return }
    $Script:Txt = $Rg.Replace($Script:Txt, [Text.RegularExpressions.MatchEvaluator]{ param($x) $x.Groups[1].Value + $Val })
    Write-Output "[SET]  ${Label}: $Cur -> $Val"
}

function Num($S) { $n = 0; if ([int]::TryParse($S, [ref]$n)) { $n } else { $null } }

Set-Key 'ParallelBuildProcessorCount' "$Threads" "render build threads ($Threads on this CPU)" { param($c) $n = Num $c; ($null -ne $n) -and $n -ge $Threads }
if ($Threads -ge 8) {
    Set-Key 'RenderWorkerThreadPriorityAboveNormal' 'Enable' 'render thread priority' { param($c) $c -ieq 'Enable' }
} else {
    Write-Output '[SKIP] render thread priority: under 8 threads it stays yours'
}
if ($VramMb -ge 12288) {
    Set-Key 'StreamingTextureLoadLevelBias' '-1' 'texture bias, past the menu' { param($c) $n = Num $c; ($null -ne $n) -and $n -le -1 }
} else {
    Write-Output '[SKIP] texture bias: under 12 GB of VRAM it stays yours'
}

$Ty = Rx 'MinimumStreamingTextureResolution'
$Tm = $Ty.Match($Txt)
if ($Tm.Success -and $Tm.Groups[2].Value -match '^MinimumStreamingTextureResolution_(\d+)\s*$') {
    $Fixed = 'MinimumStreamingTextureResoltuion_' + $Matches[1]
    $Txt = $Ty.Replace($Txt, [Text.RegularExpressions.MatchEvaluator]{ param($x) $x.Groups[1].Value + $Fixed })
    Write-Output "[SET]  famous typo fix: put back the engine's own name"
} elseif ($Tm.Success) {
    Write-Output "[KEEP] typo line: the engine's own spelling, leave it"
}

[IO.File]::WriteAllText($Cfg, $Txt, (New-Object System.Text.UTF8Encoding($Bom)))
Write-Output '[OK]   Graphics options rewrite this file: APPLY again after.'
Write-Output '[OK]   SI ULTRA applied, free. Undo = APPLY, Yes.'
exit 0
