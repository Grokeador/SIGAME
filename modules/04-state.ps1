# ---------------------------------------------------------------------------
#  SIGAME - module 04: reading the real current state
#
#  Nothing in SIGAME assumes a state. Every row asks the registry and the
#  service list what is actually there right now.
# ---------------------------------------------------------------------------
# ======================= 7. READING THE REAL CURRENT STATE =================
#
#  Nothing in SIGAME assumes a state. Every row asks the registry and the
#  service list what is actually there right now.

function Get-SIEntryRemove {
    <#
    .SYNOPSIS
        True when the wanted state of a registry entry is "the value must not
        be there". Written with ContainsKey because a hashtable also has a
        Remove() method, and $entry.Remove would return that method.
    #>
    param($Entry)
    if ($Entry.ContainsKey('Remove')) { return [bool]$Entry['Remove'] }
    return $false
}

function Get-SIEntryValue {
    param($Entry)
    if ($Entry.ContainsKey('Value')) { return $Entry['Value'] }
    return $null
}

function Get-SITweakOption {
    <#
    .SYNOPSIS
        The option the user picked in the row's combo box, if there is one.

    .PARAMETER OptionOverride
        Used by the background copy of SIGAME, which has no window and no
        combo box. It gets the option from the request file instead.
    #>
    param($Tweak, [string]$OptionOverride)

    if ($OptionOverride) { return $OptionOverride }
    # The OPTIMIZE button uses the gaming option of a tweak, also when the
    # row of that tweak is not on the screen (the Advanced section can be
    # closed).
    if ($script:SIOptionOverride -and $script:SIOptionOverride.ContainsKey($Tweak.Id)) {
        return [string]$script:SIOptionOverride[$Tweak.Id]
    }
    if ($script:SIRows.ContainsKey($Tweak.Id)) {
        $combo = $script:SIRows[$Tweak.Id].Combo
        if ($combo -and $combo.SelectedItem) { return [string]$combo.SelectedItem }
    }
    if ($Tweak.Contains('Options') -and $Tweak.Options) { return [string]$Tweak.Options[0] }
    return $null
}

function Get-SITweakRegistryEntries {
    <#
    .SYNOPSIS
        The registry entries a tweak wants right now, depending on the option
        the user picked.
    #>
    param($Tweak, [string]$OptionOverride)

    $option = Get-SITweakOption -Tweak $Tweak -OptionOverride $OptionOverride
    if ($Tweak.Contains('RegistryScript') -and $Tweak.RegistryScript) {
        return @(& $Tweak.RegistryScript $option)
    }
    if ($Tweak.Contains('Registry') -and $Tweak.Registry) {
        return @($Tweak.Registry)
    }
    return @()
}

function Get-SITweakAvailability {
    <#
    .SYNOPSIS
        '' when the tweak can work on this machine, otherwise the reason why
        it cannot.

    .DESCRIPTION
        A tweak that cannot work on this Windows version must never be
        applied: it would only produce an error and a half applied change.
        The tweak table says with "AvailabilityScript" when a tweak is not
        available, and this function runs that check.

        The check has to be CHEAP, because it is done while the window is
        painted. Anything slow (an AppX query, a WMI call) belongs into the
        StateScript, which the background copy of SIGAME runs.
    #>
    param($Tweak, [string]$OptionOverride)

    if (-not $Tweak) { return '' }
    if (-not ($Tweak.Contains('AvailabilityScript') -and $Tweak.AvailabilityScript)) { return '' }

    $option = Get-SITweakOption -Tweak $Tweak -OptionOverride $OptionOverride
    try {
        $reason = [string](& $Tweak.AvailabilityScript $option)
        return $reason
    } catch {
        return "the availability of this tweak could not be checked: $($_.Exception.Message)"
    }
}

function Test-SIRegistryWritable {
    <#
    .SYNOPSIS
        $true when SIGAME is allowed to write in that registry key.

    .DESCRIPTION
        Some keys of Windows are closed to the program (a protected key of
        the system, a key of another user, ...). Writing in them fails with
        "unauthorized operation". The key is opened for writing BEFORE the
        first change, so that a tweak that cannot work here is reported as
        "not available" instead of failing half way through.
        If the key does not exist yet ($null), returns $true so CreateSubKey
        can create it during Apply.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $target = ConvertTo-SIRegistryTarget -Path $Path
        $key = $target.Hive.OpenSubKey($target.Sub, $true)
        if ($key) {
            $key.Close()
        }
        return $true
    } catch {
        return $false
    }
}

function Get-SIRegistrySnapshot {
    <#
    .SYNOPSIS
        The CURRENT values of a list of registry entries.

    .DESCRIPTION
        This is the safety net of an Apply: if one value of a tweak cannot
        be written, the values that were already written are put back with
        these records, so that a tweak is never half applied.
    #>
    param($Entries)

    $records = @()
    foreach ($item in @($Entries)) {
        if (-not $item) { continue }
        $path = Get-SIUserRegistryPath $item.Path
        $current = Get-SIRegistryValue -Path $path -Name $item.Name
        $records += @{
            Path    = $path
            Name    = $item.Name
            Existed = [bool]$current.Exists
            Value   = $current.Value
            Kind    = [string]$current.Kind
        }
    }
    return $records
}

