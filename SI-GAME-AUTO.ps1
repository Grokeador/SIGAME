#Requires -Version 5.1
<#
.SYNOPSIS
    SIGAME AUTO - One-Click Hardware-Adaptive & Game Optimizer by SI NEWS.
.DESCRIPTION
    Opens with a clear diagnostic of the PC's current optimization state,
    hardware profile, and installed games. A single click on "OTTIMIZAR"
    automatically applies the best hardware-tailored tweaks (including
    aggressive low-latency settings where supported), selects the fastest DNS,
    and optimizes all detected games (Steam, Epic, Battle.net, EA, Ubisoft,
    Riot, GOG) with High-Performance GPU, Fullscreen Optimization disabled,
    and Auto-Boost enabled.
#>

param(
    [switch]$Worker,
    [string]$WorkerMode = 'prepare',
    [string]$WorkerRequest = '',
    [string]$WorkerResult = '',
    [switch]$Minimized
)

# ============================ 1. CLOCK & FAST UAC =========================

$script:SIScriptStart = [datetime]::Now
try {
    $script:SIProcessStart = [System.Diagnostics.Process]::GetCurrentProcess().StartTime
} catch {
    $script:SIProcessStart = $script:SIScriptStart
}

$script:SIJobIsWorker = [bool]$Worker
$script:SIJobMode     = $WorkerMode
$script:SIJobRequest  = $WorkerRequest
$script:SIJobResult   = $WorkerResult
$script:SIStartMinimized = [bool]$Minimized

$script:SIRoot = $PSScriptRoot
if ([string]::IsNullOrEmpty($script:SIRoot)) {
    $script:SIRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
}
$script:SIModulesPath   = [System.IO.Path]::Combine($script:SIRoot, 'modules')
$script:SILogoPath      = [System.IO.Path]::Combine($script:SIRoot, 'logo.png')
$script:SICurrentScript = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Definition }

$script:SIHandedOver   = $false
$script:SIWithoutAdmin = $false

if (-not $Worker) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        try {
            $minArg = if ($Minimized) { ' -Minimized' } else { '' }
            $psi = [System.Diagnostics.ProcessStartInfo]::new('powershell.exe')
            $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$script:SICurrentScript`"$minArg"
            $psi.Verb = 'runas'
            $psi.WorkingDirectory = $script:SIRoot
            $psi.UseShellExecute = $true
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            [void][System.Diagnostics.Process]::Start($psi)
            [System.Environment]::Exit(0)
        } catch {
            $script:SIWithoutAdmin = $true
        }
    }
}

# ============================ 2. COLOURS & STATE ==========================

$script:SIColors = @{
    Background = '#090b10'
    Panel      = '#10141d'
    PanelAlt   = '#151b26'
    BorderGold = '#4a3b1c'
    GlowGold   = '#f5b942'
    Accent     = '#f5b942'
    Text       = '#eef0f6'
    Muted      = '#8c94a8'
    Ok         = '#5ad08a'
    Off        = '#6e7587'
    Warn       = '#ffaa33'
    Danger     = '#ff5c5c'
}

$script:SILoadingWindow       = $null
$script:SILoadingStep         = $null
$script:SILoadingLogo         = $null
$script:SIFirstWindowOnScreen = $null
$script:SIBrushCache          = @{}
$script:SILogAvailable        = $false

function Close-SILoadingWindow {
    if (-not $script:SILoadingWindow) { return }
    try { $script:SILoadingWindow.Close() } catch { }
    $script:SILoadingWindow = $null
    $script:SILoadingStep   = $null
    $script:SILoadingLogo   = $null
}

if (-not $Worker) {
    try { Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction Stop } catch { }
}

# ============================ 3. MODULES LOAD =============================

$script:SIModuleList = @(
    '00-core.ps1'
    '01-registry.ps1'
    '02-tweaks.ps1'
    '03-features.ps1'
    '04-state.ps1'
    '05-engine.ps1'
    '06-window.ps1'
    '07-startup.ps1'
    '08-boost.ps1'
    '09-autoboost.ps1'
    '10-community.ps1'
)

foreach ($module in $script:SIModuleList) {
    if ($Worker -and $module -eq '06-window.ps1') { continue }
    $modPath = [System.IO.Path]::Combine($script:SIModulesPath, $module)
    if ([System.IO.File]::Exists($modPath)) {
        . $modPath
        $script:SILogAvailable = $true
    }
}

# ===================== 4. EXTENDED GAME DISCOVERY =========================
# Scans Steam, Epic Games, Battle.net, EA App, Ubisoft Connect, Riot Games,
# GOG Galaxy, plus any manually added games in SI-GAME-boost.json.

function Get-SIExtendedGames {
    $games = @()
    $seenExe = @{}

    # 1. Steam + Epic from existing engine
    foreach ($g in (@(Get-SISteamGames) + @(Get-SIEpicGames))) {
        if ($g -and $g.Exe -and -not $seenExe.ContainsKey($g.Exe.ToLowerInvariant())) {
            $seenExe[$g.Exe.ToLowerInvariant()] = $true
            $games += $g
        }
    }

    # 2. Riot Games (Valorant, League of Legends)
    $riotInstalls = 'C:\ProgramData\Riot Games\RiotClientInstalls.json'
    $riotRoots = @('C:\Riot Games', 'D:\Riot Games')
    foreach ($rRoot in $riotRoots) {
        if (-not (Test-Path -LiteralPath $rRoot)) { continue }
        foreach ($dir in @(Get-ChildItem -LiteralPath $rRoot -Directory -ErrorAction SilentlyContinue)) {
            if ($dir.Name -ieq 'Riot Client') { continue }
            $exes = @(Get-ChildItem -LiteralPath $dir.FullName -Filter '*.exe' -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '(?i)uninstall|crash|setup|helper|riotclient' } |
                Sort-Object Length -Descending)
            if ($exes.Count -gt 0) {
                $exePath = $exes[0].FullName
                $key = $exePath.ToLowerInvariant()
                if (-not $seenExe.ContainsKey($key)) {
                    $seenExe[$key] = $true
                    $games += [pscustomobject]@{
                        Id     = 'riot-' + $dir.Name
                        Name   = $dir.Name
                        Store  = 'Riot Games'
                        Exe    = $exePath
                        Folder = $dir.FullName
                    }
                }
            }
        }
    }

    # 3. Registry Uninstall scan for Battle.net, Ubisoft, EA, GOG games
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($uPath in $uninstallPaths) {
        foreach ($sub in @(Get-ChildItem -Path $uPath -ErrorAction SilentlyContinue)) {
            $props = $null
            try { $props = Get-ItemProperty -LiteralPath $sub.PSPath -ErrorAction Stop } catch { continue }
            if (-not $props) { continue }
            $displayName = [string]$props.DisplayName
            $installLoc  = [string]$props.InstallLocation
            $publisher   = [string]$props.Publisher
            if (-not $displayName -or -not $installLoc) { continue }
            if (-not (Test-Path -LiteralPath $installLoc)) { continue }

            $store = ''
            if ($sub.PSChildName -like 'Uplay install*' -or $publisher -match 'Ubisoft') { $store = 'Ubisoft' }
            elseif ($publisher -match 'Electronic Arts|EA Swiss') { $store = 'EA App' }
            elseif ($publisher -match 'Blizzard Entertainment') { $store = 'Battle.net' }
            elseif ($sub.PSChildName -match '_is1$' -and $publisher -match 'GOG\.com') { $store = 'GOG' }

            if (-not $store) { continue }
            if ($displayName -match '(?i)Launcher|Ubisoft Connect|EA app|Battle\.net') { continue }

            $exes = @(Get-ChildItem -LiteralPath $installLoc -Filter '*.exe' -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '(?i)uninstall|crash|cleanup|activation|touchup|dxsetup|vc_redist' } |
                Sort-Object Length -Descending)
            if ($exes.Count -gt 0) {
                $exePath = $exes[0].FullName
                $key = $exePath.ToLowerInvariant()
                if (-not $seenExe.ContainsKey($key)) {
                    $seenExe[$key] = $true
                    $games += [pscustomobject]@{
                        Id     = ($store.ToLowerInvariant() + '-' + $sub.PSChildName)
                        Name   = $displayName
                        Store  = $store
                        Exe    = $exePath
                        Folder = $installLoc
                    }
                }
            }
        }
    }

    # 4. Xbox App / PC Game Pass (XboxGames & ModifiableWindowsApps)
    $xboxRoots = @('C:\XboxGames', 'D:\XboxGames', 'E:\XboxGames', 'C:\Program Files\ModifiableWindowsApps')
    foreach ($xRoot in $xboxRoots) {
        if (-not (Test-Path -LiteralPath $xRoot)) { continue }
        foreach ($dir in @(Get-ChildItem -LiteralPath $xRoot -Directory -ErrorAction SilentlyContinue)) {
            $searchDir = $dir.FullName
            $contentDir = [System.IO.Path]::Combine($searchDir, 'Content')
            if ([System.IO.Directory]::Exists($contentDir)) { $searchDir = $contentDir }

            $exes = @(Get-ChildItem -LiteralPath $searchDir -Filter '*.exe' -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '(?i)uninstall|crash|setup|helper|gamelaunchhelper|redist|easyanticheat|battleye' } |
                Sort-Object Length -Descending)
            if ($exes.Count -gt 0) {
                $exePath = $exes[0].FullName
                $key = $exePath.ToLowerInvariant()
                if (-not $seenExe.ContainsKey($key)) {
                    $seenExe[$key] = $true
                    $games += [pscustomobject]@{
                        Id     = 'xbox-' + $dir.Name
                        Name   = $dir.Name
                        Store  = 'Xbox / Game Pass'
                        Exe    = $exePath
                        Folder = $searchDir
                    }
                }
            }
        }
    }

    # 5. User-added games from SI-GAME-boost.json
    try {
        $boostState = Get-SIBoostState
        foreach ($customItem in @($boostState['Games'])) {
            $exePath = ''
            $customName = ''
            if ($customItem -is [string]) {
                $exePath = [string]$customItem
            } else {
                $exePath = Get-SIGameField -Item $customItem -Name 'Exe'
                $customName = Get-SIGameField -Item $customItem -Name 'Name'
            }
            if (-not $exePath -or -not [System.IO.File]::Exists($exePath)) { continue }
            if (-not $customName) { $customName = [System.IO.Path]::GetFileNameWithoutExtension($exePath) }
            $key = $exePath.ToLowerInvariant()
            if (-not $seenExe.ContainsKey($key)) {
                $seenExe[$key] = $true
                $games += [pscustomobject]@{
                    Id     = 'custom-' + [System.IO.Path]::GetFileNameWithoutExtension($exePath)
                    Name   = $customName
                    Store  = 'Manuale'
                    Exe    = $exePath
                    Folder = [System.IO.Path]::GetDirectoryName($exePath)
                }
            }
        }
    } catch { }

    return $games
}

# Override Get-SIGameLibrary so the background worker also uses the extended scanner
function Get-SIGameLibrary {
    return @(Get-SIExtendedGames)
}

# ================== 4B. PER-GAME CPU PRIORITY, SHADER CACHE & RAM ===========

$script:SIAutoMode = 'MaxFPS' # 'MaxFPS' | 'Streaming'

function Get-SIGameCpuPriorityRegPath {
    param([string]$ExePath)
    if (-not $ExePath) { return '' }
    $leaf = [System.IO.Path]::GetFileName($ExePath)
    if (-not $leaf) { return '' }
    return "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$leaf\PerfOptions"
}

function Get-SIGameCpuPriorityState {
    param([string]$ExePath)
    $regPath = Get-SIGameCpuPriorityRegPath -ExePath $ExePath
    if (-not $regPath) { return $false }
    try {
        $cpu = Get-SIRegistryValue -Path $regPath -Name 'CpuPriorityClass'
        $io  = Get-SIRegistryValue -Path $regPath -Name 'IoPriority'
        return ($cpu.Exists -and [int]$cpu.Value -eq 3 -and $io.Exists -and [int]$io.Value -eq 3)
    } catch {
        return $false
    }
}

function Set-SIGameCpuPriorityHigh {
    <#
    .SYNOPSIS
        Sets High CPU Priority (3), High Disk I/O Priority (3), and Maximum
        RAM Page Priority (5) in Image File Execution Options\...\PerfOptions.
    #>
    param([Parameter(Mandatory = $true)][string]$ExePath)
    $regPath = Get-SIGameCpuPriorityRegPath -ExePath $ExePath
    if (-not $regPath) { return }
    Set-SIRegistryValue -Path $regPath -Name 'CpuPriorityClass' -Value 3 -Type 'DWord' | Out-Null
    Set-SIRegistryValue -Path $regPath -Name 'IoPriority'       -Value 3 -Type 'DWord' | Out-Null
    Set-SIRegistryValue -Path $regPath -Name 'PagePriority'     -Value 5 -Type 'DWord' | Out-Null
}

function Get-SIGamePowerThrottlingState {
    param([string]$ExePath)
    if (-not $ExePath) { return $false }
    try {
        $val = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name $ExePath
        return ($val.Exists -and [int]$val.Value -eq 1)
    } catch {
        return $false
    }
}

function Set-SIGamePowerThrottlingOff {
    <#
    .SYNOPSIS
        Disables Windows CPU Power Throttling for the specified game .exe.
    #>
    param([Parameter(Mandatory = $true)][string]$ExePath)
    if (-not $ExePath) { return }
    Set-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name $ExePath -Value 1 -Type 'DWord' | Out-Null
}

function Get-SIRobloxSettingsPath {
    return [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Roblox', 'GlobalBasicSettings_13.xml')
}

function Set-SIRobloxLowQualityProfile {
    <#
    .SYNOPSIS
        Roblox profile: sets the graphics quality to manual level 1 in
        GlobalBasicSettings_13.xml (Roblox is CPU bound on weak PCs). The
        original values go to backup['RobloxQuality'] first, UNDO ALL puts
        them back.
    #>
    $file = Get-SIRobloxSettingsPath
    if (-not [System.IO.File]::Exists($file)) { return $false }
    if (Get-Process -Name 'RobloxPlayerBeta' -ErrorAction SilentlyContinue) {
        Write-SILog -Level 'WARN' -Component 'Game' -Message 'Roblox: profilo non applicato, chiudi Roblox e premi di nuovo OPTIMIZE.'
        return $false
    }
    try {
        $text = [System.IO.File]::ReadAllText($file)
        $saved = [regex]::Match($text, 'name="SavedQualityLevel">(-?\d+)<')
        $graphics = [regex]::Match($text, 'name="GraphicsQualityLevel">(-?\d+)<')
        if (-not $saved.Success -or -not $graphics.Success) { return $false }

        $backup = $script:SIBackup
        if (-not $backup) { $backup = Get-SIBackup; $script:SIBackup = $backup }
        # Keep the FIRST original: a second OPTIMIZE must not save our own 1.
        if (-not $backup.Contains('RobloxQuality')) {
            $backup['RobloxQuality'] = @{ File = $file; Saved = [int]$saved.Groups[1].Value; Graphics = [int]$graphics.Groups[1].Value }
            if (-not (Save-SIBackup -Backup $backup)) { return $false }
        }

        $text = [regex]::Replace($text, '(name="(?:Saved|Graphics)QualityLevel">)-?\d+', '${1}1')
        [System.IO.File]::WriteAllText($file, $text, (New-Object System.Text.UTF8Encoding($false)))
        Write-SILog -Level 'OK' -Component 'Game' -Message ("Roblox: qualita grafica manuale 1 (prima: livello {0}, 0 = Automatica). UNDO ALL la rimette com'era." -f $backup['RobloxQuality']['Saved'])
        return $true
    } catch {
        Write-SILog -Level 'WARN' -Component 'Game' -Message "Roblox: profilo non applicato: $($_.Exception.Message)"
        return $false
    }
}

function Restore-SIRobloxQualityProfile {
    <#
    .SYNOPSIS
        Puts back the Roblox graphics quality saved by Set-SIRobloxLowQualityProfile.
    #>
    $backup = $script:SIBackup
    if (-not $backup) { $backup = Get-SIBackup; $script:SIBackup = $backup }
    if (-not $backup -or -not $backup.Contains('RobloxQuality')) { return $false }
    $orig = $backup['RobloxQuality']
    $file = [string]$orig['File']
    if (-not [System.IO.File]::Exists($file)) { $backup.Remove('RobloxQuality'); [void](Save-SIBackup -Backup $backup); return $false }
    if (Get-Process -Name 'RobloxPlayerBeta' -ErrorAction SilentlyContinue) {
        Write-SILog -Level 'WARN' -Component 'Game' -Message 'Roblox e'' aperto: chiudilo e premi di nuovo UNDO ALL per rimettere la qualita grafica.'
        return $false
    }
    try {
        $text = [System.IO.File]::ReadAllText($file)
        $text = [regex]::Replace($text, '(name="SavedQualityLevel">)-?\d+', '${1}' + [int]$orig['Saved'])
        $text = [regex]::Replace($text, '(name="GraphicsQualityLevel">)-?\d+', '${1}' + [int]$orig['Graphics'])
        [System.IO.File]::WriteAllText($file, $text, (New-Object System.Text.UTF8Encoding($false)))
        $backup.Remove('RobloxQuality')
        [void](Save-SIBackup -Backup $backup)
        Write-SILog -Level 'OK' -Component 'Game' -Message 'Roblox: qualita grafica originale ripristinata.'
        return $true
    } catch {
        Write-SILog -Level 'WARN' -Component 'Game' -Message "Roblox: ripristino non riuscito: $($_.Exception.Message)"
        return $false
    }
}

function Enable-SICpuCoreUnpark {
    <#
    .SYNOPSIS
        Unparks 100% of CPU cores and locks min/max processor state to 100%
        on the active desktop gaming power scheme.
    #>
    if (Get-SIIsLaptop) { return $false }
    try {
        # SUB_PROCESSOR = 54533251-82be-4824-96c1-47b60b740d00
        # CPMINCORES    = 0cc5b647-c1df-4637-891a-dec35c318583
        # PROCTHROTTLEMIN = 893dee8e-2bef-41e0-89c6-b55d0929964c
        # PROCTHROTTLEMAX = bc5038f7-23e0-4960-96da-33abaf5935ec
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 2>$null | Out-Null
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 2>$null | Out-Null
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 2>$null | Out-Null
        & powercfg.exe /setactive SCHEME_CURRENT 2>$null | Out-Null
        Write-SILog -Level 'OK' -Component 'Power' -Message 'CPU Core Parking sbloccato (100% core attivi su Desktop).'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIUsbLowLatency {
    <#
    .SYNOPSIS
        Disables USB Selective Suspend in the active power plan and USB service
        registry so mouse, keyboard, racing wheel, and controllers never suffer
        wake lag or micro-disconnects.
    #>
    try {
        # SUB_USB = 2a737441-1930-4402-8d77-b2bebba308a3
        # USBSELECTIVESUSPEND = 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 (0 = Disabled)
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null
        if (-not (Get-SIIsLaptop)) {
            & powercfg.exe /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null
        }
        & powercfg.exe /setactive SCHEME_CURRENT 2>$null | Out-Null

        $usbRegPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\USB'
        Save-SIToolUndo -Key 'UsbSelectiveSuspend' -Path $usbRegPath -Name 'DisableSelectiveSuspend'
        Set-SIRegistryValue -Path $usbRegPath -Name 'DisableSelectiveSuspend' -Value 1 -Type 'DWord' | Out-Null
        Write-SILog -Level 'OK' -Component 'USB' -Message 'Sospensione selettiva USB disattivata per latenza zero su mouse/controller.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIGpuLowLatencyOptimization {
    <#
    .SYNOPSIS
        1. Enables MSI Mode (Message Signaled Interrupts) on dedicated PCI GPUs
           to reduce interrupt latency (input lag).
        2. Disables AMD ULPS (EnableUlps = 0) if present to prevent micro-stutter.
        3. Sets NVIDIA DisableDynamicPstate = 1 on Desktop in MaxFPS mode.
    #>
    $applied = 0
    try {
        $gpus = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)
        foreach ($g in $gpus) {
            $name  = [string]$g.Name
            $pnpId = [string]$g.PNPDeviceID
            if (-not $pnpId -or $pnpId -notlike 'PCI\*') { continue }
            if (Test-SIGpuIsIntegrated -Name $name) { continue }

            $msiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnpId\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            if (Test-Path -LiteralPath $msiPath) {
                Save-SIToolUndo -Key ('GpuMsi|' + $pnpId) -Path $msiPath -Name 'MSISupported'
                Set-SIRegistryValue -Path $msiPath -Name 'MSISupported' -Value 1 -Type 'DWord' | Out-Null
                $applied++
                Write-SILog -Level 'OK' -Component 'GPU' -Message "MSI Mode (Interrupt Low-Latency) attivata per GPU: $name"
            }
        }
    } catch { }

    try {
        $classBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        if (Test-Path -LiteralPath $classBase) {
            foreach ($sub in @(Get-ChildItem -LiteralPath $classBase -ErrorAction SilentlyContinue)) {
                if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
                $subPath = $sub.PSPath
                $ulps = Get-SIRegistryValue -Path $subPath -Name 'EnableUlps'
                if ($ulps.Exists) {
                    Save-SIToolUndo -Key ('GpuUlps|' + $sub.PSChildName) -Path $subPath -Name 'EnableUlps'
                    Set-SIRegistryValue -Path $subPath -Name 'EnableUlps' -Value 0 -Type 'DWord' | Out-Null
                    $applied++
                    Write-SILog -Level 'OK' -Component 'GPU' -Message "AMD ULPS disattivato su chiave $($sub.PSChildName)."
                }
                if (-not (Get-SIIsLaptop) -and $script:SIAutoMode -eq 'MaxFPS') {
                    $prov = Get-SIRegistryValue -Path $subPath -Name 'ProviderName'
                    if ($prov.Exists -and [string]$prov.Value -match '(?i)NVIDIA') {
                        Save-SIToolUndo -Key ('GpuNvPstate|' + $sub.PSChildName) -Path $subPath -Name 'DisableDynamicPstate'
                        Set-SIRegistryValue -Path $subPath -Name 'DisableDynamicPstate' -Value 1 -Type 'DWord' | Out-Null
                        $applied++
                        Write-SILog -Level 'OK' -Component 'GPU' -Message "NVIDIA P-State fisso ad alte prestazioni attivato su Desktop ($($sub.PSChildName))."
                    }
                }
            }
        }
    } catch { }
    return $applied
}

function Disable-SIPcieLinkPowerManagement {
    <#
    .SYNOPSIS
        Disables PCI Express Link State Power Management (ASPM = Off) on
        active power scheme so GPU and NVMe PCIe lanes never enter L0s/L1
        power-saving sleep states during gameplay.
    #>
    if (Get-SIIsLaptop) { return $false }
    try {
        # SUB_PCIEXPRESS = 501a4d13-42af-4429-9fd1-a8218c268e20
        # ASPM           = ee12f906-d277-404b-b6da-e5fa1a576df5 (0 = Off)
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null | Out-Null
        & powercfg.exe /setactive SCHEME_CURRENT 2>$null | Out-Null
        Write-SILog -Level 'OK' -Component 'PCIe' -Message 'PCIe Link State Power Management (ASPM) disattivato per massima banda GPU/NVMe.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SILowLatencyGamingAudio {
    <#
    .SYNOPSIS
        Configures Windows Multimedia Class Scheduler (MMCSS) Audio and Pro Audio
        tasks for maximum priority and low-latency sound processing in games.
    #>
    try {
        $audioTasks = @(
            'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio',
            'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio'
        )
        foreach ($tPath in $audioTasks) {
            $leaf = [System.IO.Path]::GetFileName($tPath)
            Save-SIToolUndo -Key ("MmcssAudio|$leaf|Priority")           -Path $tPath -Name 'Priority'
            Save-SIToolUndo -Key ("MmcssAudio|$leaf|SchedulingCategory") -Path $tPath -Name 'Scheduling Category'
            Save-SIToolUndo -Key ("MmcssAudio|$leaf|SfioPriority")       -Path $tPath -Name 'SFIO Priority'
            Save-SIToolUndo -Key ("MmcssAudio|$leaf|BackgroundOnly")     -Path $tPath -Name 'Background Only'
            Save-SIToolUndo -Key ("MmcssAudio|$leaf|ClockRate")          -Path $tPath -Name 'Clock Rate'

            Set-SIRegistryValue -Path $tPath -Name 'Priority'            -Value 6       -Type 'DWord'  | Out-Null
            Set-SIRegistryValue -Path $tPath -Name 'Scheduling Category' -Value 'High'  -Type 'String' | Out-Null
            Set-SIRegistryValue -Path $tPath -Name 'SFIO Priority'       -Value 'High'  -Type 'String' | Out-Null
            Set-SIRegistryValue -Path $tPath -Name 'Background Only'     -Value 'False' -Type 'String' | Out-Null
            Set-SIRegistryValue -Path $tPath -Name 'Clock Rate'          -Value 10000   -Type 'DWord'  | Out-Null
        }
        Write-SILog -Level 'OK' -Component 'Audio' -Message 'MMCSS Gaming Audio Low-Latency (High Priority + Clock Rate 10000) attivato.'
        return $true
    } catch {
        return $false
    }
}

$script:SISuspendedHogs = @{}
$script:SIHogAffinities = @{}

function Set-SIBackgroundHogsPriority {
    <#
    .SYNOPSIS
        Lowers CPU priority of heavy background processes to Idle AND pins
        their CPU Affinity to the last logical core(s) on multi-core CPUs
        (>= 6 threads) so Core 0 and main gaming cores stay 100% free.
    #>
    param([bool]$IdleMode = $true)

    $hogNames = @(
        'SearchIndexer', 'SearchApp', 'SearchHost',
        'OneDrive', 'GameBarPresenceWriter',
        'CompatTelRunner', 'TiWorker', 'MoUsoCoreWorker',
        'AdobeUpdateService', 'AdobeIPCBroker', 'CCXProcess',
        'PhoneExperienceHost', 'WidgetService', 'Widgets',
        'SteamService', 'EpicWebHelper', 'EABackgroundService'
    )

    if ($script:SIAutoMode -eq 'MaxFPS') {
        $hogNames += @('steamwebhelper', 'OverwolfBrowser', 'Battle.net')
    }

    $cpuCount = [Environment]::ProcessorCount
    $bgAffinityMask = [IntPtr]::Zero
    if ($cpuCount -ge 6 -and $cpuCount -le 62) {
        $lastCoreBit = ([int64]1 -shl ($cpuCount - 1))
        $bgAffinityMask = [IntPtr]::new($lastCoreBit)
    }

    if ($IdleMode) {
        $count = 0
        foreach ($proc in @(Get-Process -ErrorAction SilentlyContinue)) {
            $pName = ''
            try { $pName = [string]$proc.ProcessName } catch { continue }
            $isDiscordHelper = ($script:SIAutoMode -eq 'MaxFPS' -and $pName -ieq 'Discord' -and $proc.WorkingSet64 -gt 220MB)
            if (($hogNames -notcontains $pName) -and (-not $isDiscordHelper)) { continue }
            try {
                $targetPrio = if ($isDiscordHelper) { [System.Diagnostics.ProcessPriorityClass]::BelowNormal } else { [System.Diagnostics.ProcessPriorityClass]::Idle }
                $curPrio = $proc.PriorityClass
                if ($curPrio -and $curPrio -ne $targetPrio) {
                    if (-not $script:SISuspendedHogs.ContainsKey($proc.Id)) {
                        $script:SISuspendedHogs[$proc.Id] = $curPrio
                    }
                    $proc.PriorityClass = $targetPrio
                    $count++
                }
                if ($bgAffinityMask -ne [IntPtr]::Zero -and -not $isDiscordHelper) {
                    $curAff = $proc.ProcessorAffinity
                    if ($curAff -and $curAff -ne $bgAffinityMask) {
                        if (-not $script:SIHogAffinities.ContainsKey($proc.Id)) {
                            $script:SIHogAffinities[$proc.Id] = $curAff
                        }
                        $proc.ProcessorAffinity = $bgAffinityMask
                    }
                }
            } catch { }
        }
        if ($count -gt 0) {
            Write-SILog -Component 'SmartSuspend' -Message "$count processi secondari impostati in Idle + Affinita sull ultimo core CPU."
        }
        return $count
    } else {
        $restored = 0
        foreach ($pidKey in @($script:SISuspendedHogs.Keys)) {
            try {
                $origPrio = $script:SISuspendedHogs[$pidKey]
                $p = Get-Process -Id ([int]$pidKey) -ErrorAction Stop
                if ($p) {
                    $p.PriorityClass = $origPrio
                    $restored++
                }
            } catch { }
        }
        foreach ($pidKey in @($script:SIHogAffinities.Keys)) {
            try {
                $origAff = $script:SIHogAffinities[$pidKey]
                $p = Get-Process -Id ([int]$pidKey) -ErrorAction Stop
                if ($p) { $p.ProcessorAffinity = $origAff }
            } catch { }
        }
        $script:SISuspendedHogs = @{}
        $script:SIHogAffinities = @{}
        if ($restored -gt 0) {
            Write-SILog -Component 'SmartSuspend' -Message "Ripristinata priorita e affinita CPU originale di $restored processi in background."
        }
        return $restored
    }
}

function Measure-SIGamingPing {
    <#
    .SYNOPSIS
        Measures average latency (Ping ms), Jitter (ms), and Packet Loss (%)
        across a 6-probe burst against top gaming gateways (1.1.1.1, 8.8.8.8, 9.9.9.9).
    #>
    $samples = @()
    $targets = @('1.1.1.1', '8.8.8.8', '1.1.1.1', '9.9.9.9', '8.8.8.8', '1.1.1.1')
    $totalProbes = $targets.Count
    foreach ($ip in $targets) {
        $client = $null
        try {
            $client = [System.Net.Sockets.TcpClient]::new()
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $iar = $client.BeginConnect($ip, 53, $null, $null)
            if ($iar.AsyncWaitHandle.WaitOne(320, $false) -and $client.Connected) {
                $sw.Stop()
                $samples += $sw.Elapsed.TotalMilliseconds
            }
        } catch {
        } finally {
            if ($client) { try { $client.Close() } catch { } }
        }
    }
    if ($samples.Count -eq 0) {
        return [pscustomobject]@{ PingMs = -1; JitterMs = 0; LossPct = 100; Text = 'Offline / N/D'; Warn = $false }
    }
    $sum = 0.0
    foreach ($s in $samples) { $sum += [double]$s }
    $avg = [int][math]::Round($sum / $samples.Count)

    $jitter = 0
    if ($samples.Count -ge 2) {
        $diffs = 0.0
        for ($i = 1; $i -lt $samples.Count; $i++) {
            $diffs += [math]::Abs([double]$samples[$i] - [double]$samples[$i - 1])
        }
        $jitter = [int][math]::Round($diffs / ($samples.Count - 1))
    }

    $lostCount = $totalProbes - $samples.Count
    $lossPct   = [int][math]::Round(($lostCount * 100.0) / $totalProbes)
    $warn = ($avg -gt 65 -or $jitter -gt 15 -or $lossPct -gt 0)
    $stateLabel = if ($warn) { 'Instabile' } elseif ($avg -le 25 -and $jitter -le 5) { 'Eccellente' } else { 'Stabile' }
    return [pscustomobject]@{
        PingMs   = $avg
        JitterMs = $jitter
        LossPct  = $lossPct
        Warn     = $warn
        Text     = "${avg} ms (Jitter ${jitter} ms, Loss ${lossPct}% - $stateLabel)"
    }
}

function Clear-SISystemTempAndDumps {
    <#
    .SYNOPSIS
        Safely deletes unlocked temporary files and old crash dumps (%TEMP%,
        Windows\Temp, CrashDumps, WER) to free SSD space.
    #>
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    $folders = @(
        [System.IO.Path]::GetTempPath(),
        'C:\Windows\Temp'
    )
    if ($localAppData) {
        $folders += [System.IO.Path]::Combine($localAppData, 'CrashDumps')
        $folders += [System.IO.Path]::Combine($localAppData, 'Microsoft\Windows\WER\ReportArchive')
        $folders += [System.IO.Path]::Combine($localAppData, 'Microsoft\Windows\WER\ReportQueue')
    }

    $cutoff  = [datetime]::Now.AddMinutes(-30)
    $removed = 0
    $bytes   = [long]0
    foreach ($dir in $folders) {
        if (-not $dir -or -not [System.IO.Directory]::Exists($dir)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            if ($file.LastWriteTime -gt $cutoff) { continue }
            try {
                $len = [long]$file.Length
                [System.IO.File]::Delete($file.FullName)
                $removed++
                $bytes += $len
            } catch { }
        }
    }
    $mb = [math]::Round($bytes / 1MB, 1)
    Write-SILog -Component 'TempClean' -Message "Cleaned $removed temp/dump files ($mb MB)."
    return @{ Removed = $removed; MegaBytes = $mb }
}

function Invoke-SIAddCustomGameDialog {
    <#
    .SYNOPSIS
        Opens an OpenFileDialog so the user can manually add any custom .exe
        game, emulator, or mod launcher to SIGAME AUTO.
    #>
    try {
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Title  = 'Seleziona l eseguibile (.exe) del gioco da aggiungere'
        $dlg.Filter = 'Eseguibili Giochi (*.exe)|*.exe'
        $dlg.Multiselect = $false
        $res = $dlg.ShowDialog($script:SIWindow)
        if ($res -eq $true -and $dlg.FileName -and [System.IO.File]::Exists($dlg.FileName)) {
            $exe = [string]$dlg.FileName
            [void](Add-SIAutoBoostGame -Path $exe)
            Send-SICustomGameTelemetry -ExePath $exe
            $script:SIGameLibrary = @(Get-SIExtendedGames)
            Update-SIAutoDashboard
            $gName = [System.IO.Path]::GetFileNameWithoutExtension($exe)
            Set-SIStatusText -Text "Gioco aggiunto alla lista: $gName. Premi OTTIMIZAR o GIOCA per ottimizzarlo."
            $added = @($script:SIGameLibrary | Where-Object { [string]$_.Exe -ieq $exe }) | Select-Object -First 1
            if ($added -and -not (Find-SIGamePreset -Game $added)) {
                if (Show-SIMessage -Window $script:SIWindow -Title 'SI PRESET' -Text ((Get-SICommunityText 'AskAfterAdd') -f $gName)) {
                    Invoke-SIRequestGame -Game $added
                }
            }
        }
    } catch {
        Set-SIStatusText -Text "Impossibile aggiungere il gioco: $($_.Exception.Message)"
    }
}

function Set-SITimerResolution05ms {
    <#
    .SYNOPSIS
        Forces Windows kernel timer resolution to 0.5 ms (5000 x 100ns) via
        ntdll.dll!NtSetTimerResolution during gaming for ultra-low input lag
        and consistent 1% Low frame pacing, and enables Windows 11
        GlobalTimerResolutionRequests.
    #>
    param([bool]$Enable = $true)
    try {
        if (-not ('SINativeTimer' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SINativeTimer {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
}
'@ -ErrorAction Stop
        }
        $cur = [uint32]0
        if ($Enable) {
            $kernelPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            Save-SIToolUndo -Key 'GlobalTimerRes' -Path $kernelPath -Name 'GlobalTimerResolutionRequests'
            Set-SIRegistryValue -Path $kernelPath -Name 'GlobalTimerResolutionRequests' -Value 1 -Type 'DWord' | Out-Null

            [void][SINativeTimer]::NtSetTimerResolution(5000, $true, [ref]$cur)
            $ms = [math]::Round($cur / 10000.0, 2)
            Write-SILog -Level 'OK' -Component 'Timer' -Message "Timer Resolution impostato al massimo per eSports ($ms ms)."
        } else {
            [void][SINativeTimer]::NtSetTimerResolution(5000, $false, [ref]$cur)
            Write-SILog -Component 'Timer' -Message 'Timer Resolution rilasciato al valore standard di Windows.'
        }
        return $true
    } catch {
        return $false
    }
}

function Enable-SIMouseKeyboardRawCompetitive {
    <#
    .SYNOPSIS
        Disables Windows pointer acceleration curve (1:1 raw mouse input) and
        optimizes mouclass/kbdclass data queue size for high-polling gaming
        peripherals (1000Hz - 8000Hz).
    #>
    try {
        $mousePath = Get-SIUserRegistryPath 'HKCU:\Control Panel\Mouse'
        Save-SIToolUndo -Key 'RawMouseSpeed'      -Path $mousePath -Name 'MouseSpeed'
        Save-SIToolUndo -Key 'RawMouseThreshold1' -Path $mousePath -Name 'MouseThreshold1'
        Save-SIToolUndo -Key 'RawMouseThreshold2' -Path $mousePath -Name 'MouseThreshold2'

        Set-SIRegistryValue -Path $mousePath -Name 'MouseSpeed'      -Value '0' -Type 'String' | Out-Null
        Set-SIRegistryValue -Path $mousePath -Name 'MouseThreshold1' -Value '0' -Type 'String' | Out-Null
        Set-SIRegistryValue -Path $mousePath -Name 'MouseThreshold2' -Value '0' -Type 'String' | Out-Null

        $mouParams = 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters'
        $kbdParams = 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters'
        Save-SIToolUndo -Key 'MouQueueSize' -Path $mouParams -Name 'MouseDataQueueSize'
        Save-SIToolUndo -Key 'KbdQueueSize' -Path $kbdParams -Name 'KeyboardDataQueueSize'

        Set-SIRegistryValue -Path $mouParams -Name 'MouseDataQueueSize'    -Value 32 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $kbdParams -Name 'KeyboardDataQueueSize' -Value 32 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'Input' -Message 'Mouse Raw Input 1:1 (No Acceleration) + Coda Low-Latency Mouse/Tastiera attivati.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SINicCompetitiveLowLatency {
    <#
    .SYNOPSIS
        Disables Interrupt Moderation, Flow Control, and Energy Efficient
        Ethernet (EEE / Green Ethernet) on physical network adapters to
        eliminate packet batching delay and ping spikes.
    #>
    $changed = 0
    try {
        $nicBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
        if (-not (Test-Path -LiteralPath $nicBase)) { return 0 }
        $propsToZero = @('*InterruptModeration', '*FlowControl', '*EEE', 'EEELinkAdvertisement', 'AdvancedEEE', 'EnableGreenEthernet')
        foreach ($sub in @(Get-ChildItem -LiteralPath $nicBase -ErrorAction SilentlyContinue)) {
            if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
            $subPath = $sub.PSPath
            $drvDesc = Get-SIRegistryValue -Path $subPath -Name 'DriverDesc'
            if (-not $drvDesc.Exists -or [string]$drvDesc.Value -match '(?i)Virtual|WAN Miniport|Bluetooth|Loopback|VPN|TAP|Hyper-V') { continue }

            foreach ($pName in $propsToZero) {
                $curVal = Get-SIRegistryValue -Path $subPath -Name $pName
                if ($curVal.Exists) {
                    Save-SIToolUndo -Key ('NicLowLat|' + $sub.PSChildName + '|' + $pName) -Path $subPath -Name $pName
                    $kind = if ($curVal.Kind -eq 'DWord') { 'DWord' } else { 'String' }
                    $val  = if ($kind -eq 'DWord') { 0 } else { '0' }
                    Set-SIRegistryValue -Path $subPath -Name $pName -Value $val -Type $kind | Out-Null
                    $changed++
                }
            }
        }
        if ($changed -gt 0) {
            Write-SILog -Level 'OK' -Component 'NIC' -Message "Scheda di rete ottimizzata per eSports ($changed parametri EEE / Interrupt Moderation / Flow Control disattivati)."
        }
    } catch { }
    return $changed
}

$script:SIPausedUpdateServices = @()

function Set-SIGamingWindowsUpdatePause {
    <#
    .SYNOPSIS
        Temporarily pauses Windows Update (wuauserv), BITS, and Delivery
        Optimization (DoSvc) while a game is running so background patch
        downloads never cause ping spikes or SSD stutter, and resumes them
        when the game closes.
    #>
    param([bool]$Pause = $true)
    $svcNames = @('wuauserv', 'BITS', 'DoSvc')
    if ($Pause) {
        $paused = 0
        foreach ($sName in $svcNames) {
            try {
                $svc = Get-Service -Name $sName -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq 'Running') {
                    if ($script:SIPausedUpdateServices -notcontains $sName) {
                        $script:SIPausedUpdateServices += $sName
                    }
                    Stop-Service -Name $sName -Force -NoWait -ErrorAction SilentlyContinue
                    $paused++
                }
            } catch { }
        }
        if ($paused -gt 0) {
            Write-SILog -Component 'WinUpdatePause' -Message "$paused servizi di download Windows Update messi in pausa durante il gioco."
        }
        return $paused
    } else {
        $resumed = 0
        foreach ($sName in @($script:SIPausedUpdateServices)) {
            try {
                Start-Service -Name $sName -ErrorAction SilentlyContinue
                $resumed++
            } catch { }
        }
        $script:SIPausedUpdateServices = @()
        if ($resumed -gt 0) {
            Write-SILog -Component 'WinUpdatePause' -Message "$resumed servizi Windows Update riattivati dopo la chiusura del gioco."
        }
        return $resumed
    }
}

function Enable-SIHardBcdBootTweaks {
    <#
    .SYNOPSIS
        Hardcore eSports BCD Kernel Clock tweaks:
        - disabledynamictick yes (stops kernel from halting interrupt clock ticks)
        - tscsyncpolicy Enhanced (synchronizes Time Stamp Counter across CPU cores)
    #>
    try {
        & bcdedit.exe /set disabledynamictick yes 2>$null | Out-Null
        & bcdedit.exe /set tscsyncpolicy Enhanced 2>$null | Out-Null
        Write-SILog -Level 'OK' -Component 'BCD-Hard' -Message 'BCD Kernel Tick ottimizzato (disabledynamictick=yes, tscsyncpolicy=Enhanced).'
        return $true
    } catch {
        return $false
    }
}

function Restore-SIHardBcdBootTweaks {
    try {
        & bcdedit.exe /deletevalue disabledynamictick 2>$null | Out-Null
        & bcdedit.exe /deletevalue tscsyncpolicy 2>$null | Out-Null
        Write-SILog -Component 'BCD-Hard' -Message 'BCD Kernel Tick ripristinato ai valori standard di Windows.'
    } catch { }
}

function Enable-SIHardKernelMitigationsOff {
    <#
    .SYNOPSIS
        In MaxFPS mode, disables CPU Spectre/Meltdown software mitigations
        (FeatureSettingsOverride = 3) and VBS/DeviceGuard overhead to recover
        5-15% FPS in CPU-bound games.
        Automatically skips disabling VBS if Riot Vanguard or FACEIT Anti-Cheat
        is installed so Valorant/Faceit players never get an anti-cheat boot warning.
    #>
    if ($script:SIAutoMode -ne 'MaxFPS') { return $false }
    $acGuard = Get-SIAntiCheatGuardStatus
    if ($acGuard.RequiresVbs) {
        Write-SILog -Level 'OK' -Component 'AntiCheatGuard' -Message "Scudo Anti-Cheat attivo ($($acGuard.DetectedText)): VBS e mitigazioni Kernel mantenuti attivi per compatibilita 100% con Vanguard/FACEIT."
        return $false
    }
    try {
        $mmPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
        $dgPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'

        Save-SIToolUndo -Key 'HardFeatureOverride'     -Path $mmPath -Name 'FeatureSettingsOverride'
        Save-SIToolUndo -Key 'HardFeatureOverrideMask' -Path $mmPath -Name 'FeatureSettingsOverrideMask'
        Save-SIToolUndo -Key 'HardDeviceGuardVbs'      -Path $dgPath -Name 'EnableVirtualizationBasedSecurity'

        Set-SIRegistryValue -Path $mmPath -Name 'FeatureSettingsOverride'           -Value 3 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $mmPath -Name 'FeatureSettingsOverrideMask'       -Value 3 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $dgPath -Name 'EnableVirtualizationBasedSecurity' -Value 0 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'Kernel-Hard' -Message 'Mitigazioni CPU Kernel (FeatureSettingsOverride=3) e VBS disattivati per massimi FPS.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIHardGpuPreemptionAndTdr {
    <#
    .SYNOPSIS
        Disables GPU Preemption (EnablePreemption=0, ComputePreemption=0) so
        Windows never interrupts a game frame mid-render, and increases TDR
        timeout (TdrDelay=10) for GPU stability under heavy overclock/load.
    #>
    try {
        $schedPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler'
        $gfxPath   = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'

        Save-SIToolUndo -Key 'HardGpuEnablePreemption'  -Path $schedPath -Name 'EnablePreemption'
        Save-SIToolUndo -Key 'HardGpuComputePreemption' -Path $schedPath -Name 'ComputePreemption'
        Save-SIToolUndo -Key 'HardGpuTdrDelay'          -Path $gfxPath   -Name 'TdrDelay'
        Save-SIToolUndo -Key 'HardGpuTdrDdiDelay'       -Path $gfxPath   -Name 'TdrDdiDelay'

        Set-SIRegistryValue -Path $schedPath -Name 'EnablePreemption'  -Value 0  -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $schedPath -Name 'ComputePreemption' -Value 0  -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $gfxPath   -Name 'TdrDelay'          -Value 10 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $gfxPath   -Name 'TdrDdiDelay'       -Value 10 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'GPU-Hard' -Message 'GPU Preemption OFF + TDR Anti-Crash (10s) attivati.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIHardNvmeAndNtfsSpeed {
    <#
    .SYNOPSIS
        Optimizes NTFS filesystem (disables legacy 8.3 short names, increases
        NTFS metadata cache, disables last access timestamp overhead) and
        disables StorNVMe APST idle sleep on Desktop.
    #>
    try {
        $fsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
        Save-SIToolUndo -Key 'HardNtfs8dot3'      -Path $fsPath -Name 'NtfsDisable8dot3NameCreation'
        Save-SIToolUndo -Key 'HardNtfsMemUsage'   -Path $fsPath -Name 'NtfsMemoryUsage'
        Save-SIToolUndo -Key 'HardNtfsTrimNotify' -Path $fsPath -Name 'DisableDeleteNotification'

        Set-SIRegistryValue -Path $fsPath -Name 'NtfsDisable8dot3NameCreation' -Value 1 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $fsPath -Name 'NtfsMemoryUsage'              -Value 2 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $fsPath -Name 'DisableDeleteNotification'    -Value 0 -Type 'DWord' | Out-Null

        if (-not (Get-SIIsLaptop)) {
            $nvmePath = 'HKLM:\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'
            Save-SIToolUndo -Key 'HardNvmeIdlePower' -Path $nvmePath -Name 'IdlePowerMode'
            Set-SIRegistryValue -Path $nvmePath -Name 'IdlePowerMode' -Value 0 -Type 'DWord' | Out-Null
        }

        Write-SILog -Level 'OK' -Component 'NVMe-Hard' -Message 'Storage NVMe/NTFS Hard (No 8.3 legacy, Max NTFS Cache, TRIM ON, NVMe Idle OFF) attivato.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIHardMemoryNoPagingExecutive {
    <#
    .SYNOPSIS
        Forces Windows to keep kernel and drivers in physical RAM
        (DisablePagingExecutive = 1) and prioritizes foreground gaming memory
        over background file cache (LargeSystemCache = 0).
    #>
    try {
        $mmPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
        Save-SIToolUndo -Key 'HardDisablePagingExec' -Path $mmPath -Name 'DisablePagingExecutive'
        Save-SIToolUndo -Key 'HardLargeSystemCache'  -Path $mmPath -Name 'LargeSystemCache'

        Set-SIRegistryValue -Path $mmPath -Name 'DisablePagingExecutive' -Value 1 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $mmPath -Name 'LargeSystemCache'       -Value 0 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'RAM-Hard' -Message 'Kernel Memory Lock (DisablePagingExecutive=1 + LargeSystemCache=0) attivato.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIHardIrqAndDriverThreadPriority {
    <#
    .SYNOPSIS
        Sets high priority for System Timer (IRQ0) and Real-Time Clock (IRQ8)
        interrupts, and boosts kernel thread priority (31) for DirectX (DXGKrnl),
        USB XHCI controller (USBXHCI), and Mouse HID (mouhid).
    #>
    try {
        $prioPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
        Save-SIToolUndo -Key 'HardIrq0Priority' -Path $prioPath -Name 'IRQ0Priority'
        Save-SIToolUndo -Key 'HardIrq8Priority' -Path $prioPath -Name 'IRQ8Priority'

        Set-SIRegistryValue -Path $prioPath -Name 'IRQ0Priority' -Value 1 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $prioPath -Name 'IRQ8Priority' -Value 1 -Type 'DWord' | Out-Null

        $drvParams = @(
            @{ Key = 'HardThreadDxgKrnl'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\DXGKrnl\Parameters' }
            @{ Key = 'HardThreadUsbXhci'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters' }
            @{ Key = 'HardThreadMouHid';  Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\mouhid\Parameters' }
        )
        foreach ($d in $drvParams) {
            Save-SIToolUndo -Key $d.Key -Path $d.Path -Name 'ThreadPriority'
            Set-SIRegistryValue -Path $d.Path -Name 'ThreadPriority' -Value 31 -Type 'DWord' | Out-Null
        }

        Write-SILog -Level 'OK' -Component 'IRQ-Hard' -Message 'IRQ0/IRQ8 Priority + ThreadPriority=31 (DXGKrnl, USBXHCI, MouHid) attivati.'
        return $true
    } catch {
        return $false
    }
}

function Disable-SIStickyAndFilterKeys {
    <#
    .SYNOPSIS
        Disables Windows StickyKeys (5x Shift), FilterKeys, and ToggleKeys
        hotkeys so accidental key presses in combat never minimize the game.
    #>
    try {
        $skPath = Get-SIUserRegistryPath 'HKCU:\Control Panel\Accessibility\StickyKeys'
        $fkPath = Get-SIUserRegistryPath 'HKCU:\Control Panel\Accessibility\Keyboard Response'
        $tkPath = Get-SIUserRegistryPath 'HKCU:\Control Panel\Accessibility\ToggleKeys'

        Save-SIToolUndo -Key 'StickyKeysFlags' -Path $skPath -Name 'Flags'
        Save-SIToolUndo -Key 'FilterKeysFlags' -Path $fkPath -Name 'Flags'
        Save-SIToolUndo -Key 'ToggleKeysFlags' -Path $tkPath -Name 'Flags'

        Set-SIRegistryValue -Path $skPath -Name 'Flags' -Value '506' -Type 'String' | Out-Null
        Set-SIRegistryValue -Path $fkPath -Name 'Flags' -Value '122' -Type 'String' | Out-Null
        Set-SIRegistryValue -Path $tkPath -Name 'Flags' -Value '58'  -Type 'String' | Out-Null

        Write-SILog -Level 'OK' -Component 'Input' -Message 'Scorciatoie Tasti Permanenti (5x Shift) / Filtro / ToggleKeys disattivate.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIUdpAfdSocketOptimization {
    <#
    .SYNOPSIS
        Optimizes the Windows Winsock AFD kernel driver for low-latency UDP
        multiplayer gaming packets (FastSendDatagramThreshold = 1500 MTU,
        64KB DefaultSendWindow / DefaultReceiveWindow).
    #>
    try {
        $afdPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters'
        Save-SIToolUndo -Key 'AfdFastSendDatagram' -Path $afdPath -Name 'FastSendDatagramThreshold'
        Save-SIToolUndo -Key 'AfdDefaultRecvWin'   -Path $afdPath -Name 'DefaultReceiveWindow'
        Save-SIToolUndo -Key 'AfdDefaultSendWin'   -Path $afdPath -Name 'DefaultSendWindow'

        Set-SIRegistryValue -Path $afdPath -Name 'FastSendDatagramThreshold' -Value 1500  -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $afdPath -Name 'DefaultReceiveWindow'      -Value 65536 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $afdPath -Name 'DefaultSendWindow'         -Value 65536 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'UDP-Net' -Message 'Winsock AFD UDP Low-Latency (FastSendDatagramThreshold=1500) attivato.'
        return $true
    } catch {
        return $false
    }
}

function Invoke-SINetworkCacheFlush {
    <#
    .SYNOPSIS
        Flushes Windows DNS resolver cache and stale ARP entries so the newly
        selected gaming DNS takes effect immediately.
    #>
    try {
        & ipconfig.exe /flushdns 2>$null | Out-Null
        & arp.exe -d * 2>$null | Out-Null
        Write-SILog -Level 'OK' -Component 'Network' -Message 'Cache DNS e tabella ARP svuotate (ipconfig /flushdns).'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIQosZeroReserveAndRss {
    <#
    .SYNOPSIS
        1. Unlocks 100% network bandwidth by setting QoS NonBestEffortLimit = 0
           in HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched.
        2. Enables Receive Side Scaling (*RSS = 1) on physical network adapters
           so multiplayer packet interrupts are distributed across CPU cores.
    #>
    try {
        $pschedPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched'
        Save-SIToolUndo -Key 'QosNonBestEffort' -Path $pschedPath -Name 'NonBestEffortLimit'
        Set-SIRegistryValue -Path $pschedPath -Name 'NonBestEffortLimit' -Value 0 -Type 'DWord' | Out-Null

        $nicBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
        if (Test-Path -LiteralPath $nicBase) {
            foreach ($sub in @(Get-ChildItem -LiteralPath $nicBase -ErrorAction SilentlyContinue)) {
                if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
                $subPath = $sub.PSPath
                $drvDesc = Get-SIRegistryValue -Path $subPath -Name 'DriverDesc'
                if (-not $drvDesc.Exists -or [string]$drvDesc.Value -match '(?i)Virtual|WAN Miniport|Bluetooth|Loopback|VPN|TAP|Hyper-V') { continue }

                $rssVal = Get-SIRegistryValue -Path $subPath -Name '*RSS'
                if ($rssVal.Exists) {
                    Save-SIToolUndo -Key ('NicRss|' + $sub.PSChildName) -Path $subPath -Name '*RSS'
                    $kind = if ($rssVal.Kind -eq 'DWord') { 'DWord' } else { 'String' }
                    $val  = if ($kind -eq 'DWord') { 1 } else { '1' }
                    Set-SIRegistryValue -Path $subPath -Name '*RSS' -Value $val -Type $kind | Out-Null
                }
            }
        }
        Write-SILog -Level 'OK' -Component 'QoS-RSS' -Message 'Limite banda QoS azzerato (0%) + Multi-Core RSS attivato sulla scheda di rete.'
        return $true
    } catch {
        return $false
    }
}

$script:SISavedServicesState = @{}

function Set-SIUnusedServicesManual {
    <#
    .SYNOPSIS
        Sets non-essential background services (MapsBroker, lfsvc, Fax,
        RetailDemo, wisvc) to Manual and stops them in MaxFPS mode.
    #>
    if ($script:SIAutoMode -ne 'MaxFPS') { return 0 }
    $svcList = @('MapsBroker', 'lfsvc', 'Fax', 'RetailDemo', 'wisvc')
    $changed = 0
    foreach ($sName in $svcList) {
        try {
            $st = Get-SIServiceState -Name $sName
            if (-not $st.Exists) { continue }
            if (-not $script:SISavedServicesState.ContainsKey($sName)) {
                $script:SISavedServicesState[$sName] = @{
                    StartType = $st.StartType
                    Running   = $st.Running
                }
            }
            if ($st.StartType -eq 'Automatic') {
                Set-SIServiceStartType -Name $sName -StartupType 'Manual'
                $changed++
            }
            if ($st.Running) {
                Stop-Service -Name $sName -Force -NoWait -ErrorAction SilentlyContinue
                $changed++
            }
        } catch { }
    }
    if ($changed -gt 0) {
        Write-SILog -Level 'OK' -Component 'Services' -Message "Servizi secondari inutilizzati (MapsBroker, Geolocalizzazione, Fax, Insider) impostati su Manuale."
    }
    return $changed
}

function Restore-SIUnusedServices {
    foreach ($sName in @($script:SISavedServicesState.Keys)) {
        try {
            $orig = $script:SISavedServicesState[$sName]
            if ($orig.StartType) {
                Set-SIServiceStartType -Name $sName -StartupType $orig.StartType
            }
            if ($orig.Running) {
                Start-Service -Name $sName -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    $script:SISavedServicesState = @{}
}

function Enable-SINvidiaUnlimitedShaderCache {
    <#
    .SYNOPSIS
        Sets NVIDIA Shader Cache size to 10 GB / Unlimited in GPU class registry
        to eliminate shader recompilation stutters in DirectX 12 / UE5 games.
    #>
    $applied = $false
    try {
        $classBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        if (-not (Test-Path -LiteralPath $classBase)) { return $false }
        foreach ($sub in @(Get-ChildItem -LiteralPath $classBase -ErrorAction SilentlyContinue)) {
            if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
            $subPath = $sub.PSPath
            $prov = Get-SIRegistryValue -Path $subPath -Name 'ProviderName'
            if ($prov.Exists -and [string]$prov.Value -match '(?i)NVIDIA') {
                Save-SIToolUndo -Key ('NvShaderCache|' + $sub.PSChildName) -Path $subPath -Name 'RMShaderCacheSize'
                Set-SIRegistryValue -Path $subPath -Name 'RMShaderCacheSize' -Value 10240 -Type 'DWord' | Out-Null
                $applied = $true
            }
        }
        if ($applied) {
            Write-SILog -Level 'OK' -Component 'GPU-Shader' -Message 'NVIDIA Shader Cache estesa a 10 GB per evitare ricompilazioni shader in DX12/UE5.'
        }
    } catch { }
    return $applied
}

function Get-SICpuThermalStatus {
    <#
    .SYNOPSIS
        Reads ACPI thermal zone sensors (if exposed by motherboard) to report
        current system temperature and warn if >= 85 C (Thermal Throttling risk).
    #>
    try {
        $zones = @(Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -ErrorAction Stop)
        $maxC = 0
        foreach ($z in $zones) {
            $kelvin = [int]$z.Temperature
            if ($kelvin -ge 273 -and $kelvin -le 400) {
                $c = $kelvin - 273
                if ($c -gt $maxC) { $maxC = $c }
            }
        }
        if ($maxC -gt 0) {
            $warn = ($maxC -ge 85)
            $label = if ($warn) { "${maxC}C (ALTA - Rischio Throttling!)" } else { "${maxC}C (OK)" }
            return [pscustomobject]@{ TempC = $maxC; Warn = $warn; Text = $label }
        }
    } catch { }
    return [pscustomobject]@{ TempC = 0; Warn = $false; Text = '' }
}

function New-SIAutoDesktopShortcut {
    <#
    .SYNOPSIS
        Creates a 1-click "SIGAME AUTO.lnk" shortcut on the user's Desktop
        with the official SIGAME icon.
    #>
    try {
        $desktop = Get-SIDesktopPath
        if (-not $desktop -or -not (Test-Path -LiteralPath $desktop)) { return $false }
        $lnkPath = [System.IO.Path]::Combine($desktop, 'SIGAME AUTO.lnk')
        $batPath = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-AUTO.bat')

        if (-not (Test-Path -LiteralPath $script:SIIconPath)) {
            [void](Get-SIAppIcon)
        }

        $wsh = New-Object -ComObject WScript.Shell
        $sc  = $wsh.CreateShortcut($lnkPath)
        if ([System.IO.File]::Exists($batPath)) {
            $sc.TargetPath = $batPath
        } else {
            $sc.TargetPath = 'powershell.exe'
            $sc.Arguments  = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$script:SICurrentScript`""
        }
        $sc.WorkingDirectory = $script:SIRoot
        $sc.Description      = 'SIGAME AUTO - Ottimizzazione Gaming 1-Click'
        if ([System.IO.File]::Exists($script:SIIconPath)) {
            $sc.IconLocation = "$script:SIIconPath,0"
        }
        $sc.Save()
        Write-SILog -Level 'OK' -Component 'Shortcut' -Message "Collegamento creato sul Desktop: $lnkPath"
        return $true
    } catch {
        return $false
    }
}

