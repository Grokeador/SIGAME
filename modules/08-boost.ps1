# ---------------------------------------------------------------------------
#  SIGAME - module 08: the boost, the games and the share card
#
#  The boost closes only the programs the user has ticked, the games of the
#  computer are found by themselves and the result can be written as a
#  picture to share.
# ---------------------------------------------------------------------------
# ============= 12. ROUND 6: BOOST, GAMES, BOTTLENECK, SHARE CARD ===========
#
#  Everything that round 6 adds to SIGAME. The window speaks the language of
#  Windows, the boost closes only the programs the user has ticked, the games
#  of the computer are found by themselves, the limit of the machine is told
#  honestly and the result can be written as a picture to share.

# --- the progress bar -----------------------------------------------------

function Set-SIProgress {
    <#
    .SYNOPSIS
        Moves the progress bar of the window and writes the name of the step
        that is running now. At the end the bar is yellow and says DONE.

    .DESCRIPTION
        There is no sound: the window only shows what is happening, so that
        a slow machine never looks like a frozen one.
    #>
    param(
        [int]$Percent = -1,
        [string]$Step = '',
        [switch]$Done
    )
    if ($script:SIProgress) {
        try {
            if ($Percent -ge 0) {
                $value = $Percent
                if ($value -lt 0) { $value = 0 }
                if ($value -gt 100) { $value = 100 }
                $script:SIProgress.Value = $value
            }
            $script:SIProgress.Foreground = Get-SIBrush -Hex $script:SIColors.Accent
        } catch { }
    }
    if ($script:SIProgressText) {
        try {
            if ($Done) {
                $script:SIProgressText.Text = (Get-SIText -Key 'StatusDone')
                $script:SIProgressText.Foreground = Get-SIBrush -Hex $script:SIColors.Accent
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Step)) {
                $script:SIProgressText.Text = $Step
                $script:SIProgressText.Foreground = Get-SIBrush -Hex $script:SIColors.Text
            }
        } catch { }
    }
}

function Reset-SIProgress {
    <#
    .SYNOPSIS
        Puts the progress bar back to the start.
    #>
    param([string]$Step = '')
    if ($script:SIProgress) {
        try {
            $script:SIProgress.Value = 0
            $script:SIProgress.Foreground = Get-SIBrush -Hex $script:SIColors.Accent
        } catch { }
    }
    if ($script:SIProgressText) {
        try {
            $script:SIProgressText.Text = $Step
            $script:SIProgressText.Foreground = Get-SIBrush -Hex $script:SIColors.Muted
        } catch { }
    }
}

# --- the line of trust ----------------------------------------------------

function Update-SITrustFooter {
    <#
    .SYNOPSIS
        The line of trust at the bottom of the window (round 6, point 6).

    .DESCRIPTION
        "Open source. Every change can be undone. Restore point created:
        <time>". When the restore point is not there yet, the line says that
        it is still on its way. It never claims a restore point that does not
        exist.
    #>
    param([string]$RestorePointAt = '')

    if (-not $RestorePointAt) { $RestorePointAt = $script:SIRestorePointAt }
    $text = ''
    if ($RestorePointAt) {
        $text = Get-SITextFormat -Key 'TrustFooter' -Arguments @($RestorePointAt)
    }
    else {
        $text = Get-SIText -Key 'TrustFooterWaiting'
    }
    # Get-SIElement is in the module 06-window.ps1, and the background copy
    # of SIGAME does not read that module. The call is protected, so that the
    # line of the trust can never break a run.
    $element = $null
    try { $element = Get-SIElement -Name 'TrustText' } catch { }
    if ($element) {
        try { $element.Text = $text } catch { }
    }
}

# --- the boost list -------------------------------------------------------

function Get-SIBoostState {
    <#
    .SYNOPSIS
        The boost list and the last boost, from SI-GAME-boost.json.

    .DESCRIPTION
        The file is written next to the script, like the other files of SI
        GAME. It holds the programs the user has ticked (so that the ticks
        are remembered) and what the last boost closed (so that GAME OVER can
        open them again).
    #>
    $state = @{
        Ticked         = @()
        Closed         = @()
        PreviousScheme = ''
        Plan           = ''
        At             = ''
        AutoBoost      = $null
        Configured     = $false
        Games          = @()
    }
    if (-not [System.IO.File]::Exists($script:SIBoostPath)) { return $state }
    try {
        $raw = [System.IO.File]::ReadAllText($script:SIBoostPath, [System.Text.Encoding]::UTF8)
        # The empty file is checked BEFORE the byte order mark is taken away:
        # an empty file has no content, and $null has no method to call.
        if ([string]::IsNullOrWhiteSpace($raw)) { return $state }
        $raw = $raw.TrimStart([char]0xFEFF)
        $parsed = ConvertTo-SIPlain (ConvertFrom-Json $raw)
        if ($parsed -is [System.Collections.IDictionary]) {
            if ($parsed.Contains('Ticked')) { $state['Ticked'] = @($parsed['Ticked']) }
            if ($parsed.Contains('Closed')) { $state['Closed'] = @($parsed['Closed']) }
            if ($parsed.Contains('PreviousScheme')) { $state['PreviousScheme'] = [string]$parsed['PreviousScheme'] }
            if ($parsed.Contains('Plan')) { $state['Plan'] = [string]$parsed['Plan'] }
            if ($parsed.Contains('At')) { $state['At'] = [string]$parsed['At'] }
            # The AUTO-BOOST (round 8): the choice of the user, the sign that
            # the boost list was set at least once, and the games that the
            # user added with the picker.
            if ($parsed.Contains('AutoBoost')) {
                $value = $parsed['AutoBoost']
                if ($null -ne $value) { $state['AutoBoost'] = [bool]$value }
            }
            if ($parsed.Contains('Configured')) { $state['Configured'] = [bool]$parsed['Configured'] }
            if ($parsed.Contains('Games')) { $state['Games'] = @($parsed['Games']) }
        }
    } catch { }
    return $state
}

