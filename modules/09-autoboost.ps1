# ---------------------------------------------------------------------------
#  SIGAME - module 09: AUTO-BOOST, the icon of the tray and the shortcut of
#  the desktop
#
#  The tray icon keeps SIGAME alive when the window is closed, and the
#  AUTO-BOOST watches the games of the computer: when a game starts, the
#  GAME BOOST runs by itself; when the game ends, the GAME OVER runs.
#
#  The check is light: one "Get-Process" every 5 seconds, with no WMI event
#  subscription and no watcher. Nothing is ever done twice.
# ---------------------------------------------------------------------------

# --- the state of the AUTO-BOOST -------------------------------------------

function Get-SIGameField {
    <#
    .SYNOPSIS
        One field of a game, whether the game comes from the JSON file (a
        hashtable) or from the memory (an object of PowerShell).
    #>
    param($Item, [string]$Name)

    if ($null -eq $Item) { return '' }
    if ($Item -is [System.Collections.IDictionary]) {
        if ($Item.Contains($Name)) { return [string]$Item[$Name] }
        return ''
    }
    $property = $Item.PSObject.Properties[$Name]
    if ($property) { return [string]$property.Value }
    return ''
}

function Get-SIAutoBoostEnabled {
    <#
    .SYNOPSIS
        $true when the AUTO-BOOST has to watch the games.

    .DESCRIPTION
        The choice of the user is remembered in SI-GAME-boost.json. The first
        time there is no choice yet, and the AUTO-BOOST is on when the user
        has set the boost list at least once: a program was ticked, so the
        user wants the boost to work without pressing the button.
    #>
    $state = Get-SIBoostState
    $value = $state['AutoBoost']
    if ($null -ne $value) { return [bool]$value }
    if ($state['Configured']) { return $true }
    return $false
}

function Set-SIAutoBoostEnabled {
    <#
    .SYNOPSIS
        Remembers the choice of the user and shows it in the window and in
        the menu of the tray.
    #>
    param([bool]$Enabled)

    $state = Get-SIBoostState
    $state['AutoBoost'] = $Enabled
    Save-SIBoostState -State $state | Out-Null
    $script:SIAutoBoostEnabled = $Enabled
    Update-SIAutoBoostUI
    Write-SILog -Component 'AutoBoost' -Message ("the AUTO-BOOST is now {0}." -f $(if ($Enabled) { 'on' } else { 'off' }))
}

function Set-SIAutoBoostListState {
    <#
    .SYNOPSIS
        Remembers the boost list of the user and refreshes the AUTO-BOOST.

    .DESCRIPTION
        It is a function and not a script block of the window, and that is
        not a style: a script block that was made with GetNewClosure() has
        its own scope and does NOT see the variables of the script scope, so
        the state would be written in the wrong place and lost.
    #>
    param($Ticks)

    $script:SIAutoBoostEnabled = [bool](Get-SIAutoBoostEnabled)
    # A boost that did not work (nothing was ticked) is tried again now that
    # the list has changed.
    $script:SIAutoBoostAttempted = ''
    $script:SIBoostTicks = @($Ticks)
    Update-SIAutoBoostUI
}

function Update-SIAutoBoostUI {
    <#
    .SYNOPSIS
        Shows the state of the AUTO-BOOST in the box of the Advanced section
        and in the menu of the tray.
    #>
    try {
        $box = Get-SIElement -Name 'AutoBoostBox'
        if ($box) {
            $on = $script:SIAutoBoostEnabled
            if ($box.IsChecked -ne $on) { $box.IsChecked = $on }
        }
    } catch { }
    try {
        if ($script:SITrayAutoItem) {
            $on = $script:SIAutoBoostEnabled
            if ($script:SITrayAutoItem.Checked -ne $on) { $script:SITrayAutoItem.Checked = $on }
        }
    } catch { }
}

