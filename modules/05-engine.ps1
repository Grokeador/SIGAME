# ---------------------------------------------------------------------------
#  SIGAME - module 05: the apply / undo engine
#
#  The original value of everything is written to the JSON backup BEFORE the
#  first change, so that every change can be put back exactly.
# ---------------------------------------------------------------------------
# ======================== 8. THE APPLY / UNDO ENGINE =======================

function Get-SIDictionaryFromOutput {
    <#
    .SYNOPSIS
        Picks the hashtable out of the output of a tweak script block, so a
        stray object cannot end up in the JSON backup.
    #>
    param($Output)
    $found = $null
    foreach ($item in @($Output)) {
        if ($item -is [System.Collections.IDictionary]) { $found = $item }
    }
    return $found
}

function New-SIOriginalRecord {
    <#
    .SYNOPSIS
        Reads the CURRENT values of everything one tweak touches.

    .DESCRIPTION
        This is what goes into the JSON backup, so that "Undo" can put the
        machine back exactly as it was. The same record is used when the
        backup of ALL tweaks is written at start-up and when a single tweak
        is applied, so both always agree about what a tweak touches.
    #>
    param($Tweak, [string]$OptionOverride)

    $record = @{
        Registry  = @()
        Services  = @()
        Extra     = @{}
        AppliedAt = (Get-Date).ToString('s')
        Option    = [string]$OptionOverride
    }

    $entries = Get-SITweakRegistryEntries -Tweak $Tweak -OptionOverride $OptionOverride
    foreach ($item in $entries) {
        $path = Get-SIUserRegistryPath $item.Path
        $current = Get-SIRegistryValue -Path $path -Name $item.Name
        $record.Registry += @{
            Path    = $path
            Name    = $item.Name
            Existed = [bool]$current.Exists
            Value   = $current.Value
            Kind    = [string]$current.Kind
        }
    }

    if ($Tweak.Contains('Services') -and $Tweak.Services) {
        foreach ($service in $Tweak.Services) {
            $state = Get-SIServiceState -Name $service.Name
            $record.Services += @{
                Name       = $service.Name
                Existed    = [bool]$state.Exists
                StartType  = $state.StartType
                WasRunning = [bool]$state.Running
            }
        }
    }

    if ($Tweak.Contains('SnapshotScript') -and $Tweak.SnapshotScript) {
        try {
            $snapshot = Get-SIDictionaryFromOutput (& $Tweak.SnapshotScript)
            if ($snapshot) {
                foreach ($key in $snapshot.Keys) { $record.Extra[$key] = $snapshot[$key] }
            }
        } catch {
            Write-SILog -Level 'WARN' -Component 'Backup' -Message "Could not read the extra values of $($Tweak.Name): $($_.Exception.Message)"
        }
    }

    return $record
}