function Save-SIBoostState {
    <#
    .SYNOPSIS
        Writes the boost list in SI-GAME-boost.json.
    #>
    param($State)

    try {
        $json = $State | ConvertTo-Json -Depth 8
        $temp = $script:SIBoostPath + '.tmp'
        [System.IO.File]::WriteAllText($temp, $json, [System.Text.Encoding]::UTF8)
        if ([System.IO.File]::Exists($script:SIBoostPath)) {
            [System.IO.File]::Delete($script:SIBoostPath)
        }
        [System.IO.File]::Move($temp, $script:SIBoostPath)
        return $true
    } catch {
        Write-SILog -Level 'WARN' -Component 'Boost' -Message "The boost list could not be saved: $($_.Exception.Message)"
        return $false
    }
}

function Get-SIBoostCandidates {
    <#
    .SYNOPSIS
        The background programs that are running right now.

    .DESCRIPTION
        Only the programs that eat memory in the background while a game is
        played: the browsers, the web helpers of the launchers, OneDrive and
        Teams.

        The Discord overlay is NOT in this list: closing Discord would close
        the overlay the owner records with, so SIGAME never touches it.
    #>
    $known = @(
        @{ Id = 'chrome';   Name = 'Google Chrome';         Process = 'chrome' }
        @{ Id = 'msedge';   Name = 'Microsoft Edge';         Process = 'msedge' }
        @{ Id = 'firefox';  Name = 'Mozilla Firefox';        Process = 'firefox' }
        @{ Id = 'brave';    Name = 'Brave';                  Process = 'brave' }
        @{ Id = 'opera';    Name = 'Opera';                  Process = 'opera' }
        @{ Id = 'vivaldi';  Name = 'Vivaldi';                Process = 'vivaldi' }
        @{ Id = 'onedrive'; Name = 'OneDrive';               Process = 'OneDrive' }
        @{ Id = 'teams';    Name = 'Microsoft Teams';        Process = 'ms-teams' }
        @{ Id = 'teamsnew'; Name = 'Microsoft Teams (new)';  Process = 'Teams' }
        @{ Id = 'steamweb'; Name = 'Steam web helper';       Process = 'steamwebhelper' }
        @{ Id = 'epicweb';  Name = 'Epic Games web helper';  Process = 'EpicWebHelper' }
        @{ Id = 'eaweb';    Name = 'EA app helper';          Process = 'EABackgroundService' }
        @{ Id = 'battle';   Name = 'Battle.net helper';      Process = 'Agent' }
    )

    $result = @()
    # The list of the processes is read ONCE: asking for every name would
    # walk through the whole list of the processes again and again.
    $wanted = @{}
    foreach ($item in $known) { $wanted[$item.Process.ToLowerInvariant()] = $true }
    $running = @{}
    try {
        foreach ($process in @(Get-Process -ErrorAction SilentlyContinue)) {
            $key = ''
            try { $key = ([string]$process.ProcessName).ToLowerInvariant() } catch { continue }
            if (-not $wanted.ContainsKey($key)) { continue }
            if ($running.ContainsKey($key)) { continue }
            $path = ''
            try { $path = [string]$process.Path } catch { $path = '' }
            $running[$key] = $path
        }
    } catch { }

    foreach ($item in $known) {
        $key = $item.Process.ToLowerInvariant()
        if (-not $running.ContainsKey($key)) { continue }
        $result += [pscustomobject]@{
            Id      = $item.Id
            Name    = $item.Name
            Process = $item.Process
            Path    = [string]$running[$key]
        }
    }
    return $result
}

function Get-SIBoostPowerPlans {
    <#
    .SYNOPSIS
        The power plans of this computer.
    #>
    $list = @()
    try {
        $output = & powercfg.exe /list 2>$null
        foreach ($line in @($output)) {
            $text = [string]$line
            if ($text -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                $guid = $Matches[1]
                $name = ''
                if ($text -match '\(([^()]+)\)') { $name = $Matches[1].Trim() }
                $list += [pscustomobject]@{ Guid = $guid; Name = $name }
            }
        }
    } catch { }
    return $list
}

function Get-SIActivePowerScheme {
    <#
    .SYNOPSIS
        The GUID of the power plan that is on right now.
    #>
    $guid = ''
    try {
        $output = & powercfg.exe /getactivescheme 2>$null
        foreach ($line in @($output)) {
            $text = [string]$line
            if ($text -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                $guid = $Matches[1]
            }
        }
    } catch { }
    return $guid
}