function Add-SIAutoBoostGame {
    <#
    .SYNOPSIS
        Adds a game that the user chose with the picker to the list of the
        games that the AUTO-BOOST watches.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $state = Get-SIBoostState
    $games = @($state['Games'])
    foreach ($item in $games) {
        if ((Get-SIGameField -Item $item -Name 'Exe') -ieq $Path) { return $false }
    }
    $name = ''
    try { $name = [System.IO.Path]::GetFileNameWithoutExtension($Path) } catch { }
    $games += @{ Name = $name; Exe = $Path }
    $state['Games'] = $games
    Save-SIBoostState -State $state | Out-Null
    return $true
}

# --- the games that the AUTO-BOOST watches ---------------------------------

function Get-SIProcessNameFromPath {
    <#
    .SYNOPSIS
        The name of the process of an .exe, in small letters.
    #>
    param([string]$Path)

    if (-not $Path) { return '' }
    $name = ''
    try { $name = [System.IO.Path]::GetFileNameWithoutExtension($Path) } catch { return '' }
    if (-not $name) { return '' }
    return $name.ToLowerInvariant()
}

function Get-SIAutoBoostGames {
    <#
    .SYNOPSIS
        The games that the AUTO-BOOST watches: the games of Steam and of Epic
        that were found on this computer, and the games that the user added
        with the picker.
    #>
    $games = @()

    foreach ($game in @($script:SIGameLibrary)) {
        $exe = Get-SIGameField -Item $game -Name 'Exe'
        if (-not $exe) { continue }
        $name = Get-SIGameField -Item $game -Name 'Name'
        if (-not $name) { $name = [System.IO.Path]::GetFileNameWithoutExtension($exe) }
        $games += [pscustomobject]@{
            Name    = $name
            Exe     = $exe
            Process = (Get-SIProcessNameFromPath -Path $exe)
        }
    }

    $state = Get-SIBoostState
    foreach ($item in @($state['Games'])) {
        $exe = Get-SIGameField -Item $item -Name 'Exe'
        if (-not $exe) { continue }
        $name = Get-SIGameField -Item $item -Name 'Name'
        if (-not $name) { $name = [System.IO.Path]::GetFileNameWithoutExtension($exe) }
        $games += [pscustomobject]@{
            Name    = $name
            Exe     = $exe
            Process = (Get-SIProcessNameFromPath -Path $exe)
        }
    }

    # The game that is chosen right now with the picker.
    if ($script:SISelectedGame) {
        $known = $false
        foreach ($game in $games) {
            if ($game.Exe -ieq $script:SISelectedGame) { $known = $true; break }
        }
        if (-not $known) {
            $name = ''
            try { $name = [System.IO.Path]::GetFileNameWithoutExtension($script:SISelectedGame) } catch { }
            $games += [pscustomobject]@{
                Name    = $name
                Exe     = $script:SISelectedGame
                Process = (Get-SIProcessNameFromPath -Path $script:SISelectedGame)
            }
        }
    }

    return $games
}

function Get-SIRunningGame {
    <#
    .SYNOPSIS
        The name of the game of this computer that is running right now, or
        an empty string when no game is running.

    .DESCRIPTION
        The list of the processes is read ONCE, and the names of the games
        are compared with it. That is the whole check of the AUTO-BOOST, and
        it costs one "Get-Process" every 5 seconds.
    #>
    $games = @(Get-SIAutoBoostGames)
    if ($games.Count -eq 0) { return '' }

    $running = @{}
    try {
        foreach ($process in @(Get-Process -ErrorAction SilentlyContinue)) {
            $key = ''
            try { $key = ([string]$process.ProcessName).ToLowerInvariant() } catch { continue }
            if (-not $key) { continue }
            if (-not $running.ContainsKey($key)) { $running[$key] = $true }
        }
    } catch { }

    foreach ($game in $games) {
        if (-not $game.Process) { continue }
        if ($running.ContainsKey($game.Process)) { return [string]$game.Name }
    }
    return ''
}

# --- the AUTO-BOOST itself -------------------------------------------------

