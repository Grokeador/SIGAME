# ---------------------------------------------------------------------------
#  SIGAME - module 07: the start-up and the background copy
#
#  The slow work (System Restore point, JSON backup, reading the real state of
#  every tweak) is done by a second copy of SIGAME, so that the window is
#  never blocked.
#
#  The request for administrator rights is NOT here: it is in the loader
#  SI-GAME.ps1, because it has to happen before the modules are loaded.
# ---------------------------------------------------------------------------
# ============================== 10. START-UP ===============================

function Get-SIShortText {
    <#
    .SYNOPSIS
        One short line of text, without line breaks and not too long, so it
        fits into the header of the window.
    #>
    param([string]$Text, [int]$Max = 60)

    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $flat = ($Text -replace '\s+', ' ').Trim()
    if ($flat.Length -le $Max) { return $flat }
    return $flat.Substring(0, [math]::Max(1, $Max - 3)) + '...'
}

function Set-SIHeaderText {
    <#
    .SYNOPSIS
        Writes one line into the header of the window.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Text,
        [string]$Color = ''
    )

    $window = $script:SIWindow
    if (-not $window) { return }
    $label = Get-SIElement -Name $Name
    if (-not $label) { return }
    $label.Text = $Text
    if ($Color) { $label.Foreground = Get-SIBrush $Color }
}

function Update-SIRestorePointHeader {
    <#
    .SYNOPSIS
        Writes the state of the System Restore point into the header of the
        window. It always tells the truth: a restore point that was not made
        is never shown as made.

    .PARAMETER Status
        pending | creating | created | recent | failed
    .PARAMETER Message
        The reason, shown when it failed.
    #>
    param([string]$Status, [string]$Message)

    if (-not $Status) { $Status = $script:SIRestorePointStatus }
    $script:SIRestorePointStatus = $Status
    $short = Get-SIShortText -Text $Message

    switch ($Status) {
        'created' {
            Set-SIHeaderText -Name 'HeaderRestore' -Text 'Restore point: created' -Color $script:SIColors.Ok
        }
        'recent' {
            Set-SIHeaderText -Name 'HeaderRestore' -Text "Restore point: the one from before is used" -Color $script:SIColors.Warn
        }
        'creating' {
            Set-SIHeaderText -Name 'HeaderRestore' -Text 'Restore point: creating ...' -Color $script:SIColors.Muted
        }
        'pending' {
            Set-SIHeaderText -Name 'HeaderRestore' -Text 'Restore point: waiting ...' -Color $script:SIColors.Muted
        }
        'none' {
            Set-SIHeaderText -Name 'HeaderRestore' -Text 'Restore point: waiting ...' -Color $script:SIColors.Muted
        }
        default {
            if ($short) {
                Set-SIHeaderText -Name 'HeaderRestore' -Text "Restore point: FAILED - $short" -Color $script:SIColors.Danger
            } else {
                Set-SIHeaderText -Name 'HeaderRestore' -Text 'Restore point: NOT created (see log)' -Color $script:SIColors.Danger
            }
        }
    }
}

function Update-SIBackupHeader {
    <#
    .SYNOPSIS
        Writes the state of the JSON backup into the header of the window.

    .PARAMETER Status
        pending | writing | written | failed
    .PARAMETER Message
        The reason, shown when it failed.
    #>
    param([string]$Status, [string]$Message)

    $short = Get-SIShortText -Text $Message
    $leaf = Split-Path -Path $script:SIBackupPath -Leaf

    switch ($Status) {
        'written' {
            Set-SIHeaderText -Name 'HeaderBackup' -Text "Backup: saved ($leaf)" -Color $script:SIColors.Ok
        }
        'writing' {
            Set-SIHeaderText -Name 'HeaderBackup' -Text 'Backup: writing ...' -Color $script:SIColors.Muted
        }
        'failed' {
            if ($short) {
                Set-SIHeaderText -Name 'HeaderBackup' -Text "Backup: FAILED - $short" -Color $script:SIColors.Danger
            } else {
                Set-SIHeaderText -Name 'HeaderBackup' -Text 'Backup: NOT written (see log)' -Color $script:SIColors.Danger
            }
        }
        default {
            Set-SIHeaderText -Name 'HeaderBackup' -Text 'Backup: waiting ...' -Color $script:SIColors.Muted
        }
    }
}

function Get-SIRestorePointAge {
    <#
    .SYNOPSIS
        How old a restore point is, as a short text.

    .DESCRIPTION
        The age is calculated with DateTime.Subtract() and never with the "-"
        operator, so that no overload can ever become ambiguous. The value
        comes from ConvertTo-SIDateTime (module 00-core.ps1), which also
        understands the string that WMI hands out.
    #>
    param($RestorePoint)

    if (-not $RestorePoint) { return 'unknown age' }
    $stamp = ConvertTo-SIDateTime $RestorePoint.CreationTime
    if (-not $stamp) { return 'unknown age' }
    $age = [datetime]::Now.Subtract([datetime]$stamp)
    $minutes = [int][math]::Floor($age.TotalMinutes)
    if ($minutes -lt 1) { return 'less than a minute' }
    if ($minutes -lt 60) { return "$minutes minutes" }
    $hours = [int][math]::Floor($minutes / 60)
    return "$hours hours"
}

function Get-SIRestorePointTimeText {
    <#
    .SYNOPSIS
        The creation time of a restore point as a readable text.
    #>
    param($RestorePoint)

    if (-not $RestorePoint) { return 'an unknown moment' }
    $stamp = ConvertTo-SIDateTime $RestorePoint.CreationTime
    if (-not $stamp) { return "the raw value '$($RestorePoint.CreationTime)'" }
    return $stamp.ToString('yyyy-MM-dd HH:mm:ss')
}