function Set-SIBoostPowerPlan {
    <#
    .SYNOPSIS
        Switches the power plan to Ultimate Performance (or to High
        performance) and remembers the one that was on before.

    .DESCRIPTION
        Only desktops do this: on a laptop the plan that gives the most
        performance is the one that eats the battery, so SIGAME leaves the
        laptop alone.

        The Ultimate Performance plan is hidden on many computers, but it can
        still be switched on with its GUID. When that does not work, the High
        performance plan is used. The plan is only reported as changed when
        Windows says that it is the active one.
    #>
    $result = @{ Changed = $false; Name = ''; Scheme = ''; Previous = ''; Message = '' }

    $current = Get-SIActivePowerScheme
    $result['Previous'] = $current

    if (Get-SIIsLaptop) {
        $result.Message = 'This machine looks like a laptop, so the power plan was not changed.'
        return $result
    }

    $ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    $high = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'

    $plans = @(Get-SIBoostPowerPlans)
    $target = ''
    $name = ''
    foreach ($plan in $plans) {
        if ($plan.Guid -ieq $ultimate -or $plan.Name -match '(?i)Ultimate Performance|Prestazioni eccellenti|Desempenho M|Rendimiento m|Performances optimales|Ultimative Leistung') {
            $target = $plan.Guid
            $name = $plan.Name
            break
        }
    }
    if (-not $target) {
        # Duplicate the Ultimate Performance template if not present yet.
        try {
            $dupOut = (& powercfg.exe /duplicatescheme $ultimate 2>$null) -join ' '
            if ($dupOut -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                $target = $Matches[1]
                $name = 'Ultimate Performance'
            }
        } catch { }
    }
    if (-not $target) {
        foreach ($plan in $plans) {
            if ($plan.Guid -ieq $high -or $plan.Name -match '(?i)High performance|Prestazioni elevate|Alto desempenho|Alto rendimiento|Performances .lev|H.chstleistung') {
                $target = $plan.Guid
                $name = $plan.Name
                break
            }
        }
    }
    if (-not $target) {
        $target = $ultimate
        $name = 'Ultimate Performance'
    }
    if (-not $name) { $name = 'Ultimate Performance' }
    if ($current -and $current -eq $target) {
        $result['Name'] = $name
        $result['Scheme'] = $target
        $result['Message'] = "The power plan $name was already on."
        return $result
    }

    $ok = $false
    try {
        & powercfg.exe /setactive $target 2>$null | Out-Null
        $ok = ($LASTEXITCODE -eq 0)
    } catch { $ok = $false }

    if ($ok) {
        # Windows is asked whether the plan really changed.
        $now = Get-SIActivePowerScheme
        if ($now -and $now -ne $target) { $ok = $false }
    }

    $result['Name'] = $name
    $result['Scheme'] = $target
    if ($ok) {
        $result['Changed'] = $true
        $result['Message'] = "The power plan is now $name."
    } else {
        $result['Message'] = "The power plan $name could not be switched on."
    }
    return $result
}

function Invoke-SIBoost {
    <#
    .SYNOPSIS
        GAME BOOST: closes the ticked background programs, switches the power
        plan and says how much memory was freed.

    .DESCRIPTION
        Only the programs the user has ticked in the boost list are closed.
        Nothing is ticked by default, so the first click of GAME BOOST does
        not close anything that the user did not choose.

        The programs are asked to close first, so that a browser can save its
        session. Only when they do not go away are they stopped.

        Everything that is done is written in SI-GAME-boost.json, so that
        GAME OVER can put everything back.

        With -Auto the boost is done by the AUTO-BOOST (round 8), because a
        game started. In that case the boost list is never opened: the user
        is not there to see it.
    #>
    param([switch]$Auto)

    if ($script:SIBoostRunning) { return }
    if (-not $script:SIPrepared) {
        Set-SIStatusText -Text (Get-SIText -Key 'StatusWorking')
        return
    }
    $script:SIBoostRunning = $true
    try {
        $state = Get-SIBoostState
        $ticked = @($state['Ticked'])
        $apps = @(Get-SIBoostCandidates)

        $toClose = @()
        foreach ($app in $apps) {
            if ($ticked -contains $app.Id) { $toClose += $app }
        }

        Reset-SIProgress -Step 'GAME BOOST: reading the free memory ...'
        Invoke-SIUIPump -Milliseconds 20
        $before = Get-SIFreeRamMB

        $closed = @()
        if ($toClose.Count -gt 0) {
            Set-SIProgress -Percent 10 -Step 'GAME BOOST: closing the ticked programs ...'
            Invoke-SIUIPump -Milliseconds 20
            foreach ($app in $toClose) {
                $stopped = $false
                try {
                    $running = @(Get-Process -Name $app.Process -ErrorAction SilentlyContinue)
                    foreach ($process in $running) {
                        try { [void]$process.CloseMainWindow() } catch { }
                    }
                    # A short wait, so that a browser can save its session.
                    $waited = 0
                    while ($waited -lt 1500) {
                        Start-Sleep -Milliseconds 250
                        $waited += 250
                        if (@(Get-Process -Name $app.Process -ErrorAction SilentlyContinue).Count -eq 0) {
                            $stopped = $true
                            break
                        }
                    }
                    if (-not $stopped) {
                        $running = @(Get-Process -Name $app.Process -ErrorAction SilentlyContinue)
                        foreach ($process in $running) {
                            try { Stop-Process -Id $process.Id -Force -ErrorAction Stop } catch { }
                        }
                        Start-Sleep -Milliseconds 400
                        $stopped = (@(Get-Process -Name $app.Process -ErrorAction SilentlyContinue).Count -eq 0)
                    }
                } catch { $stopped = $false }
                if ($stopped) {
                    $closed += @{ Id = $app.Id; Name = $app.Name; Process = $app.Process; Path = $app.Path }
                    Write-SILog -Component 'Boost' -Message "The program $($app.Name) was closed for the boost."
                } else {
                    Write-SILog -Level 'WARN' -Component 'Boost' -Message "The program $($app.Name) did not close."
                }
            }
        }

        if ($toClose.Count -eq 0) {
            # Nothing is ticked: no program is closed, the power plan is not
            # changed and no number of memory is written. The difference of
            # the memory can be negative, and "+-2 MB" is not a number that
            # means something. The list of the programs that are running now
            # is shown, so that the user can tick the ones he wants to close
            # and press GAME BOOST again.
            if ($Auto) {
                # The AUTO-BOOST: the list is not opened, because the user
                # did not ask for the boost right now.
                Write-SILog -Level 'WARN' -Component 'Boost' -Message 'the AUTO-BOOST found a game, but nothing is ticked in the boost list, so no program was closed and the power plan was not changed.'
                Set-SIProgress -Percent 0 -Step 'GAME BOOST: nothing is ticked in the boost list.'
                return
            }
            Show-SIBoostList
            $label = Get-SIText -Key 'BoostPickLabel'
            $message = Get-SIText -Key 'BoostPickFirst'
            if ($apps.Count -eq 0) {
                $label = Get-SIText -Key 'BoostNothing'
                $message = Get-SIText -Key 'BoostNothing'
            }
            $boostText = Get-SIElement -Name 'BoostResult'
            if ($boostText) { $boostText.Text = $label }
            $planText = Get-SIElement -Name 'BoostPlan'
            if ($planText) { $planText.Text = '' }
            Set-SIProgress -Percent 0 -Step 'GAME BOOST: no program is ticked yet.'
            Set-SIStatusText -Text $message
            Write-SILog -Level 'WARN' -Component 'Boost' -Message 'Nothing is ticked, so no program was closed and the power plan was not changed. The boost list was opened so that the user can tick the programs and press GAME BOOST again.'
            return
        }

        Set-SIProgress -Percent 55 -Step 'GAME BOOST: switching the power plan ...'
        Invoke-SIUIPump -Milliseconds 20
        $plan = Set-SIBoostPowerPlan
        if ($plan.Changed) {
            Write-SILog -Component 'Boost' -Message $plan.Message
        } else {
            Write-SILog -Level 'WARN' -Component 'Boost' -Message $plan.Message
        }

        Set-SIProgress -Percent 80 -Step 'GAME BOOST: measuring the free memory ...'
        Invoke-SIUIPump -Milliseconds 20
        $after = Get-SIFreeRamMB
        $freed = 0
        if ($before -ge 0 -and $after -ge 0) { $freed = [int]$after - [int]$before }
        # The number of the memory is never negative: if the computer used
        # more memory while the boost was working, 0 is written and never a
        # number with a minus sign in front of it.
        if ($freed -lt 0) { $freed = 0 }

        $newState = @{
            Ticked         = $ticked
            Closed         = $closed
            PreviousScheme = [string]$plan.Previous
            Plan           = [string]$plan.Name
            At             = (Get-Date).ToString('s')
            # The AUTO-BOOST (round 8) keeps its choice and the games that
            # the user added with the picker.
            AutoBoost      = $state['AutoBoost']
            Configured     = $state['Configured']
            Games          = @($state['Games'])
        }
        Save-SIBoostState -State $newState | Out-Null
        $script:SIBoostIsActive = $true

        $result = Get-SITextFormat -Key 'BoostResult' -Arguments @($freed)
        $boostText = Get-SIElement -Name 'BoostResult'
        if ($boostText) { $boostText.Text = $result }
        $planText = Get-SIElement -Name 'BoostPlan'
        if ($planText) { $planText.Text = (Get-SITextFormat -Key 'BoostPlan' -Arguments @([string]$plan.Name)) }

        Set-SIProgress -Percent 100 -Done
        Set-SIStatusText -Text $result
        Write-SILog -Level 'OK' -Component 'Boost' -Message "GAME BOOST is on. $result"
    } catch {
        Set-SIStatusText -Text ("GAME BOOST stopped: " + [string]$_.Exception.Message)
        Write-SILog -Level 'ERROR' -Component 'Boost' -Message "GAME BOOST stopped: $($_.Exception.Message)"
        Set-SIProgress -Done
    } finally {
        $script:SIBoostRunning = $false
    }
}