function Start-SIAutoBoost {
    <#
    .SYNOPSIS
        Starts the check of the games. It runs every 5 seconds, while SIGAME
        is open or in the tray.
    #>
    if ($script:SIAutoBoostTimer) { return }

    $script:SIAutoBoostEnabled = Get-SIAutoBoostEnabled

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(5)
    $null = $timer.Add_Tick({ Update-SIAutoBoost })
    $timer.Start()
    $script:SIAutoBoostTimer = $timer

    Write-SILog -Component 'AutoBoost' -Message ("the AUTO-BOOST is {0} and watches the games every 5 seconds." -f $(if ($script:SIAutoBoostEnabled) { 'on' } else { 'off' }))
}

function Stop-SIAutoBoost {
    <#
    .SYNOPSIS
        Stops the check of the games.
    #>
    if (-not $script:SIAutoBoostTimer) { return }
    try { $script:SIAutoBoostTimer.Stop() } catch { }
    $script:SIAutoBoostTimer = $null
}

function Update-SIAutoBoost {
    <#
    .SYNOPSIS
        The check of the AUTO-BOOST: is a game of this computer running?

    .DESCRIPTION
        A game starts  -> the GAME BOOST runs by itself, and a small note is
                         shown in the tray.
        A game ends    -> the GAME OVER runs by itself.

        The boost is never done twice for the same game, and a boost that the
        user did by hand is never done again by the AUTO-BOOST.
    #>
    try {
        if (-not $script:SIAutoBoostEnabled) { return }
        if ($script:SIBoostRunning) { return }

        $game = Get-SIRunningGame

        if ($game) {
            # The game is running.
            # Nothing is done when the boost of this game is already on: the
            # boost is never done twice.
            if ($script:SIAutoBoostedGame -eq $game) { return }
            # The boost of this game was already tried. It is not tried again
            # and again every 5 s: it is tried again when the user changes
            # the boost list.
            if ($script:SIAutoBoostAttempted -eq $game) { return }

            # The line about the game is written once, not every 5 s.
            if ($script:SIAutoBoostLastSeen -ne $game) {
                $script:SIAutoBoostLastSeen = $game
                Write-SILog -Component 'AutoBoost' -Message "the game $game is running."
            }

            if ($script:SIBoostIsActive) {
                # The user did the boost by hand: it is not done again, and
                # the GAME OVER of the AUTO-BOOST is not done either. Nothing
                # is written, so that the log is not full of the same line.
                # The check comes back in 5 s, so the AUTO-BOOST takes the
                # game over when the boost of the user is over.
                return
            }
            if (-not $script:SIPrepared) {
                # SIGAME is still starting up: the check comes back in 5 s.
                return
            }

            # The boost is done by the AUTO-BOOST: from now on, this game is
            # the one that the GAME OVER belongs to.
            $script:SIAutoBoostAttempted = $game
            $script:SIAutoBoostedGame = $game
            Invoke-SIBoost -Auto
            if ($script:SIBoostIsActive) {
                # The boost is really on: the note is shown in the tray.
                Show-SITrayNotification -Title 'GAME BOOST' -Text ("GAME BOOST: {0}" -f $game)
            }
            else {
                # The boost did not work (nothing was ticked, for example):
                # there is nothing to put back when the game ends. The boost
                # is tried again when the user ticks something in the list.
                $script:SIAutoBoostedGame = ''
            }
            return
        }

        # No game is running. The GAME OVER runs only when the AUTO-BOOST
        # was the one that did the boost.
        $script:SIAutoBoostLastSeen = ''
        $script:SIAutoBoostAttempted = ''
        if (-not $script:SIAutoBoostedGame) { return }
        $game = $script:SIAutoBoostedGame
        $script:SIAutoBoostedGame = ''
        Write-SILog -Component 'AutoBoost' -Message "the game $game is not running any more."

        if (-not $script:SIBoostIsActive) {
            Write-SILog -Component 'AutoBoost' -Message "there is nothing to put back, so the GAME OVER is not needed."
            return
        }
        Show-SITrayNotification -Title 'GAME OVER' -Text ("GAME OVER: {0}" -f $game)
        Invoke-SIGameOver -Auto
    } catch {
        Write-SILog -Level 'WARN' -Component 'AutoBoost' -Message "the AUTO-BOOST could not do its check: $($_.Exception.Message)"
    }
}