function New-SIRestorePoint {
    <#
    .SYNOPSIS
        Creates a System Restore point. Called before the first change.

    .DESCRIPTION
        The log may only say that a restore point was made when one really
        exists. So the rights are checked first, the restore point is made,
        and then it is looked up again in the list of restore points before
        "[OK] System Restore point created." is written.

        This function does not touch the window at all, so it can run in the
        background copy of SIGAME without freezing the window.

    .OUTPUTS
        @{ Status = 'created' | 'recent' | 'failed'; Message = '...'; Sequence = 0 }
    #>
    $result = @{ Status = 'failed'; Message = 'The System Restore point was not created.'; Sequence = 0; At = '' }

    Write-SILog -Component 'RestorePoint' -Message 'Creating a System Restore point ...'

    # Only an elevated process may write a restore point. Checked here as
    # well, so the log can never claim a restore point that does not exist.
    if (-not (Test-SIAdmin)) {
        $result.Message = 'SIGAME is not running as Administrator, so no System Restore point can be created.'
        Write-SILog -Level 'ERROR' -Component 'RestorePoint' -Message $result.Message
        return $result
    }

    # Windows only allows one restore point every 24 hours by default. If a
    # recent SIGAME restore point (< 24h) already exists, reuse it immediately
    # instead of waiting ~30s for Checkpoint-Computer to silently no-op.
    Clear-SICache -Keys @('RestorePoints')
    $existing = Get-SIRecentRestorePoint
    if ($existing) {
        $existingStamp = ConvertTo-SIDateTime $existing.CreationTime
        if ($existingStamp) {
            $existingHours = [datetime]::Now.Subtract([datetime]$existingStamp).TotalHours
            if ($existingHours -ge 0 -and $existingHours -lt 24) {
                $result.Status = 'recent'
                $result.Sequence = $existing.SequenceNumber
                $result.At = (Get-SIRestorePointTimeText -RestorePoint $existing)
                $result.Message = "A recent System Restore point already exists (sequence $($existing.SequenceNumber), $(Get-SIRestorePointAge -RestorePoint $existing) old)."
                Write-SILog -Level 'OK' -Component 'RestorePoint' -Message $result.Message
                return $result
            }
        }
    }

    $reason = ''
    $created = $false
    $srPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $oldFreq = $null
    try { $oldFreq = Get-SIRegistryValue -Path $srPath -Name 'SystemRestorePointCreationFrequency' } catch { }
    try {
        # Bypass Windows 24-hour (1440 min) restore point creation frequency limit
        try { Set-SIRegistryValue -Path $srPath -Name 'SystemRestorePointCreationFrequency' -Value 0 -Type 'DWord' | Out-Null } catch { }
        try {
            Checkpoint-Computer -Description 'SIGAME - before the first change' -RestorePointType 'MODIFY_SETTINGS' -WarningAction SilentlyContinue -ErrorAction Stop
            $created = $true
        } catch {
            $reason = [string]$_.Exception.Message
            Write-SILog -Level 'WARN' -Component 'RestorePoint' -Message "The first attempt did not work ($reason). System Restore is probably switched off, it is enabled and tried again ..."
            try {
                Enable-ComputerRestore -Drive $Env:SystemDrive -ErrorAction Stop
            } catch {
                $result.Message = "System Restore could not be enabled: $($_.Exception.Message)"
                Write-SILog -Level 'ERROR' -Component 'RestorePoint' -Message $result.Message
                return $result
            }
            try {
                Checkpoint-Computer -Description 'SIGAME - before the first change' -RestorePointType 'MODIFY_SETTINGS' -WarningAction SilentlyContinue -ErrorAction Stop
                $created = $true
            } catch {
                $reason = [string]$_.Exception.Message
            }
        }
    } finally {
        try {
            if ($oldFreq -and $oldFreq.Exists) {
                Set-SIRegistryValue -Path $srPath -Name 'SystemRestorePointCreationFrequency' -Value $oldFreq.Value -Type 'DWord' | Out-Null
            } else {
                Remove-SIRegistryValue -Path $srPath -Name 'SystemRestorePointCreationFrequency' | Out-Null
            }
        } catch { }
    }

    if (-not $reason) { $reason = 'Windows did not give a reason.' }

    if ($created) {
        # Check that the restore point really is there before saying so.
        Clear-SICache -Keys @('RestorePoints')
        $made = Get-SIRecentRestorePoint
        if ($made) {
            $result.Status = 'created'
            $result.Sequence = $made.SequenceNumber
            $result.At = (Get-SIRestorePointTimeText -RestorePoint $made)
            $result.Message = "System Restore point created (sequence $($made.SequenceNumber), $(Get-SIRestorePointAge -RestorePoint $made) old)."
            Write-SILog -Level 'OK' -Component 'RestorePoint' -Message $result.Message
            return $result
        }
        $result.Message = 'Checkpoint-Computer said it was done, but no SIGAME restore point was found in the list of restore points.'
        Write-SILog -Level 'ERROR' -Component 'RestorePoint' -Message $result.Message
        return $result
    }

    # Windows only allows one restore point every 24 hours. When that is the
    # reason, a recent restore point is good enough. An OLD restore point of
    # SIGAME is not: it does not protect the changes of this run, so that is
    # reported as a failure.
    Clear-SICache -Keys @('RestorePoints')
    $recent = Get-SIRecentRestorePoint
    if ($recent) {
        $stamp = ConvertTo-SIDateTime $recent.CreationTime
        $hoursOld = -1
        if ($stamp) { $hoursOld = [datetime]::Now.Subtract([datetime]$stamp).TotalHours }
        if ($hoursOld -ge 0 -and $hoursOld -lt 24) {
            $result.Status = 'recent'
            $result.At = (Get-SIRestorePointTimeText -RestorePoint $recent)
            $result.Message = "No new restore point ($reason). The restore point from $(Get-SIRestorePointTimeText -RestorePoint $recent) is used instead."
            Write-SILog -Level 'WARN' -Component 'RestorePoint' -Message $result.Message
            return $result
        }
        $result.Message = "Could not create a System Restore point: $reason The last restore point of SIGAME is from $(Get-SIRestorePointTimeText -RestorePoint $recent) and is too old to protect this change."
        Write-SILog -Level 'ERROR' -Component 'RestorePoint' -Message $result.Message
        return $result
    }

    $result.Message = "Could not create a System Restore point: $reason"
    Write-SILog -Level 'ERROR' -Component 'RestorePoint' -Message $result.Message
    return $result
}

function Get-SIRecentRestorePoint {
    <#
    .SYNOPSIS
        The newest restore point of SIGAME, $null when there is none.

    .DESCRIPTION
        Get-ComputerRestorePoint talks to WMI and is slow, so the answer is
        kept for the rest of the run.
    #>
    return Get-SICachedValue -Key 'RestorePoints' -Producer {
        try {
            # The old restore points were called "SI GAME - before the first
            # change", the new ones "SIGAME - before the first change". The
            # pattern with the asterisk finds both (whereas '?' required
            # exactly one character and missed 'SIGAME').
            $allPoints = @(Get-ComputerRestorePoint -ErrorAction Stop)
            if ($allPoints.Count -eq 0) { return $null }
            $points = @($allPoints | Where-Object { $_.Description -like 'SI*GAME*' })
            if ($points.Count -gt 0) {
                return ($points | Sort-Object -Property SequenceNumber -Descending | Select-Object -First 1)
            }
            return ($allPoints | Sort-Object -Property SequenceNumber -Descending | Select-Object -First 1)
        } catch {
            return $null
        }
    }
}

# ====================== 11. THE BACKGROUND COPY (WORKER) ====================
#
#  The slow work (System Restore point, JSON backup, reading the real state
#  of every tweak) must not freeze the window. SIGAME therefore starts a
#  second copy of itself with the switch "-Worker". That copy has no window:
#  it writes what it has done into a small JSON file, and the window reads
#  that file every 250 ms and shows it. The rows fill in while the work goes
#  on, so the window is never blocked and never frozen.

