# SI OPTI - OptiScaler installed per game, set for YOUR GPU - by SI NEWS, MIT.
# OptiScaler (github.com/optiscaler/OptiScaler, GPL-3.0) swaps the upscaler a game calls (DLSS / FSR / XeSS) for
# another one (XeSS, FSR 2/3/4, DLSS). This script does what its own setup_windows.bat and wiki Installation page
# say, without the questions:
#   - downloads the official v0.9.4 release (and 7-Zip's 7zr.exe to open it) and runs nothing unless the SHA-256
#     matches the one GitHub publishes for the asset;
#   - copies ALL its files next to the game exe (Unreal games: the *-Win64-Shipping.exe folder, never Engine) and
#     renames OptiScaler.dll to the file name the OptiScaler wiki page of that game lists (-Dll);
#   - writes OptiScaler.ini for your GPU: AMD RX 7000 desktop / RX 9000 = FSR4 in DX12, DX11 and Vulkan (the wiki:
#     FSR4 is official on RDNA3 dGPUs and RDNA4, DX11/Vulkan through the DX12 interop from 0.9), plus
#     FsrAgilitySDKUpgrade on Windows 10 ("Enabling the use of FSR4 on Windows 10" in OptiScaler.ini); Intel Arc =
#     XeSS everywhere; every other GPU keeps OptiScaler's own defaults;
#   - adds the settings the wiki page of that game gives (-Set) and leaves out the files it says to leave out (-Skip).
# OptiScaler's README: "Do not use this mod with online games. It may trigger anti-cheat software and cause bans!"
# So SI OPTI exists only for single-player games and refuses any folder with EasyAntiCheat or BattlEye.
# Every file it replaces is backed up (.sigame.bak); -Undo removes what it added and puts the backups back.
param(
    [switch]$Undo,
    [string]$GameKey = '',       # the OptiScaler wiki page of the game (also the id of this install)
    [string]$GameExe = '',       # given by SIGAME from the game card
    [string]$SteamAppId = '',    # fallback when SIGAME gives no exe
    [string]$ExeName = '',       # fallback: exe path inside the Steam folder (non-Unreal games)
    [string]$Dll = 'dxgi.dll',
    [string[]]$Set = @(),        # 'Key=Value' or 'amd,intel:Key=Value' (only for those GPU makers)
    [string[]]$Skip = @(),
    [string]$SourceDir = '',     # test only: an already extracted OptiScaler folder
    [string]$MockGpu = '',       # test only
    [switch]$MockWin10           # test only
)

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot                      # SIGAME folder (presets\..)
$tools  = Join-Path $root 'tools'
$cache  = Join-Path $env:LOCALAPPDATA 'SIGAME\optiscaler-0.9.4'
$opti   = @{ Url = 'https://github.com/optiscaler/OptiScaler/releases/download/v0.9.4/Optiscaler_0.9.4-final.20260718._MM.7z'
             Sha = '575CB4DF866116093DF75AF607E37FD70E10F5163E0F23FD5C804142E80EF0AD' }
$sevenZ = @{ Url = 'https://github.com/ip7z/7zip/releases/download/26.05/7zr.exe'
             Sha = '9BF582B894DFA665F852D7E9112B02290A1C303C2D95A21FCDC41FFCB03143B7' }
$okNames = @('dxgi.dll', 'winmm.dll', 'version.dll', 'dbghelp.dll', 'd3d12.dll', 'wininet.dll', 'winhttp.dll', 'OptiScaler.asi')
$notCopied = @('!! README_EXTRACT ALL FILES TO GAME FOLDER !!.txt', 'setup_linux.sh', 'setup_windows.bat')

function Out-Line([string]$s) { Write-Output $s }

# powershell -File passes each argument as one string: lists are ';'-separated.
$Set  = @($Set  | ForEach-Object { $_ -split ';' } | Where-Object { $_ })
$Skip = @($Skip | ForEach-Object { $_ -split ';' } | Where-Object { $_ })

if (-not $GameKey) { Out-Line '[FAIL] This SI PRESET needs the new SIGAME: download it again from GitHub.'; exit 8 }
if ($okNames -notcontains $Dll) { Out-Line "[FAIL] $Dll is not a file name OptiScaler supports."; exit 8 }

# --- Where the game is: the exe SIGAME gives, else its Steam folder ---
function Get-SteamGameRoot([string]$appId) {
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return $null }
    $libs = @($steam -replace '/', '\')
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) { $libs += ($m.Groups[1].Value -replace '\\\\', '\') }
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $acf = Join-Path $lib "steamapps\appmanifest_$appId.acf"
        if (-not (Test-Path -LiteralPath $acf)) { continue }
        $m = [regex]::Match((Get-Content -LiteralPath $acf -Raw), '"installdir"\s+"([^"]+)"')
        if ($m.Success) { $p = Join-Path $lib "steamapps\common\$($m.Groups[1].Value)"; if (Test-Path -LiteralPath $p) { return $p } }
    }
    return $null
}

