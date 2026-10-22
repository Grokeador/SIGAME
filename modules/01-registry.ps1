# ---------------------------------------------------------------------------
#  SIGAME - module 01: the registry, the services and the JSON backup
#
#  The registry is read and written through the .NET API, so that the type of
#  a value is always the type it was read with.
# ---------------------------------------------------------------------------
# =========================== 3. REGISTRY HELPERS ===========================
#
#  The registry is read and written through the .NET API instead of the
#  PowerShell registry provider. Reason: the provider silently keeps the OLD
#  type of a value when you change it, which is exactly the kind of surprise
#  that makes a "restore" wrong. Here the type is always written exactly as
#  it was read.

function ConvertTo-SIRegistryTarget {
    <#
    .SYNOPSIS
        Splits "HKLM:\SOFTWARE\Foo" into the .NET hive and the sub path.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    if ($Path.StartsWith('HKCU:\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return @{ Hive = [Microsoft.Win32.Registry]::CurrentUser; Sub = $Path.Substring(6) }
    }
    elseif ($Path.StartsWith('HKLM:\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; Sub = $Path.Substring(6) }
    }
    elseif ($Path.StartsWith('HKU:\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return @{ Hive = [Microsoft.Win32.Registry]::Users; Sub = $Path.Substring(5) }
    }
    elseif ($Path.StartsWith('HKCR:\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return @{ Hive = [Microsoft.Win32.Registry]::ClassesRoot; Sub = $Path.Substring(6) }
    }
    else {
        throw "SIGAME: unsupported registry path '$Path'."
    }
}

function Get-SIRegistryValue {
    <#
    .SYNOPSIS
        Reads one registry value and reports whether it exists, its raw value
        and its exact type.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $target = ConvertTo-SIRegistryTarget -Path $Path
    $key = $target.Hive.OpenSubKey($target.Sub, $false)
    if ($null -eq $key) {
        return [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }
    }
    try {
        if ($key.GetValueNames() -notcontains $Name) {
            return [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }
        }
        $value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $kind = $key.GetValueKind($Name)
        return [pscustomobject]@{ Exists = $true; Value = $value; Kind = [string]$kind }
    } catch {
        return [pscustomobject]@{ Exists = $false; Value = $null; Kind = $null }
    } finally {
        $key.Close()
    }
}

function Set-SIRegistryValue {
    <#
    .SYNOPSIS
        Writes one registry value with an exact type. Creates the key if needed.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value,
        [ValidateSet('DWord', 'QWord', 'String', 'ExpandString', 'Binary', 'MultiString')][string]$Type = 'DWord'
    )

    $target = ConvertTo-SIRegistryTarget -Path $Path
    $key = $target.Hive.OpenSubKey($target.Sub, $true)
    if ($null -eq $key) {
        $key = $target.Hive.CreateSubKey($target.Sub)
    }
    try {
        switch ($Type) {
            'DWord' {
                $kind = [Microsoft.Win32.RegistryValueKind]::DWord
                # A value like 0xFFFFFFFF does not fit in a signed 32 bit
                # number, but the registry wants the four bytes, so the number
                # is written as it is instead of failing.
                $number = [long]$Value
                if ($number -gt 2147483647 -or $number -lt -2147483648) {
                    $typed = [System.BitConverter]::ToInt32([System.BitConverter]::GetBytes([uint32]$number), 0)
                } else {
                    $typed = [int]$number
                }
            }
            'QWord' {
                $kind = [Microsoft.Win32.RegistryValueKind]::QWord
                $typed = [long]$Value
            }
            'Binary' {
                $kind = [Microsoft.Win32.RegistryValueKind]::Binary
                # The JSON backup keeps binary data as a list of numbers, a string is
                # read as base64 (that is how PowerShell 6 and later write it).
                if ($Value -is [string]) { $typed = [System.Convert]::FromBase64String($Value) }
                else { $typed = [byte[]]$Value }
            }
            'MultiString' {
                $kind = [Microsoft.Win32.RegistryValueKind]::MultiString
                $typed = [string[]]$Value
            }
            'ExpandString' {
                $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
                $typed = [string]$Value
            }
            default {
                $kind = [Microsoft.Win32.RegistryValueKind]::String
                $typed = [string]$Value
            }
        }
        $key.SetValue($Name, $typed, $kind)
    } finally {
        $key.Close()
    }
}

function Remove-SIRegistryValue {
    <#
    .SYNOPSIS
        Deletes one registry value. Missing values are not an error.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $target = ConvertTo-SIRegistryTarget -Path $Path
    $key = $target.Hive.OpenSubKey($target.Sub, $true)
    if ($null -eq $key) { return $false }
    try {
        $key.DeleteValue($Name, $false)
        return $true
    } catch {
        return $false
    } finally {
        $key.Close()
    }
}

function Get-SIUserRegistryPath {
    <#
    .SYNOPSIS
        Maps "HKCU:\..." onto the hive that really belongs to the person
        sitting at the machine.

    .DESCRIPTION
        When SIGAME is elevated with the credentials of a different account
        (standard user -> "over the shoulder" UAC), HKCU would point at the
        administrator. In that case the interactive user's hive is mounted
        under HKU and used instead, so per-user tweaks land on the right
        profile.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    if ($Path -like 'HKCU:\*') {
        return $script:SIUserPrefix + $Path.Substring(5)
    }
    return $Path
}

function Initialize-SIUserHive {
    <#
    .SYNOPSIS
        Works out which user hive the per-user tweaks have to touch.
    #>
    $script:SIUserPrefix = 'HKCU:'
    $script:SIUserSid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value

    try {
        $current = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $console = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
        if ([string]::IsNullOrWhiteSpace($console) -or ($console -ieq $current)) { return }

        $parts = $console -split '\\'
        $userName = $parts[-1]
        $domain = if ($parts.Count -gt 1) { $parts[0] } else { $env:COMPUTERNAME }

        # Only the one account is asked for. Asking for every account on the
        # machine is much slower and this runs while the window is opening.
        $account = Get-CimInstance -ClassName Win32_UserAccount `
            -Filter ("Name='{0}' AND Domain='{1}'" -f $userName, $domain) `
            -ErrorAction Stop | Select-Object -First 1

        if (-not $account -or [string]::IsNullOrWhiteSpace($account.SID)) { return }

        $sid = $account.SID
        if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
            New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction Stop | Out-Null
        }

        if (-not (Test-Path -LiteralPath ("Registry::HKEY_USERS\$sid"))) {
            $ntUser = Join-Path $env:SystemDrive ("Users\{0}\NTUSER.DAT" -f $userName)
            if (Test-Path -LiteralPath $ntUser) {
                & reg.exe load "HKU\$sid" "$ntUser" 2>$null | Out-Null
            }
        }

        if (Test-Path -LiteralPath ("Registry::HKEY_USERS\$sid")) {
            $script:SIUserPrefix = "HKU:\$sid"
            $script:SIUserSid = $sid
            Write-SILog -Level 'WARN' -Component 'User' -Message "Elevated as '$current' but '$console' is the interactive user. Per-user tweaks will use HKU:\$sid."
        }
    } catch {
        Write-SILog -Level 'WARN' -Component 'User' -Message "Could not determine the interactive user hive: $($_.Exception.Message)"
    }
}

function Test-SIValueEqual {
    <#
    .SYNOPSIS
        Compares two registry values, numerically when both look like numbers.
    #>
    param($A, $B)

    if ($null -eq $A -or $null -eq $B) { return ($null -eq $A -and $null -eq $B) }

    # Binary values are compared byte by byte, otherwise every byte array would
    # look the same once it is turned into a string.
    # The cast to byte[] is inside a try: a MultiString is a list of strings,
    # and [byte[]] on a list of strings throws.
    $bytesA = $null
    $bytesB = $null
    if ($A -is [byte[]]) { $bytesA = $A }
    elseif ($A -is [System.Collections.IEnumerable] -and -not ($A -is [string])) {
        try { $bytesA = [byte[]]@($A) } catch { $bytesA = $null }
    }
    if ($B -is [byte[]]) { $bytesB = $B }
    elseif ($B -is [System.Collections.IEnumerable] -and -not ($B -is [string])) {
        try { $bytesB = [byte[]]@($B) } catch { $bytesB = $null }
    }
    if ($bytesA -and $bytesB) {
        if ($bytesA.Length -ne $bytesB.Length) { return $false }
        for ($i = 0; $i -lt $bytesA.Length; $i++) {
            if ($bytesA[$i] -ne $bytesB[$i]) { return $false }
        }
        return $true
    }
    if ($bytesA -or $bytesB) { return $false }

    $na = 0.0
    $nb = 0.0
    if ([double]::TryParse([string]$A, [ref]$na) -and [double]::TryParse([string]$B, [ref]$nb)) {
        return ([math]::Abs($na - $nb) -lt 0.0000001)
    }
    return ([string]$A -eq [string]$B)
}

function ConvertTo-SIKind {
    <#
    .SYNOPSIS
        Maps a .NET registry value kind back to the type names SIGAME uses.
    #>
    param([string]$Kind)

    switch ($Kind) {
        'DWord'           { return 'DWord' }
        'QWord'           { return 'QWord' }
        'String'          { return 'String' }
        'ExpandString'    { return 'ExpandString' }
        'Binary'          { return 'Binary' }
        'MultiString'     { return 'MultiString' }
        default           { return $null }
    }
}

# =========================== 4. SERVICE HELPERS ============================

function Get-SIServiceState {
    <#
    .SYNOPSIS
        Reads the startup type and running state of one service.
    #>
    param([Parameter(Mandatory = $true)][string]$Name)

    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $service) {
        return [pscustomobject]@{ Exists = $false; StartType = $null; Running = $false }
    }
    $running = $false
    try { $running = ($service.Status -eq 'Running') } catch { $running = $false }
    return [pscustomobject]@{ Exists = $true; StartType = [string]$service.StartType; Running = $running }
}

function Set-SIServiceStartType {
    <#
    .SYNOPSIS
        Sets the startup type of one service.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$StartupType
    )

    switch ($StartupType) {
        'Automatic' { Set-Service -Name $Name -StartupType Automatic -ErrorAction Stop }
        'Manual'    { Set-Service -Name $Name -StartupType Manual -ErrorAction Stop }
        'Disabled'  { Set-Service -Name $Name -StartupType Disabled -ErrorAction Stop }
        'AutomaticDelayedStart' {
            & sc.exe config $Name start= delayed-auto | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "sc.exe config $Name failed with exit code $LASTEXITCODE." }
        }
        default { throw "SIGAME: unknown startup type '$StartupType'." }
    }
}

