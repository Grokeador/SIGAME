# ---------------------------------------------------------------------------
#  SIGAME - module 03: the tools of round 5
#
#  The DNS benchmark, the speed test, the startup programs, the per game
#  settings, the temporary files and the measurement of the PROVE IT panel.
# ---------------------------------------------------------------------------
# ====== 6b. THE ROUND 5 FEATURES: NETWORK, FPS, TOOLS AND "PROVE IT" =======
#
#  Everything that is not a plain registry value lives here: the DNS
#  benchmark, the speed test, the startup apps manager, the per game
#  settings, the temporary files and the measurement of the PROVE IT panel.
#
#  The slow parts of these features (the DNS benchmark and the speed test
#  need the internet) are done by the background copy of SIGAME, so the
#  window never waits for them.

function Test-SIHasCommand {
    <#
    .SYNOPSIS
        $true when this computer has the command.

    .DESCRIPTION
        Asking for a command that is not there loads its module, and that is
        not free on a slow machine. The answer is kept in the cache, so the
        question is asked only once.
    #>
    param([Parameter(Mandatory = $true)][string]$Name)

    return [bool](Get-SICachedValue -Key ('Command:' + $Name) -Producer {
        $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
        return [bool]$command
    })
}

function Get-SIKeyValues {
    <#
    .SYNOPSIS
        All the values of one registry key, with their content.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $result = @()
    try {
        $target = ConvertTo-SIRegistryTarget -Path $Path
        $key = $target.Hive.OpenSubKey($target.Sub, $false)
        if ($key) {
            try {
                foreach ($name in $key.GetValueNames()) {
                    $value = $key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                    $result += [pscustomobject]@{ Name = $name; Value = $value }
                }
            } finally { $key.Close() }
        }
    } catch { }
    return $result
}

function Get-SINetworkAdapter {
    <#
    .SYNOPSIS
        The adapter that has the default route, with its DNS servers.

    .DESCRIPTION
        The index of the adapter, its name, its GUID and the DNS servers it
        uses right now. The list of servers is empty when the adapter gets
        them from the DHCP server of the network.
    #>
    $index = 0
    $alias = ''
    $guid = ''
    $servers = @()

    if (Test-SIHasCommand 'Get-NetRoute') {
        try {
            $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop |
                Sort-Object -Property RouteMetric | Select-Object -First 1
            if ($route) { $index = [int]$route.InterfaceIndex }
        } catch { $index = 0 }
    }
    if ($index -le 0) {
        return @{ Index = 0; Alias = ''; Guid = ''; Servers = @() }
    }

    if (Test-SIHasCommand 'Get-NetAdapter') {
        try {
            $adapter = Get-NetAdapter -InterfaceIndex $index -ErrorAction Stop | Select-Object -First 1
            if ($adapter) {
                $alias = [string]$adapter.Name
                $guid = [string]$adapter.InterfaceGuid
            }
        } catch { }
    }
    if (Test-SIHasCommand 'Get-DnsClientServerAddress') {
        try {
            $address = Get-DnsClientServerAddress -InterfaceIndex $index -AddressFamily IPv4 -ErrorAction Stop |
                Select-Object -First 1
            if ($address) { $servers = @($address.ServerAddresses) }
        } catch { }
    }
    return @{ Index = $index; Alias = $alias; Guid = $guid; Servers = $servers }
}

function Get-SIDnsState {
    <#
    .SYNOPSIS
        The DNS of the active adapter and where it comes from.

    .DESCRIPTION
        A DNS that was set by hand is written in the registry of the adapter
        (the value NameServer). A DNS that comes from the DHCP server of the
        network is not written there. That is how the two are told apart, and
        that is what the undo needs: a hand-made list goes back as it was, a
        DHCP DNS goes back to the DHCP server.
    #>
    $adapter = Get-SINetworkAdapter
    $dhcp = $true
    $saved = @()
    if ($adapter.Guid) {
        $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\' + $adapter.Guid
        $value = Get-SIRegistryValue -Path $path -Name 'NameServer'
        if ($value.Exists) {
            $text = [string]$value.Value
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $dhcp = $false
                foreach ($part in ($text -split ',')) {
                    $clean = $part.Trim()
                    if ($clean) { $saved += $clean }
                }
            }
        }
    }
    return @{
        Index   = $adapter.Index
        Alias   = $adapter.Alias
        Servers = $adapter.Servers
        Dhcp    = $dhcp
        Saved   = $saved
    }
}