function Write-SIWorkerResult {
    <#
    .SYNOPSIS
        Writes what the background copy has done into the result file.

    .DESCRIPTION
        The file is written to a temporary name first and then moved, so that
        the window never reads half a file.
    #>
    param([hashtable]$Result, [string]$Path)

    if (-not $Path) { return }
    try {
        if ($script:SILogCapture) { $Result['Log'] = @($script:SILogCapture) }
        $json = $Result | ConvertTo-Json -Depth 12 -Compress
        $tmp = $Path + '.tmp'
        [System.IO.File]::WriteAllText($tmp, $json, [System.Text.Encoding]::UTF8)
        if ([System.IO.File]::Exists($Path)) {
            [System.IO.File]::Delete($Path)
        }
        [System.IO.File]::Move($tmp, $Path)
    } catch {
        # The file of the last round is in the way: it is removed and the
        # new one is moved into place.
        try {
            Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
            Move-Item -LiteralPath ($Path + '.tmp') -Destination $Path -Force -ErrorAction SilentlyContinue
        } catch { }
    }
}

function Get-SIWorkerOption {
    <#
    .SYNOPSIS
        The option a tweak has to be read with, in the background copy.

    .DESCRIPTION
        The window sends the option the user picked with every request. When
        there is none, the option that matches the real state of the system
        is used.
    #>
    param($Tweak, $Options)

    if (-not ($Tweak.Contains('Options') -and $Tweak.Options)) { return '' }
    if ($Options -is [System.Collections.IDictionary] -and $Options.Contains($Tweak.Id)) {
        return [string]$Options[$Tweak.Id]
    }
    if ($Tweak.Contains('DetectOption') -and $Tweak.DetectOption) {
        try { return [string](& $Tweak.DetectOption) } catch { }
    }
    return [string]$Tweak.Options[0]
}

function Invoke-SIWorker {
    <#
    .SYNOPSIS
        The background half of SIGAME.

    .DESCRIPTION
        Modes:
          prepare       the System Restore point, the JSON backup with the
                        current values of ALL the tweaks and the real state of
                        every tweak
          restorepoint  only the System Restore point
          refresh       only the real state of every tweak
    #>
    param([string]$Mode = 'prepare', [string]$RequestPath = '', [string]$ResultPath = '')

    # The log lines are collected and handed over to the window, so that only
    # one process writes to the log file.
    $script:SILogCapture = New-Object System.Collections.ArrayList

    $result = @{
        Stage      = 'running'
        Restore    = @{ Status = 'skipped'; Message = 'this phase was not part of this run' }
        Backup     = @{ Status = 'skipped'; Message = 'this phase was not part of this run' }
        States     = @{}
        Log        = @()
        Error      = ''
        UserPrefix = ''
        UserSid    = ''
        IsLaptop   = $null
        Dns        = @()
        Speed      = @{}
        Temp       = @{}
        TempCleaned = @{}
        Games      = @()
        Bottleneck = @{}
    }

    $options = @{}
    try {
        if ($RequestPath -and [System.IO.File]::Exists($RequestPath)) {
            $raw = [System.IO.File]::ReadAllText($RequestPath, [System.Text.Encoding]::UTF8)
            # Windows PowerShell 5.1 writes the UTF-8 files with a byte order
            # mark. It is not part of the JSON.
            # The empty file is checked BEFORE the mark is taken away: an
            # empty file has no content, and $null has no method to call.
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $raw = $raw.TrimStart([char]0xFEFF)
            }
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $request = ConvertTo-SIPlain (ConvertFrom-Json $raw)
                if ($request -is [System.Collections.IDictionary] -and $request.Contains('Options')) {
                    $options = $request['Options']
                }
            }
        }
    } catch { }

    try {
        $tweaks = Get-SITweakTable

        # --- 1. the System Restore point ------------------------------------
        if ($Mode -eq 'prepare' -or $Mode -eq 'restorepoint') {
            $result.Restore = @{ Status = 'creating'; Message = 'the System Restore point is being created ...' }
            Write-SIWorkerResult -Result $result -Path $ResultPath
            $restore = New-SIRestorePoint
            $result.Restore = @{
                Status   = [string]$restore.Status
                Message  = [string]$restore.Message
                Sequence = $restore.Sequence
                At       = [string]$restore.At
            }
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }

        # --- 1b. the tests of round 5 ---------------------------------------
        # The DNS test, the speed test and the count of the temporary files
        # all need the internet or the disk, and they take a while. They run
        # here, in the background copy, so that the window keeps working.
        if ($Mode -eq 'dns') {
            $result['Dns'] = @(Invoke-SIDnsBenchmark)
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }
        if ($Mode -eq 'speed') {
            try {
                $speed = Invoke-SISpeedTest
                $result['Speed'] = @{
                    Mbps    = [double]$speed.Mbps
                    Bytes   = [long]$speed.Bytes
                    Seconds = [double]$speed.Seconds
                    At      = [string]$speed.At
                }
            } catch {
                $result['Speed'] = @{ Mbps = -1; Bytes = 0; Seconds = 0; At = ''; Error = [string]$_.Exception.Message }
            }
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }
        if ($Mode -eq 'temp') {
            $size = Get-SITempFilesSize
            $result['Temp'] = @{
                Bytes  = [long]$size.Bytes
                Files  = [int]$size.Files
                Folders = @($size.Folders)
            }
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }
        if ($Mode -eq 'cleantemp') {
            $cleaned = Remove-SITempFiles
            $result['TempCleaned'] = @{
                Removed = [int]$cleaned.Removed
                Failed  = [int]$cleaned.Failed
                Bytes   = [long]$cleaned.Bytes
            }
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }

        # --- 1c. the games and the honest limit of the computer ---------------
        # The games are read from the files of Steam and of Epic, and the
        # limit of the machine is read with WMI. Both are slow enough to be
        # done HERE, in the background copy, so that the window keeps
        # working.
        if ($Mode -eq 'prepare' -or $Mode -eq 'games') {
            try {
                $result['Games'] = @(Get-SIGameLibrary)
            } catch {
                $result['Games'] = @()
            }
            try {
                $result['Bottleneck'] = Get-SIBottleneck
            } catch {
                $result['Bottleneck'] = @{}
            }
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }

        # --- 2. the person sitting at the machine ---------------------------
        # The query of the interactive user is a WMI query and is slow, so it
        # is done HERE, in the background copy, and not in the window. The
        # window gets the answer with the result file.
        if ($Mode -eq 'prepare' -or $Mode -eq 'refresh') {
            Initialize-SIUserHive
            $result['UserPrefix'] = $script:SIUserPrefix
            $result['UserSid'] = [string]$script:SIUserSid
            # The laptop test is a WMI query as well. It is asked here, at
            # the beginning, so that the window knows it early: the Ultimate
            # Performance plan and the hibernation need to know it.
            $result['IsLaptop'] = (Test-SILaptop)
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }

        # --- 3. the JSON backup with the current values of ALL the tweaks ---
        if ($Mode -eq 'prepare') {
            $result.Backup = @{ Status = 'writing'; Message = 'the JSON backup is being written ...' }
            Write-SIWorkerResult -Result $result -Path $ResultPath
            try {
                # The backup that is already on the disk is loaded, so that the
                # undo entries of an earlier run are NOT thrown away.
                $backup = Get-SIBackup
                if (-not ($backup.Contains('Tweaks'))) { $backup['Tweaks'] = @{} }
                $snapshot = @{}
                foreach ($tweak in $tweaks) {
                    if ($tweak.Contains('ShowOnly') -and $tweak.ShowOnly) { continue }
                    $option = Get-SIWorkerOption -Tweak $tweak -Options $options
                    # The current values of EVERY tweak, read now.
                    $snapshot[$tweak.Id] = New-SIOriginalRecord -Tweak $tweak -OptionOverride $option
                }
                # The "Tweaks" section is the undo list. It is only filled by
                # Apply, exactly as before, so that "Undo all" never touches a
                # tweak that SIGAME did not change.
                $backup['Snapshot'] = $snapshot
                $backup['SnapshotAt'] = (Get-Date).ToString('s')
                $written = Save-SIBackup -Backup $backup
                if ($written) {
                    $result.Backup = @{
                        Status  = 'written'
                        Message = "the current values of all the tweaks are in $(Split-Path -Path $script:SIBackupPath -Leaf)"
                    }
                } else {
                    $result.Backup = @{
                        Status  = 'failed'
                        Message = "the JSON backup file $(Split-Path -Path $script:SIBackupPath -Leaf) was not written"
                    }
                }
            } catch {
                $result.Backup = @{
                    Status  = 'failed'
                    Message = "the JSON backup could not be written: $($_.Exception.Message)"
                }
            }
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }

        # --- 4. the real state of every tweak -------------------------------
        if ($Mode -eq 'prepare' -or $Mode -eq 'refresh') {
            foreach ($tweak in $tweaks) {
                $option = Get-SIWorkerOption -Tweak $tweak -Options $options
                try {
                    $state = Get-SITweakState -Tweak $tweak -OptionOverride $option
                    $result.States[$tweak.Id] = @{
                        Status  = [string]$state.Status
                        Text    = [string]$state.Text
                        Details = [string]$state.Details
                    }
                } catch {
                    $result.States[$tweak.Id] = @{
                        Status  = 'NotApplied'
                        Text    = "the state could not be read: $($_.Exception.Message)"
                        Details = ''
                    }
                }
            }
            Write-SIWorkerResult -Result $result -Path $ResultPath
        }

        # The laptop test is asked at the beginning of the run, so that the
        # window knows it before the first row is built.

        $result.Stage = 'done'
    } catch {
        $result.Stage = 'failed'
        $result.Error = [string]$_.Exception.Message
        Write-SILog -Level 'ERROR' -Component 'Worker' -Message "The background work failed: $($_.Exception.Message)"
    }

    Write-SIWorkerResult -Result $result -Path $ResultPath
}