function Invoke-SIGameOver {
    <#
    .SYNOPSIS
        GAME OVER: puts the power plan back and opens the programs that the
        boost closed.

    .DESCRIPTION
        The other side of GAME BOOST. Everything that is put back is written
        in the log, so the user can see what happened.

        With -Auto the GAME OVER is done by the AUTO-BOOST (round 8), because
        the game ended.
    #>
    param([switch]$Auto)

    if ($script:SIBoostRunning) { return }
    $script:SIBoostRunning = $true
    try {
        $state = Get-SIBoostState

        Reset-SIProgress -Step 'GAME OVER: putting the power plan back ...'
        Invoke-SIUIPump -Milliseconds 20
        $previous = [string]$state['PreviousScheme']
        if ($previous) {
            try {
                & powercfg.exe /setactive $previous 2>$null | Out-Null
                $now = Get-SIActivePowerScheme
                if ($now -eq $previous) {
                    Write-SILog -Component 'Boost' -Message "The power plan $previous is on again."
                } else {
                    Write-SILog -Level 'WARN' -Component 'Boost' -Message 'The power plan could not be put back.'
                }
            } catch {
                Write-SILog -Level 'WARN' -Component 'Boost' -Message "The power plan could not be put back: $($_.Exception.Message)"
            }
        }

        Set-SIProgress -Percent 50 -Step 'GAME OVER: opening the programs again ...'
        Invoke-SIUIPump -Milliseconds 20
        $closed = @($state['Closed'])
        foreach ($item in $closed) {
            $path = ''
            $name = ''
            if ($item -is [System.Collections.IDictionary]) {
                if ($item.Contains('Path')) { $path = [string]$item['Path'] }
                if ($item.Contains('Name')) { $name = [string]$item['Name'] }
            }
            if (-not $path) { continue }
            try {
                if (Test-Path -LiteralPath $path) {
                    Start-Process -FilePath $path -ErrorAction Stop | Out-Null
                    Write-SILog -Component 'Boost' -Message "The program $name is open again."
                } else {
                    Write-SILog -Level 'WARN' -Component 'Boost' -Message "The program $name is not on the disk any more, so it could not be opened again."
                }
            } catch {
                Write-SILog -Level 'WARN' -Component 'Boost' -Message "The program $name could not be opened again: $($_.Exception.Message)"
            }
        }

        $state['Closed'] = @()
        $state['PreviousScheme'] = ''
        Save-SIBoostState -State $state | Out-Null
        $script:SIBoostIsActive = $false

        $boostText = Get-SIElement -Name 'BoostResult'
        if ($boostText) { $boostText.Text = (Get-SIText -Key 'GameOverDone') }
        $planText = Get-SIElement -Name 'BoostPlan'
        if ($planText) { $planText.Text = '' }

        Set-SIProgress -Percent 100 -Done
        Set-SIStatusText -Text (Get-SIText -Key 'GameOverDone')
        Write-SILog -Level 'OK' -Component 'Boost' -Message (Get-SIText -Key 'GameOverDone')
    } catch {
        Set-SIStatusText -Text ("GAME OVER stopped: " + [string]$_.Exception.Message)
        Write-SILog -Level 'ERROR' -Component 'Boost' -Message "GAME OVER stopped: $($_.Exception.Message)"
        Set-SIProgress -Done
    } finally {
        $script:SIBoostRunning = $false
    }
}