# --- the icon of the tray --------------------------------------------------

function Get-SIAppIcon {
    <#
    .SYNOPSIS
        The icon of SIGAME, made from logo.png.

    .DESCRIPTION
        The .ico file is made once with System.Drawing and kept next to the
        script, so that the tray icon and the shortcut of the desktop use the
        same picture.
    #>
    $icon = $null
    # System.Drawing is loaded first: without it, neither the .ico of the file
    # nor the icon of Windows could be read.
    try { Add-Type -AssemblyName System.Drawing -ErrorAction Stop } catch { }
    try {
        if (-not (Test-Path -LiteralPath $script:SIIconPath)) {
            New-SIAppIconFile -Path $script:SIIconPath | Out-Null
        }
        if (Test-Path -LiteralPath $script:SIIconPath) {
            $icon = [System.Drawing.Icon]::new($script:SIIconPath)
        }
    } catch {
        $icon = $null
    }
    if (-not $icon) {
        try { $icon = [System.Drawing.SystemIcons]::Application } catch { $icon = $null }
    }
    return $icon
}

function Show-SIMainWindow {
    <#
    .SYNOPSIS
        Brings the window of SIGAME back to the screen, from the tray.
    #>
    $window = $script:SIWindow
    if (-not $window) { return }
    try {
        if (-not $window.IsVisible) { $window.Show() }
        $window.WindowState = [System.Windows.WindowState]::Normal
        $window.Activate() | Out-Null
        $window.Topmost = $true
        $window.Topmost = $false
    } catch { }
}

function Show-SITrayNotification {
    <#
    .SYNOPSIS
        A small note in the tray, next to the icon of SIGAME.
    #>
    param(
        [string]$Title = 'SIGAME',
        [string]$Text = ''
    )

    if (-not $script:SITrayIcon) { return }
    try {
        $script:SITrayIcon.BalloonTipTitle = $Title
        $script:SITrayIcon.BalloonTipText = $Text
        $script:SITrayIcon.ShowBalloonTip(5000)
    } catch { }
}

function New-SITrayIcon {
    <#
    .SYNOPSIS
        The icon of SIGAME in the tray, with the menu: Open, AUTO-BOOST and
        Exit.

    .DESCRIPTION
        The icon keeps SIGAME alive when the window is closed: the AUTO-BOOST
        keeps watching the games while the user plays.

        If the icon cannot be made (no System.Windows.Forms), SIGAME keeps
        working exactly as before: the window then closes SIGAME, and the
        window is never hidden where it cannot be found again.
    #>
    if ($script:SITrayIcon) { return $script:SITrayIcon }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    } catch {
        Write-SILog -Level 'WARN' -Component 'Tray' -Message "the icon of the tray needs System.Windows.Forms, so it is not made: $($_.Exception.Message)"
        return $null
    }

    $icon = $null
    try {
        $icon = [System.Windows.Forms.NotifyIcon]::new()
        $icon.Text = 'SIGAME'
        $picture = Get-SIAppIcon
        if ($picture) { $icon.Icon = $picture }

        $menu = [System.Windows.Forms.ContextMenuStrip]::new()

        $openItem = [System.Windows.Forms.ToolStripMenuItem]::new('Open SIGAME')
        $null = $openItem.Add_Click({ Show-SIMainWindow })
        $null = $menu.Items.Add($openItem)

        $autoItem = [System.Windows.Forms.ToolStripMenuItem]::new('AUTO-BOOST')
        $autoItem.Checked = [bool](Get-SIAutoBoostEnabled)
        $null = $autoItem.Add_Click({
            $on = -not [bool]$script:SIAutoBoostEnabled
            Set-SIAutoBoostEnabled -Enabled $on
        })
        $null = $menu.Items.Add($autoItem)
        $script:SITrayAutoItem = $autoItem

        $exitItem = [System.Windows.Forms.ToolStripMenuItem]::new('Exit')
        $null = $exitItem.Add_Click({ Exit-SISigame })
        $null = $menu.Items.Add($exitItem)

        $icon.ContextMenuStrip = $menu
        $null = $icon.Add_DoubleClick({ Show-SIMainWindow })

        $icon.Visible = $true
        $script:SITrayIcon = $icon
        Write-SILog -Component 'Tray' -Message 'the icon of the tray is on the screen.'
    } catch {
        Write-SILog -Level 'WARN' -Component 'Tray' -Message "the icon of the tray could not be made: $($_.Exception.Message)"
        if ($icon) { try { $icon.Dispose() } catch { } }
        $icon = $null
    }
    return $icon
}