function Measure-SIDnsServer {
    <#
    .SYNOPSIS
        The average answer time of one DNS server, in milliseconds.

    .DESCRIPTION
        Five common names are asked three times. The hosts file is not used
        and only the DNS server is asked, so the number is the real answer
        time of that server. A server that does not answer is given up on
        after a few seconds, so the whole test never hangs.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [string[]]$Domains = @('www.microsoft.com', 'www.google.com', 'www.cloudflare.com', 'github.com', 'www.youtube.com'),
        [int]$Rounds = 3
    )

    if (-not (Test-SIHasCommand 'Resolve-DnsName')) { return -1 }

    $times = @()
    $watch = [System.Diagnostics.Stopwatch]::new()
    foreach ($round in 1..$Rounds) {
        foreach ($domain in $Domains) {
            if ($watch.Elapsed.TotalSeconds -gt 12) { break }
            $watch.Restart()
            try {
                $null = Resolve-DnsName -Name $domain -Server $Server -NoHostsFile -DnsOnly -QuickTimeout -ErrorAction Stop
                $watch.Stop()
                $times += $watch.Elapsed.TotalMilliseconds
            } catch {
                $watch.Stop()
            }
        }
        if ($watch.Elapsed.TotalSeconds -gt 12) { break }
    }
    if ($times.Count -eq 0) { return -1 }
    $average = ($times | Measure-Object -Average).Average
    return [math]::Round($average, 1)
}

function Invoke-SIDnsBenchmark {
    <#
    .SYNOPSIS
        Measures the current DNS and the three public ones.

    .DESCRIPTION
        This needs the internet and it can take a while, so it runs in the
        background copy of SIGAME.
    #>
    $state = Get-SIDnsState
    $servers = @()
    foreach ($server in @($state.Servers)) {
        if ($server) { $servers += [pscustomobject]@{ Name = 'Your DNS'; Server = [string]$server; IsCurrent = $true } }
    }
    $servers += [pscustomobject]@{ Name = 'Cloudflare'; Server = '1.1.1.1'; IsCurrent = $false }
    $servers += [pscustomobject]@{ Name = 'Google'; Server = '8.8.8.8'; IsCurrent = $false }
    $servers += [pscustomobject]@{ Name = 'Quad9'; Server = '9.9.9.9'; IsCurrent = $false }

    $results = @()
    foreach ($entry in $servers) {
        $ms = Measure-SIDnsServer -Server $entry.Server
        $results += [pscustomobject]@{
            Name      = $entry.Name
            Server    = $entry.Server
            Ms        = $ms
            IsCurrent = $entry.IsCurrent
        }
    }
    return $results
}

function Invoke-SISpeedTest {
    <#
    .SYNOPSIS
        Downloads a test file and says how fast the internet is, in Mbps.

    .DESCRIPTION
        25 MB are downloaded from Cloudflare and the time is measured. The
        file is counted in memory and never written on the disk. This never
        runs by itself: the user has to ask for it.
    #>
    $url = 'https://speed.cloudflare.com/__down?bytes=25000000'

    # Windows PowerShell 5.1 can still ask for the old TLS versions. The
    # test file is served with TLS 1.2 or newer.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch { }

    $request = [System.Net.HttpWebRequest]::Create($url)
    $request.Timeout = 20000
    $request.ReadWriteTimeout = 30000
    $request.UserAgent = 'SIGAME'
    $request.Proxy = [System.Net.WebRequest]::DefaultWebProxy
    if ($request.Proxy) { $request.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials }

    $response = $request.GetResponse()
    try {
        $stream = $response.GetResponseStream()
        $buffer = New-Object byte[] 65536
        $total = 0
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        while ($true) {
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) { break }
            $total += $read
        }
        $watch.Stop()
        $seconds = $watch.Elapsed.TotalSeconds
        if ($seconds -le 0) { $seconds = 0.001 }
        $mbps = [math]::Round((($total * 8) / 1000000) / $seconds, 2)
        return @{
            Mbps    = $mbps
            Bytes   = $total
            Seconds = [math]::Round($seconds, 2)
            At      = (Get-Date).ToString('s')
        }
    } finally {
        $response.Close()
    }
}