# --- the games of this computer -------------------------------------------

function Get-SIGameGpuState {
    <#
    .SYNOPSIS
        $true when Windows already uses the fast video card for this .exe.
    #>
    param([string]$ExePath)
    if (-not $ExePath) { return $false }
    try {
        $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
        $target = ConvertTo-SIRegistryTarget -Path $path
        $key = $target.Hive.OpenSubKey($target.Sub, $false)
        if ($key) {
            try {
                $value = $key.GetValue($ExePath, $null)
                if ($value) { return ([string]$value -like 'GpuPreference=2*') }
            } finally { $key.Close() }
        }
    } catch { }
    return $false
}

function Get-SIGameFullscreenState {
    <#
    .SYNOPSIS
        $true when the fullscreen optimizations are already off for this .exe.
    #>
    param([string]$ExePath)
    if (-not $ExePath) { return $false }
    try {
        $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
        $target = ConvertTo-SIRegistryTarget -Path $path
        $key = $target.Hive.OpenSubKey($target.Sub, $false)
        if ($key) {
            try {
                $value = $key.GetValue($ExePath, $null)
                if ($value) { return ([string]$value -like '*DISABLEDXMAXIMIZEDWINDOWEDMODE*') }
            } finally { $key.Close() }
        }
    } catch { }
    return $false
}

function Set-SIGameGpuPreferenceOff {
    <#
    .SYNOPSIS
        Takes the "high performance" GPU preference away again.
    #>
    param([Parameter(Mandatory = $true)][string]$ExePath)
    $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    Remove-SIRegistryValue -Path $path -Name $ExePath | Out-Null
}

function Set-SIGameFullscreenOptimizationsOn {
    <#
    .SYNOPSIS
        Puts the fullscreen optimizations back on.
    #>
    param([Parameter(Mandatory = $true)][string]$ExePath)
    $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    Remove-SIRegistryValue -Path $path -Name $ExePath | Out-Null
}

function Get-SISteamGames {
    <#
    .SYNOPSIS
        The games of the Steam libraries of this computer.

    .DESCRIPTION
        The libraries are read from "steamapps\libraryfolders.vdf" and the
        games from the "appmanifest_*.acf" files of every library.

        A file that cannot be read is skipped: a broken file must never stop
        the window.
    #>
    $games = @()

    $roots = @()
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($programFilesX86) { $roots += (Join-Path $programFilesX86 'Steam') }
    if ($env:ProgramFiles) { $roots += (Join-Path $env:ProgramFiles 'Steam') }
    $roots += 'C:\Program Files (x86)\Steam'
    $roots += 'C:\Program Files\Steam'

    $seen = @{}
    foreach ($root in $roots) {
        if (-not $root) { continue }
        if ($seen.ContainsKey($root)) { continue }
        $seen[$root] = $true
        if (-not (Test-Path -LiteralPath $root)) { continue }

        # The libraries of Steam.
        $libraries = @()
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            try {
                $text = Get-Content -LiteralPath $vdf -Raw -ErrorAction Stop
                $found = [regex]::Matches([string]$text, '"path"\s*"([^"]+)"')
                foreach ($match in $found) {
                    $path = $match.Groups[1].Value
                    $path = $path -replace '\\\\', '\'
                    $path = $path.TrimEnd('\')
                    if ($path -and (Test-Path -LiteralPath $path)) { $libraries += $path }
                }
            } catch { }
        }
        if (-not ($libraries -contains $root)) { $libraries += $root }

        foreach ($library in $libraries) {
            $apps = Join-Path $library 'steamapps'
            if (-not (Test-Path -LiteralPath $apps)) { continue }
            $files = @()
            try {
                $files = @(Get-ChildItem -LiteralPath $apps -Filter 'appmanifest_*.acf' -File -ErrorAction SilentlyContinue)
            } catch { }
            foreach ($file in $files) {
                $acf = ''
                try { $acf = [string](Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop) } catch { continue }
                if (-not $acf) { continue }

                $name = ''
                $appId = ''
                $install = ''
                if ($acf -match '(?m)^\s*"name"\s+"([^"]+)"') { $name = $Matches[1] }
                if ($acf -match '(?m)^\s*"appid"\s+"(\d+)"') { $appId = $Matches[1] }
                if ($acf -match '(?m)^\s*"installdir"\s+"([^"]+)"') { $install = $Matches[1] }
                if (-not $name) { continue }

                $folder = ''
                if ($install) { $folder = Join-Path (Join-Path $apps 'common') $install }

                $exe = ''
                if ($acf -match '(?m)^\s*"executable"\s+"([^"]+)"') {
                    $exe = Join-Path $folder $Matches[1]
                }
                if ((-not $exe) -or (-not (Test-Path -LiteralPath $exe))) {
                    $exe = ''
                    if ($folder -and (Test-Path -LiteralPath $folder)) {
                        try {
                            $found = @(Get-ChildItem -LiteralPath $folder -Filter '*.exe' -File -ErrorAction SilentlyContinue |
                                Where-Object { $_.Name -notlike 'Uninstall*' -and $_.Name -notlike 'UnityCrashHandler*' -and $_.Name -notlike 'UE4Editor*' -and $_.Name -notlike 'CrashReportClient*' } |
                                Sort-Object -Property Length -Descending)
                            if ($found.Count -gt 0) { $exe = $found[0].FullName }
                        } catch { }
                    }
                }
                if (-not $exe) { continue }

                $games += [pscustomobject]@{
                    Id     = ('steam-' + $appId)
                    Name   = $name
                    Store  = 'Steam'
                    Exe    = $exe
                    Folder = $folder
                }
            }
        }
    }
    return $games
}