function Invoke-SIApplyTweak {
    <#
    .SYNOPSIS
        Applies one tweak: snapshot the originals, save them, then change the
        system.
    #>
    param([Parameter(Mandatory = $true)][string]$TweakId)

    $tweak = $script:SITweaks[$TweakId]
    if (-not $tweak) { return }
    $script:SILastApplyStatus = 'skipped'
    if ($tweak.Contains('ShowOnly') -and $tweak.ShowOnly) {
        Write-SILog -Level 'WARN' -Component 'Tweak' -Message "$($tweak.Name) is shown for information only, nothing was changed."
        return
    }
    if (-not $script:SIPrepared) {
        # Nothing may be changed before SIGAME has read the real state and
        # tried to make the System Restore point.
        Write-SILog -Level 'WARN' -Component 'Tweak' -Message "$($tweak.Name) was not applied, SIGAME is still starting up."
        Set-SIStatusText -Text 'SIGAME is still starting up, please wait a moment.'
        return
    }

    # --- 0. can this tweak work on this machine at all? --------------------
    # A tweak that does not exist on this Windows version is not applied at
    # all. It is not an error and it does not change half of anything: the
    # row simply says "not available".
    $unavailable = Get-SITweakAvailability -Tweak $tweak
    if ($unavailable) {
        Write-SILog -Component 'Tweak' -Message "$($tweak.Name) is not available on this system: $unavailable Nothing was changed."
        Set-SIStatusText -Text "$($tweak.Name) is not available on this system, nothing was changed."
        $script:SILastApplyStatus = 'notavailable'
        return
    }

    Set-SIStatusText -Text "Applying $($tweak.Name) ..."
    Write-SILog -Component 'Tweak' -Message "Apply: $($tweak.Name)"

    $backup = $script:SIBackup
    # The backup in memory is always there. If the start-up work failed and
    # the file was never read, it is read now, so that a change can never be
    # made without a backup to undo it.
    if (-not $backup) {
        $script:SIBackup = Get-SIBackup
        $backup = $script:SIBackup
    }
    # The option of the row is used for both: what is read and what is
    # changed. That way the backup always matches the change.
    $option = Get-SITweakOption -Tweak $tweak
    $entries = Get-SITweakRegistryEntries -Tweak $tweak -OptionOverride $option

    # --- 1. read the originals -------------------------------------------
    # An entry that is already in the backup holds the values from BEFORE
    # SIGAME touched that tweak. It is kept as long as the option is the
    # same, so that the original value is not lost when a tweak is applied a
    # second time. With another option the entry is read again, because the
    # other option touches other keys.
    $entry = $null
    $isNewEntry = $true
    if ($backup.Tweaks.Contains($tweak.Id)) {
        $known = $backup.Tweaks[$tweak.Id]
        $knownOption = ''
        if ($known -and $known.Contains('Option')) { $knownOption = [string]$known['Option'] }
        if ($knownOption -eq [string]$option) { $entry = $known; $isNewEntry = $false }
    }
    if (-not $entry) {
        $entry = New-SIOriginalRecord -Tweak $tweak -OptionOverride $option
    }
    if (-not ($entry.Contains('Extra'))) { $entry['Extra'] = @{} }

    # --- 2. the safety net of this apply ---------------------------------
    # The values of the moment, read now. If one value of the tweak cannot
    # be written, the values that were already written are put back with
    # these records, so that a tweak is never left half applied.
    $rollback = Get-SIRegistrySnapshot -Entries $entries

    # Windows closes some keys to the program. When that is the case the
    # whole tweak is skipped, instead of writing the first values and then
    # failing on the next one.
    $closedKey = ''
    foreach ($item in $entries) {
        $path = Get-SIUserRegistryPath $item.Path
        if (-not (Test-SIRegistryWritable -Path $path)) { $closedKey = $path; break }
    }
    if ($closedKey) {
        Write-SILog -Component 'Tweak' -Message "$($tweak.Name) is not available on this system: Windows does not let SIGAME write in $closedKey. Nothing was changed."
        Set-SIStatusText -Text "$($tweak.Name) is not available on this system, nothing was changed."
        $script:SILastApplyStatus = 'notavailable'
        return
    }

    # --- 3. write the backup BEFORE touching the system -------------------
    $backup.Tweaks[$tweak.Id] = $entry
    Save-SIBackup -Backup $backup | Out-Null

    # --- 4. change the registry -------------------------------------------
    $writtenKeys = @()
    $failed = ''
    foreach ($item in $entries) {
        $path = Get-SIUserRegistryPath $item.Path
        try {
            if (Get-SIEntryRemove $item) {
                Remove-SIRegistryValue -Path $path -Name $item.Name | Out-Null
                Write-SILog -Component 'Registry' -Message "Removed $path\$($item.Name)"
            } else {
                $value = Get-SIEntryValue $item
                Set-SIRegistryValue -Path $path -Name $item.Name -Value $value -Type $item.Type | Out-Null
                Write-SILog -Component 'Registry' -Message "Set $path\$($item.Name) ($($item.Type)) to $value"
            }
            $writtenKeys += ($path + '|' + $item.Name)
        } catch {
            $failed = "$path\$($item.Name): $($_.Exception.Message)"
            break
        }
        Invoke-SIUIPump
    }

    if ($failed) {
        # Put back everything that was already written. The tweak is then
        # exactly as it was before the Apply.
        Restore-SIRegistryWrites -Records $rollback -WrittenKeys $writtenKeys | Out-Null
        if ($isNewEntry) {
            $null = $backup.Tweaks.Remove($tweak.Id)
            Save-SIBackup -Backup $backup | Out-Null
        }
        Write-SILog -Component 'Tweak' -Message "$($tweak.Name) is not available on this system: $failed Nothing was changed."
        Set-SIStatusText -Text "$($tweak.Name) is not available on this system, nothing was changed."
        $script:SILastApplyStatus = 'notavailable'
        Update-SIStates -OnlyId $tweak.Id
        return
    }

    # --- 5. change the services -------------------------------------------
    if ($tweak.Contains('Services') -and $tweak.Services) {
        foreach ($service in $tweak.Services) {
            $optional = ($service.Contains('Optional') -and $service.Optional)
            $state = Get-SIServiceState -Name $service.Name
            if (-not $state.Exists) {
                # The service is not on this Windows version. There is nothing
                # to change and it is not an error.
                Write-SILog -Component 'Service' -Message "Service $($service.Name) is not on this Windows version, it was skipped."
            } else {
                try {
                    Set-SIServiceStartType -Name $service.Name -StartupType $service.StartupType
                    Write-SILog -Component 'Service' -Message "Service $($service.Name) set to $($service.StartupType)"
                } catch {
                    if ($optional) {
                        # Windows owns this service and answers "access
                        # denied". That is not an error: the tweak works with
                        # the policy that was written above.
                        Write-SILog -Component 'Service' -Message "Service $($service.Name) is managed by Windows and was not switched by hand: $($_.Exception.Message)"
                    } else {
                        $failed = "service $($service.Name): $($_.Exception.Message)"
                        break
                    }
                }
            }
            Invoke-SIUIPump
        }
    }

    if ($failed) {
        # A service that could not be changed makes the whole tweak
        # unavailable here, so the registry part is put back as well.
        Restore-SIRegistryWrites -Records $rollback -WrittenKeys $writtenKeys | Out-Null
        if ($isNewEntry) {
            $null = $backup.Tweaks.Remove($tweak.Id)
            Save-SIBackup -Backup $backup | Out-Null
        }
        Write-SILog -Component 'Tweak' -Message "$($tweak.Name) is not available on this system: $failed Nothing was changed."
        Set-SIStatusText -Text "$($tweak.Name) is not available on this system, nothing was changed."
        $script:SILastApplyStatus = 'notavailable'
        Update-SIStates -OnlyId $tweak.Id
        return
    }

    # --- 6. the extra work of this tweak -----------------------------------
    if ($tweak.Contains('ApplyScript') -and $tweak.ApplyScript) {
        try {
            $result = Get-SIDictionaryFromOutput (& $tweak.ApplyScript)
            if ($result) {
                foreach ($key in $result.Keys) { $entry.Extra[$key] = $result[$key] }
            }
        } catch {
            $message = $_.Exception.Message
            # A tweak that has no registry value and no service is made only by
            # its ApplyScript (the DNS server, the TCP settings, the
            # hibernation). If that fails, nothing was changed at all and the
            # tweak must not be shown as applied.
            if ($entries.Count -eq 0 -and -not ($tweak.Contains('Services') -and $tweak.Services)) {
                Write-SILog -Level 'ERROR' -Component 'Tweak' -Message "$($tweak.Name) was not applied: $message"
                Set-SIStatusText -Text "$($tweak.Name) was not applied, see the log."
                if ($isNewEntry) {
                    $null = $backup.Tweaks.Remove($tweak.Id)
                    Save-SIBackup -Backup $backup | Out-Null
                }
                $script:SILastApplyStatus = 'failed'
                Update-SIStates -OnlyId $tweak.Id
                return
            }
            Write-SILog -Level 'WARN' -Component 'Tweak' -Message "The extra work of $($tweak.Name) could not be done (the rest of the tweak was applied): $message"
        }
    }

    # --- 7. write the backup again (it now holds the extra undo data) ------
    $backup.Tweaks[$tweak.Id] = $entry
    Save-SIBackup -Backup $backup | Out-Null

    # The change may have made a cached reading wrong.
    if ($tweak.Contains('CacheKeys') -and $tweak.CacheKeys) {
        Clear-SICache -Keys $tweak.CacheKeys
    }

    Set-SIStatusText -Text "$($tweak.Name) applied."
    Write-SILog -Level 'OK' -Component 'Tweak' -Message "Applied: $($tweak.Name)"
    $script:SILastApplyStatus = 'applied'
    Update-SIStates -OnlyId $tweak.Id
}