function Get-SIStartupApprovedState {
    <#
    .SYNOPSIS
        $true when a startup program is switched on.

    .DESCRIPTION
        Windows keeps the on/off state of the startup programs as a small
        binary value: 02 means on, 03 means off. A program that is not in
        that list starts with Windows, so it is on.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    try {
        $value = Get-SIRegistryValue -Path $Path -Name $Name
        if (-not $value.Exists) { return $true }
        $bytes = $value.Value
        if ($bytes -isnot [byte[]]) { return $true }
        if ($bytes.Length -eq 0) { return $true }
        $state = [int]$bytes[0]
        if ($state -eq 3 -or $state -eq 7) { return $false }
        return $true
    } catch {
        return $true
    }
}

function Get-SIStartupApps {
    <#
    .SYNOPSIS
        The programs that start with Windows, with their on/off state.

    .DESCRIPTION
        The same places that the Task Manager of Windows uses: the three Run
        keys and the two Startup folders. The on/off state is read from the
        StartupApproved keys, where Windows keeps it.

        Nothing is ever deleted here. A program is only switched off, and
        the Undo puts it back the way it was.
    #>
    $apps = @()

    $runKeys = @(
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'; Kind = 'Run key' }
        @{ Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'; Approved = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'; Kind = 'Run key' }
        @{ Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Approved = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'; Kind = 'Run key' }
    )

    foreach ($key in $runKeys) {
        # The path goes through Get-SIUserRegistryPath, like the path of the
        # on/off state below. Without it, HKCU is the hive of the account
        # that was elevated, and the list would show the programs of the
        # administrator with the on/off state of the person at the machine.
        foreach ($entry in (Get-SIKeyValues -Path (Get-SIUserRegistryPath $key.Path))) {
            $approvedPath = Get-SIUserRegistryPath $key.Approved
            $approved = Get-SIStartupApprovedState -Path $approvedPath -Name $entry.Name
            $apps += [pscustomobject]@{
                Id           = ($key.Kind + '|' + $entry.Name)
                Name         = $entry.Name
                Command      = [string]$entry.Value
                Kind         = $key.Kind
                Enabled      = $approved
                ApprovedPath = $approvedPath
                ApprovedName = $entry.Name
            }
        }
    }

    # The two startup folders. The paths are built inside a try: when an
    # environment variable is empty, Join-Path throws and the whole list of
    # the startup programs would be lost.
    $folders = @()
    try {
        if ($env:APPDATA) {
            $folders += @{ Path = (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'); Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'; Kind = 'Startup folder' }
        }
    } catch { }
    try {
        if ($env:ProgramData) {
            $folders += @{ Path = (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Startup'); Approved = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'; Kind = 'Startup folder' }
        }
    } catch { }
    foreach ($folder in $folders) {
        if (-not $folder.Path) { continue }
        if (-not (Test-Path -LiteralPath $folder.Path)) { continue }
        $items = @()
        try { $items = @(Get-ChildItem -LiteralPath $folder.Path -File -Force -ErrorAction Stop) } catch { }
        foreach ($item in $items) {
            $approvedPath = Get-SIUserRegistryPath $folder.Approved
            $approved = Get-SIStartupApprovedState -Path $approvedPath -Name $item.Name
            $apps += [pscustomobject]@{
                Id           = ('Startup folder|' + $item.Name)
                Name         = $item.Name
                Command      = $item.FullName
                Kind         = $folder.Kind
                Enabled      = $approved
                ApprovedPath = $approvedPath
                ApprovedName = $item.Name
            }
        }
    }

    return $apps
}

function Set-SIStartupAppState {
    <#
    .SYNOPSIS
        Switches one startup program on or off.

    .DESCRIPTION
        The state is written in the StartupApproved key, the same place where
        the Task Manager of Windows keeps it. The program itself is not
        touched and not deleted.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ApprovedPath,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][bool]$Enabled
    )

    # Windows 10 writes twelve bytes here: the first one is the state
    # (02 = on, 03 = off) and the rest is the time of the change.
    $bytes = [byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    if (-not $Enabled) { $bytes = [byte[]](3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) }
    Set-SIRegistryValue -Path $ApprovedPath -Name $Name -Value $bytes -Type 'Binary' | Out-Null
}

function Get-SIGameSettings {
    <#
    .SYNOPSIS
        The games that already have a GPU or a fullscreen setting.
    #>
    $result = @()
    $gpuPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    $layerPath = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'

    foreach ($entry in (Get-SIKeyValues -Path $gpuPath)) {
        $result += [pscustomobject]@{
            Path = $entry.Name
            Kind = 'GPU preference'
            Value = [string]$entry.Value
        }
    }
    foreach ($entry in (Get-SIKeyValues -Path $layerPath)) {
        $result += [pscustomobject]@{
            Path = $entry.Name
            Kind = 'Fullscreen optimizations'
            Value = [string]$entry.Value
        }
    }
    return $result
}

function Set-SIGameGpuPreference {
    <#
    .SYNOPSIS
        Tells Windows to use the fast video card for one game.

    .DESCRIPTION
        This writes exactly the value that the page
        "Settings > Graphics > High performance" writes, so the game behaves
        the same as when it is switched there by hand.
    #>
    param([Parameter(Mandatory = $true)][string]$ExePath)

    $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    Set-SIRegistryValue -Path $path -Name $ExePath -Value 'GpuPreference=2;' -Type 'String' | Out-Null
}

function Set-SIGameFullscreenOptimizations {
    <#
    .SYNOPSIS
        Switches the fullscreen optimizations off for one game.

    .DESCRIPTION
        This is the same value as the box "Disable fullscreen optimizations"
        of the Compatibility tab of the game.
    #>
    param([Parameter(Mandatory = $true)][string]$ExePath)

    $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    Set-SIRegistryValue -Path $path -Name $ExePath -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type 'String' | Out-Null
}

function Get-SITempFolders {
    <#
    .SYNOPSIS
        The folders with the temporary files of Windows.
    #>
    $folders = @()
    if ($env:TEMP) { $folders += $env:TEMP }
    if ($env:SystemRoot) { $folders += (Join-Path $env:SystemRoot 'Temp') }
    $list = @()
    foreach ($folder in $folders) {
        if (-not $folder) { continue }
        if (Test-Path -LiteralPath $folder) { $list += $folder }
    }
    return $list
}

function Get-SITempFilesSize {
    <#
    .SYNOPSIS
        How much space the temporary files take.

    .DESCRIPTION
        The files are counted first and the user is asked afterwards, so
        that nothing is deleted without the user knowing how much is freed.
    #>
    $bytes = 0
    $files = 0
    $folders = Get-SITempFolders
    foreach ($folder in $folders) {
        $items = @()
        try { $items = @(Get-ChildItem -LiteralPath $folder -Recurse -File -Force -ErrorAction SilentlyContinue) } catch { }
        foreach ($item in $items) {
            $bytes += [long]$item.Length
            $files++
        }
    }
    return @{ Bytes = $bytes; Files = $files; Folders = $folders }
}

function Remove-SITempFiles {
    <#
    .SYNOPSIS
        Deletes the temporary files.

    .DESCRIPTION
        The files that are in use cannot be deleted and are left alone. This
        cannot be undone, so the user is asked first.
    #>
    $removed = 0
    $failed = 0
    $bytes = 0
    foreach ($folder in (Get-SITempFolders)) {
        $items = @()
        try { $items = @(Get-ChildItem -LiteralPath $folder -Recurse -File -Force -ErrorAction SilentlyContinue) } catch { }
        foreach ($item in $items) {
            try {
                $size = [long]$item.Length
                Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
                $removed++
                $bytes += $size
            } catch {
                $failed++
            }
        }
    }
    return @{ Removed = $removed; Failed = $failed; Bytes = $bytes }
}

function Get-SIFreeRamMB {
    <#
    .SYNOPSIS
        The free memory of the machine, in MB.

    .DESCRIPTION
        The .NET way is fast, the WMI way is slow. The fast one is tried
        first and the slow one is the fallback.
    #>
    try {
        if (-not $script:SIVisualBasicLoaded) {
            try {
                Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
                $script:SIComputerInfo = [Microsoft.VisualBasic.Devices.ComputerInfo]::new()
                $script:SIVisualBasicLoaded = $true
            } catch { $script:SIVisualBasicLoaded = $false }
        }
        if ($script:SIVisualBasicLoaded -and $script:SIComputerInfo) {
            return [int][math]::Round($script:SIComputerInfo.AvailablePhysicalMemory / 1MB)
        }
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        return [int][math]::Round(([double]$os.FreePhysicalMemory * 1024) / 1MB)
    } catch {
        return -1
    }
}

function Get-SIStartupAppsOnCount {
    <#
    .SYNOPSIS
        How many startup programs are switched on.
    #>
    try {
        $count = 0
        foreach ($app in (Get-SIStartupApps)) {
            if ($app.Enabled) { $count++ }
        }
        return $count
    } catch {
        return -1
    }
}

function Get-SIShortPowerPlan {
    <#
    .SYNOPSIS
        The name of the power plan that is used right now.
    #>
    try {
        $reg = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme'
        if ($reg.Exists -and $reg.Value) {
            $guid = [string]$reg.Value
            if ($guid -ieq '381b4222-f694-41f0-9685-ff5bb260df2e') { return 'Balanced' }
            if ($guid -ieq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') { return 'High performance' }
            if ($guid -ieq 'a1841308-3541-4fab-bc81-f71556f20b4a') { return 'Power saver' }
            if ($guid -ieq 'e9a42b02-d5df-448d-aa00-03f14749eb61') { return 'Ultimate Performance' }
        }
        $text = (powercfg /getactivescheme 2>$null) -join "`n"
        $match = [regex]::Match($text, '\(([^)]+)\)')
        if ($match.Success) { return $match.Groups[1].Value }
    } catch { }
    return 'unknown'
}

function Get-SIHagsState {
    <#
    .SYNOPSIS
        "ON" or "OFF": the hardware GPU scheduling.
    #>
    $value = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode'
    if ($value.Exists -and [int]$value.Value -eq 1) { return 'ON' }
    return 'OFF'
}

function Get-SIGameModeState {
    <#
    .SYNOPSIS
        "ON" or "OFF": the Game Mode.
    #>
    $value = Get-SIRegistryValue -Path (Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\GameBar') -Name 'AutoGameModeEnabled'
    if ($value.Exists -and [int]$value.Value -eq 1) { return 'ON' }
    return 'OFF'
}

function Get-SIVbsState {
    <#
    .SYNOPSIS
        "ON" or "OFF": the virtualisation based security.
    #>
    $value = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity'
    if ($value.Exists -and [int]$value.Value -eq 1) { return 'ON' }
    return 'OFF'
}

function Get-SITcpAutoTuningLevel {
    <#
    .SYNOPSIS
        The TCP receive window auto-tuning level of Windows, or '' when it
        cannot be read.
    #>
    if (-not (Test-SIHasCommand 'Get-NetTCPSetting')) { return '' }
    try {
        $setting = Get-NetTCPSetting -SettingName Internet -ErrorAction Stop | Select-Object -First 1
        if (-not $setting) { return '' }
        $level = [string]$setting.AutoTuningLevelLocal
        if ([string]::IsNullOrWhiteSpace($level)) { $level = [string]$setting.AutoTuningLevel }
        return $level
    } catch {
        return ''
    }
}

function Get-SIIsLaptop {
    <#
    .SYNOPSIS
        $true when this machine looks like a laptop.

    .DESCRIPTION
        The answer of the background copy of SIGAME is used when it is
        there. Otherwise the question is asked once and then remembered.
    #>
    if ($null -ne $script:SIIsLaptop) { return [bool]$script:SIIsLaptop }
    $value = Get-SICachedValue -Key 'Laptop' -Producer { Test-SILaptop }
    $script:SIIsLaptop = [bool]$value
    return [bool]$value
}

function Get-SIHiberFileSize {
    <#
    .SYNOPSIS
        The size of the hibernation file, in bytes. 0 when there is none.
    #>
    try {
        $path = Join-Path $env:SystemDrive 'hiberfil.sys'
        $info = New-Object System.IO.FileInfo($path)
        if ($info.Exists) { return [long]$info.Length }
    } catch { }
    return [long]0
}

function Measure-SIDnsQuickMs {
    <#
    .SYNOPSIS
        The answer time of the DNS that is used right now, in milliseconds.

    .DESCRIPTION
        Uses .NET Dns resolution first so the UI thread never blocks for 2s
        importing the DnsClient CIM module on startup.
    #>
    try {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        $null = [System.Net.Dns]::GetHostAddresses('www.microsoft.com')
        $watch.Stop()
        return [math]::Round($watch.Elapsed.TotalMilliseconds, 1)
    } catch {
        return -1
    }
}

function Measure-SISystem {
    <#
    .SYNOPSIS
        The numbers of the PROVE IT panel.

    .DESCRIPTION
        The free memory, the number of startup programs that are on, the
        answer time of the DNS, the last speed test, the power plan and the
        state of the hardware GPU scheduling, the Game Mode and the virtual
        based security.

        The numbers are the same before and after the OPTIMIZE, so that they
        can be shown in two columns.

        With -QuickDns the DNS is measured right now, with one short
        question. Without it the number of the last DNS test is used, because
        the speed test never runs by itself.
    #>
    param([switch]$QuickDns)

    $dns = $script:SILastDnsMs
    if ($QuickDns) { $dns = Measure-SIDnsQuickMs }

    $measures = @{
        FreeRamMB     = Get-SIFreeRamMB
        StartupAppsOn = Get-SIStartupAppsOnCount
        DnsMs         = $dns
        SpeedMbps     = $script:SILastSpeedMbps
        PowerPlan     = Get-SIShortPowerPlan
        Hags          = Get-SIHagsState
        GameMode      = Get-SIGameModeState
        Vbs           = Get-SIVbsState
        At            = (Get-Date).ToString('s')
    }
    return $measures
}

function Get-SIMeasures {
    <#
    .SYNOPSIS
        The measurements of the last run, read from the JSON file.
    #>
    $empty = @{ Before = $null; After = $null; Updated = '' }
    if (-not [System.IO.File]::Exists($script:SIMeasuresPath)) { return $empty }
    try {
        $raw = [System.IO.File]::ReadAllText($script:SIMeasuresPath, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { return $empty }
        $raw = $raw.TrimStart([char]0xFEFF)
        $parsed = ConvertFrom-Json $raw
        if (-not $parsed) { return $empty }
        $data = ConvertTo-SIPlain $parsed
        $before = $null
        $after = $null
        if ($data.Contains('Before') -and $data['Before']) { $before = $data['Before'] }
        if ($data.Contains('After') -and $data['After']) { $after = $data['After'] }
        $updated = ''
        if ($data.Contains('Updated')) { $updated = [string]$data['Updated'] }
        return @{ Before = $before; After = $after; Updated = $updated }
    } catch {
        return $empty
    }
}

function Save-SIMeasures {
    <#
    .SYNOPSIS
        Writes the measurements of the PROVE IT panel in the JSON file.
    #>
    param($Before, $After)

    $data = @{
        Script  = 'SIGAME'
        Updated = (Get-Date).ToString('s')
        Before  = $Before
        After   = $After
    }
    try {
        $json = $data | ConvertTo-Json -Depth 8
        [System.IO.File]::WriteAllText($script:SIMeasuresPath, $json, [System.Text.Encoding]::UTF8)
        return $true
    } catch {
        Write-SILog -Level 'WARN' -Component 'Backup' -Message "The measurements could not be written: $($_.Exception.Message)"
        return $false
    }
}

function Get-SIMeasureText {
    <#
    .SYNOPSIS
        The text of one number of the PROVE IT panel.
    #>
    param($Measures, [string]$Key)

    if (-not $Measures) { return '-' }
    if (-not ($Measures.Contains($Key))) { return '-' }
    $value = $Measures[$Key]
    switch ($Key) {
        'FreeRamMB' {
            if ([int]$value -lt 0) { return '-' }
            return ('{0} MB' -f [int]$value)
        }
        'StartupAppsOn' {
            if ([int]$value -lt 0) { return '-' }
            return [string][int]$value
        }
        'DnsMs' {
            if ([double]$value -lt 0) { return '-' }
            return ('{0} ms' -f [math]::Round([double]$value, 1))
        }
        'SpeedMbps' {
            if ([double]$value -lt 0) { return '-' }
            return ('{0} Mbps' -f [math]::Round([double]$value, 1))
        }
        default { return [string]$value }
    }
}

function Update-SIProvePanel {
    <#
    .SYNOPSIS
        Writes the numbers of the PROVE IT panel into the window.
    #>
    $before = $script:SIMeasuresBefore
    $after = $script:SIMeasuresAfter

    $keys = @('FreeRamMB', 'StartupAppsOn', 'DnsMs', 'SpeedMbps')
    foreach ($key in $keys) {
        $beforeText = Get-SIElement -Name ('ProveBefore_' + $key)
        $afterText = Get-SIElement -Name ('ProveAfter_' + $key)
        if ($beforeText) { $beforeText.Text = Get-SIMeasureText -Measures $before -Key $key }
        if ($afterText) { $afterText.Text = Get-SIMeasureText -Measures $after -Key $key }
    }

    $line = Get-SIElement -Name 'ProveLine'
    if ($line) {
        $plan = 'unknown'
        $hags = '-'
        $gameMode = '-'
        $vbs = '-'
        $source = $after
        if (-not $source) { $source = $before }
        if ($source) {
            if ($source.Contains('PowerPlan')) { $plan = [string]$source['PowerPlan'] }
            if ($source.Contains('Hags')) { $hags = [string]$source['Hags'] }
            if ($source.Contains('GameMode')) { $gameMode = [string]$source['GameMode'] }
            if ($source.Contains('Vbs')) { $vbs = [string]$source['Vbs'] }
        }
        $line.Text = ('Power plan: {0}   |   HAGS: {1}   |   Game Mode: {2}   |   VBS: {3}' -f $plan, $hags, $gameMode, $vbs)
    }
}

function Invoke-SIOptimize {
    <#
    .SYNOPSIS
        The big yellow button: every safe tweak of this computer in one go.

    .DESCRIPTION
        The tweaks that are not available on this Windows version are
        skipped, the ones that need a choice (per game, DNS) are not part
        of it, and the number of the ones that were applied and the number
        of the ones that were not available is shown afterwards.

        The PROVE IT measurement is taken before and after, so that the
        window can show the two columns.
    #>
    if (-not $script:SIPrepared) {
        Set-SIStatusText -Text (Get-SIText -Key 'StatusWorking')
        return
    }

    $button = Get-SIElement -Name 'BtnOptimize'
    if ($button) { $button.IsEnabled = $false }
    try {
        Set-SIStatusText -Text (Get-SIText -Key 'StatusMeasuring')
        Invoke-SIUIPump
        $before = Measure-SISystem
        $script:SIMeasuresBefore = $before

        $done = 0
        $skipped = 0
        $failed = 0
        $isLaptop = $script:SIIsLaptop
        if ($null -eq $isLaptop) { $isLaptop = Test-SILaptop }

        # The tweaks that are done in this run, so that the progress bar can
        # show which one is running now.
        $todo = @()
        foreach ($tweak in (Get-SITweakTable)) {
            if (-not ($tweak.Contains('Optimize') -and $tweak.Optimize)) { continue }
            if ($tweak.Contains('ShowOnly') -and $tweak.ShowOnly) { continue }
            $todo += $tweak
        }
        $total = $todo.Count
        $index = 0

        foreach ($tweak in $todo) {
            $index++
            $percent = 0
            if ($total -gt 0) { $percent = [int](($index * 100) / $total) }
            Set-SIProgress -Percent $percent -Step ([string]$tweak.Name)
            if ($tweak.Id -eq 'UltimatePerformance' -and $isLaptop) {
                Write-SILog -Component 'Tweak' -Message 'Ultimate Performance was skipped: this machine looks like a laptop.'
                $skipped++
                continue
            }
            $unavailable = Get-SITweakAvailability -Tweak $tweak
            if ($unavailable) {
                Write-SILog -Component 'Tweak' -Message "$($tweak.Name) was skipped: $unavailable"
                $skipped++
                continue
            }
            # A tweak with a choice gets the gaming choice, so that the
            # OPTIMIZE button always does the same thing.
            if ($tweak.Contains('GamingOption') -and $tweak.GamingOption) {
                $script:SIOptionOverride[$tweak.Id] = [string]$tweak.GamingOption
                if ($script:SIRows.ContainsKey($tweak.Id)) {
                    $combo = $script:SIRows[$tweak.Id].Combo
                    if ($combo) {
                        # A different name than the counter of the loop: the
                        # counter is the one that moves the progress bar.
                        $choiceIndex = $combo.Items.IndexOf([string]$tweak.GamingOption)
                        if ($choiceIndex -ge 0) { $combo.SelectedIndex = $choiceIndex }
                    }
                }
            }
            Invoke-SIApplyTweak -TweakId $tweak.Id
            if ($script:SILastApplyStatus -eq 'applied') { $done++ }
            elseif ($script:SILastApplyStatus -eq 'notavailable') { $skipped++ }
            else { $failed++ }
            Invoke-SIUIPump
        }
        # The options of the table are only for the OPTIMIZE button. The rows
        # show what they show, and the Apply checked button uses them.
        $script:SIOptionOverride = @{}

        Set-SIStatusText -Text (Get-SIText -Key 'StatusMeasuring')
        Invoke-SIUIPump
        $after = Measure-SISystem
        $script:SIMeasuresAfter = $after
        Save-SIMeasures -Before $before -After $after | Out-Null
        Update-SIProvePanel

        $text = ('{0} done, {1} not available' -f $done, $skipped)
        if ($failed -gt 0) { $text = ('{0} done, {1} not available, {2} failed' -f $done, $skipped, $failed) }
        $result = Get-SIElement -Name 'OptimizeResult'
        if ($result) { $result.Text = $text }
        Set-SIStatusText -Text ("OPTIMIZE done: $text")
        Set-SIProgress -Percent 100 -Done
        Write-SILog -Level 'OK' -Component 'Tweak' -Message "OPTIMIZE: $text"

        # The rows show the new states.
        Update-SIStates
    } finally {
        if ($button) { $button.IsEnabled = $true }
    }
}