# ============================= 5. JSON BACKUP ==============================

function ConvertTo-SIPlain {
    <#
    .SYNOPSIS
        Turns any parsed JSON into plain hashtables and arrays, so the backup
        can be read the same way whether it was just written or loaded from
        disk.
    #>
    param($InputObject)

    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $InputObject.Keys) { $result[$key] = ConvertTo-SIPlain $InputObject[$key] }
        return $result
    }
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $result = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $result[$property.Name] = ConvertTo-SIPlain $property.Value
        }
        return $result
    }
    if (($InputObject -is [System.Array]) -or
        (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string]))) {
        $list = @()
        foreach ($item in $InputObject) { $list += , (ConvertTo-SIPlain $item) }
        return $list
    }
    return $InputObject
}

function New-SIBackup {
    return @{
        Script       = 'SIGAME'
        Version      = '1.0'
        Created      = (Get-Date).ToString('s')
        ComputerName = $env:COMPUTERNAME
        Tweaks       = @{}
        Tools        = @{}
    }
}

function Get-SIBackup {
    <#
    .SYNOPSIS
        Loads the JSON backup from disk, or returns an empty one.
    #>
    if ([System.IO.File]::Exists($script:SIBackupPath)) {
        try {
            $raw = [System.IO.File]::ReadAllText($script:SIBackupPath, [System.Text.Encoding]::UTF8)
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $raw = $raw.TrimStart([char]0xFEFF)
                $plain = ConvertTo-SIPlain (ConvertFrom-Json $raw)
                if ($plain -is [System.Collections.IDictionary] -and $plain.Contains('Tweaks')) {
                    return $plain
                }
            }
        } catch {
            Write-SILog -Level 'WARN' -Component 'Backup' -Message "Could not read the backup file: $($_.Exception.Message)"
        }
    }
    return (New-SIBackup)
}

function Save-SIBackup {
    <#
    .SYNOPSIS
        Writes the backup to disk. Called BEFORE the change is made, so the
        original values are safe even if the machine is pulled from under us.

    .OUTPUTS
        $true when the file was written, $false when it was not.
    #>
    param([Parameter(Mandatory = $true)]$Backup)

    try {
        $folder = [System.IO.Path]::GetDirectoryName($script:SIBackupPath)
        if ($folder -and -not [System.IO.Directory]::Exists($folder)) {
            [void][System.IO.Directory]::CreateDirectory($folder)
        }
        $json = $Backup | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($script:SIBackupPath, $json, [System.Text.Encoding]::UTF8)
        return $true
    } catch {
        Write-SILog -Level 'ERROR' -Component 'Backup' -Message "Could not write the backup file: $($_.Exception.Message)"
        return $false
    }
}