function Restore-SIRegistryRecord {
    <#
    .SYNOPSIS
        Puts one registry value back the way a record says it was.

    .OUTPUTS
        $true when the value was put back, $false when that was not allowed.
    #>
    param($Record)

    if (-not $Record) { return $false }
    $path = [string]$Record['Path']
    $name = [string]$Record['Name']
    try {
        if ($Record['Existed']) {
            $type = ConvertTo-SIKind $Record['Kind']
            if (-not $type) { $type = 'String' }
            Set-SIRegistryValue -Path $path -Name $name -Value $Record['Value'] -Type $type | Out-Null
        } else {
            Remove-SIRegistryValue -Path $path -Name $name | Out-Null
        }
        return $true
    } catch {
        return $false
    }
}

function Restore-SIRegistryWrites {
    <#
    .SYNOPSIS
        Puts a list of registry values back the way they were.

    .DESCRIPTION
        Used when an Apply could not be finished: the values that were
        already written are put back, so that the tweak is not left half
        applied.

    .PARAMETER Records
        The snapshot of the values, made by Get-SIRegistrySnapshot.

    .PARAMETER WrittenKeys
        The keys that were really written ("path|name"). Only those are put
        back, so that a value that was never changed stays as it was.
    #>
    param($Records, $WrittenKeys)

    $count = 0
    foreach ($record in @($Records)) {
        if (-not $record) { continue }
        $key = ([string]$record['Path']) + '|' + ([string]$record['Name'])
        if ($WrittenKeys -and ($WrittenKeys -notcontains $key)) { continue }
        if (Restore-SIRegistryRecord -Record $record) {
            $count++
            Write-SILog -Component 'Registry' -Message "Put back $([string]$record['Path'])\$([string]$record['Name']) (the tweak was not applied completely)"
        }
    }
    return $count
}

function Get-SITweakState {
    <#
    .SYNOPSIS
        Reads the current state of one tweak.

    .PARAMETER OptionOverride
        The option to use, when there is no window to ask (background copy).

    .OUTPUTS
        @{ Status = 'Applied' | 'Partial' | 'NotApplied'; Text = '...'; Details = '...' }
    #>
    param($Tweak, [string]$OptionOverride)

    $option = Get-SITweakOption -Tweak $Tweak -OptionOverride $OptionOverride

    # A tweak that cannot work on this Windows version is not "off", it is
    # "not available". Nothing is changed for it, so it can never fail.
    $unavailable = Get-SITweakAvailability -Tweak $Tweak -OptionOverride $option
    if ($unavailable) {
        return @{ Status = 'NotAvailable'; Text = "Not available: $unavailable"; Details = $unavailable }
    }

    if ($Tweak.Contains('StateScript') -and $Tweak.StateScript) {
        $custom = & $Tweak.StateScript $option
        if ($custom -is [System.Collections.IDictionary]) {
            $details = ''
            if ($custom.Contains('Details')) { $details = [string]$custom['Details'] }
            return @{ Status = [string]$custom['Status']; Text = [string]$custom['Text']; Details = $details }
        }
        return @{ Status = 'NotApplied'; Text = 'state unknown'; Details = '' }
    }

    $total = 0
    $match = 0
    $details = @()

    foreach ($entry in (Get-SITweakRegistryEntries -Tweak $Tweak -OptionOverride $option)) {
        $total++
        $path = Get-SIUserRegistryPath $entry.Path
        $current = Get-SIRegistryValue -Path $path -Name $entry.Name
        $shown = if ($current.Exists) { [string]$current.Value } else { '(not set)' }
        $details += ('{0} = {1}' -f $entry.Name, $shown)

        if (Get-SIEntryRemove $entry) {
            if (-not $current.Exists) { $match++ }
        } elseif ($current.Exists -and (Test-SIValueEqual $current.Value (Get-SIEntryValue $entry))) {
            $match++
        }
    }

    if ($Tweak.Contains('Services') -and $Tweak.Services) {
        foreach ($service in $Tweak.Services) {
            $optional = ($service.Contains('Optional') -and $service.Optional)
            $state = Get-SIServiceState -Name $service.Name

            # A service that does not exist on this Windows version is not a
            # failure, it simply is not there. A service that is optional
            # (Windows manages it itself) is not counted either: the tweak is
            # complete without it.
            if (-not $state.Exists) {
                $details += ('{0} = (not on this Windows version)' -f $service.Name)
                continue
            }
            if ($optional) {
                $details += ('{0} = {1} (managed by Windows, not switched by SIGAME)' -f $service.Name, $state.StartType)
                continue
            }

            $total++
            $details += ('{0} = {1}' -f $service.Name, $state.StartType)
            if ($state.StartType -eq $service.StartupType) { $match++ }
        }
    }

    if ($total -eq 0) {
        return @{ Status = 'NotApplied'; Text = 'no state to read'; Details = '' }
    }

    if ($match -eq $total) {
        return @{ Status = 'Applied'; Text = [string]$Tweak.OnText; Details = ($details -join ' | ') }
    }
    if ($match -eq 0) {
        return @{ Status = 'NotApplied'; Text = [string]$Tweak.OffText; Details = ($details -join ' | ') }
    }
    $text = 'Partly applied ({0} of {1})' -f $match, $total
    if ($Tweak.Contains('PartialText') -and $Tweak.PartialText) { $text = [string]$Tweak.PartialText }
    return @{ Status = 'Partial'; Text = $text; Details = ($details -join ' | ') }
}