function Stop-SITrayIcon {
    <#
    .SYNOPSIS
        Takes the icon of the tray off the screen.
    #>
    if (-not $script:SITrayIcon) { return }
    try { $script:SITrayIcon.Visible = $false } catch { }
    try { $script:SITrayIcon.Dispose() } catch { }
    $script:SITrayIcon = $null
    $script:SITrayAutoItem = $null
}

function Exit-SISigame {
    <#
    .SYNOPSIS
        Closes SIGAME for good: the timers stop, the icon of the tray goes
        away and the window is closed.
    #>
    $script:SIExiting = $true
    Stop-SIAutoBoost
    Stop-SITrayIcon
    $window = $script:SIWindow
    if ($window) {
        try { $window.Close() } catch { }
    }
    Write-SILog -Component 'Tray' -Message 'SIGAME is closed by the menu of the tray.'
}

function Hide-SIMainWindow {
    <#
    .SYNOPSIS
        Hides the window of SIGAME, so that it lives in the tray.

    .DESCRIPTION
        The window is hidden and not closed: SIGAME keeps watching the games
        and the user brings the window back with the icon of the tray.

        If the window cannot be hidden, it is minimized instead: a window
        that is running without the user knowing it would be worse than a
        window in the taskbar.
    #>
    param($Window)

    if (-not $Window) { $Window = $script:SIWindow }
    if (-not $Window) { return }
    try {
        $Window.Hide()
        return
    } catch { }
    try {
        $Window.WindowState = [System.Windows.WindowState]::Minimized
    } catch { }
}

function Set-SISITrayHooks {
    <#
    .SYNOPSIS
        Hides the window in the tray when it is closed or minimized.

    .DESCRIPTION
        The window is only hidden when the icon of the tray is really there:
        a window that is hidden where it cannot be found again would be a
        program that is running without the user knowing it.
    #>
    $window = $script:SIWindow
    if (-not $window) { return }
    if (-not $script:SITrayIcon) { return }

    $null = $window.Add_StateChanged({
        param($sender, $e)
        if ($script:SIExiting) { return }
        try {
            if ($sender.WindowState -eq [System.Windows.WindowState]::Minimized) {
                Hide-SIMainWindow -Window $sender
            }
        } catch { }
    })

    $null = $window.Add_Closing({
        param($sender, $e)
        if ($script:SIExiting) { return }
        try {
            # The window is not closed, it is hidden: SIGAME goes on in the
            # tray and the AUTO-BOOST goes on watching the games.
            $e.Cancel = $true
            Hide-SIMainWindow -Window $sender
            Show-SITrayNotification -Title 'SIGAME' -Text 'SIGAME is still running in the tray. Use the icon of the tray to open it or to close it.'
        } catch { }
    })
}

# --- the shortcut of the desktop -------------------------------------------