function Invoke-SIUndoTweak {
    <#
    .SYNOPSIS
        Undoes one tweak using the values stored in the JSON backup.
    #>
    param([Parameter(Mandatory = $true)][string]$TweakId)

    $tweak = $script:SITweaks[$TweakId]
    if (-not $tweak) { return }

    $backup = $script:SIBackup
    if (-not $backup) {
        $script:SIBackup = Get-SIBackup
        $backup = $script:SIBackup
    }
    if (-not $backup.Tweaks.Contains($TweakId)) {
        Write-SILog -Level 'WARN' -Component 'Tweak' -Message "Nothing to undo for $($tweak.Name): no entry in the backup."
        Set-SIStatusText -Text "Nothing to undo for $($tweak.Name)."
        return
    }

    Set-SIStatusText -Text "Undoing $($tweak.Name) ..."
    Write-SILog -Component 'Tweak' -Message "Undo: $($tweak.Name)"

    $entry = $backup.Tweaks[$TweakId]

    foreach ($record in @($entry['Registry'])) {
        $path = $record['Path']
        $name = $record['Name']
        try {
            if ($record['Existed']) {
                $type = ConvertTo-SIKind $record['Kind']
                if (-not $type) { $type = 'String' }
                Set-SIRegistryValue -Path $path -Name $name -Value $record['Value'] -Type $type | Out-Null
                Write-SILog -Component 'Registry' -Message "Restored $path\$name to $($record['Value'])"
            } else {
                Remove-SIRegistryValue -Path $path -Name $name | Out-Null
                Write-SILog -Component 'Registry' -Message "Removed $path\$name (it was not set before SIGAME ran)"
            }
        } catch {
            Write-SILog -Level 'ERROR' -Component 'Registry' -Message "Could not restore $path\$name : $($_.Exception.Message)"
        }
        Invoke-SIUIPump
    }

    foreach ($record in @($entry['Services'])) {
        if ($record['Existed']) {
            $state = Get-SIServiceState -Name $record['Name']
            if (-not $state.Exists) {
                Write-SILog -Component 'Service' -Message "Service $($record['Name']) is not on this Windows version, it was skipped."
            } else {
                try {
                    Set-SIServiceStartType -Name $record['Name'] -StartupType $record['StartType']
                    if ($record['WasRunning']) {
                        Start-Service -Name $record['Name'] -ErrorAction SilentlyContinue
                    }
                    Write-SILog -Component 'Service' -Message "Service $($record['Name']) restored to $($record['StartType'])"
                } catch {
                    # Windows owns some services (DoSvc for example) and
                    # answers "access denied". The undo of such a service is
                    # not needed: SIGAME never changed it either.
                    Write-SILog -Component 'Service' -Message "Service $($record['Name']) is managed by Windows and was not switched by hand: $($_.Exception.Message)"
                }
            }
        }
    }

    if ($tweak.Contains('UndoScript') -and $tweak.UndoScript) {
        try {
            & $tweak.UndoScript $entry['Extra'] | Out-Null
        } catch {
            Write-SILog -Level 'ERROR' -Component 'Tweak' -Message "Extra undo for $($tweak.Name) failed: $($_.Exception.Message)"
        }
    }

    $null = $backup.Tweaks.Remove($TweakId)
    Save-SIBackup -Backup $backup | Out-Null

    # The change may have made a cached reading wrong.
    if ($tweak.Contains('CacheKeys') -and $tweak.CacheKeys) {
        Clear-SICache -Keys $tweak.CacheKeys
    }

    Set-SIStatusText -Text "$($tweak.Name) undone."
    Write-SILog -Level 'OK' -Component 'Tweak' -Message "Undone: $($tweak.Name)"
    Update-SIStates -OnlyId $tweak.Id
}