function Get-SIEpicGames {
    <#
    .SYNOPSIS
        The games of the Epic Games Launcher of this computer.

    .DESCRIPTION
        The launcher keeps one ".item" file per game in
        "C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests". Every file is
        a small JSON text with the name of the game and the .exe that starts
        it.
    #>
    $games = @()

    $manifest = 'C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests'
    if (-not (Test-Path -LiteralPath $manifest)) { return $games }

    $files = @()
    try {
        $files = @(Get-ChildItem -LiteralPath $manifest -Filter '*.item' -File -ErrorAction SilentlyContinue)
    } catch { }

    foreach ($file in $files) {
        $raw = ''
        try { $raw = [string](Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop) } catch { continue }
        $raw = $raw.TrimStart([char]0xFEFF)
        if (-not $raw) { continue }

        $data = $null
        try { $data = ConvertFrom-Json $raw } catch { continue }
        if (-not $data) { continue }

        $name = ''
        $exe = ''
        $location = ''
        $launch = ''
        try { $name = [string]$data.DisplayName } catch { $name = '' }
        try { $exe = [string]$data.LaunchExecutable } catch { $exe = '' }
        try { $location = [string]$data.InstallLocation } catch { $location = '' }
        try { $launch = [string]$data.Launch } catch { $launch = '' }
        if (-not $name) { continue }

        if ($exe -and $location -and (-not (Test-Path -LiteralPath $exe))) {
            $candidate = Join-Path $location $exe
            if (Test-Path -LiteralPath $candidate) { $exe = $candidate }
        }
        if ((-not $exe) -and $launch -and $location) {
            # The folder has to be there: Join-Path throws when it is empty,
            # and that would take the whole list of the games away.
            $candidate = Join-Path $location $launch
            if (Test-Path -LiteralPath $candidate) { $exe = $candidate }
        }
        if (-not $exe) { continue }

        $games += [pscustomobject]@{
            Id     = ('epic-' + $file.BaseName)
            Name   = $name
            Store  = 'Epic Games'
            Exe    = $exe
            Folder = $location
        }
    }
    return $games
}

function Get-SIGameLibrary {
    <#
    .SYNOPSIS
        The games of this computer: Steam and Epic.
    #>
    $games = @()
    $games += @(Get-SISteamGames)
    $games += @(Get-SIEpicGames)
    return $games
}

# --- the honest limit of this computer -------------------------------------

function Test-SIGpuIsIntegrated {
    <#
    .SYNOPSIS
        $true when the name of a video card belongs to an integrated one.

    .DESCRIPTION
        The name of the card is all there is to judge with, because Windows
        does not say in a simple way what kind of card it is. The dedicated
        cards are recognized first, so that a Radeon RX 580 is never taken
        for an integrated one.
    #>
    param([string]$Name)
    if (-not $Name) { return $false }
    $text = $Name.ToLowerInvariant()

    # The dedicated cards first.
    foreach ($needle in @('rtx ', 'gtx ', 'geforce', 'quadro', 'firepro', 'radeon pro', 'radeon rx', 'rx 5', 'rx 6', 'rx 7', 'radeon hd 7', 'radeon hd 8', 'radeon hd 9')) {
        if ($text.Contains($needle)) { return $false }
    }
    # Then the integrated ones.
    foreach ($needle in @('intel(r) hd graphics', 'intel(r) uhd graphics', 'intel(r) iris', 'intel(r) graphics', 'intel hd', 'intel uhd', 'intel iris', 'amd radeon(tm) graphics', 'amd radeon graphics', 'microsoft basic', 'mali', 'adreno', 'powervr')) {
        if ($text.Contains($needle)) { return $true }
    }
    return $false
}

function Get-SISystemDiskType {
    <#
    .SYNOPSIS
        The type of the disk of the system drive: HDD, SSD or unknown.

    .DESCRIPTION
        The disk of the system drive is found with the partition of the drive
        letter, and its type with Get-PhysicalDisk, the same place where
        Windows keeps the MediaType. When that is not there, the name of the
        disk is used as a second opinion.
    #>
    $type = 'unknown'
    $name = ''

    $friendly = ''
    try {
        if (Test-SIHasCommand 'Get-Partition') {
            $letter = ''
            if ($env:SystemDrive) {
                $letter = $env:SystemDrive.TrimStart(':')
                if ($letter.Length -gt 1) { $letter = $letter.Substring(0, 1) }
            }
            if ($letter) {
                $partition = Get-Partition -DriveLetter $letter -ErrorAction Stop | Select-Object -First 1
                if ($partition) {
                    $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction Stop | Select-Object -First 1
                    if ($disk) { $friendly = [string]$disk.FriendlyName }
                }
            }
        }
    } catch { }

    try {
        if (Test-SIHasCommand 'Get-PhysicalDisk') {
            $physical = @(Get-PhysicalDisk -ErrorAction Stop)
            foreach ($disk in $physical) {
                $diskName = [string]$disk.FriendlyName
                if ($friendly -and $diskName -and ($diskName -eq $friendly)) {
                    $type = [string]$disk.MediaType
                    $name = $diskName
                    break
                }
            }
            if (($type -eq 'unknown') -and (-not $friendly) -and ($physical.Count -gt 0)) {
                # It is not known which disk it is, so the slowest one is
                # taken: a hard disk is a real limit.
                foreach ($disk in $physical) {
                    if ([string]$disk.MediaType -eq 'HDD') { $type = 'HDD'; $name = [string]$disk.FriendlyName; break }
                }
                if ($type -eq 'unknown') {
                    $type = [string]$physical[0].MediaType
                    $name = [string]$physical[0].FriendlyName
                }
            }
        }
    } catch { }

    if ($type -eq 'unknown' -or $type -eq 'Unspecified') {
        # The second opinion: the name of the disk.
        try {
            $drive = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop | Select-Object -First 1
            if ($drive) {
                $model = [string]$drive.Model
                if (-not $name) { $name = $model }
                if ($model -match 'SSD|Solid State|NVMe|M\.2') { $type = 'SSD' }
                else { $type = 'HDD' }
            }
        } catch { }
    }

    return @{ Type = $type; Name = $name }
}