function Get-SIDesktopPath {
    <#
    .SYNOPSIS
        The desktop of the person who is sitting at the machine.

    .DESCRIPTION
        SIGAME runs with administrator rights, and the desktop of the
        administrator is not always the desktop of the person who is playing.
        The account that is logged on at the machine is asked for, its profile
        is found in the registry, and its desktop is used.

        When the account that is playing is the same one that runs SIGAME,
        the desktop of Windows itself is used: it is quicker and it is right.
    #>
    $profile = ''

    $current = ''
    try { $current = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name } catch { $current = '' }
    $console = ''
    try {
        $system = Get-CimInstance -ClassName Win32_ComputerSystem -OperationTimeoutSec 5 -ErrorAction Stop
        $console = [string]$system.UserName
    } catch {
        $console = ''
    }

    if ($console) {
        # The name of the account that is playing, without the domain. The name
        # of the account that runs SIGAME is the same, without the domain too.
        $currentLeaf = ''
        if ($current) { $currentLeaf = ($current -split '\\')[-1] }
        $consoleLeaf = ($console -split '\\')[-1]

        if ($currentLeaf -and ($currentLeaf -ieq $consoleLeaf)) {
            # The same account: the desktop of Windows is the right one.
            $desktop = [Environment]::GetFolderPath('Desktop')
            if ($desktop -and (Test-Path -LiteralPath $desktop)) { return $desktop }
        }
        else {
            # Another account is playing: its profile is found in the list of
            # the profiles of Windows, by the name of the profile folder.
            # The registry is asked and not WMI: it is fast and it always
            # gives the path of the real profile.
            $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
            foreach ($sidKey in @(Get-ChildItem -Path $key -ErrorAction SilentlyContinue)) {
                $image = ''
                try {
                    $image = [string](Get-ItemProperty -Path $sidKey.PSPath -Name 'ProfileImagePath' -ErrorAction Stop).ProfileImagePath
                } catch { continue }
                if (-not $image) { continue }
                $leaf = ''
                try { $leaf = Split-Path -Path $image -Leaf } catch { continue }
                if ($leaf -ieq $consoleLeaf) { $profile = $image; break }
            }
        }
    }

    if (-not $profile) {
        # The last chance: the profile of the account that runs SIGAME.
        try { $profile = [Environment]::GetFolderPath('UserProfile') } catch { }
    }
    if (-not $profile) { return '' }

    $desktop = Join-Path $profile 'Desktop'
    if (Test-Path -LiteralPath $desktop) { return $desktop }
    return ''
}

function New-SIAppIconFile {
    <#
    .SYNOPSIS
        Makes the .ico file of SIGAME out of logo.png, with System.Drawing.

    .DESCRIPTION
        The picture is made 32 x 32 pixels, because that is the size that
        Windows shows on the desktop.
    #>
    param([string]$Path)

    if (-not $Path) { return $null }
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    } catch {
        Write-SILog -Level 'WARN' -Component 'Desktop' -Message "the icon of the shortcut needs System.Drawing: $($_.Exception.Message)"
        return $null
    }

    $logo = Join-Path $script:SIRoot 'logo.png'
    if (-not (Test-Path -LiteralPath $logo)) {
        Write-SILog -Level 'WARN' -Component 'Desktop' -Message 'there is no logo.png next to the script, so the icon of the shortcut was not made.'
        return $null
    }

    $source = $null
    $bitmap = $null
    $icon = $null
    $stream = $null
    try {
        $source = [System.Drawing.Image]::FromFile($logo)
        $bitmap = New-Object System.Drawing.Bitmap 32, 32
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.DrawImage($source, 0, 0, 32, 32)
        } finally {
            $graphics.Dispose()
        }
        $handle = $bitmap.GetHicon()
        $icon = [System.Drawing.Icon]::FromHandle($handle)
        # The icon is copied before it is written. An icon that comes from a
        # handle belongs to Windows and cannot always be written on its own:
        # the copy can, and that is the one that goes into the file.
        $copy = $null
        try { $copy = $icon.Clone() } catch { $copy = $null }
        if (-not $copy) { $copy = $icon }
        $stream = [System.IO.File]::Create($Path)
        try { $copy.Save($stream) } finally { $stream.Close(); $stream = $null }
        Write-SILog -Component 'Desktop' -Message "the icon of SIGAME was made: $Path"
        return $Path
    } catch {
        Write-SILog -Level 'WARN' -Component 'Desktop' -Message "the icon of SIGAME could not be made: $($_.Exception.Message)"
        return $null
    } finally {
        if ($stream) { try { $stream.Close() } catch { } }
        if ($icon) { try { $icon.Dispose() } catch { } }
        if ($bitmap) { try { $bitmap.Dispose() } catch { } }
        if ($source) { try { $source.Dispose() } catch { } }
    }
}