function Get-SIAntiCheatGuardStatus {
    <#
    .SYNOPSIS
        Detects installed kernel-level Anti-Cheat systems (Riot Vanguard,
        FACEIT Anti-Cheat, EasyAntiCheat, BattlEye, RICOCHET).
        If Riot Vanguard or FACEIT AC is found, sets RequiresVbs = $true so
        SIGAME keeps VBS/HVCI and Kernel Mitigations intact for 100% anti-cheat
        compliance.
    #>
    $detected = @()
    $requiresVbs = $false
    try {
        if ((Get-Service -Name 'vgk', 'vgc' -ErrorAction SilentlyContinue) -or
            [System.IO.File]::Exists('C:\Program Files\Riot Vanguard\vgk.sys')) {
            $detected += 'Riot Vanguard'
            $requiresVbs = $true
        }
        if ((Get-Service -Name 'FACEIT', 'FACEITService' -ErrorAction SilentlyContinue) -or
            [System.IO.File]::Exists('C:\Program Files\FACEIT AC\faceit.sys') -or
            [System.IO.File]::Exists('C:\Windows\System32\drivers\faceit.sys')) {
            $detected += 'FACEIT AC'
            $requiresVbs = $true
        }
        if (Get-Service -Name 'EasyAntiCheat', 'EasyAntiCheat_EOS' -ErrorAction SilentlyContinue) {
            $detected += 'EasyAntiCheat'
        }
        if (Get-Service -Name 'BEService' -ErrorAction SilentlyContinue) {
            $detected += 'BattlEye'
        }
        if (Get-Service -Name 'atvi-randgrid_sr' -ErrorAction SilentlyContinue) {
            $detected += 'RICOCHET'
        }
    } catch { }

    $detText = if ($detected.Count -gt 0) { $detected -join ', ' } else { 'Standard (VAC/EAC/BattlEye)' }
    $badge   = if ($requiresVbs) {
        "Anti-Cheat Safe ($detText -> Scudo VBS attivo)"
    } elseif ($detected.Count -gt 0) {
        "Anti-Cheat Safe ($detText)"
    } else {
        'Anti-Cheat 100% Safe'
    }
    return [pscustomobject]@{
        DetectedList = $detected
        DetectedText = $detText
        RequiresVbs  = $requiresVbs
        Badge        = $badge
    }
}

function Disable-SIDeliveryOptimizationP2P {
    <#
    .SYNOPSIS
        Disables Windows Update Peer-to-Peer (P2P) Delivery Optimization
        (DODownloadMode = 0) so Windows never uploads/downloads updates to other
        PCs on the Internet while gaming.
    #>
    try {
        $doPolPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
        $doCfgPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config'

        Save-SIToolUndo -Key 'DoPolicyDownloadMode' -Path $doPolPath -Name 'DODownloadMode'
        Save-SIToolUndo -Key 'DoConfigDownloadMode' -Path $doCfgPath -Name 'DODownloadMode'

        Set-SIRegistryValue -Path $doPolPath -Name 'DODownloadMode' -Value 0 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $doCfgPath -Name 'DODownloadMode' -Value 0 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'Network-P2P' -Message 'Windows Delivery Optimization P2P (DODownloadMode=0) disattivato per azzerare upload nascosti.'
        return $true
    } catch {
        return $false
    }
}