function Get-SIBottleneck {
    <#
    .SYNOPSIS
        The honest limit of this computer (round 6, point 3).

    .DESCRIPTION
        The CPU, the video card, the size of the memory, the type of the
        system disk and the free space on it are read, and ONE line says what
        the biggest limit is.

        The rules, in this order:
          the memory is less than 8 GB
          the system disk is a hard disk
          less than 15% of the system disk is free
          there is only an integrated video card

        There is no score and nothing is made up: what is not there is not
        written.
    #>
    $result = @{
        Cpu         = 'unknown'
        Gpu         = 'unknown'
        RamGB       = 0
        RamText     = 'unknown'
        DiskType    = 'unknown'
        DiskName    = ''
        FreePercent = -1
        FreeGB      = -1
        Integrated  = $false
        LimitKey    = ''
        Line        = ''
        Details     = ''
    }

    # The CPU.
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpu) { $result.Cpu = [string]$cpu.Name }
    } catch { }

    # The video cards.
    $cards = @()
    try { $cards = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop) } catch { }
    $names = @()
    $integrated = $true
    foreach ($card in $cards) {
        $name = ''
        try { $name = [string]$card.Name } catch { $name = '' }
        if ($name) { $names += $name }
        if (-not (Test-SIGpuIsIntegrated -Name $name)) { $integrated = $false }
    }
    if ($names.Count -gt 0) { $result.Gpu = ($names -join ' + ') }
    $result.Integrated = ($integrated -and ($cards.Count -gt 0))

    # The memory.
    $ramGB = 0
    try {
        $system = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $ramGB = [int][math]::Round(([double]$system.TotalPhysicalMemory) / 1GB)
    } catch { }
    $result.RamGB = $ramGB
    if ($ramGB -gt 0) { $result.RamText = ('{0} GB' -f $ramGB) }

    # The disk of the system drive.
    $disk = Get-SISystemDiskType
    $result.DiskType = [string]$disk.Type
    $result.DiskName = [string]$disk.Name

    # The free space of the system drive.
    try {
        $letter = $env:SystemDrive
        if ($letter) {
            $logical = @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='" + $letter + "'") -ErrorAction Stop)
            if ($logical.Count -gt 0) {
                $size = [double]$logical[0].Size
                $free = [double]$logical[0].FreeSpace
                if ($size -gt 0) {
                    $result.FreePercent = [int][math]::Floor(($free / $size) * 100)
                    $result.FreeGB = [math]::Round($free / 1GB, 1)
                }
            }
        }
    } catch { }

    # The one line.
    $limit = ''
    if (($ramGB -gt 0) -and ($ramGB -lt 8)) {
        $limit = Get-SITextFormat -Key 'LimitRam' -Arguments @($ramGB)
        $result.LimitKey = 'LimitRam'
    }
    elseif ($result.DiskType -eq 'HDD') {
        $limit = Get-SIText -Key 'LimitHdd'
        $result.LimitKey = 'LimitHdd'
    }
    elseif (($result.FreePercent -ge 0) -and ($result.FreePercent -lt 15)) {
        $limit = Get-SIText -Key 'LimitDisk'
        $result.LimitKey = 'LimitDisk'
    }
    elseif ($result.Integrated) {
        $limit = Get-SIText -Key 'LimitGpu'
        $result.LimitKey = 'LimitGpu'
    }

    if ($limit) {
        $result.Line = Get-SITextFormat -Key 'BottleneckLine' -Arguments @($limit)
    } else {
        $result.Line = Get-SIText -Key 'BottleneckOk'
    }

    $diskText = $result.DiskType
    if ($result.FreePercent -ge 0) { $diskText = ($diskText + ', ' + [string]$result.FreePercent + '% free') }
    $result.Details = Get-SITextFormat -Key 'BottleneckDetails' -Arguments @($result.Cpu, $result.Gpu, $result.RamText, $diskText)

    return $result
}

# --- the share card --------------------------------------------------------

function ConvertTo-SIXamlText {
    <#
    .SYNOPSIS
        Makes a text safe to put inside an attribute of XAML.
    #>
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $out = [string]$Text
    $out = $out.Replace('&', '&amp;')
    $out = $out.Replace('<', '&lt;')
    $out = $out.Replace('>', '&gt;')
    $out = $out.Replace('"', '&quot;')
    return $out
}

function Get-SILogoBitmap {
    <#
    .SYNOPSIS
        The logo of SI NEWS as a frozen picture, $null when there is none.
    #>
    $logo = Join-Path $script:SIRoot 'logo.png'
    if (-not (Test-Path -LiteralPath $logo)) { return $null }
    try {
        $full = (Resolve-Path -LiteralPath $logo -ErrorAction Stop).ProviderPath
        $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bitmap.BeginInit()
        $bitmap.UriSource = [System.Uri]::new($full, [System.UriKind]::Absolute)
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $bitmap.Freeze()
        return $bitmap
    } catch {
        return $null
    }
}