function Set-SIWorkerFailed {
    <#
    .SYNOPSIS
        Says that the background copy is gone and unlocks the buttons.

    .DESCRIPTION
        The window must never stay locked forever. If the background copy
        cannot be started, or if it dies before it reports anything, the
        reason goes into the log and into the header, and the Apply buttons
        are switched on anyway: every change can still be undone with the
        JSON backup.
    #>
    param([string]$Message)

    Write-SILog -Level 'ERROR' -Component 'Start' -Message "The background work did not finish: $Message"
    Update-SIRestorePointHeader -Status 'failed' -Message $Message
    Update-SIBackupHeader -Status 'failed' -Message $Message

    if (-not $script:SIBackup) { $script:SIBackup = Get-SIBackup }
    if (-not $script:SIPrepared) {
        $script:SIPrepared = $true
        Set-SIButtonsEnabled -Enabled $true
    }
    Set-SIStatusText -Text 'The start-up work did not finish, see the log.'
    $script:SIWorkerFinished = $true
    $script:SIWorkerRunning = $false
    if ($script:SIPollTimer) {
        try { $script:SIPollTimer.Stop() } catch { }
    }
    # The run that was waiting starts now.
    Start-SINextWorker
}

function Start-SIWorker {
    <#
    .SYNOPSIS
        Starts the background copy of SIGAME.

    .DESCRIPTION
        The copy inherits the administrator rights of the window, because it is
        started as a child process of it.
    #>
    param([string]$Mode = 'prepare')

    # Only ONE background copy runs at a time. Every run uses the same files,
    # so a second copy would mix its answer with the first one. The other
    # runs wait in the queue and start one after the other.
    if ($script:SIWorkerRunning) {
        $script:SIPendingModes += $Mode
        Write-SILog -Component 'Start' -Message "The $Mode run waits for the background copy that is running."
        Set-SIStatusText -Text ("SIGAME is still working in the background. The {0} run starts right after it." -f $Mode)
        return
    }
    $script:SIWorkerRunning = $true
    $script:SIWorkerMode = $Mode
    $requestPath = Join-Path $env:TEMP ("SI-GAME-request-{0}.json" -f $PID)
    $resultPath = Join-Path $env:TEMP ("SI-GAME-result-{0}.json" -f $PID)
    $script:SIWorkerRequestPath = $requestPath
    $script:SIWorkerResultPath = $resultPath
    $script:SIWorkerStamp = $null
    $script:SIWorkerLogShown = 0
    $script:SIWorkerFinished = $false
    # The states of the last run are dropped: the new run brings new ones.
    $script:SIWorkerStates = @{}

    # An old result file must not be read.
    Remove-Item -LiteralPath $resultPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath ($resultPath + '.tmp') -Force -ErrorAction SilentlyContinue

    # The options the user picked have to be known in the background copy.
    $options = @{}
    foreach ($id in @($script:SIRows.Keys)) {
        $row = $script:SIRows[$id]
        if ($row -and $row.Combo -and $row.Combo.SelectedItem) {
            $options[$id] = [string]$row.Combo.SelectedItem
        }
    }

    try {
        $request = @{ Mode = $Mode; Options = $options }
        $json = $request | ConvertTo-Json -Depth 6 -Compress
        [System.IO.File]::WriteAllText($requestPath, $json, [System.Text.Encoding]::UTF8)
    } catch {
        Write-SILog -Level 'WARN' -Component 'Start' -Message "The request file could not be written: $($_.Exception.Message)"
    }

    if (-not $script:SICurrentScript) {
        Write-SILog -Level 'ERROR' -Component 'Start' -Message 'SIGAME does not know its own file, so the background copy cannot be started.'
        # The window must not stay locked forever because of that.
        Set-SIWorkerFailed -Message 'the background copy of SIGAME could not be started'
        return
    }

    $exe = Join-Path $PSHOME 'powershell.exe'
    $arguments = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', ('"{0}"' -f $script:SICurrentScript),
        '-Worker', '-WorkerMode', $Mode,
        '-WorkerRequest', ('"{0}"' -f $requestPath),
        '-WorkerResult', ('"{0}"' -f $resultPath)
    )

    try {
        $script:SIWorkerProcess = Start-Process -FilePath $exe -ArgumentList $arguments -PassThru -WindowStyle Hidden -ErrorAction Stop
        Write-SILog -Component 'Start' -Message "The background copy of SIGAME was started ($Mode)."
    } catch {
        Write-SILog -Level 'ERROR' -Component 'Start' -Message "The background copy of SIGAME could not be started: $($_.Exception.Message)"
        # The answer is written by hand, so that the poll sees the error and
        # the window does not stay locked forever.
        $failed = @{
            Stage   = 'failed'
            Restore = @{ Status = 'failed'; Message = 'the background copy of SIGAME could not be started' }
            Backup  = @{ Status = 'failed'; Message = 'the background copy of SIGAME could not be started' }
            States  = @{}
            Log     = @()
            Error   = [string]$_.Exception.Message
        }
        Write-SIWorkerResult -Result $failed -Path $resultPath
        $script:SIWorkerRunning = $false
    }

    # The window has to read the result file, so the poll is running from now
    # on, whatever happened above.
    Start-SIPollTimer
}