function Find-Shipping([string]$dir) {
    # Unreal: <Project>\Binaries\Win64\<Project>-Win64-Shipping.exe (or WinGDK), never under Engine.
    $hits = @(Get-ChildItem -LiteralPath $dir -Recurse -Depth 4 -Filter '*-Win*-Shipping.exe' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\Engine\\' })
    return ($hits | Sort-Object Length -Descending | Select-Object -First 1)
}

$gameRoot = $null; $target = $null
if ($GameExe -and (Test-Path -LiteralPath $GameExe)) {
    $exeDir = Split-Path -Parent $GameExe
    if ($GameExe -match '-Win\w*-Shipping\.exe$') { $target = $exeDir }
    else {
        $s = Find-Shipping $exeDir
        $named = if ($ExeName) { Join-Path $exeDir $ExeName } else { '' }
        $target = if ($s) { $s.DirectoryName } elseif ($named -and (Test-Path -LiteralPath $named)) { Split-Path -Parent $named } else { $exeDir }
    }
    $gameRoot = $exeDir
    # The anti-cheat check looks at the whole Steam folder of the game, not only the exe folder (bin\x64...).
    if ($exeDir -match '^(.+?\\steamapps\\common\\[^\\]+)') { $gameRoot = $Matches[1] }
} elseif ($SteamAppId) {
    $gameRoot = Get-SteamGameRoot $SteamAppId
    if ($gameRoot) {
        $s = Find-Shipping $gameRoot
        if ($s) { $target = $s.DirectoryName }
        elseif ($ExeName -and (Test-Path -LiteralPath (Join-Path $gameRoot $ExeName))) { $target = Split-Path -Parent (Join-Path $gameRoot $ExeName) }
    }
}
if (-not $target) { Out-Line '[FAIL] Game folder not found: add the game to SIGAME and use the SI PRESET button on its card.'; exit 2 }
$manifestPath = Join-Path $target 'SIGAME-optiscaler.json'

# --- The game must be closed ---
$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $pp = $null; try { $pp = $_.Path } catch { }
    $pp -and $pp.StartsWith($target, [StringComparison]::OrdinalIgnoreCase) })
if ($running.Count) { Out-Line "[FAIL] $($running[0].ProcessName) is running: close the game, then apply again."; exit 4 }

function Invoke-Undo {
    if (-not (Test-Path -LiteralPath $manifestPath)) { Out-Line '[FAIL] No SI OPTI install found in this game folder.'; exit 3 }
    $m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    foreach ($rel in @($m.Added)) {
        $p = Join-Path $target $rel
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
        if (Test-Path -LiteralPath "$p.sigame.bak") { Move-Item -LiteralPath "$p.sigame.bak" -Destination $p -Force; Out-Line "[OK]   $rel restored from the backup" }
    }
    foreach ($rel in (@($m.Dirs) | Sort-Object Length -Descending)) {
        $p = Join-Path $target $rel
        if ((Test-Path -LiteralPath $p) -and -not (Get-ChildItem -LiteralPath $p -Force)) { Remove-Item -LiteralPath $p -Force }
    }
    Remove-Item -LiteralPath $manifestPath -Force
    Out-Line "[OK]   OptiScaler removed from $(Split-Path -Leaf $target): the game is back as it was."
}

if ($Undo) { Invoke-Undo; exit 0 }