function New-SIDesktopShortcut {
    <#
    .SYNOPSIS
        Creates the shortcut "SIGAME" on the desktop of the person who is
        sitting at the machine.

    .DESCRIPTION
        The shortcut starts "AVVIA SI GAME.bat" of the folder of SIGAME, and
        it uses the icon that is made out of logo.png.

        A flag file next to the script remembers that the shortcut was made,
        so that it is never made again by itself: if the user deletes the
        shortcut, it stays deleted. The button of the Advanced section makes
        it again.
    #>
    param([switch]$Force)

    if ((Test-Path -LiteralPath $script:SIDesktopFlag) -and (-not $Force)) {
        return 'the shortcut of the desktop was already made, and it is never made again by itself'
    }

    $desktop = Get-SIDesktopPath
    if (-not $desktop) {
        Write-SILog -Level 'WARN' -Component 'Desktop' -Message 'the desktop of the person who is sitting at the machine was not found.'
        return 'the desktop was not found'
    }

    $bat = Join-Path $script:SIRoot 'AVVIA SI GAME.bat'
    if (-not (Test-Path -LiteralPath $bat)) {
        Write-SILog -Level 'WARN' -Component 'Desktop' -Message "the launcher AVVIA SI GAME.bat is not in $($script:SIRoot)."
        return 'the launcher of SIGAME was not found'
    }

    $icon = $null
    try {
        if (-not (Test-Path -LiteralPath $script:SIIconPath)) {
            New-SIAppIconFile -Path $script:SIIconPath | Out-Null
        }
        if (Test-Path -LiteralPath $script:SIIconPath) { $icon = $script:SIIconPath }
    } catch { $icon = $null }

    $shortcut = Join-Path $desktop 'SIGAME.lnk'
    try {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($shortcut)
        $link.TargetPath = $bat
        $link.WorkingDirectory = $script:SIRoot
        $link.Description = 'SIGAME - gaming tweaks by SI NEWS'
        if ($icon) { $link.IconLocation = ($icon + ',0') }
        $link.Save()
    } catch {
        Write-SILog -Level 'WARN' -Component 'Desktop' -Message "the shortcut of the desktop could not be made: $($_.Exception.Message)"
        return 'the shortcut of the desktop could not be made'
    }

    try {
        Set-Content -LiteralPath $script:SIDesktopFlag -Value ('the shortcut of the desktop was made at ' + (Get-Date).ToString('s')) -Encoding ASCII -ErrorAction Stop
    } catch { }

    Write-SILog -Level 'OK' -Component 'Desktop' -Message "the shortcut SIGAME was made on the desktop: $shortcut"
    return 'the shortcut SIGAME was made on the desktop'
}

function Invoke-SIDesktopShortcut {
    <#
    .SYNOPSIS
        The button of the Advanced section: it makes the shortcut of the
        desktop again.
    #>
    $message = New-SIDesktopShortcut -Force
    Set-SIStatusText -Text ([string]$message)
    try {
        $label = Get-SIElement -Name 'DesktopInfo'
        if ($label) { $label.Text = [string]$message }
    } catch { }
}