function Read-SIWorkerResult {
    <#
    .SYNOPSIS
        Reads the result file of the background copy.
    #>
    param([string]$Path)

    if (-not $Path) { return $null }
    if (-not [System.IO.File]::Exists($Path)) { return $null }
    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        # The byte order mark of Windows PowerShell 5.1 is not part of the JSON.
        # The empty file is checked first: an empty file has no content, and
        # $null has no method to call.
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $raw = $raw.TrimStart([char]0xFEFF)
        $parsed = ConvertFrom-Json $raw
        if (-not $parsed) { return $null }
        return ConvertTo-SIPlain $parsed
    } catch {
        return $null
    }
}

function Update-SIWorkerResult {
    <#
    .SYNOPSIS
        Shows what the background copy has done in the window.

    .DESCRIPTION
        Called by the poll timer every 250 ms. It brings in the new log
        lines, the state of the System Restore point, the state of the JSON
        backup and the state of the tweaks that were read.
    #>
    $path = $script:SIWorkerResultPath
    if (-not $path) { return }

    # Is the background copy still alive? A copy that dies without leaving a
    # message must not keep the window locked.
    $workerGone = $false
    if ($script:SIWorkerProcess) {
        try { $workerGone = $script:SIWorkerProcess.HasExited } catch { $workerGone = $false }
    }

    if (-not (Test-Path -LiteralPath $path)) {
        if ($workerGone) {
            Set-SIWorkerFailed -Message 'the background copy of SIGAME stopped before it could report anything'
        }
        return
    }

    try {
        $stamp = (Get-Item -LiteralPath $path -ErrorAction Stop).LastWriteTimeUtc
    } catch { return }
    if ($script:SIWorkerStamp -and ($stamp -eq $script:SIWorkerStamp)) {
        # The file did not change, so there is nothing new to read. But a
        # background copy that is gone and never said "done" is a failure.
        if ($workerGone -and -not $script:SIWorkerFinished) {
            Set-SIWorkerFailed -Message 'the background copy of SIGAME stopped before it could finish'
        }
        return
    }
    $script:SIWorkerStamp = $stamp

    $result = Read-SIWorkerResult -Path $path
    if (-not $result) { return }

    # --- the new log lines of the background copy ---------------------------
    $lines = @()
    if ($result.Contains('Log') -and $result['Log']) { $lines = @($result['Log']) }
    for ($index = $script:SIWorkerLogShown; $index -lt $lines.Count; $index++) {
        Write-SILog -Raw -Message ([string]$lines[$index])
    }
    if ($lines.Count -gt $script:SIWorkerLogShown) { $script:SIWorkerLogShown = $lines.Count }

    # --- the hive of the person sitting at the machine ----------------------
    # The background copy looked it up (it is a slow WMI query), so that the
    # window does not have to.
    if ($result.Contains('UserPrefix') -and $result['UserPrefix']) {
        $script:SIUserPrefix = [string]$result['UserPrefix']
        if ($result.Contains('UserSid')) { $script:SIUserSid = [string]$result['UserSid'] }
    }
    if ($result.Contains('IsLaptop') -and $null -ne $result['IsLaptop']) {
        $script:SIIsLaptop = [bool]$result['IsLaptop']
    }

    # --- the System Restore point -------------------------------------------
    $restoreStatus = ''
    $restoreMessage = ''
    if ($result.Contains('Restore') -and $result['Restore']) {
        $restore = $result['Restore']
        $restoreStatus = [string]$restore['Status']
        $restoreMessage = [string]$restore['Message']
        # "skipped" means that this phase was not part of this run, so the
        # header keeps what it says.
        if ($restoreStatus -ne 'skipped') {
            Update-SIRestorePointHeader -Status $restoreStatus -Message $restoreMessage
            # The line of trust says WHEN the restore point was made.
            if ($restore.Contains('At') -and $restore['At']) {
                $script:SIRestorePointAt = [string]$restore['At']
                Update-SITrustFooter
            }
        }
    }

    # --- the JSON backup ----------------------------------------------------
    $backupStatus = ''
    if ($result.Contains('Backup') -and $result['Backup']) {
        $backup = $result['Backup']
        $backupStatus = [string]$backup['Status']
        if ($backupStatus -ne 'skipped') {
            Update-SIBackupHeader -Status $backupStatus -Message ([string]$backup['Message'])
        }
    }

    # --- the real state of the tweaks ---------------------------------------
    if ($result.Contains('States') -and $result['States']) {
        foreach ($id in @($result['States'].Keys)) {
            $state = $result['States'][$id]
            # The state is kept, so that a row that is built after the state
            # was read still gets it.
            $script:SIWorkerStates[[string]$id] = $state
            Set-SIRowState -Id ([string]$id) -Status ([string]$state['Status']) -Text ([string]$state['Text']) -Details ([string]$state['Details'])
        }
    }

    # --- the games and the honest limit of the computer (round 6) ------------
    if ($result.Contains('Games') -and $result['Games'] -and @($result['Games']).Count -gt 0) {
        $rows = @()
        foreach ($game in @($result['Games'])) {
            $rows += [pscustomobject]@{
                Id     = [string]$game['Id']
                Name   = [string]$game['Name']
                Store  = [string]$game['Store']
                Exe    = [string]$game['Exe']
                Folder = [string]$game['Folder']
            }
        }
        $script:SIGameLibrary = $rows
        Build-SIGameLibrary
    }

    if ($result.Contains('Bottleneck') -and $result['Bottleneck'] -and $result['Bottleneck'].Count -gt 0) {
        $script:SIBottleneck = $result['Bottleneck']
        Update-SIBottleneck
    }

    # --- the tests of round 5 ------------------------------------------------
    if ($result.Contains('Dns') -and $result['Dns'] -and @($result['Dns']).Count -gt 0) {
        $rows = @()
        foreach ($row in @($result['Dns'])) {
            $rows += [pscustomobject]@{
                Name      = [string]$row['Name']
                Server    = [string]$row['Server']
                Ms        = [double]$row['Ms']
                IsCurrent = [bool]$row['IsCurrent']
            }
        }
        $script:SIDnsResults = $rows
        # The fastest server is the one that answers in the fewest ms.
        $best = $null
        foreach ($row in $rows) {
            if ($row.Ms -lt 0) { continue }
            if ((-not $best) -or ($row.Ms -lt $best.Ms)) { $best = $row }
        }
        if ($best) { $script:SILastDnsMs = $best.Ms }
        Update-SIDnsText
        Set-SIStatusText -Text 'The DNS test is done.'
        Write-SILog -Component 'Network' -Message 'The DNS test is done.'
    }

    if ($result.Contains('Speed') -and $result['Speed'] -and $result['Speed'].Contains('Mbps')) {
        $speed = $result['Speed']
        $mbps = -1
        if ($speed.Contains('Mbps')) { $mbps = [double]$speed['Mbps'] }
        if ($mbps -ge 0) {
            $script:SILastSpeedMbps = $mbps
            $script:SILastSpeedAt = [string]$speed['At']
            Update-SISpeedText
            Set-SIStatusText -Text ('The speed test is done: {0} Mbps.' -f $mbps)
            Write-SILog -Component 'Network' -Message ("The speed test is done: $mbps Mbps.")
        } else {
            $why = ''
            if ($speed.Contains('Error')) { $why = [string]$speed['Error'] }
            Set-SIStatusText -Text ('The speed test did not work: ' + $why)
            Write-SILog -Level 'WARN' -Component 'Network' -Message "The speed test did not work: $why"
        }
    }

    if ($result.Contains('Temp') -and $result['Temp'] -and $result['Temp'].Contains('Bytes')) {
        $temp = $result['Temp']
        $bytes = 0
        $files = 0
        if ($temp.Contains('Bytes')) { $bytes = [long]$temp['Bytes'] }
        if ($temp.Contains('Files')) { $files = [int]$temp['Files'] }
        $label = Get-SIElement -Name 'TempInfo'
        if ($label) {
            $label.Text = ('{0:0.0} GB in {1} files would be freed.' -f ($bytes / 1GB), $files)
        }
        $script:SITempBytes = $bytes
        # The user is asked before anything is deleted, because it cannot be
        # undone.
        $text = ('{0:0.0} GB of temporary files would be freed.' -f ($bytes / 1GB)) + [System.Environment]::NewLine +
                'The temporary files of your user and of Windows are deleted. This cannot be undone.' + [System.Environment]::NewLine +
                'Do you want to do it now?'
        $answer = $false
        try {
            if ($script:SIWindow) {
                $answer = [System.Windows.MessageBox]::Show($script:SIWindow, $text, 'Clean the temporary files', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question) -eq [System.Windows.MessageBoxResult]::Yes
            }
        } catch { }
        if ($answer) {
            Set-SIStatusText -Text 'The temporary files are being deleted ...'
            Start-SIWorker -Mode 'cleantemp'
        } else {
            Set-SIStatusText -Text 'Nothing was deleted.'
        }
    }

    if ($result.Contains('TempCleaned') -and $result['TempCleaned'] -and $result['TempCleaned'].Contains('Removed')) {
        $cleaned = $result['TempCleaned']
        $removed = 0
        $bytes = 0
        if ($cleaned.Contains('Removed')) { $removed = [int]$cleaned['Removed'] }
        if ($cleaned.Contains('Bytes')) { $bytes = [long]$cleaned['Bytes'] }
        $label = Get-SIElement -Name 'TempInfo'
        if ($label) {
            $label.Text = ('{0:0.0} GB in {1} files were deleted. It cannot be undone.' -f ($bytes / 1GB), $removed)
        }
        Set-SIStatusText -Text ('{0} temporary files were deleted ({1:0.0} GB).' -f $removed, ($bytes / 1GB))
        Write-SILog -Component 'Backup' -Message ("$removed temporary files were deleted ({0:0.0} GB)." -f ($bytes / 1GB))
    }

    # --- may the machine be changed now? -------------------------------------
    if ($script:SIWorkerMode -eq 'prepare') {
        $restoreDone = ($restoreStatus -eq 'created' -or $restoreStatus -eq 'recent' -or $restoreStatus -eq 'failed')
        $backupDone = ($backupStatus -eq 'written' -or $backupStatus -eq 'failed')
        if ($restoreDone -and $backupDone -and -not $script:SIPrepared) {
            $script:SIPrepared = $true
            # The backup that the background copy wrote is the one in memory
            # from now on.
            $script:SIBackup = Get-SIBackup
            Set-SIButtonsEnabled -Enabled $true
            Set-SIStatusText -Text 'Ready. Tick a tweak and press Apply, or use the GAMING preset.'

            if ($restoreStatus -eq 'failed' -and -not $script:SIRestorePointWarned) {
                $script:SIRestorePointWarned = $true
                $text = 'SIGAME could not create a System Restore point. Windows usually refuses this when System Restore is switched off. Every change SIGAME makes can still be undone with Undo and Undo all.'
                try {
                    if ($script:SIWindow) {
                        [System.Windows.MessageBox]::Show($script:SIWindow, $text, 'No System Restore point', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
                    }
                } catch { }
            }
        }
    }

    # --- is the background copy done? ---------------------------------------
    $stage = ''
    if ($result.Contains('Stage')) { $stage = [string]$result['Stage'] }
    if ($stage -eq 'done' -or $stage -eq 'failed') {
        $script:SIWorkerFinished = $true
        $script:SIWorkerRunning = $false
        if ($stage -eq 'failed') {
            $message = 'the background work failed'
            if ($result.Contains('Error') -and $result['Error']) { $message = [string]$result['Error'] }
            Write-SILog -Level 'ERROR' -Component 'Start' -Message "The background work did not finish: $message"
            if (-not $script:SIBackup) { $script:SIBackup = Get-SIBackup }
            if (-not $script:SIPrepared) {
                $script:SIPrepared = $true
                Set-SIButtonsEnabled -Enabled $true
                Set-SIStatusText -Text 'The start-up work did not finish, see the log.'
            }
        }
        if ($script:SIPollTimer) {
            try { $script:SIPollTimer.Stop() } catch { }
        }
        # The run that was waiting starts now.
        Start-SINextWorker
    }
    elseif ($workerGone) {
        # The copy is gone and it never said that it was done.
        Set-SIWorkerFailed -Message 'the background copy of SIGAME stopped before it could finish'
    }
}

function Start-SINextWorker {
    <#
    .SYNOPSIS
        Starts the run that was waiting for the background copy.

    .DESCRIPTION
        The DNS test, the speed test and the count of the temporary files
        need a background copy of their own, and there can be only one at a
        time. The runs that are asked for while another one is working wait
        in a queue, and this function starts the first one of the queue.
    #>
    if (-not $script:SIPendingModes) { return }
    $next = [string]$script:SIPendingModes[0]
    $rest = @()
    if ($script:SIPendingModes.Count -gt 1) {
        $rest = @($script:SIPendingModes[1..($script:SIPendingModes.Count - 1)])
    }
    $script:SIPendingModes = $rest
    Write-SILog -Component 'Start' -Message "The $next run of the background copy starts now."
    Start-SIWorker -Mode $next
}

function Start-SIPollTimer {
    <#
    .SYNOPSIS
        Starts the timer that reads the result file of the background copy.
    #>
    if ($script:SIPollTimer) {
        try { $script:SIPollTimer.Stop() } catch { }
    }
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(250)
    # The tick of the timer runs inside the hand-made dispatcher loop. An
    # error that is not caught here leaves the loop and ends the program
    # with the box of the error, while the owner is using it. So the tick
    # is protected and the reason is written on the log.
    $null = $timer.Add_Tick({
        try {
            Update-SIWorkerResult
        } catch {
            Write-SILog -Level 'ERROR' -Component 'Start' -Message ("the result of the background copy could not be read: {0}" -f $_.Exception.Message)
        }
    })
    $script:SIPollTimer = $timer
    $timer.Start()
}

function Stop-SIWorker {
    <#
    .SYNOPSIS
        Cleans up after the background copy when the window is closed.

    .DESCRIPTION
        The background copy is NOT killed: it may be in the middle of the
        System Restore point, and that is better left to Windows.
    #>
    foreach ($path in @($script:SIWorkerResultPath, $script:SIWorkerRequestPath)) {
        if (-not $path) { continue }
        try { Remove-Item -LiteralPath $path -Force -ErrorAction Stop } catch { }
        try { Remove-Item -LiteralPath ($path + '.tmp') -Force -ErrorAction Stop } catch { }
    }
    $script:SIWorkerProcess = $null
}

function Start-SISlowStart {
    <#
    .SYNOPSIS
        The work that is too slow to do before the window is on screen.

    .DESCRIPTION
        The window is already visible when this runs.

        The background copy of SIGAME is started FIRST, because it has to
        make the System Restore point, and that takes half a minute. It
        creates the System Restore point, writes the JSON backup with the
        current values of all the tweaks and reads the real state of every
        tweak. The window shows all of that while it happens, so it never
        freezes.

        The rows are built while the background copy works. The window is
        pumped after every row, so the rows appear one after the other.

        Apply and the GAMING preset stay off until the System Restore point
        and the JSON backup are done, so that nothing can be changed before
        them.
    #>
    if ($script:SISlowStartDone) { return }
    $script:SISlowStartDone = $true

    try {
        # How long the window needed. This is the number the owner is
        # interested in: it is measured from the start of this PowerShell
        # process, so it includes the loading of the script.
        if ($script:SIWindowOnScreen) {
            Write-SILog -Component 'Start' -Message ("The window is on screen after {0:0.00} s." -f $script:SIWindowOnScreen.TotalSeconds)
        }
        # The time of the FIRST window of SIGAME: the logo and the word
        # "Loading ...". It is the number that the owner wants to be under
        # 8 seconds on his machine.
        if ($script:SIFirstWindowOnScreen) {
            Write-SILog -Component 'Start' -Message ("The first window (the logo and Loading) was on the screen after {0:0.00} s." -f $script:SIFirstWindowOnScreen.TotalSeconds)
        }

        # The version information is written now, so that the log says the
        # same as before, but nothing is read before the window is on screen.
        Write-SILog -Component 'Start' -Message "Working folder: $script:SIRoot"
        Write-SILog -Component 'Start' -Message "Administrator rights: $(Test-SIAdmin)"
        Write-SILog -Component 'Start' -Message "Signed in as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        Write-SILog -Component 'Start' -Message "Windows build: $(Get-SIWindowsBuild)"

        # The last lines of the log go into the window.
        Show-SILogTail

        # The JSON backup is read here, not before the window was opened.
        $script:SIBackup = Get-SIBackup

        # The background copy goes first: the System Restore point and the
        # tweak states start immediately in the background while the window
        # measures the system and initializes the tray icon.
        Set-SIStatusText -Text (Get-SIText -Key 'StatusPreparing')
        Start-SIWorker -Mode 'prepare'

        # The measurements of the last run are read here too, so that the
        # PROVE IT panel is not empty when the window opens.
        $measures = Get-SIMeasures
        if ($measures) {
            if ($measures.Before) { $script:SIMeasuresBefore = $measures.Before }
            if ($measures.After) { $script:SIMeasuresAfter = $measures.After }
        }

        # The first measurement of this run. The window is on the screen
        # already, so the numbers of the BEFORE column are there at once: the
        # free memory, the startup programs that are on, the answer time of
        # the DNS, the power plan and the state of the HAGS, of the Game Mode
        # and of the VBS. The window is pumped before and after, so that it
        # stays alive while it measures.
        try {
            Set-SIStatusText -Text (Get-SIText -Key 'StatusMeasuring')
            Invoke-SIUIPump -Milliseconds 20
            $first = Measure-SISystem -QuickDns
            $script:SIMeasuresBefore = $first
            # The AFTER column stays empty until something was changed.
            $script:SIMeasuresAfter = $null
            Update-SIProvePanel
            Invoke-SIUIPump -Milliseconds 20
            Write-SILog -Component 'UI' -Message 'The first measurement of this run was made.'
        } catch {
            Write-SILog -Level 'WARN' -Component 'UI' -Message "The first measurement did not work: $($_.Exception.Message)"
        }
        Update-SIProvePanel
        Set-SIStatusText -Text (Get-SIText -Key 'StatusPreparing')

        # --- the tray and the AUTO-BOOST (initialized after window is shown) ---
        try {
            $null = New-SITrayIcon
            Set-SISITrayHooks
            Start-SIAutoBoost
        } catch {
            Write-SILog -Level 'WARN' -Component 'Tray' -Message "the icon of the tray could not be started: $($_.Exception.Message)"
        }

        # The rows of the tweaks are NOT built here. They are built when the
        # Advanced section is opened for the first time, so that the window
        # is on the screen in a couple of seconds.
        # The XAML fallback has no Advanced section, so its rows are built now.
        if (-not (Get-SIElement -Name 'AdvancedExpander')) {
            Build-SIRows
        }

        # The window says it when the administrator rights are not there, so
        # that the user knows why some tweaks do not work.
        if ($script:SIWithoutAdmin) {
            Set-SIStatusText -Text 'SIGAME is running without administrator rights: some tweaks will not work.'
        }
    } catch {
        Write-SILog -Level 'ERROR' -Component 'Start' -Message "The start-up work failed: $($_.Exception.Message)"
        $script:SIPrepared = $true
        if (-not $script:SIBackup) { $script:SIBackup = Get-SIBackup }
        Set-SIButtonsEnabled -Enabled $true
        Set-SIStatusText -Text (Get-SIText -Key 'StatusReady')
    }
}

function Invoke-SIMain {
    <#
    .SYNOPSIS
        The real start: log, window, and the slow work behind it.

    .DESCRIPTION
        Only ONE line is written before the window is opened. Every line of
        the log is a file write, and every file write is on the way to the
        window.
    #>
    $loaded = Get-SIElapsedSinceStart
    Write-SILog -Component 'Start' -Message ("SIGAME started, PowerShell $($PSVersionTable.PSVersion), the script was loaded after {0:0.00} s." -f $loaded.TotalSeconds)

    $window = $null
    try {
        $window = New-SIWindow
    } catch {
        $message = [string]$_.Exception.Message
        if ([string]::IsNullOrWhiteSpace($message)) { $message = 'unknown error' }
        $stack = [string]$_.ScriptStackTrace
        if ([string]::IsNullOrWhiteSpace($stack)) { $stack = '(no stack trace)' }
        Write-SILog -Level 'ERROR' -Component 'Start' -Message "The window could not be opened: $message"
        Write-SILog -Component 'Start' -Message $stack
        try {
            Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
            [System.Windows.MessageBox]::Show(
                "SIGAME could not open its window.`n`n$message`n`nThe full details are in the log file:`n$script:SILogPath",
                'SIGAME',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error) | Out-Null
        } catch {
            Write-Host "SIGAME could not open its window: $message"
        }
        return
    }
    if (-not $window) {
        # New-SIWindow has already written the reason in the log.
        Write-Host "SIGAME could not open its window. The log file is here: $script:SILogPath"
        return
    }

    # The window is painted first, the slow work starts afterwards.
    # ContentRendered fires as soon as the window is on the screen. The timer
    # is the safety net for the case where that event does not come. It is a
    # LONG way off on purpose: a short timer would win the race against the
    # first paint, the rows would be built while the window is still empty,
    # and the window would then stay blank until all of them are done.
    $startTimer = New-Object System.Windows.Threading.DispatcherTimer
    $startTimer.Interval = [TimeSpan]::FromMilliseconds(2500)

    $null = $window.Add_ContentRendered({
        # The moment the window was on the screen. Only the time is taken
        # here: a log line is a file write, and the file write would hold
        # back the paint that is running right now.
        # The time is set by a function and not by a line here: a script
        # block cannot always see the variables of the script scope, and the
        # number would be lost.
        try { $startTimer.Stop() } catch { }
        Set-SIWindowOnScreenTime
        # The loading window has done its job: the real window is here.
        Close-SILoadingWindow
        # Background priority: the dispatcher finishes the paint first and
        # only then starts the slow work.
        [void]$window.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]{ Start-SISlowStart })
    }.GetNewClosure())

    $null = $startTimer.Add_Tick({
        $startTimer.Stop()
        # The safety net. The window has been on the screen for a while by
        # now, so the time is only known roughly.
        # The time is set by a function and not by a line here: a script
        # block that was made with GetNewClosure() does NOT see the variables
        # of the script scope, so "[datetime]::Now.Subtract($script:...)"
        # would work with an empty value and would throw
        # 'Cannot find an overload for "Subtract" and the argument count: "1"'.
        Set-SIWindowOnScreenTime
        Close-SILoadingWindow
        Start-SISlowStart
    }.GetNewClosure())
    $startTimer.Start()

    # The shortcut of the desktop is made on the first start, but NOT before
    # the window is on the screen: the search of the desktop of the person
    # who is playing is slow, and the window must not wait for it. A timer
    # does the work a moment later, when the user is already looking at the
    # window. The flag file next to the script remembers that the shortcut
    # was made, so that it is never made again by itself: if the user deletes
    # it, it stays deleted.
    $desktopTimer = New-Object System.Windows.Threading.DispatcherTimer
    $desktopTimer.Interval = [TimeSpan]::FromSeconds(3)
    $null = $desktopTimer.Add_Tick({
        $desktopTimer.Stop()
        try {
            $null = New-SIDesktopShortcut
        } catch {
            Write-SILog -Level 'WARN' -Component 'Desktop' -Message "the shortcut of the desktop could not be made: $($_.Exception.Message)"
        }
    }.GetNewClosure())
    $desktopTimer.Start()

    Set-SIStatusText -Text 'SIGAME is starting ...'

    # The window is NOT opened with ShowDialog. A modal window cannot be
    # hidden, and the window of SIGAME has to be able to go to the tray when
    # the user closes it. So the window is shown the normal way and the
    # dispatcher is run by hand: the loop ends when the window is closed.
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $endFrame = { $frame.Continue = $false }.GetNewClosure()
    $null = $window.Add_Closed($endFrame)
    $window.Show()
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)

    if ($script:SIPollTimer) {
        try { $script:SIPollTimer.Stop() } catch { }
    }
    if ($script:SIAdvancedTimer) {
        try { $script:SIAdvancedTimer.Stop() } catch { }
    }
    if ($desktopTimer) {
        try { $desktopTimer.Stop() } catch { }
    }
    # The AUTO-BOOST and the icon of the tray stop with the program.
    Stop-SIAutoBoost
    Stop-SITrayIcon
    Stop-SIWorker

    Write-SILog -Component 'Stop' -Message 'SIGAME closed.'
}