# --- Single player only ---
$acHits = @(Get-ChildItem -LiteralPath $gameRoot -Recurse -Depth 3 -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(EasyAntiCheat|BattlEye|BEService.*|start_protected_game\.exe|EasyAntiCheat.*\.exe)$' })
if ($acHits.Count) { Out-Line "[FAIL] Anti-cheat found ($($acHits[0].Name)): OptiScaler is not for online games, nothing was changed."; exit 7 }

# --- Your GPU ---
$gpus = if ($MockGpu) { @($MockGpu) } else { @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Basic|Remote|Virtual|Parsec' } | ForEach-Object { $_.Name }) }
$gpu = ($gpus | Where-Object { $_ -match 'NVIDIA|Radeon|Arc' } | Select-Object -First 1)
if (-not $gpu) { $gpu = $gpus | Select-Object -First 1 }
$maker = if ($gpu -match 'NVIDIA') { 'nvidia' } elseif ($gpu -match 'AMD|Radeon') { 'amd' } elseif ($gpu -match 'Intel') { 'intel' } else { 'other' }
$fsr4 = ($gpu -match 'Radeon.*RX\s*9\d{3}') -or ($gpu -match 'Radeon.*RX\s*7\d{3}(?!M)\b' -and $gpu -notmatch '\d{4}M\b')
$arc  = ($gpu -match 'Intel.*Arc')
$win10 = $MockWin10 -or ([Environment]::OSVersion.Version.Build -lt 22000)
Out-Line "[PC]   $gpu"

# --- OptiScaler files (official release, hash checked) ---
function Get-Verified([hashtable]$asset, [string]$path) {
    if ((Test-Path -LiteralPath $path) -and (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $asset.Sha) { return }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmp = "$path.download"
    Invoke-WebRequest -Uri $asset.Url -UseBasicParsing -TimeoutSec 600 -OutFile $tmp
    if ((Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash -ne $asset.Sha) { Remove-Item -LiteralPath $tmp -Force; throw "SHA-256 mismatch: $($asset.Url)" }
    Move-Item -LiteralPath $tmp -Destination $path -Force
}

$src = $SourceDir
if (-not $src) {
    $src = Join-Path $cache 'files'
    if (-not (Test-Path -LiteralPath (Join-Path $src 'OptiScaler.dll'))) {
        try {
            Out-Line '[GET]  OptiScaler 0.9.4 (55 MB) from github.com/optiscaler/OptiScaler'
            Write-Host 'SI OPTI: downloading OptiScaler 0.9.4 (55 MB) from GitHub, this window closes by itself...'
            $arch = Join-Path $cache 'OptiScaler_0.9.4.7z'
            Get-Verified $opti $arch
            $7zr = Join-Path $tools '7zr.exe'
            Get-Verified $sevenZ $7zr
            $null = & $7zr x $arch "-o$src" -y
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $src 'OptiScaler.dll'))) { throw '7zr could not extract the archive' }
        } catch { Out-Line "[FAIL] Download/extract failed: $($_.Exception.Message)"; exit 5 }
    }
}

# --- Install (a previous SI OPTI install of this folder is removed first) ---
if (Test-Path -LiteralPath $manifestPath) { Invoke-Undo | Out-Null }
$added = [System.Collections.Generic.List[string]]::new()
$dirs  = [System.Collections.Generic.List[string]]::new()
$srcFull = (Resolve-Path -LiteralPath $src).Path.TrimEnd('\')
try {
    foreach ($f in Get-ChildItem -LiteralPath $srcFull -Recurse -File) {
        $rel = $f.FullName.Substring($srcFull.Length + 1)
        if ($notCopied -contains $rel -or $Skip -contains $rel) { continue }
        if ($rel -eq 'OptiScaler.dll') { $rel = $Dll }
        $dest = Join-Path $target $rel
        $dDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $dDir)) {
            New-Item -ItemType Directory -Force -Path $dDir | Out-Null
            $dirs.Add($dDir.Substring($target.TrimEnd('\').Length).TrimStart('\'))
        }
        if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath "$dest.sigame.bak")) {
            Copy-Item -LiteralPath $dest -Destination "$dest.sigame.bak" -Force
            Out-Line "[BAK]  $rel (the game's own file, kept as .sigame.bak)"
        }
        Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
        $added.Add($rel)
    }
} catch {
    [pscustomobject]@{ GameKey = $GameKey; Added = @($added); Dirs = @($dirs) } | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Invoke-Undo | Out-Null
    Out-Line "[FAIL] Copy failed ($($_.Exception.Message)): everything put back."; exit 6
}
[pscustomobject]@{ Preset = 'si-opti'; GameKey = $GameKey; Version = '0.9.4'; Dll = $Dll; At = [datetime]::Now.ToString('s')
    Added = @($added); Dirs = @($dirs) } | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Out-Line "[SET]  $($added.Count) OptiScaler files in $(Split-Path -Leaf $target), OptiScaler.dll as $Dll"

# --- OptiScaler.ini for this GPU and this game ---
$ini = Join-Path $target 'OptiScaler.ini'
$lines = [System.Collections.Generic.List[string]]::new([string[]](Get-Content -LiteralPath $ini))
function Set-Ini([string]$key, [string]$value, [string]$why) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^$([regex]::Escape($key))\s*=") { $lines[$i] = "$key=$value"; Out-Line "[SET]  $key=$value ($why)"; return }
    }
    Out-Line "[SKIP] $key not in this OptiScaler.ini"
}
if ($fsr4) {
    Set-Ini 'Dx12Upscaler' 'fsr31' 'FSR4 on your Radeon'
    Set-Ini 'Dx11Upscaler' 'fsr31_12' 'FSR4 through DX12'
    Set-Ini 'VulkanUpscaler' 'fsr31_12' 'FSR4 through DX12'
    Set-Ini 'Fsr4Update' 'true' 'FSR 3.x -> FSR4'
    if ($win10) { Set-Ini 'FsrAgilitySDKUpgrade' 'true' 'FSR4 on Windows 10' }
} elseif ($arc) {
    Set-Ini 'Dx12Upscaler' 'xess' 'XeSS on your Arc'
    Set-Ini 'Dx11Upscaler' 'xess' 'native DX11 XeSS, Arc only'
    Set-Ini 'VulkanUpscaler' 'xess' 'XeSS on your Arc'
}
foreach ($s in $Set) {
    $only = ''; $kv = $s
    if ($s -match '^([a-z,]+):(.+)$') { $only = $Matches[1]; $kv = $Matches[2] }
    if ($only -and ($only -split ',') -notcontains $maker) { continue }
    $k, $v = $kv -split '=', 2
    Set-Ini $k.Trim() $v.Trim() 'OptiScaler wiki, this game'
}
[System.IO.File]::WriteAllLines($ini, $lines)

Out-Line "[OK]   OptiScaler ready. In the game pick DLSS, FSR or XeSS, then press Insert for the OptiScaler menu."
exit 0