function Invoke-SIUndoAll {
    <#
    .SYNOPSIS
        Restores every tweak that is recorded in the JSON backup.
    #>
    $backup = $script:SIBackup
    if (-not $backup) {
        $script:SIBackup = Get-SIBackup
        $backup = $script:SIBackup
    }
    if (-not $backup) {
        Set-SIStatusText -Text 'The backup is empty, there is nothing to undo.'
        Write-SILog -Component 'Tweak' -Message 'Undo all: the backup is empty.'
        return
    }
    $hasTools = $false
    if ($backup.Contains('Tools') -and $backup['Tools']) { $hasTools = @($backup['Tools'].Keys).Count -gt 0 }
    $hasTweaks = $false
    if ($backup.Contains('Tweaks') -and $backup['Tweaks']) { $hasTweaks = @($backup['Tweaks'].Keys).Count -gt 0 }
    if ((-not $hasTweaks) -and (-not $hasTools)) {
        Set-SIStatusText -Text 'The backup is empty, there is nothing to undo.'
        Write-SILog -Component 'Tweak' -Message 'Undo all: the backup is empty.'
        return
    }

    # Undo the newest tweak first, so the order of the changes is reversed.
    $ordered = @()
    if ($hasTweaks) {
        foreach ($id in $backup.Tweaks.Keys) {
            $appliedAt = ''
            if ($backup.Tweaks[$id].Contains('AppliedAt')) { $appliedAt = [string]$backup.Tweaks[$id]['AppliedAt'] }
            # The date of the backup is a STRING ("2026-10-21T10:37:01"), so
            # it is parsed before it is compared. Only real dates give the
            # right order, and only real dates can be subtracted later.
            $moment = ConvertTo-SIDateTime $appliedAt
            if (-not $moment) { $moment = [datetime]::MinValue }
            $ordered += [pscustomobject]@{ Id = $id; AppliedAt = $appliedAt; Moment = $moment }
        }
    }
    $ordered = @($ordered | Sort-Object -Property Moment -Descending)

    foreach ($item in $ordered) {
        Invoke-SIUndoTweak -TweakId $item.Id
    }

    # The per game settings and the startup programs have their own place in
    # the backup, so they are put back here.
    Invoke-SIUndoTools

    Set-SIStatusText -Text 'All recorded changes were undone.'
}