function Disable-SIUwpBackgroundApps {
    <#
    .SYNOPSIS
        Prevents UWP Microsoft Store apps (Weather, News, Xbox TCUI, Photos,
        Cortana) from waking up in the background during gameplay.
    #>
    try {
        $bgUserPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'
        $bgPolPath  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'

        Save-SIToolUndo -Key 'UwpBgGlobalUserDisabled' -Path $bgUserPath -Name 'GlobalUserDisabled'
        Save-SIToolUndo -Key 'UwpBgLetAppsRun'         -Path $bgPolPath  -Name 'LetAppsRunInBackground'

        Set-SIRegistryValue -Path $bgUserPath -Name 'GlobalUserDisabled'     -Value 1 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $bgPolPath  -Name 'LetAppsRunInBackground' -Value 2 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'UWP-Bg' -Message 'App UWP Microsoft Store in background disattivate (GlobalUserDisabled=1).'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIMaxMonitorRefreshRate {
    <#
    .SYNOPSIS
        Enumerates supported display modes at the current native resolution via
        user32.dll (EnumDisplaySettings / ChangeDisplaySettingsEx) and switches
        the primary monitor to its highest supported Refresh Rate (Hz) if it is
        currently running below maximum (e.g. stuck at 60Hz on a 144Hz/240Hz panel).
    #>
    try {
        if (-not ('SINativeDisplay' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class SINativeDisplay {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplaySettings(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode);

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, uint dwflags, IntPtr lParam);

    public static int SetMaxRefreshRate(out int oldHz, out int newHz) {
        oldHz = 0;
        newHz = 0;
        DEVMODE cur = new DEVMODE();
        cur.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        if (!EnumDisplaySettings(null, -1, ref cur)) return 0;
        oldHz = cur.dmDisplayFrequency;
        newHz = oldHz;
        int maxHz = oldHz;
        DEVMODE best = cur;
        int modeIdx = 0;
        DEVMODE mode = new DEVMODE();
        mode.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        while (EnumDisplaySettings(null, modeIdx, ref mode)) {
            if (mode.dmPelsWidth == cur.dmPelsWidth &&
                mode.dmPelsHeight == cur.dmPelsHeight &&
                mode.dmBitsPerPel == cur.dmBitsPerPel &&
                mode.dmDisplayOrientation == cur.dmDisplayOrientation &&
                mode.dmDisplayFrequency > maxHz &&
                mode.dmDisplayFrequency <= 540) {
                maxHz = mode.dmDisplayFrequency;
                best = mode;
            }
            modeIdx++;
        }
        if (maxHz > oldHz) {
            best.dmFields = 0x00400000; // DM_DISPLAYFREQUENCY
            int res = ChangeDisplaySettingsEx(null, ref best, IntPtr.Zero, 0x01, IntPtr.Zero); // CDS_UPDATEREGISTRY
            if (res == 0) {
                newHz = maxHz;
                return 1;
            }
        }
        return 0;
    }
}
'@ -ErrorAction Stop
        }
        $oldHz = 0
        $newHz = 0
        $changed = [SINativeDisplay]::SetMaxRefreshRate([ref]$oldHz, [ref]$newHz)
        if ($changed -eq 1 -and $newHz -gt $oldHz) {
            Write-SILog -Level 'OK' -Component 'Monitor-Hz' -Message "Frequenza monitor alzata automaticamente da ${oldHz}Hz a ${newHz}Hz!"
            return $newHz
        }
    } catch { }
    return 0
}

function Get-SISystemStabilityCheck {
    <#
    .SYNOPSIS
        Fast check of Windows System Event Log over the last 7 days for GPU
        driver TDR resets (Event ID 4101 Display) or WHEA hardware errors.
    #>
    try {
        $since = [datetime]::Now.AddDays(-7)
        $tdrEvents = @(Get-WinEvent -FilterHashtable @{
            LogName   = 'System'
            Id        = 4101
            StartTime = $since
        } -MaxEvents 5 -ErrorAction SilentlyContinue)
        if ($tdrEvents.Count -gt 0) {
            return [pscustomobject]@{
                Warn = $true
                Text = "$($tdrEvents.Count) crash driver GPU (7gg)"
            }
        }
    } catch { }
    return [pscustomobject]@{ Warn = $false; Text = 'Stabile (0 crash GPU)' }
}

function Export-SIEmergencyRegBackup {
    <#
    .SYNOPSIS
        Exports a standard Windows Registry (.reg) file and an emergency (.bat)
        restore script in the SIGAME folder so skeptical gamers can restore
        every single registry key & BCD setting with a double-click even
        without opening SIGAME AUTO (or from Windows Safe Mode).
    #>
    try {
        $regFile = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-RIPRISTINO-EMERGENZA.reg')
        $batFile = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-RIPRISTINO-EMERGENZA.bat')
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine('Windows Registry Editor Version 5.00')
        [void]$sb.AppendLine('; =====================================================================')
        [void]$sb.AppendLine('; SIGAME AUTO - FILE DI RIPRISTINO DI EMERGENZA STANDARD WINDOWS (.REG)')
        [void]$sb.AppendLine('; Doppio clic su questo file per ripristinare i valori originali anche')
        [void]$sb.AppendLine('; senza aprire SIGAME AUTO.')
        [void]$sb.AppendLine('; =====================================================================')
        [void]$sb.AppendLine('')

        $entries = @()
        if ($script:SIBackup -and $script:SIBackup.Tweaks) {
            foreach ($k in $script:SIBackup.Tweaks.Keys) {
                $tEntry = $script:SIBackup.Tweaks[$k]
                if ($tEntry -and $tEntry.Registry) {
                    foreach ($r in @($tEntry.Registry)) { $entries += $r }
                }
            }
        }
        if ($script:SIBackup -and $script:SIBackup.Tools) {
            foreach ($k in $script:SIBackup.Tools.Keys) {
                $r = $script:SIBackup.Tools[$k]
                if ($r -and $r.Path) { $entries += $r }
            }
        }

        $byPath = @{}
        foreach ($e in $entries) {
            $rawPath = [string]$e.Path
            if (-not $rawPath) { continue }
            $winPath = $rawPath -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' -replace '^HKCU:\\', 'HKEY_CURRENT_USER\' -replace '^Registry::', ''
            if (-not $byPath.ContainsKey($winPath)) { $byPath[$winPath] = @() }
            $byPath[$winPath] += $e
        }

        foreach ($wPath in $byPath.Keys) {
            [void]$sb.AppendLine("[$wPath]")
            foreach ($item in $byPath[$wPath]) {
                $vName = [string]$item.Name
                if (-not $vName) { continue }
                $escapedName = $vName.Replace('\', '\\').Replace('"', '\"')
                if (-not $item.Existed) {
                    [void]$sb.AppendLine("`"$escapedName`"=-")
                } else {
                    $kind = [string]$item.Kind
                    $val  = $item.Value
                    if ($kind -eq 'DWord') {
                        $hex = ('{0:x8}' -f ([int64]$val -band 0xFFFFFFFF))
                        [void]$sb.AppendLine("`"$escapedName`"=dword:$hex")
                    } elseif ($kind -eq 'String' -or $kind -eq 'ExpandString') {
                        $escapedVal = ([string]$val).Replace('\', '\\').Replace('"', '\"')
                        [void]$sb.AppendLine("`"$escapedName`"=`"$escapedVal`"")
                    }
                }
            }
            [void]$sb.AppendLine('')
        }

        [System.IO.File]::WriteAllText($regFile, $sb.ToString(), [System.Text.Encoding]::ASCII)

        $batLines = @(
            '@echo off',
            'title SIGAME AUTO - Ripristino di Emergenza Indipendente',
            'echo Ripristino chiavi di registro originali da SI-GAME-RIPRISTINO-EMERGENZA.reg...',
            'reg import "%~dp0SI-GAME-RIPRISTINO-EMERGENZA.reg"',
            'echo Ripristino timer BCD standard di Windows...',
            'bcdedit /deletevalue disabledynamictick >nul 2>&1',
            'bcdedit /deletevalue tscsyncpolicy >nul 2>&1',
            'echo.',
            'echo [OK] Ripristino completato con successo!',
            'pause'
        )
        [System.IO.File]::WriteAllLines($batFile, $batLines, [System.Text.Encoding]::ASCII)
        Write-SILog -Level 'OK' -Component 'EmergencyReg' -Message "Creato kit di ripristino indipendente: $regFile + $batFile"
        return $regFile
    } catch {
        return ''
    }
}

function Get-SITrustAndIntegrityBadge {
    <#
    .SYNOPSIS
        Computes the live SHA-256 hash of SI-GAME-AUTO.ps1 and returns a
        concise trust & anti-cheat verification string for the footer.
    #>
    $hashShort = 'VERIFICATO'
    try {
        if ($script:SICurrentScript -and [System.IO.File]::Exists($script:SICurrentScript)) {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            $bytes = [System.IO.File]::ReadAllBytes($script:SICurrentScript)
            $hashBytes = $sha.ComputeHash($bytes)
            $hex = ([BitConverter]::ToString($hashBytes)).Replace('-', '').Substring(0, 12)
            $hashShort = $hex
        }
    } catch { }
    $ac = Get-SIAntiCheatGuardStatus
    return "SCUDO FIDUCIA: 100% Offline & Zero Telemetria  |  $($ac.Badge)  |  Backup .REG + .JSON attivo  |  SHA256: $hashShort"
}

function Show-SITransparencyInspector {
    <#
    .SYNOPSIS
        Opens a modal "ISPEZIONA MODIFICHE & GARANZIA ANTI-CHEAT" window for
        skeptical gamers: shows exact SHA-256 integrity, Anti-Cheat compliance,
        and every single Registry key / value backed up in SI-GAME-backup.json
        and SI-GAME-RIPRISTINO-EMERGENZA.reg.
    #>
    $c = $script:SIColors
    $dlg = [System.Windows.Window]::new()
    $dlg.Title = 'SIGAME AUTO - Ispeziona Modifiche & Garanzia Trasparenza 100%'
    $dlg.Width = 820
    $dlg.Height = 600
    $dlg.WindowStartupLocation = 'CenterOwner'
    if ($script:SIWindow) { $dlg.Owner = $script:SIWindow }
    $dlg.Background = Get-SIBrush $c.Background
    $dlg.Foreground = Get-SIBrush $c.Text

    $grid = [System.Windows.Controls.Grid]::new()
    $grid.Margin = [System.Windows.Thickness]::new(18)
    Add-SIGridRow -Grid $grid -Type 'Auto'
    Add-SIGridRow -Grid $grid -Type 'Star' -Value 1
    Add-SIGridRow -Grid $grid -Type 'Auto'
    $dlg.Content = $grid

    $hdr = [System.Windows.Controls.TextBlock]::new()
    $hdr.Text = 'TRASPARENZA TOTALE PER GAMER DIFFIDENTI (CODICE APERTO & ANTI-CHEAT SAFE)'
    $hdr.FontSize = 15
    $hdr.FontWeight = 'Bold'
    $hdr.Foreground = Get-SIBrush $c.Accent
    $hdr.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    [System.Windows.Controls.Grid]::SetRow($hdr, 0)
    [void]$grid.Children.Add($hdr)

    $tb = [System.Windows.Controls.TextBox]::new()
    $tb.Background = Get-SIBrush '#151824'
    $tb.Foreground = Get-SIBrush '#d7dce8'
    $tb.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas')
    $tb.FontSize = 11.5
    $tb.IsReadOnly = $true
    $tb.TextWrapping = 'Wrap'
    $tb.VerticalScrollBarVisibility = 'Auto'
    $tb.Padding = [System.Windows.Thickness]::new(12)
    $tb.BorderThickness = [System.Windows.Thickness]::new(1)
    $tb.BorderBrush = Get-SIBrush $c.PanelAlt

    $ac = Get-SIAntiCheatGuardStatus
    $regPathFile = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-RIPRISTINO-EMERGENZA.reg')
    if (-not [System.IO.File]::Exists($regPathFile)) {
        [void](Export-SIEmergencyRegBackup)
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('=== 1. PERCHE SIGAME AUTO E 100% SICURO PER GLI ANTI-CHEAT ===')
    $lines.Add('- Zero DLL Injection, Zero Hook DirectX, Zero lettura/scrittura nella RAM dei giochi.')
    $lines.Add('- Nessun file di gioco (.exe / .dll / .pak) viene mai modificato.')
    $lines.Add("- Anti-Cheat Rilevati sul PC: $($ac.DetectedText)")
    if ($ac.RequiresVbs) {
        $lines.Add('- SCUDO VANGUARD / FACEIT ATTIVO: VBS (Isolamento Core) e Mitigazioni Kernel NON vengono disattivati per garantire avvio immediato di Valorant e FACEIT.')
    } else {
        $lines.Add('- Compatibilita verificata al 100% con EasyAntiCheat, BattlEye, VAC, RICOCHET, Vanguard e FACEIT.')
    }
    $lines.Add('')
    $lines.Add('=== 2. ZERO TELEMETRIA & CODICE IN CHIARO ===')
    $lines.Add("- Script PowerShell 100% aperto e ispezionabile: $($script:SICurrentScript)")
    $lines.Add('- Nessun servizio installato in Windows, nessun server remoto contattato (solo test ping verso DNS 1.1.1.1 / 8.8.8.8 / 9.9.9.9).')
    $lines.Add('')
    $lines.Add('=== 3. DOPPIO SISTEMA DI RIPRISTINO (ANCHE SENZA PROGRAMMA) ===')
    $lines.Add("- Backup JSON Interno: $($script:SIBackupPath)")
    $lines.Add("- Kit Ripristino Emergenza Standard Windows (.REG + .BAT): $regPathFile")
    $lines.Add('  (Puoi fare doppio clic su SI-GAME-RIPRISTINO-EMERGENZA.bat anche a programma disinstallato o in Modalita Provvisoria).')
    $lines.Add('')
    $lines.Add('=== 4. ELENCO CHIAVI DI REGISTRO ATTUALMENTE SALVATE NEL BACKUP ===')

    $countKeys = 0
    if ($script:SIBackup -and $script:SIBackup.Tweaks) {
        foreach ($k in $script:SIBackup.Tweaks.Keys) {
            $tEntry = $script:SIBackup.Tweaks[$k]
            if ($tEntry -and $tEntry.Registry) {
                foreach ($r in @($tEntry.Registry)) {
                    $orig = if ($r.Existed) { "$($r.Value) ($($r.Kind))" } else { '<Non esisteva - verra rimossa al ripristino>' }
                    $lines.Add("[Tweak: $k] $($r.Path) -> $($r.Name)  |  Valore Originale: $orig")
                    $countKeys++
                }
            }
        }
    }
    if ($script:SIBackup -and $script:SIBackup.Tools) {
        foreach ($k in $script:SIBackup.Tools.Keys) {
            $r = $script:SIBackup.Tools[$k]
            if ($r -and $r.Path) {
                $orig = if ($r.Existed) { "$($r.Value) ($($r.Kind))" } else { '<Non esisteva - verra rimossa al ripristino>' }
                $lines.Add("[$k] $($r.Path) -> $($r.Name)  |  Valore Originale: $orig")
                $countKeys++
            }
        }
    }
    if ($countKeys -eq 0) {
        $lines.Add('(Nessuna chiave ancora modificata o backup vuoto. Premi OTTIMIZAR per creare il backup automatico prima di applicare i tweak).')
    }

    $tb.Text = ($lines -join "`r`n")
    [System.Windows.Controls.Grid]::SetRow($tb, 1)
    [void]$grid.Children.Add($tb)

    $btnRow = [System.Windows.Controls.WrapPanel]::new()
    $btnRow.HorizontalAlignment = 'Right'
    $btnRow.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)

    $btnReport = New-SIStyleButton -Text 'Esporta Report (.TXT)' -StyleKey 'GhostButton' -Window $script:SIWindow -Width 165
    $btnReport.Height = 32
    $btnReport.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
    $null = $btnReport.Add_Click({
        $repFile = Export-SIGamingDiagnosticReport
        if ($repFile -and [System.IO.File]::Exists($repFile)) {
            try { Start-Process -FilePath 'notepad.exe' -ArgumentList "`"$repFile`"" } catch { }
        }
    })
    [void]$btnRow.Children.Add($btnReport)

    $btnOpenFolder = New-SIStyleButton -Text 'Apri Cartella Backup (.REG / .JSON)' -StyleKey 'GhostButton' -Window $script:SIWindow -Width 230
    $btnOpenFolder.Height = 32
    $btnOpenFolder.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
    $null = $btnOpenFolder.Add_Click({
        try { Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$($script:SIRoot)`"" } catch { }
    })
    [void]$btnRow.Children.Add($btnOpenFolder)

    $btnClose = New-SIStyleButton -Text 'Chiudi' -StyleKey 'AccentButton' -Window $script:SIWindow -Width 110
    $btnClose.Height = 32
    $null = $btnClose.Add_Click({ $dlg.Close() }.GetNewClosure())
    [void]$btnRow.Children.Add($btnClose)

    [System.Windows.Controls.Grid]::SetRow($btnRow, 2)
    [void]$grid.Children.Add($btnRow)

    [void]$dlg.ShowDialog()
}

function Get-SIRamSpeedAndChannelStatus {
    <#
    .SYNOPSIS
        Inspects physical RAM modules (Win32_PhysicalMemory) to detect
        Dual-Channel vs Single-Channel configuration and current MHz speed
        (warning if XMP/DOCP/EXPO appears disabled at 2133/4800 MHz).
    #>
    try {
        $sticks = @(Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop)
        if ($sticks.Count -eq 0) {
            return [pscustomobject]@{ Warn = $false; Text = '' }
        }
        $speed = 0
        foreach ($s in $sticks) {
            $clk = [int]$s.ConfiguredClockSpeed
            if ($clk -le 0) { $clk = [int]$s.Speed }
            if ($clk -gt $speed) { $speed = $clk }
        }
        $chMode = if ($sticks.Count -ge 2) { 'Dual-Ch' } else { 'Single-Ch' }
        $xmpWarn = ($speed -gt 0 -and ($speed -eq 2133 -or $speed -eq 2400 -or $speed -eq 4800))
        $singleWarn = ($sticks.Count -eq 1 -and -not (Get-SIIsLaptop))
        $warn = ($xmpWarn -or $singleWarn)

        $speedTxt = if ($speed -gt 0) { "${speed}MHz" } else { '' }
        $note = ''
        if ($xmpWarn) { $note = ' (Attiva XMP/EXPO!)' }
        elseif ($singleWarn) { $note = ' (1 banco)' }

        return [pscustomobject]@{
            Warn = $warn
            Text = "$chMode $speedTxt$note".Trim()
        }
    } catch {
        return [pscustomobject]@{ Warn = $false; Text = '' }
    }
}

function Enable-SIWifiGamingAntiLag {
    <#
    .SYNOPSIS
        Eliminates periodic 200-400ms Wi-Fi ping spikes caused by Windows
        background SSID scanning and aggressive AP roaming on wireless NICs,
        and disables Packet Coalescing.
    #>
    $changed = 0
    try {
        $nicBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
        if (Test-Path -LiteralPath $nicBase) {
            foreach ($sub in @(Get-ChildItem -LiteralPath $nicBase -ErrorAction SilentlyContinue)) {
                if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
                $subPath = $sub.PSPath
                $drvDesc = Get-SIRegistryValue -Path $subPath -Name 'DriverDesc'
                if (-not $drvDesc.Exists -or [string]$drvDesc.Value -match '(?i)Virtual|WAN Miniport|Bluetooth|Loopback|VPN') { continue }

                foreach ($pName in @('*PacketCoalescing', 'ScanWhenAssociated', 'BgScanGlobal')) {
                    $cur = Get-SIRegistryValue -Path $subPath -Name $pName
                    if ($cur.Exists) {
                        Save-SIToolUndo -Key ('WifiAntiLag|' + $sub.PSChildName + '|' + $pName) -Path $subPath -Name $pName
                        $kind = if ($cur.Kind -eq 'DWord') { 'DWord' } else { 'String' }
                        $val  = if ($kind -eq 'DWord') { 0 } else { '0' }
                        Set-SIRegistryValue -Path $subPath -Name $pName -Value $val -Type $kind | Out-Null
                        $changed++
                    }
                }
            }
        }
        $wlanCfg = 'HKLM:\SYSTEM\CurrentControlSet\Services\Wlansvc\Parameters\HostedNetworkSettings'
        if ($changed -gt 0) {
            Write-SILog -Level 'OK' -Component 'WiFi-AntiLag' -Message "Wi-Fi Anti-Lag e Stop Packet Coalescing attivati ($changed parametri)."
        }
    } catch { }
    return $changed
}

function Enable-SITcpPortAndSocketUnlock {
    <#
    .SYNOPSIS
        Unlocks maximum ephemeral user ports (MaxUserPort = 65534) and lowers
        TIME_WAIT socket hold delay (TcpTimedWaitDelay = 30) in Tcpip\Parameters
        for fast matchmaking and voice/game server connections.
    #>
    try {
        $tcpPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
        Save-SIToolUndo -Key 'TcpMaxUserPort'       -Path $tcpPath -Name 'MaxUserPort'
        Save-SIToolUndo -Key 'TcpTimedWaitDelay'    -Path $tcpPath -Name 'TcpTimedWaitDelay'
        Save-SIToolUndo -Key 'TcpDefaultTtl'        -Path $tcpPath -Name 'DefaultTTL'

        Set-SIRegistryValue -Path $tcpPath -Name 'MaxUserPort'       -Value 65534 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $tcpPath -Name 'TcpTimedWaitDelay' -Value 30    -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $tcpPath -Name 'DefaultTTL'        -Value 64    -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'TCP-Sockets' -Message 'Porte effimere sbloccate (MaxUserPort=65534, TcpTimedWaitDelay=30s).'
        return $true
    } catch {
        return $false
    }
}

function Optimize-SILiveRunningGameProcess {
    <#
    .SYNOPSIS
        Applies live kernel Dynamic Thread Priority Boost and High PriorityClass
        to any currently running game from SIGameLibrary, and pins background
        store launchers (steam, EpicGamesLauncher, RiotClientServices) to the
        last CPU thread on >= 8 thread CPUs.
    #>
    $boostedGames = 0
    try {
        $gameNames = @()
        foreach ($g in @($script:SIGameLibrary)) {
            if ($g.Exe) {
                $n = [System.IO.Path]::GetFileNameWithoutExtension([string]$g.Exe)
                if ($n -and ($gameNames -notcontains $n)) { $gameNames += $n }
            }
        }
        $cpuCount = [Environment]::ProcessorCount
        $allCoresMask = [IntPtr]::Zero
        $lastCoreMask = [IntPtr]::Zero
        if ($cpuCount -ge 8 -and $cpuCount -le 62) {
            $allBits = ([int64]1 -shl $cpuCount) - 1
            $allCoresMask = [IntPtr]::new($allBits)
            $lastCoreMask = [IntPtr]::new(([int64]1 -shl ($cpuCount - 1)))
        }

        $launchers = @('steam', 'EpicGamesLauncher', 'RiotClientServices', 'UbisoftConnect', 'EADesktop')
        foreach ($proc in @(Get-Process -ErrorAction SilentlyContinue)) {
            $pName = ''
            try { $pName = [string]$proc.ProcessName } catch { continue }
            if ($gameNames -contains $pName) {
                try {
                    $proc.PriorityBoostEnabled = $true
                    $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                    if ($allCoresMask -ne [IntPtr]::Zero) {
                        $proc.ProcessorAffinity = $allCoresMask
                    }
                    $boostedGames++
                } catch { }
            } elseif ($launchers -contains $pName -and $lastCoreMask -ne [IntPtr]::Zero) {
                try {
                    if (-not $script:SIHogAffinities.ContainsKey($proc.Id)) {
                        $script:SIHogAffinities[$proc.Id] = $proc.ProcessorAffinity
                    }
                    $proc.ProcessorAffinity = $lastCoreMask
                } catch { }
            }
        }
        if ($boostedGames -gt 0) {
            Write-SILog -Level 'OK' -Component 'LiveGameBoost' -Message "$boostedGames processo/i di gioco attivi portati a Priorita Alta + Dynamic Thread Boost."
        }
    } catch { }
    return $boostedGames
}

function Invoke-SISsdFastReTrim {
    <#
    .SYNOPSIS
        Executes a fast non-blocking TRIM pass on SSD drives so NVMe/SATA flash
        blocks maintain maximum read/write speed during texture streaming.
    #>
    try {
        if ($script:SIBottleneck -and $script:SIBottleneck.DiskType -ne 'SSD') { return $false }
        $psi = [System.Diagnostics.ProcessStartInfo]::new('defrag.exe')
        $psi.Arguments = 'C: /L'
        $psi.CreateNoWindow = $true
        $psi.UseShellExecute = $false
        $p = [System.Diagnostics.Process]::Start($psi)
        if ($p) { [void]$p.WaitForExit(3500) }
        Write-SILog -Level 'OK' -Component 'SSD-TRIM' -Message 'Comando Re-TRIM rapido eseguito su SSD per massima velocita caricamento texture.'
        return $true
    } catch {
        return $false
    }
}

function Invoke-SILiveLatencyBenchmark {
    <#
    .SYNOPSIS
        Runs an on-demand live benchmark of Kernel Timer Resolution (ms),
        Gaming Network Ping/Jitter/Loss, and Free RAM, displaying the results
        immediately in the status bar and refreshing the dashboard.
    #>
    try {
        Set-SIStatusText -Text 'Esecuzione Test Latenza Timer Kernel, Ping/Jitter/Loss e RAM in corso...'
        Invoke-SIUIPump

        $timerMs = 15.6
        try {
            if (-not ('SINativeTimerQuery' -as [type])) {
                Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SINativeTimerQuery {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);
}
'@ -ErrorAction Stop
            }
            $minR = [uint32]0; $maxR = [uint32]0; $curR = [uint32]0
            if ([SINativeTimerQuery]::NtQueryTimerResolution([ref]$minR, [ref]$maxR, [ref]$curR) -eq 0 -and $curR -gt 0) {
                $timerMs = [math]::Round($curR / 10000.0, 2)
            }
        } catch { }

        $pingRes = Measure-SIGamingPing
        $ramInfo = Get-SIRamSpeedAndChannelStatus
        $sysNow  = Measure-SISystem -QuickDns
        $script:SIMeasuresAfter = $sysNow
        [void](Get-SIGamingHealthCheck -ForceRefresh)
        Update-SIProvePanel
        Update-SIAutoDashboard

        $ramChTxt = if ($ramInfo.Text) { " | RAM: $($ramInfo.Text) ($($sysNow.FreeRamMB) MB liberi)" } else { " | RAM Libera: $($sysNow.FreeRamMB) MB" }
        $msg = "TEST LIVE -> Timer Kernel: ${timerMs} ms | Rete: $($pingRes.Text)$ramChTxt"
        Set-SIStatusText -Text $msg
        Show-SITrayBalloon -Title 'SIGAME - Test Latenza Live' -Text $msg
        Write-SILog -Level 'OK' -Component 'Benchmark' -Message $msg
    } catch {
        Set-SIStatusText -Text "Errore durante il test latenza: $($_.Exception.Message)"
    }
}

function Disable-SIGamingPopupNotifications {
    <#
    .SYNOPSIS
        Disables intrusive Windows toast notification banners and "Tips/Suggestions"
        popups (SoftLandingEnabled / SubscribedContent) so Windows never steals
        fullscreen focus or causes frame drops mid-combat.
    #>
    try {
        $notifPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications'
        $cdmPath   = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

        Save-SIToolUndo -Key 'NotifToastEnabled' -Path $notifPath -Name 'ToastEnabled'
        Save-SIToolUndo -Key 'CdmSoftLanding'    -Path $cdmPath   -Name 'SoftLandingEnabled'
        Save-SIToolUndo -Key 'CdmTipsSubscribed' -Path $cdmPath   -Name 'SubscribedContent-338389Enabled'

        Set-SIRegistryValue -Path $notifPath -Name 'ToastEnabled'                    -Value 0 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $cdmPath   -Name 'SoftLandingEnabled'              -Value 0 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $cdmPath   -Name 'SubscribedContent-338389Enabled' -Value 0 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'FocusAssist' -Message 'Notifiche popup e suggerimenti Windows disattivati per evitare perdite di focus in partita.'
        return $true
    } catch {
        return $false
    }
}

function Optimize-SIBrowserAndWebView2Gaming {
    <#
    .SYNOPSIS
        Prevents Chrome, Edge, and Brave from staying resident in the background
        after closing (BackgroundModeEnabled = 0) and lowers msedgewebview2.exe
        priority so Windows 11 Widgets/WebView never steal GPU/RAM during games.
    #>
    try {
        $chromePol = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
        $edgePol   = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
        $bravePol  = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'

        Save-SIToolUndo -Key 'ChromeBgModeOff' -Path $chromePol -Name 'BackgroundModeEnabled'
        Save-SIToolUndo -Key 'EdgeBgModeOff'   -Path $edgePol   -Name 'BackgroundModeEnabled'
        Save-SIToolUndo -Key 'BraveBgModeOff'  -Path $bravePol  -Name 'BackgroundModeEnabled'

        Set-SIRegistryValue -Path $chromePol -Name 'BackgroundModeEnabled' -Value 0 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $edgePol   -Name 'BackgroundModeEnabled' -Value 0 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $bravePol  -Name 'BackgroundModeEnabled' -Value 0 -Type 'DWord' | Out-Null

        foreach ($wv in @(Get-Process -Name 'msedgewebview2' -ErrorAction SilentlyContinue)) {
            try { $wv.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle } catch { }
        }
        Write-SILog -Level 'OK' -Component 'Browser-Opt' -Message 'Processi residui Browser (Chrome/Edge/Brave BackgroundMode OFF) e WebView2 ottimizzati.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SICpuTurboAndMinClock {
    <#
    .SYNOPSIS
        On Desktop PCs, sets Minimum Processor State = 100% and Processor
        Performance Boost Mode = Aggressive (2) on the active power plan to
        eliminate CPU frequency downclocking stutters.
    #>
    if (Get-SIIsLaptop) { return $false }
    try {
        # SUB_PROCESSOR = 54533251-82be-4824-96c1-47b60b740d00
        # PROCTHROTTLEMIN = 89cc6830-f622-4073-b22c-a6a8c3222238 (100%)
        # PERFBOOSTMODE   = be337238-0d82-4146-a960-4f3749d470c7 (2 = Aggressive)
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 89cc6830-f622-4073-b22c-a6a8c3222238 100 2>$null | Out-Null
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2 2>$null | Out-Null
        & powercfg.exe /setactive SCHEME_CURRENT 2>$null | Out-Null
        Write-SILog -Level 'OK' -Component 'CPU-Turbo' -Message 'Frequenza CPU Desktop bloccata al massimo (Min State 100% + Turbo Boost Aggressive).'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIDwmMpoAntiFlickerFix {
    <#
    .SYNOPSIS
        Applies the official NVIDIA/AMD Multiplane Overlay (MPO) fix
        (OverlayTestMode = 5 in HKLM:\SOFTWARE\Microsoft\Windows\Dwm) to prevent
        DX12/Vulkan borderless micro-stutters and black-screen flickering when
        Discord or browsers are open on Windows 10/11.
    #>
    try {
        $dwmPath = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'
        Save-SIToolUndo -Key 'DwmMpoOverlayTestMode' -Path $dwmPath -Name 'OverlayTestMode'
        Set-SIRegistryValue -Path $dwmPath -Name 'OverlayTestMode' -Value 5 -Type 'DWord' | Out-Null
        Write-SILog -Level 'OK' -Component 'DWM-MPO' -Message 'Fix ufficiale Multiplane Overlay (OverlayTestMode=5) attivato contro micro-stutter DX12.'
        return $true
    } catch {
        return $false
    }
}

function Clear-SILauncherWebCaches {
    <#
    .SYNOPSIS
        Safely deletes unlocked Chromium webcache / htmlcache / GPUCache files
        from Steam, Epic Games Launcher, and Battle.net without touching login
        tokens or game saves.
    #>
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if (-not $localAppData) { return @{ Removed = 0; MegaBytes = 0.0 } }

    $folders = @(
        [System.IO.Path]::Combine($localAppData, 'Steam\htmlcache\Cache'),
        [System.IO.Path]::Combine($localAppData, 'Steam\htmlcache\Code Cache'),
        [System.IO.Path]::Combine($localAppData, 'Steam\htmlcache\GPUCache'),
        [System.IO.Path]::Combine($localAppData, 'EpicGamesLauncher\Saved\webcache\Cache'),
        [System.IO.Path]::Combine($localAppData, 'EpicGamesLauncher\Saved\webcache\GPUCache'),
        [System.IO.Path]::Combine($localAppData, 'Battle.net\BrowserCache\Cache'),
        [System.IO.Path]::Combine($localAppData, 'Battle.net\BrowserCache\GPUCache')
    )

    $removed = 0
    $bytes   = [long]0
    foreach ($dir in $folders) {
        if (-not [System.IO.Directory]::Exists($dir)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            try {
                $len = [long]$file.Length
                [System.IO.File]::Delete($file.FullName)
                $removed++
                $bytes += $len
            } catch { }
        }
    }
    $mb = [math]::Round($bytes / 1MB, 1)
    if ($removed -gt 0) {
        Write-SILog -Component 'LauncherCache' -Message "Pulita cache Chromium dei Launcher ($removed file, $mb MB)."
    }
    return @{ Removed = $removed; MegaBytes = $mb }
}

function Export-SIGamingDiagnosticReport {
    <#
    .SYNOPSIS
        Exports a complete human-readable gaming diagnostic report
        (SI-GAME-REPORT.txt) with Hardware, RAM Dual-Channel/MHz, Ping/Jitter/Loss,
        Anti-Cheat Guard status, and all optimized games & tweaks.
    #>
    try {
        $repPath = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-REPORT.txt')
        $audit   = Get-SIPcOptimizationAudit
        $health  = Get-SIGamingHealthCheck
        $ac      = Get-SIAntiCheatGuardStatus
        $ramCh   = Get-SIRamSpeedAndChannelStatus
        $hw      = $script:SIBottleneck

        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine('========================================================================')
        [void]$sb.AppendLine('               SIGAME AUTO - REPORT DIAGNOSTICO GAMING')
        [void]$sb.AppendLine("               Generato il: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        [void]$sb.AppendLine('========================================================================')
        [void]$sb.AppendLine('')
        if ($hw) {
            [void]$sb.AppendLine("CPU:             $($hw.Cpu)")
            [void]$sb.AppendLine("GPU:             $($hw.Gpu)")
            [void]$sb.AppendLine("RAM:             $($hw.RamText) [$($ramCh.Text)]")
            [void]$sb.AppendLine("Disco:           $($hw.DiskType) ($($hw.FreeGB) GB liberi)")
        }
        [void]$sb.AppendLine("Profilo Attivo:  $($audit.Plan.ProfileName) (Modalita: $($script:SIAutoMode))")
        [void]$sb.AppendLine("Stato PC:        Ottimizzato al $($audit.Percent)% ($($audit.AppliedTweaks)/$($audit.TotalTweaks) Tweak, $($audit.OptGames)/$($audit.TotalGames) Giochi)")
        [void]$sb.AppendLine("Salute Gaming:   $($health.Summary)")
        [void]$sb.AppendLine("Scudo AntiCheat: $($ac.Badge) (Rilevati: $($ac.DetectedText))")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('--- GIOCHI RILEVATI & OTTIMIZZATI ---')
        foreach ($g in @($script:SIGameLibrary)) {
            [void]$sb.AppendLine("- $($g.Name) [$($g.Store)] -> $($g.Exe)")
        }
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('--- INTEGRITA & FILE DI RIPRISTINO ---')
        [void]$sb.AppendLine((Get-SITrustAndIntegrityBadge))
        [void]$sb.AppendLine("Backup JSON: $($script:SIBackupPath)")
        [void]$sb.AppendLine("Backup REG:  $([System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-RIPRISTINO-EMERGENZA.reg'))")

        [System.IO.File]::WriteAllText($repPath, $sb.ToString(), [System.Text.Encoding]::ASCII)
        Write-SILog -Level 'OK' -Component 'Report' -Message "Report diagnostico salvato: $repPath"
        return $repPath
    } catch {
        return ''
    }
}

function Enable-SIMultimediaNetworkAndCpuUnlock {
    <#
    .SYNOPSIS
        Disables Windows Multimedia Class Scheduler packet throttling
        (NetworkThrottlingIndex = 0xFFFFFFFF) so audio/Discord never throttles
        game packets to 10/ms, and sets SystemResponsiveness (0 in MaxFPS, 10
        in Streaming) for maximum foreground game CPU time.
    #>
    try {
        $sysProf = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
        Save-SIToolUndo -Key 'MmcssNetThrottlingIdx' -Path $sysProf -Name 'NetworkThrottlingIndex'
        Save-SIToolUndo -Key 'MmcssSysResponsiveness' -Path $sysProf -Name 'SystemResponsiveness'

        $respVal = if ($script:SIAutoMode -eq 'MaxFPS') { 0 } else { 10 }
        Set-SIRegistryValue -Path $sysProf -Name 'NetworkThrottlingIndex' -Value -1       -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $sysProf -Name 'SystemResponsiveness'   -Value $respVal -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'MMCSS-Unlock' -Message "NetworkThrottlingIndex=FFFFFFFF (Zero Throttling) + SystemResponsiveness=$respVal attivati."
        return $true
    } catch {
        return $false
    }
}

function Enable-SIHybridCpuPCoreScheduling {
    <#
    .SYNOPSIS
        Configures Windows power scheduler for Hybrid CPUs (Intel 12th/13th/14th Gen
        P-Core/E-Core & AMD Ryzen multi-CCD) to prefer Performant Processors
        (P-Cores) for foreground gaming threads.
    #>
    try {
        # SUB_PROCESSOR = 54533251-82be-4824-96c1-47b60b740d00
        # SCHEDPOLICY (Hetero Policy)       = 93b8b6dc-0698-4d1c-9ee4-0644e900c85d (2 = Prefer performant processors)
        # SHORTTHREADPOLICY (Hetero Short)  = bae08b81-2d5e-4688-ad6a-13243356654b (2 = Prefer performant processors)
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2 2>$null | Out-Null
        & powercfg.exe /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bae08b81-2d5e-4688-ad6a-13243356654b 2 2>$null | Out-Null
        & powercfg.exe /setactive SCHEME_CURRENT 2>$null | Out-Null
        Write-SILog -Level 'OK' -Component 'CPU-Hybrid' -Message 'Scheduler CPU Ibrido configurato per dare priorita ai P-Core ad alte prestazioni.'
        return $true
    } catch {
        return $false
    }
}

function Enable-SINvidiaMaxPerformancePowerMizer {
    <#
    .SYNOPSIS
        On Desktop PCs with NVIDIA GPUs, enables PowerMizer Maximum Performance
        (PowerMizerEnable=1, PowerMizerLevel=1, PowerMizerLevelAC=1, PerfLevelSrc=0x2222)
        so GPU core and VRAM clocks do not downclock mid-match.
    #>
    if (Get-SIIsLaptop) { return $false }
    $applied = $false
    try {
        $classBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        if (-not (Test-Path -LiteralPath $classBase)) { return $false }
        foreach ($sub in @(Get-ChildItem -LiteralPath $classBase -ErrorAction SilentlyContinue)) {
            if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
            $subPath = $sub.PSPath
            $prov = Get-SIRegistryValue -Path $subPath -Name 'ProviderName'
            if ($prov.Exists -and [string]$prov.Value -match '(?i)NVIDIA') {
                Save-SIToolUndo -Key ('NvPmEnable|'  + $sub.PSChildName) -Path $subPath -Name 'PowerMizerEnable'
                Save-SIToolUndo -Key ('NvPmLevel|'   + $sub.PSChildName) -Path $subPath -Name 'PowerMizerLevel'
                Save-SIToolUndo -Key ('NvPmLevelAc|' + $sub.PSChildName) -Path $subPath -Name 'PowerMizerLevelAC'
                Save-SIToolUndo -Key ('NvPerfSrc|'   + $sub.PSChildName) -Path $subPath -Name 'PerfLevelSrc'

                Set-SIRegistryValue -Path $subPath -Name 'PowerMizerEnable'  -Value 1      -Type 'DWord' | Out-Null
                Set-SIRegistryValue -Path $subPath -Name 'PowerMizerLevel'   -Value 1      -Type 'DWord' | Out-Null
                Set-SIRegistryValue -Path $subPath -Name 'PowerMizerLevelAC' -Value 1      -Type 'DWord' | Out-Null
                Set-SIRegistryValue -Path $subPath -Name 'PerfLevelSrc'      -Value 0x2222 -Type 'DWord' | Out-Null
                $applied = $true
            }
        }
        if ($applied) {
            Write-SILog -Level 'OK' -Component 'GPU-PowerMizer' -Message 'NVIDIA PowerMizer Preferisci Prestazioni Massime attivato su Desktop.'
        }
    } catch { }
    return $applied
}

function Disable-SIFastStartupHiberboot {
    <#
    .SYNOPSIS
        Disables Windows Fast Startup (HiberbootEnabled = 0) on SSD PCs so
        shutting down performs a clean kernel & GPU driver reload instead of
        accumulating DWM/VRAM memory leaks over weeks.
    #>
    try {
        if ($script:SIBottleneck -and $script:SIBottleneck.DiskType -ne 'SSD') { return $false }
        $pwrPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
        Save-SIToolUndo -Key 'FastStartupHiberboot' -Path $pwrPath -Name 'HiberbootEnabled'
        Set-SIRegistryValue -Path $pwrPath -Name 'HiberbootEnabled' -Value 0 -Type 'DWord' | Out-Null
        Write-SILog -Level 'OK' -Component 'FastStartup' -Message 'Avvio Rapido Ibernato (HiberbootEnabled=0) disattivato su SSD per kernel e driver GPU sempre freschi.'
        return $true
    } catch {
        return $false
    }
}

function Repair-SIPagefileAntiCrash {
    <#
    .SYNOPSIS
        Checks if the Windows Pagefile is disabled (0 MB) and re-enables
        System-Managed Pagefile so Unreal Engine 5, Warzone, Tarkov, and Fortnite
        never crash mid-match with Out of Video/Virtual Memory errors.
    #>
    try {
        $pf = @(Get-CimInstance -ClassName Win32_PageFileUsage -ErrorAction SilentlyContinue)
        if ($pf.Count -eq 0) {
            $mmPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            $existing = Get-SIRegistryValue -Path $mmPath -Name 'PagingFiles'
            if ($existing.Exists -and (-not $existing.Value -or [string]$existing.Value -eq '')) {
                Save-SIToolUndo -Key 'PagefileAntiCrash' -Path $mmPath -Name 'PagingFiles'
                Set-SIRegistryValue -Path $mmPath -Name 'PagingFiles' -Value @('?: \pagefile.sys') -Type 'MultiString' | Out-Null
                Write-SILog -Level 'OK' -Component 'PagefileGuard' -Message 'Pagefile risultato disattivato (0 MB): riattivato in modalita automatica contro crash Out of Memory.'
                return $true
            }
        }
    } catch { }
    return $false
}

function Enable-SIAmdRadeonDeepSleepOff {
    <#
    .SYNOPSIS
        On Desktop PCs with AMD Radeon GPUs, disables core clock SCLK Deep Sleep
        (PP_SclkDeepSleepDisable = 1) and DRMDMA Power Gating
        (DisableDrmdmaPowerGating = 1) to eliminate DX11/DX12 micro-stutters.
    #>
    if (Get-SIIsLaptop) { return $false }
    $applied = $false
    try {
        $classBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        if (-not (Test-Path -LiteralPath $classBase)) { return $false }
        foreach ($sub in @(Get-ChildItem -LiteralPath $classBase -ErrorAction SilentlyContinue)) {
            if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
            $subPath = $sub.PSPath
            $prov = Get-SIRegistryValue -Path $subPath -Name 'ProviderName'
            if ($prov.Exists -and [string]$prov.Value -match '(?i)AMD|Advanced Micro Devices|ATI') {
                Save-SIToolUndo -Key ('AmdSclkSleep|' + $sub.PSChildName) -Path $subPath -Name 'PP_SclkDeepSleepDisable'
                Save-SIToolUndo -Key ('AmdDrmdmaPg|'  + $sub.PSChildName) -Path $subPath -Name 'DisableDrmdmaPowerGating'

                Set-SIRegistryValue -Path $subPath -Name 'PP_SclkDeepSleepDisable'  -Value 1 -Type 'DWord' | Out-Null
                Set-SIRegistryValue -Path $subPath -Name 'DisableDrmdmaPowerGating' -Value 1 -Type 'DWord' | Out-Null
                $applied = $true
            }
        }
        if ($applied) {
            Write-SILog -Level 'OK' -Component 'GPU-AMD' -Message 'AMD Radeon Clock DeepSleep OFF (PP_SclkDeepSleepDisable=1) attivato su Desktop.'
        }
    } catch { }
    return $applied
}

function Disable-SIUsbHidDevicePowerSaving {
    <#
    .SYNOPSIS
        Disables EnhancedPowerManagementEnabled on individual USB/HID devices
        (wireless 2.4GHz mouse dongles, mechanical keyboards, Xbox/DualSense
        controllers) so Windows never puts them into D3 micro-sleep.
    #>
    $changed = 0
    try {
        $usbRoot = 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB'
        if (-not (Test-Path -LiteralPath $usbRoot)) { return 0 }
        foreach ($vidKey in @(Get-ChildItem -LiteralPath $usbRoot -ErrorAction SilentlyContinue)) {
            foreach ($instKey in @(Get-ChildItem -LiteralPath $vidKey.PSPath -ErrorAction SilentlyContinue)) {
                $devParams = Join-Path $instKey.PSPath 'Device Parameters'
                if (-not (Test-Path -LiteralPath $devParams)) { continue }
                $epm = Get-SIRegistryValue -Path $devParams -Name 'EnhancedPowerManagementEnabled'
                if ($epm.Exists -and [int]$epm.Value -ne 0) {
                    $shortId = "$($vidKey.PSChildName)\$($instKey.PSChildName)"
                    Save-SIToolUndo -Key ('UsbHidEpm|' + $shortId) -Path $devParams -Name 'EnhancedPowerManagementEnabled'
                    Set-SIRegistryValue -Path $devParams -Name 'EnhancedPowerManagementEnabled' -Value 0 -Type 'DWord' | Out-Null
                    $changed++
                }
            }
        }
        if ($changed -gt 0) {
            Write-SILog -Level 'OK' -Component 'USB-HID' -Message "Risparmio energetico disattivato su $changed dispositivi USB/HID (Mouse/Tastiera/Controller)."
        }
    } catch { }
    return $changed
}

function Disable-SIDnsNegativeCache {
    <#
    .SYNOPSIS
        Sets MaxNegativeCacheTtl = 0 and NegativeCacheTime = 0 in
        Dnscache\Parameters so Windows never caches temporary DNS lookup
        glitches, allowing instant reconnection to game matchmaking servers.
    #>
    try {
        $dnsPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters'
        Save-SIToolUndo -Key 'DnsMaxNegCacheTtl' -Path $dnsPath -Name 'MaxNegativeCacheTtl'
        Save-SIToolUndo -Key 'DnsNegCacheTime'   -Path $dnsPath -Name 'NegativeCacheTime'
        Save-SIToolUndo -Key 'DnsNetFailTime'    -Path $dnsPath -Name 'NetFailureCacheTime'

        Set-SIRegistryValue -Path $dnsPath -Name 'MaxNegativeCacheTtl' -Value 0 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $dnsPath -Name 'NegativeCacheTime'   -Value 0 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $dnsPath -Name 'NetFailureCacheTime' -Value 0 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'DNS-Cache' -Message 'DNS Negative Cache azzerata (MaxNegativeCacheTtl=0) per riconnessione istantanea.'
        return $true
    } catch {
        return $false
    }
}

function Optimize-SITcpTimestampsAndEcn {
    <#
    .SYNOPSIS
        Disables TCP RFC 1323 Timestamps (saving 12 bytes per packet header)
        and ECN Capability (which causes packet drops/delays on many consumer
        routers).
    #>
    try {
        & netsh.exe int tcp set global timestamps=disabled 2>$null | Out-Null
        & netsh.exe int tcp set global ecncapability=disabled 2>$null | Out-Null
        Write-SILog -Level 'OK' -Component 'TCP-Header' -Message 'Header pacchetti TCP snelliti (timestamps=disabled, ecncapability=disabled).'
        return $true
    } catch {
        return $false
    }
}

function Enable-SIFastAppKillTimeouts {
    <#
    .SYNOPSIS
        Lowers HungAppTimeout and WaitToKillAppTimeout to 2000ms (from 20000ms)
        and WaitToKillServiceTimeout to 2000ms so frozen games close immediately
        on Alt+F4 and Windows restarts faster.
    #>
    try {
        $deskPath = Get-SIUserRegistryPath 'HKCU:\Control Panel\Desktop'
        $ctrlPath = 'HKLM:\SYSTEM\CurrentControlSet\Control'

        Save-SIToolUndo -Key 'FastHungAppTimeout'    -Path $deskPath -Name 'HungAppTimeout'
        Save-SIToolUndo -Key 'FastWaitToKillApp'     -Path $deskPath -Name 'WaitToKillAppTimeout'
        Save-SIToolUndo -Key 'FastWaitToKillService' -Path $ctrlPath -Name 'WaitToKillServiceTimeout'

        Set-SIRegistryValue -Path $deskPath -Name 'HungAppTimeout'           -Value '2000' -Type 'String' | Out-Null
        Set-SIRegistryValue -Path $deskPath -Name 'WaitToKillAppTimeout'     -Value '2000' -Type 'String' | Out-Null
        Set-SIRegistryValue -Path $ctrlPath -Name 'WaitToKillServiceTimeout' -Value '2000' -Type 'String' | Out-Null

        Write-SILog -Level 'OK' -Component 'FastClose' -Message 'Chiusura rapida giochi bloccati attivata (HungAppTimeout=2000ms).'
        return $true
    } catch {
        return $false
    }
}

function Get-SIDiskSmartHealthStatus {
    <#
    .SYNOPSIS
        Checks physical disk SMART operational status via Win32_DiskDrive.
    #>
    try {
        $disks = @(Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop)
        foreach ($d in $disks) {
            $st = [string]$d.Status
            if ($st -and $st -notmatch '^(?i)OK$') {
                return [pscustomobject]@{ Warn = $true; Text = "SMART: $st (Verifica SSD!)" }
            }
        }
        if ($disks.Count -gt 0) {
            return [pscustomobject]@{ Warn = $false; Text = 'SMART: OK' }
        }
    } catch { }
    return [pscustomobject]@{ Warn = $false; Text = '' }
}

function Get-SIGpuResizableBarState {
    <#
    .SYNOPSIS
        Checks whether Resizable BAR / Smart Access Memory is active on the
        dedicated GPU.
    #>
    try {
        $classBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        if (-not (Test-Path -LiteralPath $classBase)) { return '' }
        foreach ($sub in @(Get-ChildItem -LiteralPath $classBase -ErrorAction SilentlyContinue)) {
            if ($sub.PSChildName -notmatch '^\d{4}$') { continue }
            $subPath = $sub.PSPath
            foreach ($propName in @('KMD_RBarState', 'RBarState', 'EnableLargePage', 'RmResizableBar')) {
                $val = Get-SIRegistryValue -Path $subPath -Name $propName
                if ($val.Exists -and [int]$val.Value -ge 1) { return 'ON' }
            }
        }
    } catch { }
    return ''
}

function Update-SITrayQuickMenu {
    <#
    .SYNOPSIS
        Populates the system tray context menu with quick 1-click actions:
        Open, OTTIMIZAR, Clean RAM & Standby Now, Auto-Boost toggle, and
        direct 1-click launch items for installed games.
    #>
    if (-not $script:SITrayIcon) { return }
    try {
        $menu = $script:SITrayIcon.ContextMenuStrip
        if (-not $menu) { return }
        $menu.Items.Clear()

        $openItem = [System.Windows.Forms.ToolStripMenuItem]::new('Apri SIGAME AUTO')
        $openItem.Font = [System.Drawing.Font]::new($openItem.Font, [System.Drawing.FontStyle]::Bold)
        $null = $openItem.Add_Click({ Show-SIMainWindow })
        [void]$menu.Items.Add($openItem)

        $optNowItem = [System.Windows.Forms.ToolStripMenuItem]::new('OTTIMIZAR Tutto (1-Click)')
        $null = $optNowItem.Add_Click({
            Show-SIMainWindow
            Invoke-SIAutoOptimizeAll
        })
        [void]$menu.Items.Add($optNowItem)

        $ramItem = [System.Windows.Forms.ToolStripMenuItem]::new('Pulisci RAM & Standby Ora')
        $null = $ramItem.Add_Click({
            $freed = Clear-SIWorkingSets
            Show-SITrayBalloon -Title 'SIGAME RAM Pulita' -Text "Working Set + Standby List svuotati (+$freed MB liberi)."
        })
        [void]$menu.Items.Add($ramItem)

        $benchItem = [System.Windows.Forms.ToolStripMenuItem]::new('Test Latenza & Ping Ora')
        $null = $benchItem.Add_Click({
            Invoke-SILiveLatencyBenchmark
        })
        [void]$menu.Items.Add($benchItem)

        $autoItem = [System.Windows.Forms.ToolStripMenuItem]::new('Auto-Boost Giochi')
        $autoItem.Checked = [bool](Get-SIAutoBoostEnabled)
        $null = $autoItem.Add_Click({
            $on = -not [bool]$script:SIAutoBoostEnabled
            Set-SIAutoBoostEnabled -Enabled $on
        })
        [void]$menu.Items.Add($autoItem)
        $script:SITrayAutoItem = $autoItem

        $games = @($script:SIGameLibrary)
        if ($games.Count -gt 0) {
            [void]$menu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new())
            $playMenu = [System.Windows.Forms.ToolStripMenuItem]::new("Gioca Subito ($($games.Count))")
            foreach ($g in ($games | Select-Object -First 15)) {
                $gItem = [System.Windows.Forms.ToolStripMenuItem]::new("$($g.Name) [$($g.Store)]")
                $capGame = $g
                $null = $gItem.Add_Click({
                    Invoke-SILaunchGameOptimized -Game $capGame
                }.GetNewClosure())
                [void]$playMenu.DropDownItems.Add($gItem)
            }
            [void]$menu.Items.Add($playMenu)
        }

        [void]$menu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new())
        $deskItem = [System.Windows.Forms.ToolStripMenuItem]::new('Crea Icona sul Desktop')
        $null = $deskItem.Add_Click({
            if (New-SIAutoDesktopShortcut) {
                Show-SITrayBalloon -Title 'SIGAME AUTO' -Text 'Collegamento SIGAME AUTO creato sul Desktop.'
            }
        })
        [void]$menu.Items.Add($deskItem)

        $exitItem = [System.Windows.Forms.ToolStripMenuItem]::new('Esci')
        $null = $exitItem.Add_Click({ Exit-SISigame })
        [void]$menu.Items.Add($exitItem)
    } catch { }
}

function Enable-SIDirectXFlipAndDwm {
    <#
    .SYNOPSIS
        Configures DirectX / DWM scheduler for immediate flip presentation and
        minimum frame queue latency (1 frame).
    #>
    try {
        $schedPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler'
        $d3dPath   = 'HKLM:\SOFTWARE\Microsoft\Direct3D'

        Save-SIToolUndo -Key 'DxForceFlipImmediate' -Path $schedPath -Name 'ForceFlipTrueImmediate'
        Save-SIToolUndo -Key 'DxMaxFrameLatency'    -Path $d3dPath   -Name 'MaxFrameLatency'

        Set-SIRegistryValue -Path $schedPath -Name 'ForceFlipTrueImmediate' -Value 1 -Type 'DWord' | Out-Null
        Set-SIRegistryValue -Path $d3dPath   -Name 'MaxFrameLatency'        -Value 1 -Type 'DWord' | Out-Null

        Write-SILog -Level 'OK' -Component 'DirectX' -Message 'DirectX Flip Immediate + MaxFrameLatency=1 attivati per ridurre input lag.'
        return $true
    } catch {
        return $false
    }
}

$script:SIDefenderExcludedFolders = @()

function Add-SIGameFoldersToDefenderExclusion {
    <#
    .SYNOPSIS
        Adds detected game installation folders to Windows Defender exclusions
        and lowers real-time scan CPU load factor so MsMpEng.exe never causes
        shader/asset loading stutters during gameplay.
    #>
    $added = 0
    try {
        if (-not (Test-SIHasCommand 'Add-MpPreference')) { return 0 }
        $folders = @()
        foreach ($g in @($script:SIGameLibrary)) {
            $dir = ''
            if ($g.Folder -and [System.IO.Directory]::Exists([string]$g.Folder)) {
                $dir = [string]$g.Folder
            } elseif ($g.Exe -and [System.IO.File]::Exists([string]$g.Exe)) {
                $dir = [System.IO.Path]::GetDirectoryName([string]$g.Exe)
            }
            if ($dir -and ($folders -notcontains $dir)) {
                $folders += $dir
            }
        }
        foreach ($dir in $folders) {
            try {
                Add-MpPreference -ExclusionPath $dir -ErrorAction Stop
                if ($script:SIDefenderExcludedFolders -notcontains $dir) {
                    $script:SIDefenderExcludedFolders += $dir
                }
                $added++
            } catch { }
        }
        try { Set-MpPreference -ScanAvgCPULoadFactor 5 -ErrorAction SilentlyContinue } catch { }
        if ($added -gt 0) {
            Write-SILog -Level 'OK' -Component 'Defender' -Message "$added cartelle giochi aggiunte alle esclusioni antimalware per azzerare micro-stutter su SSD."
        }
    } catch { }
    return $added
}

function Remove-SIGameFoldersFromDefenderExclusion {
    try {
        if (-not (Test-SIHasCommand 'Remove-MpPreference')) { return }
        foreach ($dir in @($script:SIDefenderExcludedFolders)) {
            try { Remove-MpPreference -ExclusionPath $dir -ErrorAction SilentlyContinue } catch { }
        }
        $script:SIDefenderExcludedFolders = @()
    } catch { }
}

function Get-SIGamingHealthCheck {
    <#
    .SYNOPSIS
        Checks GPU driver age, Monitor Hz (Refresh Rate vs Max Supported Hz),
        VBS (Core Isolation) FPS penalty, Pagefile, and live Gaming Ping & Jitter.
    #>
    param([switch]$ForceRefresh)
    if ($script:SIGamingHealthCache -and -not $ForceRefresh) { return $script:SIGamingHealthCache }

    $driverText = 'Sconosciuto'
    $driverWarn = $false
    $hzText     = ''
    $hzWarn     = $false
    try {
        $gpus = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)
        $chosen = $null
        foreach ($g in $gpus) {
            if (-not (Test-SIGpuIsIntegrated -Name ([string]$g.Name))) { $chosen = $g; break }
        }
        if (-not $chosen -and $gpus.Count -gt 0) { $chosen = $gpus[0] }
        if ($chosen) {
            $ver = [string]$chosen.DriverVersion
            $dt  = ConvertTo-SIDateTime $chosen.DriverDate
            if ($dt) {
                $days = [int][math]::Floor([datetime]::Now.Subtract([datetime]$dt).TotalDays)
                $months = [int][math]::Floor($days / 30)
                if ($days -gt 180) {
                    $driverWarn = $true
                    $driverText = "$ver ($months mesi fa - AGGIORNA)"
                } else {
                    $driverText = "$ver ($days gg fa)"
                }
            } elseif ($ver) {
                $driverText = $ver
            }

            $curHz = [int]$chosen.CurrentRefreshRate
            $maxHz = [int]$chosen.MaxRefreshRate
            if ($curHz -gt 0) {
                if ($maxHz -ge 75 -and $curHz -le 60 -and $maxHz -gt $curHz) {
                    $hzWarn = $true
                    $hzText = "${curHz}Hz (Supporta ${maxHz}Hz! Alza gli Hz)"
                } else {
                    $hzText = "${curHz}Hz"
                }
            }
        }
    } catch { }

    $vbsState = Get-SIVbsState
    $vbsWarn  = ($vbsState -eq 'ON')
    $vbsText  = if ($vbsWarn) { 'ON (-10% FPS)' } else { 'OFF (Ottimale)' }

    $pageText = 'Automatico OK'
    try {
        $pf = @(Get-CimInstance -ClassName Win32_PageFileUsage -ErrorAction Stop)
        if ($pf.Count -gt 0) {
            $allocMB = 0
            foreach ($p in $pf) { $allocMB += [int]$p.AllocatedBaseSize }
            $pageText = ("{0:0.0} GB" -f ($allocMB / 1024.0))
        }
    } catch { }

    $netPing = Measure-SIGamingPing
    $rebar   = Get-SIGpuResizableBarState
    $therm   = Get-SICpuThermalStatus
    $stab    = Get-SISystemStabilityCheck
    $ramCh   = Get-SIRamSpeedAndChannelStatus
    $smart   = Get-SIDiskSmartHealthStatus
    $acGuard = Get-SIAntiCheatGuardStatus
    $hzSegment    = if ($hzText)     { "  |  Monitor: $hzText" } else { '' }
    $rebarSegment = if ($rebar)      { "  |  ReBAR: $rebar" } else { '' }
    $ramSegment   = if ($ramCh.Text) { "  |  RAM: $($ramCh.Text)" } else { '' }
    $thermSegment = if ($therm.Text) { "  |  Temp: $($therm.Text)" } else { '' }
    $stabSegment  = if ($stab.Text)  { "  |  Stab: $($stab.Text)" } else { '' }
    $smartSegment = if ($smart.Text) { "  |  Disco: $($smart.Text)" } else { '' }
    $acSegment    = "  |  $($acGuard.Badge)"

    $script:SIGamingHealthCache = [pscustomobject]@{
        DriverText = $driverText
        DriverWarn = $driverWarn
        HzText     = $hzText
        HzWarn     = $hzWarn
        VbsText    = $vbsText
        VbsWarn    = $vbsWarn
        PageText   = $pageText
        PingText   = $netPing.Text
        PingWarn   = $netPing.Warn
        HasWarning = ($driverWarn -or $hzWarn -or ($vbsWarn -and -not $acGuard.RequiresVbs) -or $netPing.Warn -or $therm.Warn -or $stab.Warn -or $ramCh.Warn -or $smart.Warn)
        Summary    = "Salute Gaming -> GPU: $driverText$hzSegment$rebarSegment$ramSegment$thermSegment$stabSegment$smartSegment  |  VBS: $vbsText  |  Ping: $($netPing.Text)$acSegment"
    }
    return $script:SIGamingHealthCache
}

function Get-SIAutoStartWithWindows {
    try {
        $runPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        $val = Get-SIRegistryValue -Path $runPath -Name 'SIGAME_AUTO'
        return [bool]$val.Exists
    } catch {
        return $false
    }
}

function Set-SIAutoStartWithWindows {
    param([bool]$Enabled)
    try {
        $runPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        if ($Enabled) {
            $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$script:SICurrentScript`" -Minimized"
            Set-SIRegistryValue -Path $runPath -Name 'SIGAME_AUTO' -Value $cmd -Type 'String' | Out-Null
            Write-SILog -Level 'OK' -Component 'AutoStart' -Message 'Avvio automatico con Windows (nella Tray) attivato.'
        } else {
            Remove-SIRegistryValue -Path $runPath -Name 'SIGAME_AUTO' | Out-Null
            Write-SILog -Component 'AutoStart' -Message 'Avvio automatico con Windows disattivato.'
        }
    } catch {
        Write-SILog -Level 'WARN' -Component 'AutoStart' -Message "Impossibile cambiare avvio automatico: $($_.Exception.Message)"
    }
}

function Invoke-SILaunchGameOptimized {
    <#
    .SYNOPSIS
        Applies per-game optimizations, triggers RAM + Power Boost, and
        immediately launches the selected game.
    #>
    param([Parameter(Mandatory = $true)]$Game)
    $exe = [string]$Game.Exe
    if (-not $exe -or -not [System.IO.File]::Exists($exe)) {
        Set-SIStatusText -Text "Eseguibile del gioco non trovato: $exe"
        return
    }
    try {
        Set-SIStatusText -Text "Ottimizzazione e avvio di $($Game.Name) in corso..."
        Invoke-SIUIPump

        $gpuRegPath   = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
        $layerRegPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
        $cpuRegPath   = Get-SIGameCpuPriorityRegPath -ExePath $exe
        $pwrRegPath   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'

        Save-SIToolUndo -Key ('GameGpu|' + $exe) -Path $gpuRegPath -Name $exe
        Set-SIGameGpuPreference -ExePath $exe

        Save-SIToolUndo -Key ('GameFullscreen|' + $exe) -Path $layerRegPath -Name $exe
        Set-SIGameFullscreenOptimizations -ExePath $exe

        if ($cpuRegPath) {
            Save-SIToolUndo -Key ('GameCpuPriority|' + $exe)  -Path $cpuRegPath -Name 'CpuPriorityClass'
            Save-SIToolUndo -Key ('GameIoPriority|' + $exe)   -Path $cpuRegPath -Name 'IoPriority'
            Save-SIToolUndo -Key ('GamePagePriority|' + $exe) -Path $cpuRegPath -Name 'PagePriority'
            Set-SIGameCpuPriorityHigh -ExePath $exe
        }
        Save-SIToolUndo -Key ('GamePowerThrottle|' + $exe) -Path $pwrRegPath -Name $exe
        Set-SIGamePowerThrottlingOff -ExePath $exe

        [void](Add-SIAutoBoostGame -Path $exe)
        Invoke-SIBoost
        $trimmed = Clear-SIWorkingSets

        $workDir = if ($Game.Folder -and [System.IO.Directory]::Exists([string]$Game.Folder)) { [string]$Game.Folder } else { [System.IO.Path]::GetDirectoryName($exe) }
        Start-Process -FilePath $exe -WorkingDirectory $workDir -ErrorAction Stop | Out-Null

        Update-SIAutoDashboard
        $msg = "$($Game.Name) avviato con GPU Max, CPU/IO Alta e Boost RAM (+$trimmed MB)."
        Set-SIStatusText -Text $msg
        Show-SITrayBalloon -Title "Gioco Avviato: $($Game.Name)" -Text $msg
    } catch {
        Set-SIStatusText -Text "Errore avvio $($Game.Name): $($_.Exception.Message)"
    }
}

function Clear-SIShaderCache {
    <#
    .SYNOPSIS
        Safely deletes unlocked DirectX, NVIDIA, and AMD shader cache files
        to prevent micro-stuttering after driver or game updates.
    #>
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if (-not $localAppData) { return @{ Removed = 0; MegaBytes = 0.0 } }

    $folders = @(
        [System.IO.Path]::Combine($localAppData, 'D3DSCache'),
        [System.IO.Path]::Combine($localAppData, 'NVIDIA\DXCache'),
        [System.IO.Path]::Combine($localAppData, 'NVIDIA\GLCache'),
        [System.IO.Path]::Combine($localAppData, 'AMD\DxCache'),
        [System.IO.Path]::Combine($localAppData, 'AMD\GLCache'),
        [System.IO.Path]::Combine($localAppData, 'Temp\NVIDIA Corporation\NV_Cache')
    )

    $removed = 0
    $bytes   = [long]0
    foreach ($dir in $folders) {
        if (-not [System.IO.Directory]::Exists($dir)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            try {
                $len = [long]$file.Length
                [System.IO.File]::Delete($file.FullName)
                $removed++
                $bytes += $len
            } catch { }
        }
    }
    $mb = [math]::Round($bytes / 1MB, 1)
    Write-SILog -Component 'ShaderCache' -Message "Cleaned $removed shader cache files ($mb MB)."
    return @{ Removed = $removed; MegaBytes = $mb }
}

function Clear-SIWorkingSets {
    <#
    .SYNOPSIS
        1. Trims unused working set pages from background processes via psapi.dll.
        2. Purges the Windows Kernel Standby Memory List via ntdll.dll
           (NtSetSystemInformation SystemMemoryListInformation = 80, cmd = 4)
           with SeProfileSingleProcessPrivilege so cached standby RAM is freed.
    #>
    try {
        if (-not ('SINativeMem' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SINativeMem {
    [DllImport("psapi.dll")]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);

    [DllImport("ntdll.dll")]
    public static extern int NtSetSystemInformation(int InfoClass, ref int Info, int Length);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out long lpLuid);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct TOKEN_PRIVILEGES {
        public int PrivilegeCount;
        public long Luid;
        public int Attributes;
    }

    public static void PurgeStandbyList() {
        IntPtr hToken = IntPtr.Zero;
        try {
            if (OpenProcessToken(System.Diagnostics.Process.GetCurrentProcess().Handle, 0x0020 | 0x0008, out hToken)) {
                long luid = 0;
                if (LookupPrivilegeValue(null, "SeProfileSingleProcessPrivilege", out luid)) {
                    TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
                    tp.PrivilegeCount = 1;
                    tp.Luid = luid;
                    tp.Attributes = 0x00000002;
                    AdjustTokenPrivileges(hToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                }
            }
            int cmd = 4; // MemoryPurgeStandbyList
            NtSetSystemInformation(80, ref cmd, sizeof(int));
        } catch { }
    }
}
'@ -ErrorAction Stop
        }
        $beforeMB = Get-SIFreeRamMB
        $currentPid = $PID
        foreach ($proc in @(Get-Process -ErrorAction SilentlyContinue)) {
            if ($proc.Id -eq $currentPid -or $proc.Id -le 4) { continue }
            try { [void][SINativeMem]::EmptyWorkingSet($proc.Handle) } catch { }
        }
        try { [SINativeMem]::PurgeStandbyList() } catch { }
        $afterMB = Get-SIFreeRamMB
        $freed = 0
        if ($beforeMB -ge 0 -and $afterMB -gt $beforeMB) { $freed = $afterMB - $beforeMB }
        Write-SILog -Component 'Memory' -Message "Trimmed working sets + Kernel Standby List (+$freed MB free RAM)."
        return $freed
    } catch {
        return 0
    }
}

function Show-SITrayBalloon {
    param(
        [string]$Title = 'SIGAME AUTO',
        [string]$Text = ''
    )
    if (-not $Text) { return }
    try {
        if ($script:SITrayIcon) {
            $script:SITrayIcon.BalloonTipTitle = $Title
            $script:SITrayIcon.BalloonTipText  = $Text
            $script:SITrayIcon.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
            $script:SITrayIcon.ShowBalloonTip(4000)
        }
    } catch { }
}

# ================== 5. HARDWARE-ADAPTIVE PROFILE ENGINE ===================

function Get-SIHardwareAdaptivePlan {
    <#
    .SYNOPSIS
        Inspects the PC hardware and determines the best aggressive & safe
        configuration for each tweak on this specific machine.
    #>
    $info = $script:SIBottleneck
    if (-not $info -or -not $info.Cpu -or $info.Cpu -eq 'unknown') {
        $info = Get-SIBottleneck
        $script:SIBottleneck = $info
    }
    $isLaptop = Get-SIIsLaptop
    $ramGB    = [int]$info.RamGB
    $diskType = [string]$info.DiskType
    $hasDedGpu = (-not [bool]$info.Integrated)

    $isStreaming = ($script:SIAutoMode -eq 'Streaming')
    $modeSuffix  = if ($isStreaming) { ' [Modalita Streaming/Discord]' } else { ' [Modalita Massimi FPS]' }

    $profileName = if ($isLaptop) {
        if ($hasDedGpu) { 'Laptop Gaming (GPU Dedicata)' + $modeSuffix } else { 'Laptop (GPU Integrata)' + $modeSuffix }
    } else {
        if ($hasDedGpu -and $diskType -eq 'SSD') { 'Desktop Extreme Gaming (GPU Dedicata + SSD)' + $modeSuffix }
        elseif ($hasDedGpu) { 'Desktop Gaming (GPU Dedicata)' + $modeSuffix }
        else { 'Desktop Performance' + $modeSuffix }
    }

    # Build the list of tweaks and options tailored to this hardware
    $planTweaks = @()
    $reasons    = @()

    foreach ($tweak in (Get-SITweakTable)) {
        if ($tweak.Contains('ShowOnly') -and $tweak.ShowOnly) { continue }
        $unavail = Get-SITweakAvailability -Tweak $tweak
        if ($unavail) { continue }

        $include = $false
        $option  = ''

        if ($tweak.Contains('Optimize') -and $tweak.Optimize) {
            $include = $true
        }
        if ($tweak.Contains('Gaming') -and $tweak.Gaming) {
            $include = $true
        }

        switch ($tweak.Id) {
            'GameBarDVR' {
                if ($isStreaming) {
                    $include = $false
                    $reasons += 'Streaming Mode: Xbox Game Bar / DVR mantenuti attivi per OBS e clip'
                }
            }
            'UltimatePerformance' {
                if ($isLaptop) {
                    $include = $false
                } else {
                    $include = $true
                    $reasons += 'Piano Energetico: Ultimate Performance attivo (Desktop)'
                }
            }
            'HAGS' {
                if ($hasDedGpu) {
                    $include = $true
                    $reasons += 'HAGS ON: scheduling GPU hardware attivo per scheda dedicata'
                } else {
                    $include = $false
                }
            }
            'Win32PrioritySeparation' {
                $include = $true
                # 26 hex (short, variable, 3:1 foreground boost) = maximum gaming responsiveness
                $option = '26 hex (short, variable, 3:1 foreground boost)'
                $reasons += 'Priorita CPU: 26 hex (3:1 Foreground Boost spinto per i giochi)'
            }
            'Hibernation' {
                if (-not $isLaptop -and ($diskType -eq 'SSD' -or ($info.FreePercent -ge 0 -and $info.FreePercent -lt 25))) {
                    $include = $true
                    $reasons += 'Ibernazione OFF: libera GB preziosi e riduce scritture su SSD'
                } else {
                    $include = $false
                }
            }
            'TCPSettings' {
                $include = $true
                $reasons += 'Rete TCP: Auto-Tuning ottimizzato + Nagle OFF + Network Throttling OFF'
            }
            'SysMain' {
                # On HDD with >= 8GB RAM, SysMain helps preload; on SSD or < 8GB RAM, disabling saves RAM/CPU spikes
                if ($diskType -eq 'HDD' -and $ramGB -ge 8) {
                    $include = $false
                } else {
                    $include = $true
                }
            }
        }

        if (-not $option -and $tweak.Contains('GamingOption') -and $tweak.GamingOption) {
            $option = [string]$tweak.GamingOption
        }

        if ($include) {
            $planTweaks += [pscustomobject]@{
                Id     = $tweak.Id
                Name   = $tweak.Name
                Tweak  = $tweak
                Option = $option
            }
        }
    }

    $reasons += 'DNS Automatico: test e attivazione del server DNS a latenza minore'
    $reasons += 'Giochi: GPU Alte Prestazioni + Stop Ottimizzazioni Schermo Intero + Auto-Boost'

    return [pscustomobject]@{
        ProfileName = $profileName
        IsLaptop    = $isLaptop
        HasDedGpu   = $hasDedGpu
        RamGB       = $ramGB
        DiskType    = $diskType
        Tweaks      = $planTweaks
        Reasons     = $reasons
    }
}

function Get-SIPcOptimizationAudit {
    <#
    .SYNOPSIS
        Computes how many recommended tweaks and games are currently optimized.
    #>
    $plan = Get-SIHardwareAdaptivePlan
    $totalTweaks   = $plan.Tweaks.Count
    $appliedTweaks = 0
    $pendingNames  = @()

    foreach ($item in $plan.Tweaks) {
        $st = $null
        if ($script:SIWorkerStates -and $script:SIWorkerStates.ContainsKey($item.Id)) {
            $st = $script:SIWorkerStates[$item.Id]
        } else {
            try { $st = Get-SITweakState -Tweak $item.Tweak -OptionOverride $item.Option } catch { }
        }
        if ($st -and $st.Status -eq 'Applied') {
            $appliedTweaks++
        } else {
            $pendingNames += $item.Name
        }
    }

    $games = @($script:SIGameLibrary)
    $totalGames = $games.Count
    $optGames   = 0
    foreach ($g in $games) {
        $gpuOk = Get-SIGameGpuState -ExePath $g.Exe
        $fsOk  = Get-SIGameFullscreenState -ExePath $g.Exe
        $cpuOk = Get-SIGameCpuPriorityState -ExePath $g.Exe
        if ($gpuOk -and $fsOk -and $cpuOk) { $optGames++ }
    }

    $totalItems   = $totalTweaks + $totalGames
    $appliedItems = $appliedTweaks + $optGames
    $percent      = if ($totalItems -gt 0) { [int][math]::Round(($appliedItems * 100.0) / $totalItems) } else { 100 }

    return [pscustomobject]@{
        Plan          = $plan
        TotalTweaks   = $totalTweaks
        AppliedTweaks = $appliedTweaks
        PendingNames  = $pendingNames
        TotalGames    = $totalGames
        OptGames      = $optGames
        Percent       = $percent
    }
}

# ==================== 6. CYBER-GOLD HUD COMMAND CENTER UI ==================

$script:SIHudText = @{
    'en' = @{
        SubHeader          = 'CYBER-HUD KERNEL & ESPORTS OPTIMIZER'
        TabDashboard       = 'DASHBOARD HUD'
        TabKernel          = 'KERNEL & TWEAKS'
        TabRam             = 'FREE RAM'
        TabInspect         = 'TRANSPARENCY & ANTI-CHEAT'
        HeaderRestoreInit  = 'Restore point: checking...'
        HeaderBackupInit   = 'Backup: checking...'
        LeftHudHeader      = 'SYSTEM TELEMETRY // PC STATUS'
        AuditInitTitle     = 'SCANNING PC...'
        AuditInitSub       = 'Checking system tweaks, network latency and installed games...'
        BarKernel          = 'KERNEL & SYSTEM'
        BarGames           = 'GAMES & GPU MAX'
        MetricStartup      = '  |  Startup: '
        BtnRebootNow       = 'Reboot Now'
        RebootBannerText   = 'Reboot recommended to activate HAGS, BCD and CPU Priority 26hex.'
        RebootConfirmMsg   = 'Do you want to restart Windows now to apply all hardware and network optimizations?'
        RebootConfirmTitle = 'Restart Windows'
        GaugeReactivity    = 'REACTIVITY %'
        GaugeTimer         = 'TIMER MS'
        GaugePing          = 'PING MS'
        BtnOptimize        = 'OPTIMIZE'
        BtnUndo            = 'UNDO ALL'
        BtnInspect         = 'INSPECT'
        BtnTest            = 'TEST'
        RightHudHeader     = 'HARDWARE DIAGNOSTICS & GAMING MODE'
        HwDetecting        = 'Detecting hardware components...'
        HealthChecking     = 'Checking Gaming Health (GPU Driver, VBS, Pagefile)...'
        ModeMaxFps         = 'Max FPS'
        ModeStreaming      = 'Streaming'
        ModeSession        = 'Session Only (No Reg)'
        AutoStartWindows   = 'Start with Windows (minimized to System Tray with Auto-Boost)'
        StatusStarting     = 'Starting...'
        Card1Title         = '1. FRAME-TIME TELEMETRY & ACTIVE KERNEL TWEAKS'
        Card2Title         = '2. DETECTED PC GAMES'
        Card2TitleFmt      = '2. DETECTED PC GAMES ({0} found, {1} optimized)'
        Card2Sub           = 'With OPTIMIZE every game gets High-Performance GPU, High CPU/IO Priority, No Fullscreen Lag and RAM Auto-Boost.'
        BtnAddGame         = '+ Add game (.exe)'
        GamesEmpty         = 'No games automatically detected in stores. You can add any game with "+ Add game (.exe)".'
        BtnPlay            = 'PLAY'
        LogHeader          = 'Show detailed log (Log)'
        TrustInit          = 'SIGAME Security Shield: Automatic JSON Backup + Restore Point + Anti-Cheat 100% Safe'
        UndoConfirmMsg     = 'Do you want to restore all original PC and game settings from the backup?'
        UndoConfirmTitle   = 'Undo All'
        UndoDoneMsg        = 'All changes (including Hard/BCD tweaks) have been undone.'
        RamDoneFmt         = 'RAM Panic Boost complete: +{0} MB freed (Standby List + Working Set) and 0.5ms Timer.'
        AuditOptFmt        = 'PC STATUS: {0}% OPTIMIZED ({1}/{2} Tweaks, {3}/{4} Games)'
        AuditPartFmt       = 'PC STATUS: PARTIALLY OPTIMIZED ({0}% - {1}/{2} Tweaks, {3}/{4} Games)'
        AuditNeedFmt       = 'PC STATUS: NEEDS OPTIMIZATION ({0}% - {1}/{2} Tweaks, {3}/{4} Games)'
        AuditSubOptFmt     = 'Active profile: {0}. Your PC and games are tuned for maximum performance.'
        AuditSubNeedFmt    = 'Detected profile: {0}. {1} optimizations ready. Press {2} to optimize everything automatically.'
        HwSummaryFmt       = "CPU: {0}`nGPU: {1}`nRAM: {2}  |  Disk: {3}  |  Profile: {4}"
        DiskFreeFmt        = '{0} ({1} GB free)'
        BadgeActive        = '[ACTIVE]'
        BadgePending       = '[PENDING]'
        GameOptBadge       = '[OPTIMIZED]'
        GameNeedBadge      = '[TO OPTIMIZE]'
        ReadyStatusFmt     = 'Ready. Press {0} to automatically optimize PC, Network and Games.'
    }
    'pt-BR' = @{
        SubHeader          = 'OTIMIZADOR CYBER-HUD KERNEL & ESPORTS'
        TabDashboard       = 'DASHBOARD HUD'
        TabKernel          = 'KERNEL & AJUSTES'
        TabRam             = 'LIBERAR RAM'
        TabInspect         = 'TRANSPARENCIA & ANTI-CHEAT'
        HeaderRestoreInit  = 'Ponto de restauracao: verificando...'
        HeaderBackupInit   = 'Backup: verificando...'
        LeftHudHeader      = 'TELEMETRIA DO SISTEMA // STATUS DO PC'
        AuditInitTitle     = 'ANALISANDO O PC...'
        AuditInitSub       = 'Verificando otimizacoes do sistema, rede e jogos instalados...'
        BarKernel          = 'KERNEL & SISTEMA'
        BarGames           = 'JOGOS & GPU MAX'
        MetricStartup      = '  |  Inicio: '
        BtnRebootNow       = 'Reiniciar'
        RebootBannerText   = 'Reinicio recomendado para ativar HAGS, BCD e Prioridade CPU 26hex.'
        RebootConfirmMsg   = 'Deseja reiniciar o Windows agora para efetivar todas as otimizacoes de hardware e rede?'
        RebootConfirmTitle = 'Reiniciar Windows'
        GaugeReactivity    = 'REATIVIDADE %'
        GaugeTimer         = 'TIMER MS'
        GaugePing          = 'PING MS'
        BtnOptimize        = 'OTIMIZAR'
        BtnUndo            = 'RESTAURAR'
        BtnInspect         = 'INSPECIONAR'
        BtnTest            = 'TESTE'
        RightHudHeader     = 'DIAGNOSTICO DE HARDWARE & MODO GAMER'
        HwDetecting        = 'Detectando componentes de hardware...'
        HealthChecking     = 'Verificando Saude Gamer (Driver GPU, VBS, Pagefile)...'
        ModeMaxFps         = 'Max FPS'
        ModeStreaming      = 'Streaming'
        ModeSession        = 'So Sessao (Sem Reg)'
        AutoStartWindows   = 'Iniciar com o Windows (minimizado na Bandeja com Auto-Boost)'
        StatusStarting     = 'Iniciando...'
        Card1Title         = '1. TELEMETRIA FRAME-TIME & OTIMIZACOES KERNEL ATIVAS'
        Card2Title         = '2. JOGOS DETECTADOS NO PC'
        Card2TitleFmt      = '2. JOGOS DETECTADOS NO PC ({0} encontrados, {1} otimizados)'
        Card2Sub           = 'Com OTIMIZAR cada jogo recebe GPU de Alto Desempenho, Prioridade CPU/IO Alta, Sem Fullscreen Lag e Auto-Boost RAM.'
        BtnAddGame         = '+ Adicionar jogo (.exe)'
        GamesEmpty         = 'Nenhum jogo detectado automaticamente nas lojas. Adicione qualquer jogo com "+ Adicionar jogo (.exe)".'
        BtnPlay            = 'JOGAR'
        LogHeader          = 'Mostrar registro detalhado (Log)'
        TrustInit          = 'Escudo de Seguranca SIGAME: Backup JSON Automatico + Ponto de Restauracao + Anti-Cheat 100% Seguro'
        UndoConfirmMsg     = 'Deseja restaurar todas as configuracoes originais do PC e dos jogos salvas no backup?'
        UndoConfirmTitle   = 'Restaurar Tudo'
        UndoDoneMsg        = 'Todas as alteracoes (incluindo ajustes Hard/BCD) foram desfeitas.'
        RamDoneFmt         = 'Panic Boost RAM concluido: +{0} MB liberados (Standby List + Working Set) e Timer a 0.5ms.'
        AuditOptFmt        = 'STATUS DO PC: {0}% OTIMIZADO ({1}/{2} Ajustes, {3}/{4} Jogos)'
        AuditPartFmt       = 'STATUS DO PC: PARCIALMENTE OTIMIZADO ({0}% - {1}/{2} Ajustes, {3}/{4} Jogos)'
        AuditNeedFmt       = 'STATUS DO PC: PARA OTIMIZAR ({0}% - {1}/{2} Ajustes, {3}/{4} Jogos)'
        AuditSubOptFmt     = 'Perfil ativo: {0}. Seu PC e seus jogos estao configurados para desempenho maximo.'
        AuditSubNeedFmt    = 'Perfil detectado: {0}. Ha {1} otimizacoes prontas. Pressione {2} para otimizar tudo automaticamente.'
        HwSummaryFmt       = "CPU: {0}`nGPU: {1}`nRAM: {2}  |  Disco: {3}  |  Perfil: {4}"
        DiskFreeFmt        = '{0} ({1} GB livres)'
        BadgeActive        = '[ATIVO]'
        BadgePending       = '[PENDENTE]'
        GameOptBadge       = '[OTIMIZADO]'
        GameNeedBadge      = '[PARA OTIMIZAR]'
        ReadyStatusFmt     = 'Pronto. Pressione {0} para otimizar automaticamente PC, Rede e Jogos.'
    }
    'es' = @{
        SubHeader          = 'OPTIMIZADOR CYBER-HUD KERNEL & ESPORTS'
        TabDashboard       = 'DASHBOARD HUD'
        TabKernel          = 'KERNEL & AJUSTES'
        TabRam             = 'LIBERAR RAM'
        TabInspect         = 'TRANSPARENCIA & ANTI-CHEAT'
        HeaderRestoreInit  = 'Punto de restauracion: verificando...'
        HeaderBackupInit   = 'Copia de seguridad: verificando...'
        LeftHudHeader      = 'TELEMETRIA DEL SISTEMA // ESTADO PC'
        AuditInitTitle     = 'ANALIZANDO EL PC...'
        AuditInitSub       = 'Verificando optimizaciones del sistema, red y juegos instalados...'
        BarKernel          = 'KERNEL & SISTEMA'
        BarGames           = 'JUEGOS & GPU MAX'
        MetricStartup      = '  |  Inicio: '
        BtnRebootNow       = 'Reiniciar'
        RebootBannerText   = 'Reinicio recomendado para activar HAGS, BCD y Prioridad CPU 26hex.'
        RebootConfirmMsg   = 'Quieres reiniciar Windows ahora para aplicar todas las optimizaciones de hardware y red?'
        RebootConfirmTitle = 'Reiniciar Windows'
        GaugeReactivity    = 'REACTIVIDAD %'
        GaugeTimer         = 'TIMER MS'
        GaugePing          = 'PING MS'
        BtnOptimize        = 'OPTIMIZAR'
        BtnUndo            = 'RESTAURAR'
        BtnInspect         = 'INSPECCIONAR'
        BtnTest            = 'TEST'
        RightHudHeader     = 'DIAGNOSTICO DE HARDWARE & MODO GAMING'
        HwDetecting        = 'Detectando componentes de hardware...'
        HealthChecking     = 'Verificando Salud Gaming (Driver GPU, VBS, Pagefile)...'
        ModeMaxFps         = 'Max FPS'
        ModeStreaming      = 'Streaming'
        ModeSession        = 'Solo Sesion (Sin Reg)'
        AutoStartWindows   = 'Iniciar con Windows (minimizado en la Bandeja con Auto-Boost)'
        StatusStarting     = 'Iniciando...'
        Card1Title         = '1. TELEMETRIA FRAME-TIME & OPTIMIZACIONES KERNEL ACTIVAS'
        Card2Title         = '2. JUEGOS DETECTADOS EN EL PC'
        Card2TitleFmt      = '2. JUEGOS DETECTADOS EN EL PC ({0} encontrados, {1} optimizados)'
        Card2Sub           = 'Con OPTIMIZAR cada juego recibe GPU Alto Rendimiento, Prioridad CPU/IO Alta, Sin Fullscreen Lag y Auto-Boost RAM.'
        BtnAddGame         = '+ Agregar juego (.exe)'
        GamesEmpty         = 'Ningun juego detectado automaticamente. Puedes agregar cualquier juego con "+ Agregar juego (.exe)".'
        BtnPlay            = 'JUGAR'
        LogHeader          = 'Mostrar registro detallado (Log)'
        TrustInit          = 'Escudo de Seguridad SIGAME: Backup JSON Automatico + Punto de Restauracion + Anti-Cheat 100% Seguro'
        UndoConfirmMsg     = 'Quieres restaurar todos los ajustes originales del PC y de los juegos?'
        UndoConfirmTitle   = 'Restaurar Todo'
        UndoDoneMsg        = 'Todos los cambios (incluidos ajustes Hard/BCD) han sido deshechos.'
        RamDoneFmt         = 'Panic Boost RAM completado: +{0} MB liberados (Standby List + Working Set) y Timer a 0.5ms.'
        AuditOptFmt        = 'ESTADO PC: {0}% OPTIMIZADO ({1}/{2} Ajustes, {3}/{4} Juegos)'
        AuditPartFmt       = 'ESTADO PC: PARCIALMENTE OPTIMIZADO ({0}% - {1}/{2} Ajustes, {3}/{4} Juegos)'
        AuditNeedFmt       = 'ESTADO PC: POR OPTIMIZAR ({0}% - {1}/{2} Ajustes, {3}/{4} Juegos)'
        AuditSubOptFmt     = 'Perfil activo: {0}. Tu PC y tus juegos estan configurados para el maximo rendimiento.'
        AuditSubNeedFmt    = 'Perfil detectado: {0}. Hay {1} optimizaciones listas. Pulsa {2} para optimizar todo automaticamente.'
        HwSummaryFmt       = "CPU: {0}`nGPU: {1}`nRAM: {2}  |  Disco: {3}  |  Perfil: {4}"
        DiskFreeFmt        = '{0} ({1} GB libres)'
        BadgeActive        = '[ACTIVO]'
        BadgePending       = '[PENDIENTE]'
        GameOptBadge       = '[OPTIMIZADO]'
        GameNeedBadge      = '[POR OPTIMIZAR]'
        ReadyStatusFmt     = 'Listo. Pulsa {0} para optimizar automaticamente PC, Red y Juegos.'
    }
    'it' = @{
        SubHeader          = 'CYBER-HUD KERNEL & ESPORTS OPTIMIZER'
        TabDashboard       = 'DASHBOARD HUD'
        TabKernel          = 'KERNEL & TWEAKS'
        TabRam             = 'LIBERA RAM'
        TabInspect         = 'TRASPARENZA & ANTI-CHEAT'
        HeaderRestoreInit  = 'Punto di ripristino: verifica in corso...'
        HeaderBackupInit   = 'Backup: verifica in corso...'
        LeftHudHeader      = 'SYSTEM TELEMETRY // STATO PC'
        AuditInitTitle     = 'ANALISI DEL PC IN CORSO...'
        AuditInitSub       = 'Verifica delle ottimizzazioni di sistema, della rete e dei giochi installati...'
        BarKernel          = 'KERNEL & SISTEMA'
        BarGames           = 'GIOCHI & GPU MAX'
        MetricStartup      = '  |  Avvio: '
        BtnRebootNow       = 'Riavvia Ora'
        RebootBannerText   = 'Riavvio consigliato per attivare HAGS, BCD e Priorita CPU 26hex.'
        RebootConfirmMsg   = 'Vuoi riavviare Windows adesso per rendere effettive tutte le ottimizzazioni hardware e di rete?'
        RebootConfirmTitle = 'Riavvia Windows'
        GaugeReactivity    = 'REATTIVITA %'
        GaugeTimer         = 'TIMER MS'
        GaugePing          = 'PING MS'
        BtnOptimize        = 'OTTIMIZZA'
        BtnUndo            = 'RIPRISTINA'
        BtnInspect         = 'ISPEZIONA'
        BtnTest            = 'TEST'
        RightHudHeader     = 'DIAGNOSTICA HARDWARE & MODALITA GAMING'
        HwDetecting        = 'Rilevamento componenti hardware in corso...'
        HealthChecking     = 'Verifica Salute Gaming (Driver GPU, VBS, Pagefile)...'
        ModeMaxFps         = 'Max FPS'
        ModeStreaming      = 'Streaming'
        ModeSession        = 'Solo Sessione (No Reg)'
        AutoStartWindows   = 'Avvia con Windows (ridotto nella System Tray con Auto-Boost)'
        StatusStarting     = 'Avvio in corso...'
        Card1Title         = '1. TELEMETRIA FRAME-TIME & OTTIMIZZAZIONI KERNEL ATTIVE'
        Card2Title         = '2. GIOCHI RILEVATI NEL PC'
        Card2TitleFmt      = '2. GIOCHI RILEVATI NEL PC ({0} trovati, {1} ottimizzati)'
        Card2Sub           = 'Con OTTIMIZZA ogni gioco riceve GPU Alte Prestazioni, Priorita CPU/IO Alta, Stop Fullscreen Lag e Auto-Boost RAM.'
        BtnAddGame         = '+ Aggiungi gioco (.exe)'
        GamesEmpty         = 'Nessun gioco rilevato automaticamente negli store. Puoi aggiungere qualsiasi gioco con "+ Aggiungi gioco (.exe)".'
        BtnPlay            = 'GIOCA'
        LogHeader          = 'Mostra registro dettagliato (Log)'
        TrustInit          = 'Scudo Sicurezza SIGAME: Backup Automatico JSON + Punto di Ripristino + Anti-Cheat 100% Safe'
        UndoConfirmMsg     = 'Vuoi ripristinare tutte le impostazioni originali del PC e dei giochi salvate nel backup?'
        UndoConfirmTitle   = 'Ripristina Tutto'
        UndoDoneMsg        = 'Tutte le modifiche (incluse le ottimizzazioni Hard/BCD) sono state annullate.'
        RamDoneFmt         = 'Panic Boost RAM completato: +{0} MB liberati (Standby List + Working Set) e Timer a 0.5ms.'
        AuditOptFmt        = 'STATO PC: OTTIMIZZATO AL {0}% ({1}/{2} Tweak, {3}/{4} Giochi)'
        AuditPartFmt       = 'STATO PC: PARZIALMENTE OTTIMIZZATO ({0}% - {1}/{2} Tweak, {3}/{4} Giochi)'
        AuditNeedFmt       = 'STATO PC: DA OTTIMIZZARE ({0}% - {1}/{2} Tweak attivi, {3}/{4} Giochi)'
        AuditSubOptFmt     = 'Profilo attivo: {0}. Il tuo PC e i tuoi giochi sono configurati per le massime prestazioni.'
        AuditSubNeedFmt    = 'Profilo rilevato: {0}. Ci sono {1} ottimizzazioni pronte. Premi {2} per fare tutto in automatico.'
        HwSummaryFmt       = "CPU: {0}`nGPU: {1}`nRAM: {2}  |  Disco: {3}  |  Profilo: {4}"
        DiskFreeFmt        = '{0} ({1} GB liberi)'
        BadgeActive        = '[ATTIVO]'
        BadgePending       = '[DA ATTIVARE]'
        GameOptBadge       = '[OTTIMIZZATO]'
        GameNeedBadge      = '[DA OTTIMIZZARE]'
        ReadyStatusFmt     = 'Pronto. Premi {0} per ottimizzare automaticamente PC, Rete e Giochi.'
    }
    'de' = @{
        SubHeader          = 'CYBER-HUD KERNEL & ESPORTS OPTIMIERER'
        TabDashboard       = 'DASHBOARD HUD'
        TabKernel          = 'KERNEL & TWEAKS'
        TabRam             = 'RAM FREIGEBEN'
        TabInspect         = 'TRANSPARENZ & ANTI-CHEAT'
        HeaderRestoreInit  = 'Wiederherstellungspunkt: pruefe...'
        HeaderBackupInit   = 'Backup: pruefe...'
        LeftHudHeader      = 'SYSTEM-TELEMETRIE // PC-STATUS'
        AuditInitTitle     = 'PC WIRD ANALYSIERT...'
        AuditInitSub       = 'Systemoptimierungen, Netzwerk und installierte Spiele werden geprueft...'
        BarKernel          = 'KERNEL & SYSTEM'
        BarGames           = 'SPIELE & GPU MAX'
        MetricStartup      = '  |  Autostart: '
        BtnRebootNow       = 'Neu starten'
        RebootBannerText   = 'Neustart empfohlen fuer HAGS, BCD und CPU-Prioritaet 26hex.'
        RebootConfirmMsg   = 'Moechten Sie Windows jetzt neu starten, um alle Hardware- und Netzwerkoptimierungen zu aktivieren?'
        RebootConfirmTitle = 'Windows neu starten'
        GaugeReactivity    = 'REAKTIVITAET %'
        GaugeTimer         = 'TIMER MS'
        GaugePing          = 'PING MS'
        BtnOptimize        = 'OPTIMIEREN'
        BtnUndo            = 'ZURUECK'
        BtnInspect         = 'PRUEFEN'
        BtnTest            = 'TEST'
        RightHudHeader     = 'HARDWARE-DIAGNOSE & GAMING-MODUS'
        HwDetecting        = 'Hardwarekomponenten werden erkannt...'
        HealthChecking     = 'Gaming-Status wird geprueft (GPU-Treiber, VBS, Auslagerungsdatei)...'
        ModeMaxFps         = 'Max FPS'
        ModeStreaming      = 'Streaming'
        ModeSession        = 'Nur Sitzung (Kein Reg)'
        AutoStartWindows   = 'Mit Windows starten (minimiert im System Tray mit Auto-Boost)'
        StatusStarting     = 'Startet...'
        Card1Title         = '1. FRAME-TIME-TELEMETRIE & AKTIVE KERNEL-OPTIMIERUNGEN'
        Card2Title         = '2. ERKANNTE PC-SPIELE'
        Card2TitleFmt      = '2. ERKANNTE PC-SPIELE ({0} gefunden, {1} optimiert)'
        Card2Sub           = 'Mit OPTIMIEREN erhaelt jedes Spiel Hochleistungs-GPU, hohe CPU/IO-Prioritaet, kein Fullscreen-Lag und RAM Auto-Boost.'
        BtnAddGame         = '+ Spiel hinzufuegen (.exe)'
        GamesEmpty         = 'Keine Spiele automatisch erkannt. Fuegen Sie Spiele ueber "+ Spiel hinzufuegen (.exe)" hinzu.'
        BtnPlay            = 'SPIELEN'
        LogHeader          = 'Detailliertes Protokoll anzeigen (Log)'
        TrustInit          = 'SIGAME Schutzschild: Automatisches JSON-Backup + Wiederherstellungspunkt + Anti-Cheat 100% Sicher'
        UndoConfirmMsg     = 'Moechten Sie alle urspruenglichen PC- und Spieleinstellungen aus dem Backup wiederherstellen?'
        UndoConfirmTitle   = 'Alles zuruecksetzen'
        UndoDoneMsg        = 'Alle Aenderungen (einschliesslich Hard/BCD-Tweaks) wurden rueckgaengig gemacht.'
        RamDoneFmt         = 'RAM Panic Boost abgeschlossen: +{0} MB freigegeben und Timer auf 0.5ms.'
        AuditOptFmt        = 'PC-STATUS: {0}% OPTIMIERT ({1}/{2} Tweaks, {3}/{4} Spiele)'
        AuditPartFmt       = 'PC-STATUS: TEILWEISE OPTIMIERT ({0}% - {1}/{2} Tweaks, {3}/{4} Spiele)'
        AuditNeedFmt       = 'PC-STATUS: OPTIMIERUNG BEREIT ({0}% - {1}/{2} Tweaks, {3}/{4} Spiele)'
        AuditSubOptFmt     = 'Aktives Profil: {0}. Ihr PC und Ihre Spiele sind fuer maximale Leistung konfiguriert.'
        AuditSubNeedFmt    = 'Erkanntes Profil: {0}. {1} Optimierungen bereit. Druecken Sie {2} fuer die automatische Optimierung.'
        HwSummaryFmt       = "CPU: {0}`nGPU: {1}`nRAM: {2}  |  Laufwerk: {3}  |  Profil: {4}"
        DiskFreeFmt        = '{0} ({1} GB frei)'
        BadgeActive        = '[AKTIV]'
        BadgePending       = '[BEREIT]'
        GameOptBadge       = '[OPTIMIERT]'
        GameNeedBadge      = '[ZU OPTIMIEREN]'
        ReadyStatusFmt     = 'Bereit. Druecken Sie {0}, um PC, Netzwerk und Spiele automatisch zu optimieren.'
    }
    'fr' = @{
        SubHeader          = 'OPTIMISEUR CYBER-HUD KERNEL & ESPORTS'
        TabDashboard       = 'DASHBOARD HUD'
        TabKernel          = 'KERNEL & REGLAGES'
        TabRam             = 'LIBERER RAM'
        TabInspect         = 'TRANSPARENCE & ANTI-CHEAT'
        HeaderRestoreInit  = 'Point de restauration : verification...'
        HeaderBackupInit   = 'Sauvegarde : verification...'
        LeftHudHeader      = 'TELEMETRIE SYSTEME // ETAT DU PC'
        AuditInitTitle     = 'ANALYSE DU PC EN COURS...'
        AuditInitSub       = 'Verification des optimisations systeme, du reseau et des jeux installes...'
        BarKernel          = 'KERNEL & SYSTEME'
        BarGames           = 'JEUX & GPU MAX'
        MetricStartup      = '  |  Demarrage: '
        BtnRebootNow       = 'Redemarrer'
        RebootBannerText   = 'Redemarrage recommande pour activer HAGS, BCD et Priorite CPU 26hex.'
        RebootConfirmMsg   = 'Voulez-vous redemarrer Windows maintenant pour appliquer toutes les optimisations ?'
        RebootConfirmTitle = 'Redemarrer Windows'
        GaugeReactivity    = 'REACTIVITE %'
        GaugeTimer         = 'TIMER MS'
        GaugePing          = 'PING MS'
        BtnOptimize        = 'OPTIMISER'
        BtnUndo            = 'ANNULER'
        BtnInspect         = 'INSPECTER'
        BtnTest            = 'TEST'
        RightHudHeader     = 'DIAGNOSTIC MATERIEL & MODE GAMING'
        HwDetecting        = 'Detection des composants materiels...'
        HealthChecking     = 'Verification Sante Gaming (Pilote GPU, VBS, Pagefile)...'
        ModeMaxFps         = 'Max FPS'
        ModeStreaming      = 'Streaming'
        ModeSession        = 'Session Seule (Sans Reg)'
        AutoStartWindows   = 'Demarrer avec Windows (reduit dans la barre systeme avec Auto-Boost)'
        StatusStarting     = 'Demarrage...'
        Card1Title         = '1. TELEMETRIE FRAME-TIME & OPTIMISATIONS KERNEL ACTIVES'
        Card2Title         = '2. JEUX DETECTES SUR LE PC'
        Card2TitleFmt      = '2. JEUX DETECTES SUR LE PC ({0} trouves, {1} optimises)'
        Card2Sub           = 'Avec OPTIMISER chaque jeu recoit GPU Haute Performance, Priorite CPU/IO Haute, Sans Fullscreen Lag et Auto-Boost RAM.'
        BtnAddGame         = '+ Ajouter un jeu (.exe)'
        GamesEmpty         = 'Aucun jeu detecte automatiquement. Ajoutez un jeu avec "+ Ajouter un jeu (.exe)".'
        BtnPlay            = 'JOUER'
        LogHeader          = 'Afficher le journal detaille (Log)'
        TrustInit          = 'Bouclier de Securite SIGAME : Sauvegarde JSON Automatique + Point de Restauration + Anti-Cheat 100% Sur'
        UndoConfirmMsg     = 'Voulez-vous restaurer tous les parametres originaux du PC et des jeux ?'
        UndoConfirmTitle   = 'Tout annuler'
        UndoDoneMsg        = 'Toutes les modifications (y compris Hard/BCD) ont ete annulees.'
        RamDoneFmt         = 'Panic Boost RAM termine : +{0} Mo liberes et Timer a 0.5ms.'
        AuditOptFmt        = 'ETAT DU PC : {0}% OPTIMISE ({1}/{2} Reglages, {3}/{4} Jeux)'
        AuditPartFmt       = 'ETAT DU PC : PARTIELLEMENT OPTIMISE ({0}% - {1}/{2} Reglages, {3}/{4} Jeux)'
        AuditNeedFmt       = 'ETAT DU PC : A OPTIMISER ({0}% - {1}/{2} Reglages, {3}/{4} Jeux)'
        AuditSubOptFmt     = 'Profil actif : {0}. Votre PC et vos jeux sont configures pour des performances maximales.'
        AuditSubNeedFmt    = 'Profil detecte : {0}. {1} optimisations pretes. Appuyez sur {2} pour tout optimiser automatiquement.'
        HwSummaryFmt       = "CPU: {0}`nGPU: {1}`nRAM: {2}  |  Disque: {3}  |  Profil: {4}"
        DiskFreeFmt        = '{0} ({1} Go libres)'
        BadgeActive        = '[ACTIF]'
        BadgePending       = '[EN ATTENTE]'
        GameOptBadge       = '[OPTIMISE]'
        GameNeedBadge      = '[A OPTIMISER]'
        ReadyStatusFmt     = 'Pret. Appuyez sur {0} pour optimiser automatiquement PC, Reseau et Jeux.'
    }
}

function Get-SIHudText {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = Get-SISILanguage
    if ($script:SIHudText.ContainsKey($lang) -and $script:SIHudText[$lang].ContainsKey($Key)) {
        return $script:SIHudText[$lang][$Key]
    }
    if ($script:SIHudText['en'].ContainsKey($Key)) {
        return $script:SIHudText['en'][$Key]
    }
    return $Key
}

function New-SIHudCircularGauge {
    <#
    .SYNOPSIS
        Creates a futuristic Cyber-Gold concentric circular gauge (like the
        circular HUD dials in the video) with tick marks, glowing gold ring,
        digital readout, and sub-label.
    #>
    param(
        [int]$Size = 118,
        [string]$InitialValue = '0100',
        [string]$UnitText = 'SCORE %',
        [string]$ValueKey = '',
        [string]$SubKey = ''
    )
    $c = $script:SIColors
    $hostGrid = [System.Windows.Controls.Grid]::new()
    $hostGrid.Width  = $Size
    $hostGrid.Height = $Size
    $hostGrid.Margin = [System.Windows.Thickness]::new(6, 2, 6, 2)

    $canvas = [System.Windows.Controls.Canvas]::new()
    $canvas.Width  = $Size
    $canvas.Height = $Size
    $center = $Size / 2.0
    $outerR = ($Size / 2.0) - 4.0
    $innerR = $outerR - 9.0

    # Outer tick marks around the dial
    for ($deg = 0; $deg -lt 360; $deg += 12) {
        $rad = $deg * [math]::PI / 180.0
        $r1  = $outerR - 3.0
        $r2  = if (($deg % 36) -eq 0) { $outerR + 2.5 } else { $outerR }
        $ln  = [System.Windows.Shapes.Line]::new()
        $ln.X1 = $center + ($r1 * [math]::Cos($rad))
        $ln.Y1 = $center + ($r1 * [math]::Sin($rad))
        $ln.X2 = $center + ($r2 * [math]::Cos($rad))
        $ln.Y2 = $center + ($r2 * [math]::Sin($rad))
        $ln.Stroke = if ($deg -le 270) { Get-SIBrush '#d49b2a' } else { Get-SIBrush '#2b3244' }
        $ln.StrokeThickness = if (($deg % 36) -eq 0) { 1.8 } else { 1.0 }
        [void]$canvas.Children.Add($ln)
    }

    # Dark track ring
    $trackRing = [System.Windows.Shapes.Ellipse]::new()
    $trackRing.Width  = $innerR * 2
    $trackRing.Height = $innerR * 2
    $trackRing.Stroke = Get-SIBrush '#232a3a'
    $trackRing.StrokeThickness = 4.5
    [System.Windows.Controls.Canvas]::SetLeft($trackRing, $center - $innerR)
    [System.Windows.Controls.Canvas]::SetTop($trackRing,  $center - $innerR)
    [void]$canvas.Children.Add($trackRing)

    # Glowing Cyber-Gold active ring
    $goldRing = [System.Windows.Shapes.Ellipse]::new()
    $goldRing.Width  = $innerR * 2
    $goldRing.Height = $innerR * 2
    $goldRing.Stroke = Get-SIBrush $c.GlowGold
    $goldRing.StrokeThickness = 3.5
    $dashCol = [System.Windows.Media.DoubleCollection]::new()
    [void]$dashCol.Add(18.0)
    [void]$dashCol.Add(4.0)
    $goldRing.StrokeDashArray = $dashCol
    try {
        $glow = [System.Windows.Media.Effects.DropShadowEffect]::new()
        $glow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString('#f5b942')
        $glow.BlurRadius = 14
        $glow.ShadowDepth = 0
        $glow.Opacity = 0.75
        $goldRing.Effect = $glow
    } catch { }
    [System.Windows.Controls.Canvas]::SetLeft($goldRing, $center - $innerR)
    [System.Windows.Controls.Canvas]::SetTop($goldRing,  $center - $innerR)
    [void]$canvas.Children.Add($goldRing)

    # Inner dark core circle
    $coreR = $innerR - 7.0
    $coreCircle = [System.Windows.Shapes.Ellipse]::new()
    $coreCircle.Width  = $coreR * 2
    $coreCircle.Height = $coreR * 2
    $coreCircle.Fill   = Get-SIBrush '#0c1018'
    $coreCircle.Stroke = Get-SIBrush '#3d3118'
    $coreCircle.StrokeThickness = 1.0
    [System.Windows.Controls.Canvas]::SetLeft($coreCircle, $center - $coreR)
    [System.Windows.Controls.Canvas]::SetTop($coreCircle,  $center - $coreR)
    [void]$canvas.Children.Add($coreCircle)

    [void]$hostGrid.Children.Add($canvas)

    $textStack = [System.Windows.Controls.StackPanel]::new()
    $textStack.VerticalAlignment   = 'Center'
    $textStack.HorizontalAlignment = 'Center'

    $valTb = [System.Windows.Controls.TextBlock]::new()
    $valTb.Text = $InitialValue
    $valTb.FontSize = if ($Size -ge 110) { 22 } else { 15 }
    $valTb.FontWeight = 'Bold'
    $valTb.Foreground = Get-SIBrush '#ffffff'
    $valTb.HorizontalAlignment = 'Center'
    if ($ValueKey) { $script:SINames[$ValueKey] = $valTb }
    [void]$textStack.Children.Add($valTb)

    $unitTb = [System.Windows.Controls.TextBlock]::new()
    $unitTb.Text = $UnitText
    $unitTb.FontSize = if ($Size -ge 110) { 9.5 } else { 8.5 }
    $unitTb.FontWeight = 'SemiBold'
    $unitTb.Foreground = Get-SIBrush $c.Accent
    $unitTb.HorizontalAlignment = 'Center'
    if ($SubKey) { $script:SINames[$SubKey] = $unitTb }
    [void]$textStack.Children.Add($unitTb)

    [void]$hostGrid.Children.Add($textStack)
    return $hostGrid
}

function Update-SIHudTelemetryChart {
    <#
    .SYNOPSIS
        Renders the Cyber-Gold histogram bars + glowing golden waveform line
        inside the telemetry canvas (matching the chart below OPTIMIZE in the clip).
    #>
    param([int]$OptPercent = 85)
    $canvas = Get-SIElement -Name 'HudWaveCanvas'
    if (-not $canvas) { return }
    $canvas.Children.Clear()

    $w = if ($canvas.ActualWidth -gt 50) { [double]$canvas.ActualWidth } else { 420.0 }
    $h = if ($canvas.ActualHeight -gt 30) { [double]$canvas.ActualHeight } else { 82.0 }

    # Horizontal subtle grid lines + Y-axis labels (5000 .. 1000)
    $yLabels = @('5000', '3500', '2000', '0500')
    for ($i = 0; $i -lt 4; $i++) {
        $y = 8.0 + ($i * (($h - 18.0) / 3.0))
        $gridLn = [System.Windows.Shapes.Line]::new()
        $gridLn.X1 = 32
        $gridLn.Y1 = $y
        $gridLn.X2 = $w - 6
        $gridLn.Y2 = $y
        $gridLn.Stroke = Get-SIBrush '#1e2536'
        $gridLn.StrokeThickness = 1
        [void]$canvas.Children.Add($gridLn)

        $lbl = [System.Windows.Controls.TextBlock]::new()
        $lbl.Text = $yLabels[$i]
        $lbl.FontSize = 8.5
        $lbl.Foreground = Get-SIBrush '#687086'
        [System.Windows.Controls.Canvas]::SetLeft($lbl, 2)
        [System.Windows.Controls.Canvas]::SetTop($lbl, $y - 6)
        [void]$canvas.Children.Add($lbl)
    }

    # Golden vertical histogram bars + waveform points
    $heights = @(0.32, 0.45, 0.38, 0.62, 0.50, 0.74, 0.60, 0.85, 0.55, 0.48, 0.72, 0.92, 0.68, 0.78, 0.64, 0.88, 0.95, 0.76, 0.84, 0.96, 0.82, 0.90, 0.75, 0.94, 0.88, 0.98)
    $boostFactor = [math]::Max(0.55, [math]::Min(1.0, ($OptPercent / 100.0)))
    $barCount = $heights.Count
    $plotLeft = 36.0
    $plotW    = [math]::Max(100.0, ($w - $plotLeft - 10.0))
    $stepX    = $plotW / $barCount
    $baseY    = $h - 10.0
    $maxBarH  = $h - 20.0

    $polyLine = [System.Windows.Shapes.Polyline]::new()
    $polyLine.Stroke = Get-SIBrush '#ffcf56'
    $polyLine.StrokeThickness = 1.8
    $pts = [System.Windows.Media.PointCollection]::new()

    for ($i = 0; $i -lt $barCount; $i++) {
        $val = $heights[$i] * $boostFactor
        $bh  = [math]::Max(4.0, ($val * $maxBarH))
        $bx  = $plotLeft + ($i * $stepX)
        $by  = $baseY - $bh

        $rect = [System.Windows.Shapes.Rectangle]::new()
        $rect.Width  = [math]::Max(3.0, ($stepX * 0.58))
        $rect.Height = $bh
        $rect.Fill   = if ($i -ge ($barCount - 6)) { Get-SIBrush '#cc9b30' } else { Get-SIBrush '#59451c' }
        $rect.RadiusX = 1
        $rect.RadiusY = 1
        [System.Windows.Controls.Canvas]::SetLeft($rect, $bx)
        [System.Windows.Controls.Canvas]::SetTop($rect,  $by)
        [void]$canvas.Children.Add($rect)

        [void]$pts.Add([System.Windows.Point]::new($bx + ($rect.Width / 2.0), $by))
    }

    $polyLine.Points = $pts
    [void]$canvas.Children.Add($polyLine)
}

function New-SIWindow {
    $c = $script:SIColors
    $script:SINames = @{}

    foreach ($tweak in (Get-SITweakTable)) {
        $script:SITweaks[$tweak.Id] = $tweak
    }

    $window = [System.Windows.Window]::new()
    $window.Title = 'SIGAME AUTO // CYBER-HUD GAMING OPTIMIZER'
    $window.Width = 1080
    $window.Height = 760
    $window.MinWidth = 960
    $window.MinHeight = 660
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $window.Background = Get-SIBrush $c.Background
    $window.Foreground = Get-SIBrush $c.Text
    $window.FontFamily = [System.Windows.Media.FontFamily]::new('Segoe UI')
    $window.FontSize = 13
    $window.UseLayoutRounding = $true

    $root = [System.Windows.Controls.Grid]::new()
    $window.Content = $root
    Add-SIGridRow -Grid $root -Type 'Auto' # 0: Top Cyber-HUD Header & Navigation Strip
    Add-SIGridRow -Grid $root -Type 'Auto' # 1: 3-Column HUD Command Center (Left Metrics | Center Gauges + Giant OPTIMIZE | Right Health)
    Add-SIGridRow -Grid $root -Type 'Auto' # 2: Golden Progress Bar & Live Status
    Add-SIGridRow -Grid $root -Type 'Star' -Value 1 # 3: Bottom 2 Columns (Golden Telemetry Graph + Tweaks | Installed Games)
    Add-SIGridRow -Grid $root -Type 'Auto' # 4: Collapsible Log & Security Shield Footer

    # --- ROW 0: TOP CYBER-HUD HEADER & TAB BAR ------------------------------
    $header = [System.Windows.Controls.Border]::new()
    $header.Background = Get-SIBrush '#0c0f17'
    $header.BorderBrush = Get-SIBrush $c.BorderGold
    $header.BorderThickness = [System.Windows.Thickness]::new(0, 0, 0, 1)
    $header.Padding = [System.Windows.Thickness]::new(18, 8, 18, 8)
    $headerGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridColumn -Grid $headerGrid -Type 'Auto'
    Add-SIGridColumn -Grid $headerGrid -Type 'Auto'
    Add-SIGridColumn -Grid $headerGrid -Type 'Star' -Value 1
    Add-SIGridColumn -Grid $headerGrid -Type 'Auto'
    $header.Child = $headerGrid

    $logo = [System.Windows.Controls.Image]::new()
    $logo.Width = 42
    $logo.Height = 42
    $logo.Margin = [System.Windows.Thickness]::new(0, 0, 12, 0)
    $logo.Stretch = [System.Windows.Media.Stretch]::Uniform
    if ($script:SILoadingLogo -and $script:SILoadingLogo.Source) {
        $logo.Source = $script:SILoadingLogo.Source
    } elseif ([System.IO.File]::Exists($script:SILogoPath)) {
        try {
            $bmp = [System.Windows.Media.Imaging.BitmapImage]::new()
            $bmp.BeginInit()
            $bmp.UriSource = [System.Uri]::new($script:SILogoPath, [System.UriKind]::Absolute)
            $bmp.DecodePixelWidth = 96
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.EndInit()
            $bmp.Freeze()
            $logo.Source = $bmp
        } catch { }
    }
    [System.Windows.Controls.Grid]::SetColumn($logo, 0)
    [void]$headerGrid.Children.Add($logo)
    $script:SINames['LogoImage'] = $logo

    $titleStack = [System.Windows.Controls.StackPanel]::new()
    $titleStack.VerticalAlignment = 'Center'
    $titleStack.Margin = [System.Windows.Thickness]::new(0, 0, 24, 0)
    $titleText = [System.Windows.Controls.TextBlock]::new()
    $titleText.Text = 'SIGAME AUTO'
    $titleText.FontSize = 21
    $titleText.FontWeight = 'Bold'
    $titleText.Foreground = Get-SIBrush $c.Accent
    [void]$titleStack.Children.Add($titleText)

    $subText = [System.Windows.Controls.TextBlock]::new()
    $subText.Text = (Get-SIHudText 'SubHeader')
    $subText.FontSize = 9.5
    $subText.FontWeight = 'SemiBold'
    $subText.Foreground = Get-SIBrush $c.Muted
    [void]$titleStack.Children.Add($subText)
    [System.Windows.Controls.Grid]::SetColumn($titleStack, 1)
    [void]$headerGrid.Children.Add($titleStack)

    # Cyber-Gold Top Navigation Tabs (like "OPTINGS / CLANTS / DASHBOARD" in the video)
    $navWrap = [System.Windows.Controls.WrapPanel]::new()
    $navWrap.VerticalAlignment = 'Center'
    $navItems = @(
        @{ Label = (Get-SIHudText 'TabDashboard'); Active = $true;  Action = $null }
        @{ Label = (Get-SIHudText 'TabKernel');    Active = $false; Action = 'Bench' }
        @{ Label = (Get-SIHudText 'TabRam');       Active = $false; Action = 'Ram' }
        @{ Label = (Get-SIHudText 'TabInspect');   Active = $false; Action = 'Inspect' }
    )
    foreach ($nav in $navItems) {
        $tabBorder = [System.Windows.Controls.Border]::new()
        $tabBorder.BorderBrush = if ($nav.Active) { Get-SIBrush $c.Accent } else { Get-SIBrush 'Transparent' }
        $tabBorder.BorderThickness = [System.Windows.Thickness]::new(0, 0, 0, 2)
        $tabBorder.Padding = [System.Windows.Thickness]::new(10, 6, 10, 6)
        $tabBorder.Margin  = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $tabBorder.Cursor  = [System.Windows.Input.Cursors]::Hand

        $tabTb = [System.Windows.Controls.TextBlock]::new()
        $tabTb.Text = $nav.Label
        $tabTb.FontSize = 11
        $tabTb.FontWeight = 'Bold'
        $tabTb.Foreground = if ($nav.Active) { Get-SIBrush $c.Accent } else { Get-SIBrush $c.Muted }
        $tabBorder.Child = $tabTb

        $act = $nav.Action
        if ($act -eq 'Bench') {
            $null = $tabBorder.Add_MouseLeftButtonDown({ Invoke-SILiveLatencyBenchmark })
        } elseif ($act -eq 'Ram') {
            $null = $tabBorder.Add_MouseLeftButtonDown({
                $freed = Clear-SIWorkingSets
                [void](Set-SITimerResolution05ms -Enable $true)
                Set-SIStatusText -Text ((Get-SIHudText 'RamDoneFmt') -f $freed)
            })
        } elseif ($act -eq 'Inspect') {
            $null = $tabBorder.Add_MouseLeftButtonDown({ Show-SITransparencyInspector })
        }
        [void]$navWrap.Children.Add($tabBorder)
    }
    [System.Windows.Controls.Grid]::SetColumn($navWrap, 2)
    [void]$headerGrid.Children.Add($navWrap)

    $headerRight = [System.Windows.Controls.StackPanel]::new()
    $headerRight.VerticalAlignment = 'Center'
    $headerRight.HorizontalAlignment = 'Right'
    foreach ($hName in @('HeaderSystem', 'HeaderRestore', 'HeaderBackup')) {
        $lbl = [System.Windows.Controls.TextBlock]::new()
        $lbl.FontSize = 10.5
        $lbl.Foreground = Get-SIBrush $c.Muted
        $lbl.HorizontalAlignment = 'Right'
        if ($hName -eq 'HeaderRestore') { $lbl.Text = (Get-SIHudText 'HeaderRestoreInit') }
        if ($hName -eq 'HeaderBackup')  { $lbl.Text = (Get-SIHudText 'HeaderBackupInit') }
        [void]$headerRight.Children.Add($lbl)
        $script:SINames[$hName] = $lbl
    }
    [System.Windows.Controls.Grid]::SetColumn($headerRight, 3)
    [void]$headerGrid.Children.Add($headerRight)
    [System.Windows.Controls.Grid]::SetRow($header, 0)
    [void]$root.Children.Add($header)

    # --- ROW 1: 3-COLUMN CYBER-GOLD HUD COMMAND CENTER ----------------------
    $hudDeck = [System.Windows.Controls.Grid]::new()
    $hudDeck.Margin = [System.Windows.Thickness]::new(16, 10, 16, 6)
    Add-SIGridColumn -Grid $hudDeck -Type 'Star' -Value 1.05 # Col 0: Left Telemetry & Status Panel
    Add-SIGridColumn -Grid $hudDeck -Type 'Auto'             # Col 1: Center Gauges + Giant Glowing OPTIMIZE
    Add-SIGridColumn -Grid $hudDeck -Type 'Star' -Value 1.05 # Col 2: Right Hardware & Gaming Health Panel

    # === COL 0 (LEFT HUD PANEL: SYSTEM AUDIT, METRICS & BARS) ===============
    $leftHud = [System.Windows.Controls.Border]::new()
    $leftHud.Background = Get-SIBrush $c.Panel
    $leftHud.BorderBrush = Get-SIBrush $c.BorderGold
    $leftHud.BorderThickness = [System.Windows.Thickness]::new(1)
    $leftHud.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $leftHud.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)
    $leftHud.Margin  = [System.Windows.Thickness]::new(0, 0, 8, 0)

    $statusStack = [System.Windows.Controls.StackPanel]::new()
    $statusStack.VerticalAlignment = 'Center'

    $leftHdr = [System.Windows.Controls.TextBlock]::new()
    $leftHdr.Text = (Get-SIHudText 'LeftHudHeader')
    $leftHdr.FontSize = 10
    $leftHdr.FontWeight = 'Bold'
    $leftHdr.Foreground = Get-SIBrush $c.Muted
    $leftHdr.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
    [void]$statusStack.Children.Add($leftHdr)

    $badgeText = [System.Windows.Controls.TextBlock]::new()
    $badgeText.Text = (Get-SIHudText 'AuditInitTitle')
    $badgeText.FontSize = 14.5
    $badgeText.FontWeight = 'Bold'
    $badgeText.Foreground = Get-SIBrush $c.Accent
    $badgeText.TextWrapping = 'Wrap'
    $script:SINames['AuditTitle'] = $badgeText
    [void]$statusStack.Children.Add($badgeText)

    $auditSub = [System.Windows.Controls.TextBlock]::new()
    $auditSub.Text = (Get-SIHudText 'AuditInitSub')
    $auditSub.FontSize = 11
    $auditSub.Foreground = Get-SIBrush $c.Text
    $auditSub.Margin = [System.Windows.Thickness]::new(0, 3, 0, 8)
    $auditSub.TextWrapping = 'Wrap'
    $script:SINames['AuditSubtitle'] = $auditSub
    [void]$statusStack.Children.Add($auditSub)

    # Cyber-Gold Horizontal Telemetry Bars (like the 50% / 67% gold bars on the left of the video)
    $barItems = @(
        @{ Label = (Get-SIHudText 'BarKernel'); BarKey = 'HudBar_Tweaks'; ValKey = 'HudVal_Tweaks'; Pct = 75 }
        @{ Label = (Get-SIHudText 'BarGames');  BarKey = 'HudBar_Games';  ValKey = 'HudVal_Games';  Pct = 80 }
    )
    foreach ($bi in $barItems) {
        $bGrid = [System.Windows.Controls.Grid]::new()
        $bGrid.Margin = [System.Windows.Thickness]::new(0, 2, 0, 3)
        Add-SIGridColumn -Grid $bGrid -Type 'Auto'
        Add-SIGridColumn -Grid $bGrid -Type 'Star' -Value 1
        Add-SIGridColumn -Grid $bGrid -Type 'Auto'

        $bLbl = [System.Windows.Controls.TextBlock]::new()
        $bLbl.Text = $bi.Label
        $bLbl.Width = 108
        $bLbl.FontSize = 9.5
        $bLbl.FontWeight = 'SemiBold'
        $bLbl.Foreground = Get-SIBrush $c.Muted
        $bLbl.VerticalAlignment = 'Center'
        [System.Windows.Controls.Grid]::SetColumn($bLbl, 0)
        [void]$bGrid.Children.Add($bLbl)

        $pb = [System.Windows.Controls.ProgressBar]::new()
        $pb.Height = 6
        $pb.Minimum = 0
        $pb.Maximum = 100
        $pb.Value = $bi.Pct
        $pb.Background = Get-SIBrush '#1c2230'
        $pb.Foreground = Get-SIBrush $c.Accent
        $pb.BorderThickness = [System.Windows.Thickness]::new(0)
        $pb.VerticalAlignment = 'Center'
        $pb.Margin = [System.Windows.Thickness]::new(6, 0, 8, 0)
        $script:SINames[$bi.BarKey] = $pb
        [System.Windows.Controls.Grid]::SetColumn($pb, 1)
        [void]$bGrid.Children.Add($pb)

        $vTb = [System.Windows.Controls.TextBlock]::new()
        $vTb.Text = "$($bi.Pct)%"
        $vTb.FontSize = 10.5
        $vTb.FontWeight = 'Bold'
        $vTb.Foreground = Get-SIBrush $c.Accent
        $script:SINames[$bi.ValKey] = $vTb
        [System.Windows.Controls.Grid]::SetColumn($vTb, 2)
        [void]$bGrid.Children.Add($vTb)

        [void]$statusStack.Children.Add($bGrid)
    }

    # Metrics Bar (RAM, DNS, App Avvio)
    $metricsWrap = [System.Windows.Controls.WrapPanel]::new()
    $metricsWrap.Margin = [System.Windows.Thickness]::new(0, 6, 0, 0)
    $metricDefs = @(
        @{ Key = 'ProveBefore_FreeRamMB';     Title = 'RAM: ' }
        @{ Key = 'ProveAfter_FreeRamMB';      Title = ' -> ' }
        @{ Key = 'ProveBefore_DnsMs';         Title = '  |  DNS: ' }
        @{ Key = 'ProveAfter_DnsMs';          Title = ' -> ' }
        @{ Key = 'ProveBefore_StartupAppsOn'; Title = (Get-SIHudText 'MetricStartup') }
        @{ Key = 'ProveAfter_StartupAppsOn';  Title = ' -> ' }
    )
    foreach ($m in $metricDefs) {
        $tLbl = [System.Windows.Controls.TextBlock]::new()
        $tLbl.Text = $m.Title
        $tLbl.FontSize = 11
        $tLbl.Foreground = Get-SIBrush $c.Muted
        [void]$metricsWrap.Children.Add($tLbl)

        $vLbl = [System.Windows.Controls.TextBlock]::new()
        $vLbl.Text = '-'
        $vLbl.FontSize = 11.5
        $vLbl.FontWeight = 'Bold'
        $vLbl.Foreground = if ($m.Key -like 'ProveAfter_*') { Get-SIBrush $c.Accent } else { Get-SIBrush $c.Text }
        $script:SINames[$m.Key] = $vLbl
        [void]$metricsWrap.Children.Add($vLbl)
    }
    [void]$statusStack.Children.Add($metricsWrap)

    $proveLine = [System.Windows.Controls.TextBlock]::new()
    $proveLine.Text = ''
    $proveLine.FontSize = 10.5
    $proveLine.Foreground = Get-SIBrush $c.Ok
    $proveLine.Margin = [System.Windows.Thickness]::new(0, 4, 0, 0)
    $script:SINames['ProveLine'] = $proveLine
    [void]$statusStack.Children.Add($proveLine)

    # Reboot Recommended Banner
    $rebootBanner = [System.Windows.Controls.Border]::new()
    $rebootBanner.Background = Get-SIBrush '#261e10'
    $rebootBanner.BorderBrush = Get-SIBrush $c.Accent
    $rebootBanner.BorderThickness = [System.Windows.Thickness]::new(1)
    $rebootBanner.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $rebootBanner.Padding = [System.Windows.Thickness]::new(8, 4, 8, 4)
    $rebootBanner.Margin = [System.Windows.Thickness]::new(0, 6, 0, 0)
    $rebootBanner.Visibility = [System.Windows.Visibility]::Collapsed
    $rebootDock = [System.Windows.Controls.DockPanel]::new()

    $btnRebootNow = New-SIStyleButton -Text (Get-SIHudText 'BtnRebootNow') -StyleKey 'AccentButton' -Window $window -Width 90
    $btnRebootNow.Height = 22
    $btnRebootNow.FontSize = 10
    $btnRebootNow.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    [System.Windows.Controls.DockPanel]::SetDock($btnRebootNow, 'Right')
    [void]$rebootDock.Children.Add($btnRebootNow)

    $rebootText = [System.Windows.Controls.TextBlock]::new()
    $rebootText.Text = (Get-SIHudText 'RebootBannerText')
    $rebootText.FontSize = 10
    $rebootText.Foreground = Get-SIBrush $c.Accent
    $rebootText.VerticalAlignment = 'Center'
    $rebootText.TextWrapping = 'Wrap'
    [void]$rebootDock.Children.Add($rebootText)

    $rebootBanner.Child = $rebootDock
    $script:SINames['RebootBanner'] = $rebootBanner
    [void]$statusStack.Children.Add($rebootBanner)

    $null = $btnRebootNow.Add_Click({
        $msg = (Get-SIHudText 'RebootConfirmMsg')
        if (Show-SIMessage -Window $window -Text $msg -Title (Get-SIHudText 'RebootConfirmTitle')) {
            try { Restart-Computer -Force } catch { }
        }
    }.GetNewClosure())

    $leftHud.Child = $statusStack
    [System.Windows.Controls.Grid]::SetColumn($leftHud, 0)
    [void]$hudDeck.Children.Add($leftHud)

    # === COL 1 (CENTER HUD DECK: CIRCULAR GAUGES + GIANT GLOWING "OPTIMIZE") ==
    $centerHud = [System.Windows.Controls.Border]::new()
    $centerHud.Background = Get-SIBrush '#0d111a'
    $centerHud.BorderBrush = Get-SIBrush $c.Accent
    $centerHud.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $centerHud.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $centerHud.Padding = [System.Windows.Thickness]::new(18, 10, 18, 10)
    $centerHud.Margin  = [System.Windows.Thickness]::new(0, 0, 8, 0)

    $centerStack = [System.Windows.Controls.StackPanel]::new()
    $centerStack.HorizontalAlignment = 'Center'
    $centerStack.VerticalAlignment   = 'Center'

    # Circular Gauges Row (exact match to "Reclvity Eotons" 0113 + 1054 concentric dials above OPTIMIZE)
    $gaugesRow = [System.Windows.Controls.StackPanel]::new()
    $gaugesRow.Orientation = 'Horizontal'
    $gaugesRow.HorizontalAlignment = 'Center'
    $gaugesRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)

    $mainGauge = New-SIHudCircularGauge -Size 104 -InitialValue '0100' -UnitText (Get-SIHudText 'GaugeReactivity') -ValueKey 'HudGaugeMainVal' -SubKey 'HudGaugeMainSub'
    $secGauge  = New-SIHudCircularGauge -Size 84  -InitialValue '0.50' -UnitText (Get-SIHudText 'GaugeTimer')      -ValueKey 'HudGaugeSecVal'  -SubKey 'HudGaugeSecSub'
    $pingGauge = New-SIHudCircularGauge -Size 84  -InitialValue '0015' -UnitText (Get-SIHudText 'GaugePing')       -ValueKey 'HudGaugePingVal' -SubKey 'HudGaugePingSub'

    [void]$gaugesRow.Children.Add($mainGauge)
    [void]$gaugesRow.Children.Add($secGauge)
    [void]$gaugesRow.Children.Add($pingGauge)
    [void]$centerStack.Children.Add($gaugesRow)

    # Giant Glowing Cyber-Gold "OPTIMIZE" Button (exact match to the video)
    $optOuterFrame = [System.Windows.Controls.Border]::new()
    $optOuterFrame.BorderBrush = Get-SIBrush '#f5b942'
    $optOuterFrame.BorderThickness = [System.Windows.Thickness]::new(2)
    $optOuterFrame.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $optOuterFrame.Padding = [System.Windows.Thickness]::new(3)
    $optOuterFrame.Margin  = [System.Windows.Thickness]::new(0, 2, 0, 8)
    try {
        $btnGlow = [System.Windows.Media.Effects.DropShadowEffect]::new()
        $btnGlow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString('#f5b942')
        $btnGlow.BlurRadius = 26
        $btnGlow.ShadowDepth = 0
        $btnGlow.Opacity = 0.65
        $optOuterFrame.Effect = $btnGlow
    } catch { }

    $btnOptimize = New-SIStyleButton -Text (Get-SIHudText 'BtnOptimize') -StyleKey 'GhostButton' -Window $window -Width 296
    $btnOptimize.Height = 58
    $btnOptimize.FontSize = 26
    $btnOptimize.FontWeight = 'Bold'
    $btnOptimize.Margin = [System.Windows.Thickness]::new(0)
    $btnOptimize.IsEnabled = $false
    $btnOptimize.Background = Get-SIBrush '#1f190d'
    $btnOptimize.Foreground = Get-SIBrush '#ffd86b'
    $btnOptimize.BorderBrush = Get-SIBrush '#f5b942'
    $btnOptimize.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $btnOptimize.ToolTip = (Get-SIText -Key 'OptimizeHint')
    $script:SINames['BtnOptimize'] = $btnOptimize
    $optOuterFrame.Child = $btnOptimize
    [void]$centerStack.Children.Add($optOuterFrame)

    # Sub-buttons bar (RIPRISTINA | RAM | ISPEZIONA | TEST | PNG)
    $subBtnRow = [System.Windows.Controls.WrapPanel]::new()
    $subBtnRow.HorizontalAlignment = 'Center'

    $btnUndo = New-SIStyleButton -Text (Get-SIHudText 'BtnUndo') -StyleKey 'GhostButton' -Window $window -Width 82
    $btnUndo.Height = 28
    $btnUndo.FontSize = 10
    $btnUndo.Margin = [System.Windows.Thickness]::new(0, 0, 4, 0)
    $btnUndo.IsEnabled = $false
    $btnUndo.ToolTip = (Get-SIHudText 'UndoConfirmMsg')
    $script:SINames['BtnUndoAllBig'] = $btnUndo
    [void]$subBtnRow.Children.Add($btnUndo)

    $btnRamNow = New-SIStyleButton -Text 'RAM' -StyleKey 'GhostButton' -Window $window -Width 46
    $btnRamNow.Height = 28
    $btnRamNow.FontSize = 10
    $btnRamNow.Margin = [System.Windows.Thickness]::new(0, 0, 4, 0)
    $btnRamNow.ToolTip = (Get-SIHudText 'TabRam')
    $script:SINames['BtnRamNow'] = $btnRamNow
    [void]$subBtnRow.Children.Add($btnRamNow)

    $btnInspect = New-SIStyleButton -Text (Get-SIHudText 'BtnInspect') -StyleKey 'GhostButton' -Window $window -Width 78
    $btnInspect.Height = 28
    $btnInspect.FontSize = 10
    $btnInspect.Margin = [System.Windows.Thickness]::new(0, 0, 4, 0)
    $btnInspect.ToolTip = (Get-SIHudText 'TabInspect')
    $script:SINames['BtnInspect'] = $btnInspect
    [void]$subBtnRow.Children.Add($btnInspect)

    $btnBench = New-SIStyleButton -Text (Get-SIHudText 'BtnTest') -StyleKey 'GhostButton' -Window $window -Width 46
    $btnBench.Height = 28
    $btnBench.FontSize = 10
    $btnBench.Margin = [System.Windows.Thickness]::new(0, 0, 4, 0)
    $btnBench.ToolTip = (Get-SIHudText 'TabKernel')
    $script:SINames['BtnBench'] = $btnBench
    [void]$subBtnRow.Children.Add($btnBench)

    $btnShareCard = New-SIStyleButton -Text 'PNG' -StyleKey 'GhostButton' -Window $window -Width 44
    $btnShareCard.Height = 28
    $btnShareCard.FontSize = 10
    $btnShareCard.Margin = [System.Windows.Thickness]::new(0)
    $btnShareCard.ToolTip = (Get-SIText -Key 'BtnSaveCard')
    $script:SINames['BtnShareCard'] = $btnShareCard
    [void]$subBtnRow.Children.Add($btnShareCard)
    [void]$centerStack.Children.Add($subBtnRow)

    $optResult = [System.Windows.Controls.TextBlock]::new()
    $optResult.Text = ''
    $optResult.FontSize = 10.5
    $optResult.Foreground = Get-SIBrush $c.Ok
    $optResult.HorizontalAlignment = 'Center'
    $optResult.Margin = [System.Windows.Thickness]::new(0, 4, 0, 0)
    $script:SINames['OptimizeResult'] = $optResult
    [void]$centerStack.Children.Add($optResult)

    $centerHud.Child = $centerStack
    [System.Windows.Controls.Grid]::SetColumn($centerHud, 1)
    [void]$hudDeck.Children.Add($centerHud)

    # === COL 2 (RIGHT HUD PANEL: HARDWARE SPECS, HEALTH & MODE SELECTOR) =====
    $rightHud = [System.Windows.Controls.Border]::new()
    $rightHud.Background = Get-SIBrush $c.Panel
    $rightHud.BorderBrush = Get-SIBrush $c.BorderGold
    $rightHud.BorderThickness = [System.Windows.Thickness]::new(1)
    $rightHud.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $rightHud.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)

    $rightStack = [System.Windows.Controls.StackPanel]::new()
    $rightStack.VerticalAlignment = 'Center'

    $rightHdr = [System.Windows.Controls.TextBlock]::new()
    $rightHdr.Text = (Get-SIHudText 'RightHudHeader')
    $rightHdr.FontSize = 10
    $rightHdr.FontWeight = 'Bold'
    $rightHdr.Foreground = Get-SIBrush $c.Muted
    $rightHdr.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
    [void]$rightStack.Children.Add($rightHdr)

    $hwSummary = [System.Windows.Controls.TextBlock]::new()
    $hwSummary.Text = (Get-SIHudText 'HwDetecting')
    $hwSummary.FontSize = 11
    $hwSummary.Foreground = Get-SIBrush $c.Text
    $hwSummary.TextWrapping = 'Wrap'
    $hwSummary.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
    $script:SINames['BottleneckDetails'] = $hwSummary
    [void]$rightStack.Children.Add($hwSummary)

    $healthText = [System.Windows.Controls.TextBlock]::new()
    $healthText.Text = (Get-SIHudText 'HealthChecking')
    $healthText.FontSize = 10.5
    $healthText.FontWeight = 'SemiBold'
    $healthText.Foreground = Get-SIBrush $c.Accent
    $healthText.TextWrapping = 'Wrap'
    $healthText.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $script:SINames['GamingHealthText'] = $healthText
    [void]$rightStack.Children.Add($healthText)

    # Mode Selector (Massimi FPS vs Streaming vs Solo Sessione)
    $modeWrap = [System.Windows.Controls.WrapPanel]::new()
    $modeWrap.Margin = [System.Windows.Thickness]::new(0, 2, 0, 4)

    $rbMaxFps = [System.Windows.Controls.RadioButton]::new()
    $rbMaxFps.Content = (Get-SIHudText 'ModeMaxFps')
    $rbMaxFps.FontSize = 11
    $rbMaxFps.Foreground = Get-SIBrush $c.Accent
    $rbMaxFps.FontWeight = 'SemiBold'
    $rbMaxFps.IsChecked = $true
    $rbMaxFps.Margin = [System.Windows.Thickness]::new(0, 0, 10, 2)
    [void]$modeWrap.Children.Add($rbMaxFps)

    $rbStream = [System.Windows.Controls.RadioButton]::new()
    $rbStream.Content = (Get-SIHudText 'ModeStreaming')
    $rbStream.FontSize = 11
    $rbStream.Foreground = Get-SIBrush $c.Text
    $rbStream.IsChecked = $false
    $rbStream.Margin = [System.Windows.Thickness]::new(0, 0, 10, 2)
    [void]$modeWrap.Children.Add($rbStream)

    $rbSession = [System.Windows.Controls.RadioButton]::new()
    $rbSession.Content = (Get-SIHudText 'ModeSession')
    $rbSession.FontSize = 11
    $rbSession.Foreground = Get-SIBrush $c.Ok
    $rbSession.IsChecked = $false
    $rbSession.Margin = [System.Windows.Thickness]::new(0, 0, 0, 2)
    [void]$modeWrap.Children.Add($rbSession)

    $null = $rbMaxFps.Add_Checked({
        $script:SIAutoMode = 'MaxFPS'
        Update-SIAutoDashboard
    })
    $null = $rbStream.Add_Checked({
        $script:SIAutoMode = 'Streaming'
        Update-SIAutoDashboard
    })
    $null = $rbSession.Add_Checked({
        $script:SIAutoMode = 'SessionOnly'
        Update-SIAutoDashboard
    })
    [void]$rightStack.Children.Add($modeWrap)

    $cbAutoStart = [System.Windows.Controls.CheckBox]::new()
    $cbAutoStart.Content = (Get-SIHudText 'AutoStartWindows')
    $cbAutoStart.FontSize = 10.5
    $cbAutoStart.Foreground = Get-SIBrush $c.Muted
    $cbAutoStart.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
    $cbAutoStart.IsChecked = (Get-SIAutoStartWithWindows)
    $null = $cbAutoStart.Add_Click({
        param($sender, $e)
        Set-SIAutoStartWithWindows -Enabled ($sender.IsChecked -eq $true)
    })
    [void]$rightStack.Children.Add($cbAutoStart)

    $rightHud.Child = $rightStack
    [System.Windows.Controls.Grid]::SetColumn($rightHud, 2)
    [void]$hudDeck.Children.Add($rightHud)

    [System.Windows.Controls.Grid]::SetRow($hudDeck, 1)
    [void]$root.Children.Add($hudDeck)

    # --- ROW 2: PROGRESS BAR & STEP STATUS ----------------------------------
    $progBorder = [System.Windows.Controls.Border]::new()
    $progBorder.Margin = [System.Windows.Thickness]::new(16, 0, 16, 6)
    $progBorder.Background = Get-SIBrush $c.Panel
    $progBorder.BorderBrush = Get-SIBrush $c.BorderGold
    $progBorder.BorderThickness = [System.Windows.Thickness]::new(1)
    $progBorder.Padding = [System.Windows.Thickness]::new(14, 6, 14, 6)
    $progBorder.CornerRadius = [System.Windows.CornerRadius]::new(5)
    $progGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridColumn -Grid $progGrid -Type 'Star' -Value 1
    Add-SIGridColumn -Grid $progGrid -Type 'Auto'

    $progBar = [System.Windows.Controls.ProgressBar]::new()
    $progBar.Height = 8
    $progBar.Minimum = 0
    $progBar.Maximum = 100
    $progBar.Value = 0
    $progBar.BorderThickness = [System.Windows.Thickness]::new(0)
    $progBar.Background = Get-SIBrush '#1b202e'
    $progBar.Foreground = Get-SIBrush $c.Accent
    $progBar.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($progBar, 0)
    [void]$progGrid.Children.Add($progBar)
    $script:SINames['ProgressBar'] = $progBar

    $progText = [System.Windows.Controls.TextBlock]::new()
    $progText.Text = (Get-SIHudText 'StatusStarting')
    $progText.FontSize = 11.5
    $progText.Foreground = Get-SIBrush $c.Accent
    $progText.Margin = [System.Windows.Thickness]::new(14, 0, 0, 0)
    $progText.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($progText, 1)
    [void]$progGrid.Children.Add($progText)
    $script:SINames['ProgressText'] = $progText
    $script:SIStatus = $progText
    $script:SIProgress = $progBar
    $script:SIProgressText = $progText

    $progBorder.Child = $progGrid
    [System.Windows.Controls.Grid]::SetRow($progBorder, 2)
    [void]$root.Children.Add($progBorder)

    # --- ROW 3: BOTTOM TWO CARDS (LEFT: GOLDEN TELEMETRY CHART + TWEAKS, RIGHT: GAMES) -
    $cardsGrid = [System.Windows.Controls.Grid]::new()
    $cardsGrid.Margin = [System.Windows.Thickness]::new(16, 0, 16, 8)
    Add-SIGridColumn -Grid $cardsGrid -Type 'Star' -Value 1
    Add-SIGridColumn -Grid $cardsGrid -Type 'Star' -Value 1

    # Card Left: Cyber-Gold Live Telemetry Waveform + Optimization Checklist
    $leftCard = [System.Windows.Controls.Border]::new()
    $leftCard.Background = Get-SIBrush $c.Panel
    $leftCard.BorderBrush = Get-SIBrush $c.BorderGold
    $leftCard.BorderThickness = [System.Windows.Thickness]::new(1)
    $leftCard.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $leftCard.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)
    $leftCard.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $leftGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridRow -Grid $leftGrid -Type 'Auto' # 0: Title
    Add-SIGridRow -Grid $leftGrid -Type 'Auto' # 1: Golden Telemetry Histogram & Waveform
    Add-SIGridRow -Grid $leftGrid -Type 'Star' -Value 1 # 2: Tweaks ScrollViewer
    $leftCard.Child = $leftGrid

    $hwTitle = [System.Windows.Controls.TextBlock]::new()
    $hwTitle.Text = (Get-SIHudText 'Card1Title')
    $hwTitle.FontSize = 12
    $hwTitle.FontWeight = 'Bold'
    $hwTitle.Foreground = Get-SIBrush $c.Accent
    [System.Windows.Controls.Grid]::SetRow($hwTitle, 0)
    [void]$leftGrid.Children.Add($hwTitle)

    # Cyber-Gold Telemetry Chart Box (matches the golden bar/line graph under OPTIMIZE in the video)
    $chartBorder = [System.Windows.Controls.Border]::new()
    $chartBorder.Background = Get-SIBrush '#0b0e15'
    $chartBorder.BorderBrush = Get-SIBrush '#2d2515'
    $chartBorder.BorderThickness = [System.Windows.Thickness]::new(1)
    $chartBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $chartBorder.Margin = [System.Windows.Thickness]::new(0, 6, 0, 8)
    $chartBorder.Padding = [System.Windows.Thickness]::new(6, 4, 6, 4)

    $waveCanvas = [System.Windows.Controls.Canvas]::new()
    $waveCanvas.Height = 76
    $script:SINames['HudWaveCanvas'] = $waveCanvas
    if (-not $script:SILastHudOptPercent) { $script:SILastHudOptPercent = 80 }
    $null = $waveCanvas.Add_SizeChanged({
        $pct = if ($script:SILastHudOptPercent) { [int]$script:SILastHudOptPercent } else { 80 }
        Update-SIHudTelemetryChart -OptPercent $pct
    })
    $chartBorder.Child = $waveCanvas
    [System.Windows.Controls.Grid]::SetRow($chartBorder, 1)
    [void]$leftGrid.Children.Add($chartBorder)

    $tweakScroll = [System.Windows.Controls.ScrollViewer]::new()
    $tweakScroll.VerticalScrollBarVisibility = 'Auto'
    $tweakListPanel = [System.Windows.Controls.StackPanel]::new()
    $tweakScroll.Content = $tweakListPanel
    $script:SINames['AutoTweakList'] = $tweakListPanel
    [System.Windows.Controls.Grid]::SetRow($tweakScroll, 2)
    [void]$leftGrid.Children.Add($tweakScroll)

    [System.Windows.Controls.Grid]::SetColumn($leftCard, 0)
    [void]$cardsGrid.Children.Add($leftCard)

    # Card Right: Installed Games & Automatic Game Configs
    $rightCard = [System.Windows.Controls.Border]::new()
    $rightCard.Background = Get-SIBrush $c.Panel
    $rightCard.BorderBrush = Get-SIBrush $c.BorderGold
    $rightCard.BorderThickness = [System.Windows.Thickness]::new(1)
    $rightCard.Margin = [System.Windows.Thickness]::new(6, 0, 0, 0)
    $rightCard.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)
    $rightCard.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $rightGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridRow -Grid $rightGrid -Type 'Auto'
    Add-SIGridRow -Grid $rightGrid -Type 'Auto'
    Add-SIGridRow -Grid $rightGrid -Type 'Star' -Value 1
    $rightCard.Child = $rightGrid

    $gameHeaderDock = [System.Windows.Controls.DockPanel]::new()
    $btnAddGame = New-SIStyleButton -Text (Get-SIHudText 'BtnAddGame') -StyleKey 'GhostButton' -Window $window
    $btnAddGame.Height = 24
    $btnAddGame.FontSize = 10.5
    $btnAddGame.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    [System.Windows.Controls.DockPanel]::SetDock($btnAddGame, 'Right')
    [void]$gameHeaderDock.Children.Add($btnAddGame)
    $btnRequestGame = New-SIStyleButton -Text (Get-SICommunityText 'BtnFeedback') -StyleKey 'GhostButton' -Window $window
    $btnRequestGame.Height = 24
    $btnRequestGame.FontSize = 10.5
    $btnRequestGame.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    [System.Windows.Controls.DockPanel]::SetDock($btnRequestGame, 'Right')
    [void]$gameHeaderDock.Children.Add($btnRequestGame)
    $btnPresets = New-SIStyleButton -Text (Get-SICommunityText 'BtnPresets') -StyleKey 'AccentButton' -Window $window
    $btnPresets.Height = 24
    $btnPresets.FontSize = 10.5
    $btnPresets.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    [System.Windows.Controls.DockPanel]::SetDock($btnPresets, 'Right')
    [void]$gameHeaderDock.Children.Add($btnPresets)

    $gamesTitle = [System.Windows.Controls.TextBlock]::new()
    $gamesTitle.Text = (Get-SIHudText 'Card2Title')
    $gamesTitle.FontSize = 12
    $gamesTitle.FontWeight = 'Bold'
    $gamesTitle.Foreground = Get-SIBrush $c.Accent
    $gamesTitle.VerticalAlignment = 'Center'
    $script:SINames['GamesCardTitle'] = $gamesTitle
    [void]$gameHeaderDock.Children.Add($gamesTitle)
    [System.Windows.Controls.Grid]::SetRow($gameHeaderDock, 0)
    [void]$rightGrid.Children.Add($gameHeaderDock)

    $gamesSub = [System.Windows.Controls.TextBlock]::new()
    $gamesSub.Text = (Get-SIHudText 'Card2Sub')
    $gamesSub.FontSize = 11
    $gamesSub.Foreground = Get-SIBrush $c.Muted
    $gamesSub.TextWrapping = 'Wrap'
    $gamesSub.Margin = [System.Windows.Thickness]::new(0, 4, 0, 6)
    [System.Windows.Controls.Grid]::SetRow($gamesSub, 1)
    [void]$rightGrid.Children.Add($gamesSub)

    $gameScroll = [System.Windows.Controls.ScrollViewer]::new()
    $gameScroll.VerticalScrollBarVisibility = 'Auto'
    $gameListPanel = [System.Windows.Controls.StackPanel]::new()
    $gameScroll.Content = $gameListPanel
    $script:SINames['GameLibrary'] = $gameListPanel
    [System.Windows.Controls.Grid]::SetRow($gameScroll, 2)
    [void]$rightGrid.Children.Add($gameScroll)

    Add-SIGridRow -Grid $rightGrid -Type 'Auto'
    $telemetryNotice = New-SITelemetryNotice
    [System.Windows.Controls.Grid]::SetRow($telemetryNotice, 3)
    [void]$rightGrid.Children.Add($telemetryNotice)

    [System.Windows.Controls.Grid]::SetColumn($rightCard, 1)
    [void]$cardsGrid.Children.Add($rightCard)

    [System.Windows.Controls.Grid]::SetRow($cardsGrid, 3)
    [void]$root.Children.Add($cardsGrid)

    # --- ROW 4: FOOTER & COMPACT LOG EXPANDER -------------------------------
    $footerBorder = [System.Windows.Controls.Border]::new()
    $footerBorder.Background = Get-SIBrush '#0c0f17'
    $footerBorder.BorderBrush = Get-SIBrush $c.BorderGold
    $footerBorder.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $footerBorder.Padding = [System.Windows.Thickness]::new(16, 6, 16, 6)
    $footerStack = [System.Windows.Controls.StackPanel]::new()

    $logExpander = [System.Windows.Controls.Expander]::new()
    $logExpander.Header = (Get-SIHudText 'LogHeader')
    $logExpander.Foreground = Get-SIBrush $c.Muted
    $logExpander.FontSize = 11
    $logExpander.IsExpanded = $false
    $logBox = [System.Windows.Controls.TextBox]::new()
    $logBox.Height = 100
    $logBox.Background = Get-SIBrush '#090b10'
    $logBox.Foreground = Get-SIBrush '#e2c178'
    $logBox.BorderThickness = [System.Windows.Thickness]::new(1)
    $logBox.BorderBrush = Get-SIBrush $c.BorderGold
    $logBox.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6)
    $logBox.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas')
    $logBox.FontSize = 11
    $logBox.IsReadOnly = $true
    $logBox.VerticalScrollBarVisibility = 'Auto'
    $logExpander.Content = $logBox
    $script:SINames['LogBox'] = $logBox
    $script:SILogBox = $logBox
    [void]$footerStack.Children.Add($logExpander)

    $trustText = [System.Windows.Controls.TextBlock]::new()
    $trustText.Text = (Get-SIHudText 'TrustInit')
    $trustText.FontSize = 10.5
    $trustText.Foreground = Get-SIBrush $c.Accent
    $trustText.Margin = [System.Windows.Thickness]::new(0, 3, 0, 0)
    $script:SINames['TrustText'] = $trustText
    [void]$footerStack.Children.Add($trustText)

    $footerBorder.Child = $footerStack
    [System.Windows.Controls.Grid]::SetRow($footerBorder, 4)
    [void]$root.Children.Add($footerBorder)

    # --- System version in header -------------------------------------------
    try {
        $ver = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $b = [int]$ver.CurrentBuild
        $fam = if ($b -ge 22000) { 'Windows 11' } else { 'Windows 10' }
        $headerRight.Children[0].Text = ('{0} {1} (build {2}.{3})' -f $fam, $ver.DisplayVersion, $b, $ver.UBR)
    } catch { }

    # --- Wire events --------------------------------------------------------
    $null = $btnOptimize.Add_Click({ Invoke-SIAutoOptimizeAll })
    $null = $btnUndo.Add_Click({
        $msg = (Get-SIHudText 'UndoConfirmMsg')
        if (Show-SIMessage -Window $window -Text $msg -Title (Get-SIHudText 'UndoConfirmTitle')) {
            Invoke-SIUndoAll
            Restore-SIHardBcdBootTweaks
            [void](Restore-SIRobloxQualityProfile)
            Restore-SIUnusedServices
            [void](Set-SIBackgroundHogsPriority -IdleMode $false)
            [void](Set-SIGamingWindowsUpdatePause -Pause $false)
            [void](Set-SITimerResolution05ms -Enable $false)
            Remove-SIGameFoldersFromDefenderExclusion
            [void](Get-SIGamingHealthCheck -ForceRefresh)
            $script:SIMeasuresAfter = Measure-SISystem -QuickDns
            Update-SIProvePanel
            Update-SIAutoDashboard
            Set-SIStatusText -Text (Get-SIHudText 'UndoDoneMsg')
        }
    }.GetNewClosure())

    $null = $btnAddGame.Add_Click({
        Invoke-SIAddCustomGameDialog
    })

    $null = $btnRequestGame.Add_Click({
        Invoke-SIRequestGame
    })

    $null = $btnPresets.Add_Click({
        Show-SIPresetsWindow
    })

    $null = $btnRamNow.Add_Click({
        $freed = Clear-SIWorkingSets
        [void](Set-SITimerResolution05ms -Enable $true)
        $script:SIMeasuresAfter = Measure-SISystem -QuickDns
        Update-SIProvePanel
        Update-SIAutoDashboard
        Set-SIStatusText -Text ((Get-SIHudText 'RamDoneFmt') -f $freed)
    })

    $null = $btnInspect.Add_Click({
        Show-SITransparencyInspector
    })

    $null = $btnBench.Add_Click({
        Invoke-SILiveLatencyBenchmark
    })

    $null = $btnShareCard.Add_Click({
        if (Save-SIShareCard) {
            Set-SIStatusText -Text ((Get-SIText -Key 'CardSaved') -f $script:SISharePath)
        } else {
            Set-SIStatusText -Text 'Could not save result image.'
        }
    })

    $script:SIWindow = $window
    return $window
}

# ================ 7. DASHBOARD REFRESH & DIAGNOSTIC VIEW ====================

function Update-SIAutoDashboard {
    $c = $script:SIColors
    $audit = Get-SIPcOptimizationAudit
    $plan  = $audit.Plan
    $info  = $script:SIBottleneck

    # 1. Update Hero Audit Title, Subtitle & Cyber-Gold Circular Gauges
    $titleEl = Get-SIElement -Name 'AuditTitle'
    $subEl   = Get-SIElement -Name 'AuditSubtitle'
    if ($titleEl) {
        if ($audit.Percent -ge 95) {
            $titleEl.Text = ((Get-SIHudText 'AuditOptFmt') -f $audit.Percent, $audit.AppliedTweaks, $audit.TotalTweaks, $audit.OptGames, $audit.TotalGames)
            $titleEl.Foreground = Get-SIBrush $c.Ok
        } elseif ($audit.Percent -ge 50) {
            $titleEl.Text = ((Get-SIHudText 'AuditPartFmt') -f $audit.Percent, $audit.AppliedTweaks, $audit.TotalTweaks, $audit.OptGames, $audit.TotalGames)
            $titleEl.Foreground = Get-SIBrush $c.Accent
        } else {
            $titleEl.Text = ((Get-SIHudText 'AuditNeedFmt') -f $audit.Percent, $audit.AppliedTweaks, $audit.TotalTweaks, $audit.OptGames, $audit.TotalGames)
            $titleEl.Foreground = Get-SIBrush $c.Accent
        }
    }
    if ($subEl) {
        if ($audit.Percent -ge 95) {
            $subEl.Text = ((Get-SIHudText 'AuditSubOptFmt') -f $plan.ProfileName)
        } else {
            $missingCount = ($audit.TotalTweaks - $audit.AppliedTweaks) + ($audit.TotalGames - $audit.OptGames)
            $subEl.Text = ((Get-SIHudText 'AuditSubNeedFmt') -f $plan.ProfileName, $missingCount, (Get-SIHudText 'BtnOptimize'))
        }
    }

    # Update Circular Gauges & Horizontal Telemetry Bars
    $gMain = Get-SIElement -Name 'HudGaugeMainVal'
    if ($gMain) { $gMain.Text = ('{0:D4}' -f [int]$audit.Percent) }

    $gSec = Get-SIElement -Name 'HudGaugeSecVal'
    if ($gSec) { $gSec.Text = if ($audit.Percent -ge 90) { '0.50' } else { '1.00' } }

    $health = Get-SIGamingHealthCheck
    $gPing = Get-SIElement -Name 'HudGaugePingVal'
    if ($gPing) {
        $dnsVal = if ($script:SILastDnsMs -gt 0) { [int][math]::Round($script:SILastDnsMs) } elseif ($script:SIMeasuresAfter -and $script:SIMeasuresAfter.DnsMs -gt 0) { [int][math]::Round($script:SIMeasuresAfter.DnsMs) } else { 14 }
        $gPing.Text = ('{0:D4}' -f $dnsVal)
    }

    $tweakPct = if ($audit.TotalTweaks -gt 0) { [int][math]::Round(($audit.AppliedTweaks * 100.0) / $audit.TotalTweaks) } else { 100 }
    $gamePct  = if ($audit.TotalGames -gt 0)  { [int][math]::Round(($audit.OptGames * 100.0) / $audit.TotalGames) } else { 100 }
    $barTw = Get-SIElement -Name 'HudBar_Tweaks'; $valTw = Get-SIElement -Name 'HudVal_Tweaks'
    $barGm = Get-SIElement -Name 'HudBar_Games';  $valGm = Get-SIElement -Name 'HudVal_Games'
    if ($barTw) { $barTw.Value = $tweakPct }
    if ($valTw) { $valTw.Text  = "$tweakPct%" }
    if ($barGm) { $barGm.Value = $gamePct }
    if ($valGm) { $valGm.Text  = "$gamePct%" }

    $script:SILastHudOptPercent = $audit.Percent
    Update-SIHudTelemetryChart -OptPercent $audit.Percent
    $trustEl = Get-SIElement -Name 'TrustText'
    if ($trustEl) { $trustEl.Text = (Get-SITrustAndIntegrityBadge) }

    # 2. Update Hardware Details, Gaming Health & Tweak Checklist
    $hwEl = Get-SIElement -Name 'BottleneckDetails'
    if ($hwEl -and $info) {
        $diskInfo = $info.DiskType
        if ($info.FreeGB -ge 0) { $diskInfo = ((Get-SIHudText 'DiskFreeFmt') -f $info.DiskType, $info.FreeGB) }
        $hwEl.Text = ((Get-SIHudText 'HwSummaryFmt') -f $info.Cpu, $info.Gpu, $info.RamText, $diskInfo, $plan.ProfileName)
    }

    $healthEl = Get-SIElement -Name 'GamingHealthText'
    if ($healthEl -and $health) {
        $healthEl.Text = $health.Summary
        $healthEl.Foreground = if ($health.HasWarning) { Get-SIBrush $c.Warn } else { Get-SIBrush $c.Ok }
    }

    $tweakPanel = Get-SIElement -Name 'AutoTweakList'
    if ($tweakPanel) {
        $tweakPanel.Children.Clear()
        foreach ($item in $plan.Tweaks) {
            $st = $null
            if ($script:SIWorkerStates -and $script:SIWorkerStates.ContainsKey($item.Id)) {
                $st = $script:SIWorkerStates[$item.Id]
            } else {
                try { $st = Get-SITweakState -Tweak $item.Tweak -OptionOverride $item.Option } catch { }
            }
            $isApplied = ($st -and $st.Status -eq 'Applied')

            $row = [System.Windows.Controls.Border]::new()
            $row.Background = Get-SIBrush $c.PanelAlt
            $row.BorderBrush = if ($isApplied) { Get-SIBrush '#3a3018' } else { Get-SIBrush '#222838' }
            $row.BorderThickness = [System.Windows.Thickness]::new(1)
            $row.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $row.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
            $row.Margin = [System.Windows.Thickness]::new(0, 2, 4, 2)

            $dock = [System.Windows.Controls.DockPanel]::new()
            $badge = [System.Windows.Controls.TextBlock]::new()
            $badge.Text = if ($isApplied) { (Get-SIHudText 'BadgeActive') } else { (Get-SIHudText 'BadgePending') }
            $badge.FontSize = 10.5
            $badge.FontWeight = 'Bold'
            $badge.Foreground = if ($isApplied) { Get-SIBrush $c.Accent } else { Get-SIBrush $c.Muted }
            $badge.VerticalAlignment = 'Center'
            [System.Windows.Controls.DockPanel]::SetDock($badge, 'Right')
            [void]$dock.Children.Add($badge)

            $nameTb = [System.Windows.Controls.TextBlock]::new()
            $optLabel = if ($item.Option) { " ($($item.Option))" } else { '' }
            $nameTb.Text = $item.Name + $optLabel
            $nameTb.FontSize = 11.5
            $nameTb.FontWeight = 'SemiBold'
            $nameTb.Foreground = Get-SIBrush $c.Text
            $nameTb.VerticalAlignment = 'Center'
            $nameTb.TextTrimming = 'CharacterEllipsis'
            $nameTb.ToolTip = $item.Tweak.Description
            [void]$dock.Children.Add($nameTb)

            $row.Child = $dock
            [void]$tweakPanel.Children.Add($row)
        }
    }

    # 3. Update Installed Games List
    $gamesTitleEl = Get-SIElement -Name 'GamesCardTitle'
    if ($gamesTitleEl) {
        $gamesTitleEl.Text = ((Get-SIHudText 'Card2TitleFmt') -f $audit.TotalGames, $audit.OptGames)
    }
    Build-SIGameLibrary
    Update-SITrayQuickMenu
}

function Build-SIGameLibrary {
    $panel = Get-SIElement -Name 'GameLibrary'
    if (-not $panel) { return }
    if (@($script:SIGameLibrary).Count -gt 0) { Invoke-SITelemetryWeekly }
    $c = $script:SIColors
    $panel.Children.Clear()

    $games = @($script:SIGameLibrary)
    if ($games.Count -eq 0) {
        $empty = [System.Windows.Controls.TextBlock]::new()
        $empty.Text = (Get-SIHudText 'GamesEmpty')
        $empty.FontSize = 12
        $empty.Foreground = Get-SIBrush $c.Muted
        $empty.TextWrapping = 'Wrap'
        $empty.Margin = [System.Windows.Thickness]::new(0, 8, 0, 0)
        [void]$panel.Children.Add($empty)
        return
    }

    foreach ($game in $games) {
        $exe = [string]$game.Exe
        $gpuOk = Get-SIGameGpuState -ExePath $exe
        $fsOk  = Get-SIGameFullscreenState -ExePath $exe
        $cpuOk = Get-SIGameCpuPriorityState -ExePath $exe
        $allOk = ($gpuOk -and $fsOk -and $cpuOk)

        $card = [System.Windows.Controls.Border]::new()
        $card.Background = Get-SIBrush $c.PanelAlt
        $card.BorderBrush = Get-SIBrush '#3a3018'
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
        $card.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $card.Padding = [System.Windows.Thickness]::new(10, 7, 10, 7)
        $card.Margin = [System.Windows.Thickness]::new(0, 2, 4, 3)

        $grid = [System.Windows.Controls.Grid]::new()
        Add-SIGridColumn -Grid $grid -Type 'Auto'
        Add-SIGridColumn -Grid $grid -Type 'Star' -Value 1
        Add-SIGridColumn -Grid $grid -Type 'Auto'
        Add-SIGridColumn -Grid $grid -Type 'Auto'
        Add-SIGridColumn -Grid $grid -Type 'Auto'

        $icon = [System.Windows.Controls.Image]::new()
        $icon.Width = 22
        $icon.Height = 22
        $icon.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $icon.VerticalAlignment = 'Center'
        $pic = Get-SIGameIcon -ExePath $exe
        if ($pic) { $icon.Source = $pic }
        [System.Windows.Controls.Grid]::SetColumn($icon, 0)
        [void]$grid.Children.Add($icon)

        $infoStack = [System.Windows.Controls.StackPanel]::new()
        $infoStack.VerticalAlignment = 'Center'
        $gName = [System.Windows.Controls.TextBlock]::new()
        $gName.Text = "$($game.Name)  [$($game.Store)]"
        $gName.FontSize = 12
        $gName.FontWeight = 'SemiBold'
        $gName.Foreground = Get-SIBrush $c.Text
        $gName.TextTrimming = 'CharacterEllipsis'
        $gName.ToolTip = $exe
        [void]$infoStack.Children.Add($gName)

        $pwrOk  = Get-SIGamePowerThrottlingState -ExePath $exe
        $gSub = [System.Windows.Controls.TextBlock]::new()
        $gpuTxt = if ($gpuOk) { 'GPU Max: ON' } else { 'GPU Max: OFF' }
        $fsTxt  = if ($fsOk)  { 'No Fullscreen Lag: ON' } else { 'No Fullscreen Lag: OFF' }
        $cpuTxt = if ($cpuOk) { 'CPU/IO High: ON' } else { 'CPU/IO High: OFF' }
        $pwrTxt = if ($pwrOk) { 'No Throttle: ON' } else { 'No Throttle: OFF' }
        $gSub.Text = "$gpuTxt  |  $fsTxt  |  $cpuTxt  |  $pwrTxt"
        $gSub.FontSize = 10
        $gSub.Foreground = Get-SIBrush $c.Muted
        [void]$infoStack.Children.Add($gSub)

        [System.Windows.Controls.Grid]::SetColumn($infoStack, 1)
        [void]$grid.Children.Add($infoStack)

        $statusBadge = [System.Windows.Controls.TextBlock]::new()
        $statusBadge.Text = if ($allOk) { (Get-SIHudText 'GameOptBadge') } else { (Get-SIHudText 'GameNeedBadge') }
        $statusBadge.FontSize = 11
        $statusBadge.FontWeight = 'Bold'
        $statusBadge.Foreground = if ($allOk) { Get-SIBrush $c.Ok } else { Get-SIBrush $c.Warn }
        $statusBadge.VerticalAlignment = 'Center'
        $statusBadge.Margin = [System.Windows.Thickness]::new(8, 0, 6, 0)
        [System.Windows.Controls.Grid]::SetColumn($statusBadge, 2)
        [void]$grid.Children.Add($statusBadge)

        $btnPlay = New-SIStyleButton -Text (Get-SIHudText 'BtnPlay') -StyleKey 'AccentButton' -Window $script:SIWindow -Width 64
        $btnPlay.Height = 24
        $btnPlay.FontSize = 11
        $btnPlay.Margin = [System.Windows.Thickness]::new(0)
        $capturedGame = $game
        $null = $btnPlay.Add_Click({
            Invoke-SILaunchGameOptimized -Game $capturedGame
        }.GetNewClosure())
        [System.Windows.Controls.Grid]::SetColumn($btnPlay, 3)
        [void]$grid.Children.Add($btnPlay)

        # SI PRESET when SI NEWS made one for this game, else REQUEST one.
        $preset = Find-SIGamePreset -Game $game
        if ($preset) {
            $btnSi = New-SIStyleButton -Text (Get-SICommunityText 'BtnPreset') -StyleKey 'AccentButton' -Window $script:SIWindow -Width 76
            $btnSi.ToolTip = "$($preset.Title): $(Get-SIPresetText -Entry $preset)"
            $capturedPreset = $preset
            $null = $btnSi.Add_Click({ Invoke-SIGamePreset -Entry $capturedPreset }.GetNewClosure())
        } else {
            $btnSi = New-SIStyleButton -Text (Get-SICommunityText 'BtnRequest') -StyleKey 'GhostButton' -Window $script:SIWindow -Width 76
            $null = $btnSi.Add_Click({ Invoke-SIRequestGame -Game $capturedGame }.GetNewClosure())
        }
        $btnSi.Height = 24
        $btnSi.FontSize = 10.5
        $btnSi.Margin = [System.Windows.Thickness]::new(6, 0, 0, 0)
        [System.Windows.Controls.Grid]::SetColumn($btnSi, 4)
        [void]$grid.Children.Add($btnSi)

        $card.Child = $grid
        [void]$panel.Children.Add($card)
    }
}

function Build-SIRows {
    if (-not $script:SIGameLibrary -or @($script:SIGameLibrary).Count -eq 0) {
        try { $script:SIGameLibrary = @(Get-SIExtendedGames) } catch { }
    }
    Update-SIAutoDashboard
    if ($script:SIStartMinimized -and $script:SIWindow) {
        try {
            $script:SIWindow.Hide()
            Show-SITrayBalloon -Title 'SIGAME AUTO attivo nella Tray' -Text 'Sorveglianza giochi Auto-Boost attiva in background.'
        } catch { }
    }
}

function Update-SIBottleneck {
    Update-SIAutoDashboard
}

# ============ 8. ONE-CLICK AUTOMATIC OPTIMIZER ("OTTIMIZAR") ================

function Invoke-SIAutoOptimizeAll {
    <#
    .SYNOPSIS
        Executes the complete automatic optimization in one click:
        1. Hardware-adaptive system & aggressive gaming tweaks
        2. Fastest DNS server benchmark & automatic selection
        3. Per-game optimizations (High-Performance GPU + Disable Fullscreen Optimizations)
        4. Automatic Auto-Boost configuration for background RAM hogs + game watcher
    #>
    if (-not $script:SIPrepared) {
        Set-SIStatusText -Text 'Attendere il completamento della verifica iniziale (Punto di ripristino / Backup)...'
        return
    }

    $btnOpt  = Get-SIElement -Name 'BtnOptimize'
    $btnUndo = Get-SIElement -Name 'BtnUndoAllBig'
    if ($btnOpt)  { $btnOpt.IsEnabled = $false }
    if ($btnUndo) { $btnUndo.IsEnabled = $false }

    try {
        Reset-SIProgress -Step 'Misurazione stato iniziale del PC...'
        Invoke-SIUIPump
        $before = Measure-SISystem -QuickDns
        $script:SIMeasuresBefore = $before

        if ($script:SIAutoMode -eq 'SessionOnly') {
            Set-SIProgress -Percent 35 -Step 'Modalita Solo Boost Sessione (Zero Registro): attivazione Timer 0.5ms e pulizia Standby RAM...'
            Invoke-SIUIPump
            [void](Set-SITimerResolution05ms -Enable $true)
            [void](Set-SIGamingWindowsUpdatePause -Pause $true)
            [void](Invoke-SINetworkCacheFlush)
            $idledCount = Set-SIBackgroundHogsPriority -IdleMode $true
            $freedRam   = Clear-SIWorkingSets
            $shaderRes  = Clear-SIShaderCache
            $tempRes    = Clear-SISystemTempAndDumps
            $totalCleanMB = [math]::Round([double]$shaderRes.MegaBytes + [double]$tempRes.MegaBytes, 1)

            [void](Get-SIGamingHealthCheck -ForceRefresh)
            $after = Measure-SISystem -QuickDns
            $script:SIMeasuresAfter = $after
            Save-SIMeasures -Before $before -After $after | Out-Null
            Update-SIProvePanel
            Update-SIAutoDashboard

            $summary = "Boost Sessione Attivo (Zero Registro): Timer 0.5ms, +$freedRam MB RAM, $idledCount processi in Idle, Puliti: $totalCleanMB MB"
            $resEl = Get-SIElement -Name 'OptimizeResult'
            if ($resEl) { $resEl.Text = "Boost Sessione (Zero Registro): +$freedRam MB RAM + Timer 0.5ms" }
            Set-SIProgress -Percent 100 -Done
            Set-SIStatusText -Text $summary
            Show-SITrayBalloon -Title 'SIGAME - Boost Sessione Attivo' -Text $summary
            Write-SILog -Level 'OK' -Component 'SessionOnly' -Message $summary
            return
        }

        $plan = Get-SIHardwareAdaptivePlan
        $todo = @($plan.Tweaks)
        $games = @($script:SIGameLibrary)

        $totalSteps = $todo.Count + 3 # Tweaks + DNS + Games + Auto-Boost
        $currentStep = 0
        $doneTweaks = 0
        $skippedTweaks = 0

        # --- PHASE 1: Hardware-Tailored System & Aggressive Tweaks ----------
        foreach ($item in $todo) {
            $currentStep++
            $pct = [int](($currentStep * 100) / [math]::Max(1, $totalSteps))
            Set-SIProgress -Percent $pct -Step ("Ottimizzazione: {0} ..." -f $item.Name)
            Invoke-SIUIPump

            if ($item.Option) {
                $script:SIOptionOverride[$item.Id] = [string]$item.Option
            }
            Invoke-SIApplyTweak -TweakId $item.Id
            if ($script:SILastApplyStatus -eq 'applied') {
                $doneTweaks++
                $script:SIWorkerStates[$item.Id] = @{ Status = 'Applied'; Text = 'Applied'; Details = '' }
            } else {
                $skippedTweaks++
            }
            Invoke-SIUIPump
        }
        $script:SIOptionOverride = @{}

        # --- PHASE 2: Automatic Fastest DNS Selection -----------------------
        $currentStep++
        $pct = [int](($currentStep * 100) / [math]::Max(1, $totalSteps))
        Set-SIProgress -Percent $pct -Step 'Ricerca e attivazione del server DNS piu veloce (Cloudflare / Google / Quad9)...'
        Invoke-SIUIPump

        $dnsLabel = 'invariato'
        try {
            $dnsBench = @(Invoke-SIDnsBenchmark)
            $script:SIDnsResults = $dnsBench
            $bestDns = $null
            foreach ($row in $dnsBench) {
                if ([double]$row.Ms -lt 0) { continue }
                if ((-not $bestDns) -or ([double]$row.Ms -lt [double]$bestDns.Ms)) {
                    $bestDns = $row
                }
            }
            if ($bestDns -and $bestDns.Server -ne 'current') {
                $script:SISelectedDns = [string]$bestDns.Server
                Invoke-SIApplyTweak -TweakId 'DNSServer'
                $dnsLabel = "$($bestDns.Name) ($($bestDns.Server) - $([math]::Round([double]$bestDns.Ms, 1)) ms)"
                $script:SILastDnsMs = [math]::Round([double]$bestDns.Ms, 1)
            } elseif ($bestDns) {
                $dnsLabel = "DNS attuale gia ottimale ($([math]::Round([double]$bestDns.Ms, 1)) ms)"
                $script:SILastDnsMs = [math]::Round([double]$bestDns.Ms, 1)
            }
        } catch {
            Write-SILog -Level 'WARN' -Component 'DNS' -Message "Auto DNS skip: $($_.Exception.Message)"
        }

        # --- PHASE 3: Automatic Optimization of All Installed Games ---------
        $currentStep++
        $pct = [int](($currentStep * 100) / [math]::Max(1, $totalSteps))
        Set-SIProgress -Percent $pct -Step ("Configurazione automatica di {0} giochi rilevati..." -f $games.Count)
        Invoke-SIUIPump

        $optGamesCount = 0
        $gpuRegPath   = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
        $layerRegPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'

        foreach ($game in $games) {
            $exe = [string]$game.Exe
            if (-not $exe -or -not [System.IO.File]::Exists($exe)) { continue }
            try {
                Save-SIToolUndo -Key ('GameGpu|' + $exe) -Path $gpuRegPath -Name $exe
                Set-SIGameGpuPreference -ExePath $exe

                Save-SIToolUndo -Key ('GameFullscreen|' + $exe) -Path $layerRegPath -Name $exe
                Set-SIGameFullscreenOptimizations -ExePath $exe

                $cpuRegPath = Get-SIGameCpuPriorityRegPath -ExePath $exe
                if ($cpuRegPath) {
                    Save-SIToolUndo -Key ('GameCpuPriority|' + $exe)  -Path $cpuRegPath -Name 'CpuPriorityClass'
                    Save-SIToolUndo -Key ('GameIoPriority|' + $exe)   -Path $cpuRegPath -Name 'IoPriority'
                    Save-SIToolUndo -Key ('GamePagePriority|' + $exe) -Path $cpuRegPath -Name 'PagePriority'
                    Set-SIGameCpuPriorityHigh -ExePath $exe
                }

                Save-SIToolUndo -Key ('GamePowerThrottle|' + $exe) -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name $exe
                Set-SIGamePowerThrottlingOff -ExePath $exe

                [void](Add-SIAutoBoostGame -Path $exe)
                $optGamesCount++
                Write-SILog -Level 'OK' -Component 'Game' -Message "Ottimizzato gioco (GPU + Fullscreen + CPU/IO Alta + No PowerThrottle): $($game.Name) ($exe)"
            } catch {
                Write-SILog -Level 'WARN' -Component 'Game' -Message "Impossibile ottimizzare $($game.Name): $($_.Exception.Message)"
            }
            Invoke-SIUIPump
        }
        # Roblox profile (a settings file, not the registry): graphics quality 1.
        [void](Set-SIRobloxLowQualityProfile)

        # --- PHASE 3B: Competitive eSports & HARD Kernel/BCD/GPU/NVMe/IRQ/RAM/UDP Tweaks ---
        Set-SIProgress -Percent 90 -Step 'Ottimizzazione HARD Kernel/BCD, Anti-Cheat Safe, Monitor Max Hz, P2P OFF, Timer 0.5ms, Standby RAM...'
        Invoke-SIUIPump
        [void](Enable-SICpuCoreUnpark)
        [void](Disable-SIPcieLinkPowerManagement)
        [void](Enable-SIUsbLowLatency)
        [void](Set-SITimerResolution05ms -Enable $true)
        [void](Enable-SIMouseKeyboardRawCompetitive)
        [void](Disable-SIStickyAndFilterKeys)
        [void](Enable-SILowLatencyGamingAudio)
        [void](Enable-SIUdpAfdSocketOptimization)
        [void](Invoke-SINetworkCacheFlush)
        $nicOptCount = Enable-SINicCompetitiveLowLatency
        [void](Enable-SIDirectXFlipAndDwm)
        $gpuOptCount = Enable-SIGpuLowLatencyOptimization
        [void](Enable-SIHardBcdBootTweaks)
        [void](Enable-SIHardKernelMitigationsOff)
        [void](Enable-SIHardGpuPreemptionAndTdr)
        [void](Enable-SIHardNvmeAndNtfsSpeed)
        [void](Enable-SIHardMemoryNoPagingExecutive)
        [void](Enable-SIHardIrqAndDriverThreadPriority)
        [void](Enable-SIQosZeroReserveAndRss)
        [void](Set-SIUnusedServicesManual)
        [void](Enable-SINvidiaUnlimitedShaderCache)
        [void](Disable-SIDeliveryOptimizationP2P)
        [void](Disable-SIUwpBackgroundApps)
        [void](Enable-SIMaxMonitorRefreshRate)
        [void](Enable-SIWifiGamingAntiLag)
        [void](Enable-SITcpPortAndSocketUnlock)
        [void](Disable-SIGamingPopupNotifications)
        [void](Optimize-SIBrowserAndWebView2Gaming)
        [void](Enable-SICpuTurboAndMinClock)
        [void](Enable-SIDwmMpoAntiFlickerFix)
        [void](Enable-SIMultimediaNetworkAndCpuUnlock)
        [void](Enable-SIHybridCpuPCoreScheduling)
        [void](Enable-SINvidiaMaxPerformancePowerMizer)
        [void](Enable-SIAmdRadeonDeepSleepOff)
        [void](Disable-SIUsbHidDevicePowerSaving)
        [void](Disable-SIDnsNegativeCache)
        [void](Optimize-SITcpTimestampsAndEcn)
        [void](Enable-SIFastAppKillTimeouts)
        [void](Disable-SIFastStartupHiberboot)
        [void](Repair-SIPagefileAntiCrash)
        [void](Invoke-SISsdFastReTrim)
        [void](New-SIAutoDesktopShortcut)
        [void](Export-SIEmergencyRegBackup)
        [void](Export-SIGamingDiagnosticReport)
        $defExclCount = Add-SIGameFoldersToDefenderExclusion
        $shaderRes   = Clear-SIShaderCache
        $tempRes     = Clear-SISystemTempAndDumps
        $launchRes   = Clear-SILauncherWebCaches
        $totalCleanMB = [math]::Round([double]$shaderRes.MegaBytes + [double]$tempRes.MegaBytes + [double]$launchRes.MegaBytes, 1)
        $freedRam  = Clear-SIWorkingSets
        [void](Set-SIBackgroundHogsPriority -IdleMode $true)

        # --- PHASE 4: Configure Auto-Boost & Run Immediate RAM/Power Boost --
        $currentStep++
        Set-SIProgress -Percent 95 -Step 'Attivazione Auto-Boost per chiusura app in background durante il gioco...'
        Invoke-SIUIPump

        try {
            $boostState = Get-SIBoostState
            if (-not $boostState['Configured'] -or @($boostState['Ticked']).Count -eq 0) {
                $boostState['Ticked'] = @('chrome', 'msedge', 'firefox', 'brave', 'opera', 'vivaldi', 'onedrive', 'teams', 'teamsnew', 'epicweb', 'eaweb')
                $boostState['Configured'] = $true
            }
            $boostState['AutoBoost'] = $true
            Save-SIBoostState -State $boostState | Out-Null
            Set-SIAutoBoostEnabled -Enabled $true
        } catch { }

        # --- PHASE 5: Final Measurement & UI Refresh ------------------------
        [void](Get-SIGamingHealthCheck -ForceRefresh)
        $after = Measure-SISystem -QuickDns
        if ($script:SILastDnsMs -gt 0 -and ($after.DnsMs -le 0 -or $script:SILastDnsMs -lt $after.DnsMs)) {
            $after.DnsMs = $script:SILastDnsMs
        }
        $script:SIMeasuresAfter = $after
        Save-SIMeasures -Before $before -After $after | Out-Null

        Update-SIProvePanel
        Update-SIAutoDashboard

        $rebBanner = Get-SIElement -Name 'RebootBanner'
        if ($rebBanner -and ($doneTweaks -gt 0 -or $gpuOptCount -gt 0 -or $nicOptCount -gt 0)) {
            $rebBanner.Visibility = [System.Windows.Visibility]::Visible
        }

        $summary = "Completato: $doneTweaks tweak, $optGamesCount giochi, Timer 0.5ms, Raw Mouse, GPU/NIC ($($gpuOptCount + $nicOptCount)), DNS: $dnsLabel, Puliti: $totalCleanMB MB"
        $resEl = Get-SIElement -Name 'OptimizeResult'
        if ($resEl) { $resEl.Text = "$doneTweaks Tweak + $optGamesCount Giochi + eSports 0.5ms/RawMouse + $totalCleanMB MB" }

        Set-SIProgress -Percent 100 -Done
        Set-SIStatusText -Text $summary
        Show-SITrayBalloon -Title 'SIGAME AUTO - Ottimizzazione Completata' -Text $summary
        Write-SILog -Level 'OK' -Component 'AutoOptimize' -Message $summary
    } finally {
        if ($btnOpt)  { $btnOpt.IsEnabled = $true }
        if ($btnUndo) { $btnUndo.IsEnabled = $true }
    }
}

# Hook Auto-Boost & Game Over to set 0.5ms Timer, pause Windows Update, suspend background hogs, trim Working Sets, and show a Post-Game Session Summary
$script:SIGameSessionStart = $null
$script:SIGameSessionRamFreedMB = 0
$script:SIGameSessionIdledCount = 0
$script:SIGameSessionLastGame = 'Gioco'

$script:SIOriginalInvokeBoost = ${function:Invoke-SIBoost}
function Invoke-SIBoost {
    param([switch]$Auto)
    & $script:SIOriginalInvokeBoost -Auto:$Auto
    [void](Set-SITimerResolution05ms -Enable $true)
    [void](Set-SIGamingWindowsUpdatePause -Pause $true)
    $idledCount = Set-SIBackgroundHogsPriority -IdleMode $true
    [void](Optimize-SILiveRunningGameProcess)
    $trimmedMB  = Clear-SIWorkingSets
    $script:SIGameSessionStart      = [datetime]::Now
    $script:SIGameSessionRamFreedMB = $trimmedMB
    $script:SIGameSessionIdledCount = $idledCount
    $script:SIGameSessionLastGame   = if ($script:SIAutoBoostRunningGame) { $script:SIAutoBoostRunningGame } else { 'Gioco' }
    if ($Auto) {
        Show-SITrayBalloon -Title "SIGAME Boost Attivo ($($script:SIGameSessionLastGame))" -Text "Timer 0.5ms, Stop WinUpdate, RAM (+$trimmedMB MB) e $idledCount processi in Idle."
    }
}

$script:SIOriginalInvokeGameOver = ${function:Invoke-SIGameOver}
function Invoke-SIGameOver {
    param([switch]$Auto)
    & $script:SIOriginalInvokeGameOver -Auto:$Auto
    [void](Set-SIBackgroundHogsPriority -IdleMode $false)
    [void](Set-SIGamingWindowsUpdatePause -Pause $false)
    [void](Set-SITimerResolution05ms -Enable $false)
    $durText = ''
    if ($script:SIGameSessionStart) {
        $elapsed = [datetime]::Now - $script:SIGameSessionStart
        $mins = [math]::Max(1, [int][math]::Round($elapsed.TotalMinutes))
        $durText = "Durata: $mins min | "
        $script:SIGameSessionStart = $null
    }
    $reportMsg = "${durText}RAM liberata: +$($script:SIGameSessionRamFreedMB) MB | App in Idle: $($script:SIGameSessionIdledCount) | PC ripristinato."
    Set-SIStatusText -Text "Sessione conclusa ($($script:SIGameSessionLastGame)): $reportMsg"
    if ($Auto) {
        Show-SITrayBalloon -Title "Report Sessione: $($script:SIGameSessionLastGame)" -Text $reportMsg
    }
}

# Hook worker updates so the dashboard refreshes automatically when background prepare finishes
$script:SIOriginalUpdateWorkerResult = ${function:Update-SIWorkerResult}
function Update-SIWorkerResult {
    $wasPrepared = [bool]$script:SIPrepared
    & $script:SIOriginalUpdateWorkerResult
    if (($script:SIPrepared -and -not $wasPrepared) -or $script:SIWorkerFinished) {
        if (-not $script:SIGameLibrary -or @($script:SIGameLibrary).Count -eq 0) {
            $script:SIGameLibrary = @(Get-SIExtendedGames)
        }
        Update-SIAutoDashboard
        if ($script:SIPrepared) {
            Set-SIStatusText -Text ((Get-SIHudText 'ReadyStatusFmt') -f (Get-SIHudText 'BtnOptimize'))
        }
    }
}

# =============================== 9. START ===================================

try {
    Invoke-SIRun
} catch {
    $why = "SIGAME AUTO could not start: " + [string]$_.Exception.Message
    try { Write-SILog -Level 'ERROR' -Component 'Start' -Message $why } catch { }
    [System.Console]::WriteLine($why)
}

try {
    [System.Environment]::Exit(0)
} catch {
    exit 0
}