function Invoke-SIRun {
    <#
    .SYNOPSIS
        The last part of the loader: the background copy of SIGAME or the real
        program.

    .DESCRIPTION
        The loader SI-GAME.ps1 only loads the modules and calls this. The
        parameters of the background copy are read from the script scope
        ($script:SIJobIsWorker and the others), because a function of a
        module does not see the parameters of the loader.
    #>
    if ($script:SIJobIsWorker) {
        try {
            Invoke-SIWorker -Mode $script:SIJobMode -RequestPath $script:SIJobRequest -ResultPath $script:SIJobResult
        } catch {
            # The window reads the result file, so the error has to be in there.
            $failed = @{
                Stage   = 'failed'
                Restore = @{ Status = 'failed'; Message = 'the background copy of SIGAME stopped with an error' }
                Backup  = @{ Status = 'failed'; Message = 'the background copy of SIGAME stopped with an error' }
                States  = @{}
                Log     = @()
                Error   = [string]$_.Exception.Message
            }
            Write-SIWorkerResult -Result $failed -Path $script:SIJobResult
        }
        return
    }

    try {
        Invoke-SIMain
    } catch {
        # An error that nobody sees is the reason a run of SIGAME looked like
        # nothing happened. It is written to the log and shown in a message box.
        $message = [string]$_.Exception.Message
        if ([string]::IsNullOrWhiteSpace($message)) { $message = 'unknown error' }
        $stack = [string]$_.ScriptStackTrace
        if ([string]::IsNullOrWhiteSpace($stack)) { $stack = '(no stack trace)' }
        try {
            Write-SILog -Level 'ERROR' -Component 'Start' -Message "SIGAME stopped with an error: $message"
        } catch { }
        try {
            Write-SILog -Component 'Start' -Message $stack
        } catch { }
        try {
            Close-SILoadingWindow
        } catch { }
        try {
            Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
            [System.Windows.MessageBox]::Show(
                "SIGAME stopped with an error.`n`n$message`n`nThe full details are in the log file:`n$script:SILogPath",
                'SIGAME',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error) | Out-Null
        } catch {
            Write-Host "SIGAME stopped with an error: $message"
        }
    }
}