function Save-SIShareCard {
    <#
    .SYNOPSIS
        Writes the share card (round 6, point 4).

    .DESCRIPTION
        A picture of 1200x630 pixels with the numbers of the PROVE IT panel
        before and after, the logo of SI NEWS and the address of the channel.
        The file is written next to the script, like every other file of SI
        GAME, and the folder is opened so that the picture is right there.
    #>
    $path = $script:SISharePath
    $width = 1200
    $height = 630

    $before = $script:SIMeasuresBefore
    $after = $script:SIMeasuresAfter
    if (-not $after) { $after = $before }
    $hasNumbers = ($null -ne $after)

    try {
        # --- the rows with the numbers ---------------------------------------
        $keys = @(
            @{ Key = 'FreeRamMB';     Label = (Get-SIText -Key 'LabelFreeRam') }
            @{ Key = 'StartupAppsOn'; Label = (Get-SIText -Key 'LabelStartupApps') }
            @{ Key = 'DnsMs';         Label = (Get-SIText -Key 'LabelDns') }
            @{ Key = 'SpeedMbps';     Label = (Get-SIText -Key 'LabelSpeed') }
        )
        $rows = ''
        $rowIndex = 1
        foreach ($item in $keys) {
            $valueBefore = ConvertTo-SIXamlText (Get-SIMeasureText -Measures $before -Key $item.Key)
            $valueAfter = ConvertTo-SIXamlText (Get-SIMeasureText -Measures $after -Key $item.Key)
            $label = ConvertTo-SIXamlText $item.Label
            $rows += '<TextBlock Grid.Row="' + $rowIndex + '" Grid.Column="0" Text="' + $label + '" Foreground="#98a0b3" FontSize="23" VerticalAlignment="Center"/>'
            $rows += '<TextBlock Grid.Row="' + $rowIndex + '" Grid.Column="1" Text="' + $valueBefore + '" Foreground="#e9eaf0" FontSize="30" FontWeight="Bold" VerticalAlignment="Center"/>'
            $rows += '<TextBlock Grid.Row="' + $rowIndex + '" Grid.Column="2" Text="-&gt;" Foreground="#ffd23f" FontSize="30" HorizontalAlignment="Center" VerticalAlignment="Center"/>'
            $rows += '<TextBlock Grid.Row="' + $rowIndex + '" Grid.Column="3" Text="' + $valueAfter + '" Foreground="#5ad08a" FontSize="30" FontWeight="Bold" VerticalAlignment="Center"/>'
            $rowIndex++
        }

        $subtitle = Get-SIText -Key 'Subtitle'
        if (-not $hasNumbers) { $subtitle = Get-SIText -Key 'CardNoMeasure' }

        # --- the card ---------------------------------------------------------
        $xaml = @'
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Background="#1b1f29">
  <Grid.RowDefinitions>
    <RowDefinition Height="Auto"/>
    <RowDefinition Height="Auto"/>
    <RowDefinition Height="*"/>
    <RowDefinition Height="Auto"/>
  </Grid.RowDefinitions>
  <Grid.ColumnDefinitions>
    <ColumnDefinition Width="Auto"/>
    <ColumnDefinition Width="*"/>
  </Grid.ColumnDefinitions>
  <Image x:Name="CardLogo" Grid.Row="0" Grid.Column="0" Width="86" Height="86" Margin="44,40,0,0" Stretch="Uniform"/>
  <StackPanel Grid.Row="0" Grid.Column="1" Margin="22,44,0,0">
    <TextBlock Text="%%TITLE%%" Foreground="#ffd23f" FontSize="44" FontWeight="Bold"/>
    <TextBlock Text="%%SUBTITLE%%" Foreground="#98a0b3" FontSize="21" Margin="0,6,0,0"/>
  </StackPanel>
  <Border Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Height="2" Background="#272d3f" Margin="44,26,44,0"/>
  <Grid Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Margin="44,22,44,0">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="240"/>
      <ColumnDefinition Width="*"/>
      <ColumnDefinition Width="64"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>
    <TextBlock Grid.Row="0" Grid.Column="1" Text="%%BEFORE%%" Foreground="#98a0b3" FontSize="21"/>
    <TextBlock Grid.Row="0" Grid.Column="3" Text="%%AFTER%%" Foreground="#98a0b3" FontSize="21"/>
    %%ROWS%%
  </Grid>
  <TextBlock Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="2" Text="%%MADE%%" Foreground="#98a0b3" FontSize="20" Margin="44,0,44,34"/>
</Grid>
'@
        $xaml = $xaml.Replace('%%TITLE%%', (ConvertTo-SIXamlText (Get-SIText -Key 'CardTitle')))
        $xaml = $xaml.Replace('%%SUBTITLE%%', (ConvertTo-SIXamlText $subtitle))
        $xaml = $xaml.Replace('%%BEFORE%%', (ConvertTo-SIXamlText (Get-SIText -Key 'CardBefore')))
        $xaml = $xaml.Replace('%%AFTER%%', (ConvertTo-SIXamlText (Get-SIText -Key 'CardAfter')))
        $xaml = $xaml.Replace('%%MADE%%', (ConvertTo-SIXamlText (Get-SIText -Key 'CardMade')))
        $xaml = $xaml.Replace('%%ROWS%%', $rows)

        $card = [System.Windows.Markup.XamlReader]::Parse($xaml)

        $logo = Get-SILogoBitmap
        if ($logo) {
            try {
                $image = $card.FindName('CardLogo')
                if ($image) { $image.Source = $logo }
            } catch { }
        }

        # --- the picture ------------------------------------------------------
        $card.Measure([System.Windows.Size]::new($width, $height))
        $card.Arrange([System.Windows.Rect]::new(0, 0, $width, $height))
        $card.UpdateLayout()

        $target = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($width, $height, 96.0, 96.0, [System.Windows.Media.PixelFormats]::Pbgra32)
        $target.Render($card)

        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($target))

        $stream = [System.IO.File]::Create($path)
        try {
            $encoder.Save($stream)
        } finally {
            $stream.Close()
        }

        $script:SIShareSaved = $true
        Write-SILog -Level 'OK' -Component 'Card' -Message "The share card was written: $path"

        # The folder is opened, so that the picture is right there.
        # The result of Start-Process goes to Out-Null: without it, the
        # process object stays in the output of the function.
        try {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ('/select,"{0}"' -f $path) -ErrorAction Stop | Out-Null
        } catch {
            try { Start-Process -FilePath (Split-Path -Parent $path) -ErrorAction Stop | Out-Null } catch { }
        }
        return $true
    } catch {
        Write-SILog -Level 'ERROR' -Component 'Card' -Message "The share card could not be written: $($_.Exception.Message)"
        return $false
    }
}
