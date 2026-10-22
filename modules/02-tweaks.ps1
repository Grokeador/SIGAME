# ---------------------------------------------------------------------------
#  SIGAME - module 02: the table of the tweaks
#
#  Every tweak is one entry of this table. The table is the single source of
#  truth: the UI, the state reader, the apply engine and the undo engine all
#  work from the same definition.
# ---------------------------------------------------------------------------
# ============================ 6. THE TWEAK TABLE ===========================
#
#  Every tweak is one entry of this table. The table is the single source of
#  truth: the UI, the state reader, the apply engine and the undo engine all
#  work from the same definition, which is why Apply and Undo can never
#  disagree about what a tweak touches.
#
#  Keys of a tweak entry:
#    Id            unique name, also the key used in the JSON backup
#    Name          text shown in the UI
#    Description   one line explanation, also used as the tool tip
#    Source        where the tweak comes from (WinUtil id or "new for 2026")
#    Group         UI group heading
#    Gaming        $true when the tweak belongs to the GAMING preset
#    Registry      wanted registry values (Value) or wanted ABSENCE (Remove)
#    RegistryScript  optional; returns the wanted values for the chosen option
#    Services      wanted startup types of services
#    Options       optional; choices shown in the row's combo box
#    StateScript   optional; returns @{Status;Text} for the real current state
#    SnapshotScript optional; runs before the change, result stored in the backup
#    ApplyScript   optional; extra work that is not a registry value
#    UndoScript    optional; undoes what ApplyScript did
#    OnText / OffText / PartialText   wording of the state column
#    ShowOnly      $true when the tweak is read-only (never switched by SIGAME)
#
#  Path note: "HKCU:\" is remapped by Get-SIUserRegistryPath when the person
#  running SIGAME is not the person logged on to the machine.

function Test-SILaptop {
    <#
    .SYNOPSIS
        Best effort "is this a laptop" test. Used to skip the Ultimate
        Performance power plan, which is not meant for laptops.
    #>
    try {
        if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) { return $true }
        $system = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($system -and $system.PCSystemType -eq 2) { return $true }   # 2 = Mobile
    } catch { }
    return $false
}

function Get-SIGameBarCapturePackages {
    return @('MicrosoftWindows.Client.WebExperience', 'Microsoft.WidgetsPlatformRuntime')
}

function Get-SIRecallState {
    <#
    .SYNOPSIS
        The state of the Recall optional feature, read only once.

    .DESCRIPTION
        Get-WindowsOptionalFeature talks to DISM and takes seconds. Recall only
        exists on Windows 11 24H2 (build 26100) and newer, so on Windows 10 the
        question is not even asked.
    #>
    return Get-SICachedValue -Key 'Recall' -Producer {
        if ((Get-SIWindowsBuild) -lt 26100) {
            return 'not available on this Windows version'
        }
        try {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName 'Recall' -ErrorAction Stop
            return [string]$feature.State
        } catch {
            return 'not installed'
        }
    }
}

function Get-SIWidgetsInstalled {
    <#
    .SYNOPSIS
        $true when the Widgets package is still on the machine.
    #>
    return Get-SICachedValue -Key 'WidgetsAppx' -Producer {
        foreach ($package in (Get-SIGameBarCapturePackages)) {
            # The package of the user that is logged on is the quick check, the
            # one of every user on the machine is the slow one.
            $found = Get-AppxPackage -Name $package -ErrorAction SilentlyContinue
            if (-not $found) { $found = Get-AppxPackage -AllUsers -Name $package -ErrorAction SilentlyContinue }
            if ($found) { return $true }
        }
        return $false
    }
}

function Get-SIPowerSchemeInfo {
    <#
    .SYNOPSIS
        Which power plans exist and which one is active.

    .DESCRIPTION
        "powercfg /list" prints every plan and marks the active one with a
        star, so one call is enough and no second process has to be started.
    #>
    return Get-SICachedValue -Key 'PowerSchemes' -Producer {
        $ultimateTemplate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
        $savedUltimate = ''
        try {
            $b = $script:SIBackup
            if (-not $b) { $b = Get-SIBackup }
            if ($b -and $b.Contains('Tweaks') -and $b.Tweaks.Contains('UltimatePerformance')) {
                $ex = $b.Tweaks['UltimatePerformance']['Extra']
                if ($ex -and $ex.Contains('NewScheme') -and $ex['NewScheme']) {
                    $savedUltimate = [string]$ex['NewScheme']
                }
            }
        } catch { }

        $active = ''
        $ultimateFound = $false
        $ultimateGuid = ''
        $text = ''
        try { $text = (powercfg /list 2>$null) -join "`n" } catch { $text = '' }
        foreach ($line in ($text -split "`r?`n")) {
            $match = [regex]::Match($line, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
            if (-not $match.Success) { continue }
            $guid = $match.Value
            if ($line -match '\*\s*$') { $active = $guid }
            if ($guid -ieq $ultimateTemplate -or ($savedUltimate -and $guid -ieq $savedUltimate) -or ($line -match '(?i)Ultimate Performance|Prestazioni eccellenti|Desempenho M|Maximo desempenho|M.ximo rendimiento|Ultimative Leistung|Performances optimales')) {
                $ultimateFound = $true
                if (-not $ultimateGuid -or ($line -match '\*\s*$')) { $ultimateGuid = $guid }
            }
        }
        return @{ Active = $active; UltimatePresent = $ultimateFound; UltimateGuid = $ultimateGuid }
    }
}

function Get-SIDeviceGuardState {
    <#
    .SYNOPSIS
        The virtualisation based security state, read only once.

    .DESCRIPTION
        -1 means "not known", 0 is off, 1 is enabled but not running and 2 is
        running. The WMI class is only asked when the registry says there is
        something to ask about.
    #>
    return Get-SICachedValue -Key 'DeviceGuard' -Producer {
        $vbsValue = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity'
        $vbsOn = ($vbsValue.Exists -and [int]$vbsValue.Value -eq 1)
        if (-not $vbsOn) { return 0 }
        try {
            $guard = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard -ErrorAction Stop
            return [int]$guard.VirtualizationBasedSecurityStatus
        } catch {
            return -1
        }
    }
}

function Get-SITweakTable {
    if ($script:SITweakTableCache) { return $script:SITweakTableCache }

    $tweaks = @()

    # ---------------------------------------------------------------- Game Mode
    $tweaks += @{
        Id          = 'GameMode'
        Name        = 'Game Mode'
        Description = 'Windows prioritises the running game and frees resources for it.'
        Source      = 'WinUtil: WPFToggleGameMode'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'Game Mode is ON'
        OffText     = 'Game Mode is OFF'
        Registry    = @(
            @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AllowAutoGameMode';   Type = 'DWord'; Value = 1 }
            @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AutoGameModeEnabled'; Type = 'DWord'; Value = 1 }
        )
    }

    # ------------------------------------------------------- Mouse acceleration
    $tweaks += @{
        Id          = 'MouseAcceleration'
        Name        = 'Mouse acceleration'
        Description = 'Turns mouse acceleration OFF, so the pointer never overshoots the target.'
        Source      = 'WinUtil: WPFToggleMouseAcceleration (inverted: we switch acceleration off)'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'Acceleration is OFF'
        OffText     = 'Acceleration is ON'
        Registry    = @(
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseSpeed';      Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold1'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold2'; Type = 'DWord'; Value = 0 }
        )
    }

    # ---------------------------------------------------------- Background apps
    $tweaks += @{
        Id          = 'BackgroundApps'
        Name        = 'Background apps'
        Description = 'Stops Microsoft Store apps from running in the background.'
        Source      = 'WinUtil: WPFTweaksDisableBGapps'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'Background apps are OFF'
        OffText     = 'Background apps are allowed'
        Registry    = @(
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Type = 'DWord'; Value = 1 }
        )
    }

    # ------------------------------------------------------------ Visual effects
    $tweaks += @{
        Id          = 'VisualEffects'
        Name        = 'Visual effects'
        Description = 'Sets the visual effects to the best performance profile.'
        Source      = 'WinUtil: WPFTweaksDisplay'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'Best performance is set'
        OffText     = 'Not set to best performance'
        Registry    = @(
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'DragFullWindows'; Type = 'String'; Value = '0' }
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MenuShowDelay';  Type = 'String'; Value = '200' }
            @{ Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Type = 'String'; Value = '0' }
            @{ Path = 'HKCU:\Control Panel\Keyboard'; Name = 'KeyboardDelay'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewAlphaSelect'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewShadow';      Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAnimations';   Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Type = 'DWord'; Value = 3 }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\DWM'; Name = 'EnableAeroPeek'; Type = 'DWord'; Value = 0 }
            # The taskbar icons (TaskbarMn) and the task view button
            # (ShowTaskViewButton) are NOT part of SIGAME: they are not
            # written and they are not undone.
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'UserPreferencesMask'; Type = 'Binary'; Value = [byte[]](144, 18, 3, 128, 16, 0, 0, 0) }
        )
    }

    # ------------------------------------------------------ Delivery optimization
    $tweaks += @{
        Id          = 'DeliveryOptimization'
        Name        = 'Delivery Optimization'
        Description = 'Stops Windows from using your bandwidth to send updates to other PCs.'
        Source      = 'WinUtil: WPFTweaksDeliveryOptimization'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'Delivery Optimization is OFF'
        OffText     = 'Delivery Optimization is allowed'
        Registry    = @(
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; Name = 'DODownloadMode'; Type = 'DWord'; Value = 0 }
        )
        # DoSvc is a protected service: since Windows 10 1709 Windows itself
        # owns its start type and says "access denied" when somebody tries to
        # change it. The policy above is what really switches Delivery
        # Optimization off, so the service is optional: it is skipped when
        # Windows refuses it and it is not counted in the state.
        Services    = @(
            @{ Name = 'DoSvc'; StartupType = 'Disabled'; Optional = $true }
        )
    }

    # ----------------------------------------------------------------- Telemetry
    $tweaks += @{
        Id          = 'Telemetry'
        Name        = 'Telemetry'
        Description = 'Disables Microsoft telemetry, the error reporting service and the advertising id.'
        Source      = 'WinUtil: WPFTweaksTelemetry'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'Telemetry is reduced'
        OffText     = 'Telemetry is not reduced'
        Registry    = @(
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'; Name = 'HasAccepted'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Input\TIPC'; Name = 'Enabled'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitInkCollection'; Type = 'DWord'; Value = 1 }
            @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitTextCollection'; Type = 'DWord'; Value = 1 }
            @{ Path = 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore'; Name = 'HarvestContacts'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Personalization\Settings'; Name = 'AcceptedPrivacyPolicy'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'AllowTelemetry'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKCU:\Software\Microsoft\Siuf\Rules'; Name = 'NumberOfSIUFInPeriod'; Type = 'DWord'; Value = 0 }
        )
        Services    = @(
            @{ Name = 'DiagTrack'; StartupType = 'Disabled' }
            @{ Name = 'WerSvc';    StartupType = 'Disabled' }
        )
    }

    # ------------------------------------------------------------ Activity history
    $tweaks += @{
        Id          = 'ActivityHistory'
        Name        = 'Activity history'
        Description = 'Stops Windows from publishing or uploading your activities.'
        Source      = 'WinUtil: WPFTweaksActivity'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'Activity history is OFF'
        OffText     = 'Activity history is ON'
        Registry    = @(
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'EnableActivityFeed';    Type = 'DWord'; Value = 1 }
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Type = 'DWord'; Value = 0 }
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'UploadUserActivities';  Type = 'DWord'; Value = 0 }
        )
    }

    # ------------------------------------------------------- Multiplane overlay
    $tweaks += @{
        Id          = 'MultiplaneOverlay'
        Name        = 'Multiplane Overlay'
        Description = 'Some video cards misbehave with the Windows overlay. Pick how MPO should behave.'
        Source      = 'WinUtil: WPFMultiplaneOverlay (SIGAME adds the missing undo)'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        Options     = @('Enabled', 'Disabled (Compatibility)', 'Fully Disabled')
        GamingOption = 'Disabled (Compatibility)'
        OnText      = 'Multiplane Overlay is disabled'
        OffText     = 'Multiplane Overlay is in the default Windows mode'
        DetectOption = {
            $overlay = Get-SIRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'OverlayTestMode'
            $disable = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'DisableOverlays'
            $overlayValue = if ($overlay.Exists) { [int]$overlay.Value } else { 0 }
            $disableValue = if ($disable.Exists) { [int]$disable.Value } else { 0 }
            if ($overlayValue -eq 5 -and $disableValue -eq 1) { return 'Fully Disabled' }
            if ($overlayValue -eq 5) { return 'Disabled (Compatibility)' }
            return 'Enabled'
        }
        RegistryScript = {
            param($option)
            switch ($option) {
                'Fully Disabled' {
                    return @(
                        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'; Name = 'OverlayTestMode'; Type = 'DWord'; Value = 5 }
                        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name = 'DisableOverlays'; Type = 'DWord'; Value = 1 }
                    )
                }
                'Disabled (Compatibility)' {
                    return @(
                        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'; Name = 'OverlayTestMode'; Type = 'DWord'; Value = 5 }
                        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name = 'DisableOverlays'; Type = 'DWord'; Remove = $true }
                    )
                }
                default {
                    return @(
                        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'; Name = 'OverlayTestMode'; Type = 'DWord'; Remove = $true }
                        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name = 'DisableOverlays'; Type = 'DWord'; Remove = $true }
                    )
                }
            }
        }
        StateScript = {
            param($option)
            $overlay = Get-SIRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'OverlayTestMode'
            $disable = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'DisableOverlays'
            $overlayValue = if ($overlay.Exists) { [int]$overlay.Value } else { 0 }
            $disableValue = if ($disable.Exists) { [int]$disable.Value } else { 0 }

            if ($overlayValue -eq 5 -and $disableValue -eq 1) { $current = 'Fully Disabled' }
            elseif ($overlayValue -eq 5) { $current = 'Disabled (Compatibility)' }
            elseif ($overlayValue -eq 0 -and $disableValue -eq 0) { $current = 'Enabled' }
            else { $current = "custom (OverlayTestMode=$overlayValue, DisableOverlays=$disableValue)" }

            if ($current -eq $option) {
                return @{ Status = 'Applied'; Text = "Multiplane Overlay: $current" }
            }
            return @{ Status = 'NotApplied'; Text = "Multiplane Overlay: $current" }
        }
    }

    # ------------------------------------------------------------------ Widgets
    $tweaks += @{
        Id          = 'Widgets'
        Name        = 'Widgets'
        Description = 'Removes the Widgets panel from the taskbar. Undo puts it back.'
        Source      = 'WinUtil: WPFTweaksWidget (SIGAME adds the missing undo)'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        CacheKeys   = @('WidgetsAppx')
        OnText      = 'Widgets are removed'
        OffText     = 'Widgets are installed'
        Registry    = @(
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDa'; Type = 'DWord'; Value = 0 }
        )
        # The Widgets panel was introduced with Windows 11. On Windows 10
        # there is nothing to remove and the key that hides the panel is
        # closed to the program, so the whole tweak is "not available" there
        # instead of failing.
        AvailabilityScript = {
            param($option)
            if ((Get-SIWindowsBuild) -lt 22000) {
                return ('not available on ' + (Get-SIWindowsFamily) + ': the Widgets panel only exists on Windows 11')
            }
            return ''
        }
        StateScript = {
            param($option)
            if (Get-SIWidgetsInstalled) {
                return @{ Status = 'NotApplied'; Text = 'Widgets are installed'; Details = 'The Widgets panel is still on the taskbar.' }
            }
            # The panel is not there. Either SIGAME removed it, or it was
            # never installed on this computer.
            $removedBySIGame = $false
            try {
                # The backup that is in memory is the one the engine keeps up
                # to date. The cached copy never expires, so it could show a
                # backup of a start from hours ago, with the Widgets panel
                # still in it, and the row would say "not available" when
                # SIGAME had removed the panel.
                $backup = $script:SIBackup
                if (-not $backup) { $backup = Get-SIBackup }
                if ($backup -and $backup.Contains('Tweaks') -and $backup.Tweaks.Contains('Widgets')) {
                    $known = $backup.Tweaks['Widgets']
                    if ($known.Contains('Extra')) {
                        $extra = $known['Extra']
                        if ($extra -and $extra.Contains('RemovedPackages') -and (@($extra['RemovedPackages'])).Count -gt 0) {
                            $removedBySIGame = $true
                        }
                    }
                }
            } catch { }
            if ($removedBySIGame) {
                return @{ Status = 'Applied'; Text = 'Widgets are removed'; Details = 'SIGAME removed the Widgets panel.' }
            }
            return @{ Status = 'NotAvailable'; Text = 'Not available: the Widgets panel is not installed on this computer'; Details = 'There is nothing to remove.' }
        }
        ApplyScript = {
            $removed = @()
            Get-Process -ErrorAction SilentlyContinue |
                Where-Object { $_.ProcessName -like '*Widget*' } |
                Stop-Process -Force -ErrorAction SilentlyContinue

            foreach ($package in (Get-SIGameBarCapturePackages)) {
                $installed = Get-AppxPackage -AllUsers -Name $package -ErrorAction SilentlyContinue
                if (-not $installed) { $installed = Get-AppxPackage -Name $package -ErrorAction SilentlyContinue }
                foreach ($pkg in $installed) {
                    try {
                        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                        $removed += $package
                        Write-SILog -Component 'AppX' -Message "Removed $package."
                    } catch {
                        Write-SILog -Level 'WARN' -Component 'AppX' -Message "Could not remove $package : $($_.Exception.Message)"
                    }
                    # The window is pumped, so that it stays alive while the
                    # packages are removed.
                    Invoke-SIUIPump
                }
            }
            return @{ RemovedPackages = $removed }
        }
        UndoScript = {
            param($Extra)
            $packages = @()
            if ($Extra -and $Extra.Contains('RemovedPackages')) { $packages = @($Extra.RemovedPackages) }
            if ($packages.Count -eq 0) { $packages = Get-SIGameBarCapturePackages }

            foreach ($package in $packages) {
                $registered = $false
                $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -eq $package } | Select-Object -First 1
                if ($provisioned) {
                    $manifest = Join-Path $provisioned.InstallLocation 'AppXManifest.xml'
                    if (Test-Path -LiteralPath $manifest) {
                        try {
                            Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
                            $registered = $true
                            Write-SILog -Component 'AppX' -Message "Re-registered $package from the provisioned package."
                        } catch {
                            Write-SILog -Level 'WARN' -Component 'AppX' -Message "Could not re-register $package : $($_.Exception.Message)"
                        }
                    }
                }
                if (-not $registered) {
                    $installed = Get-AppxPackage -AllUsers -Name $package -ErrorAction SilentlyContinue
                    if (-not $installed) { $installed = Get-AppxPackage -Name $package -ErrorAction SilentlyContinue }
                    foreach ($pkg in $installed) {
                        $manifest = Join-Path $pkg.InstallLocation 'AppXManifest.xml'
                        if (Test-Path -LiteralPath $manifest) {
                            try {
                                Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
                                Write-SILog -Component 'AppX' -Message "Re-registered $package."
                            } catch {
                                Write-SILog -Level 'WARN' -Component 'AppX' -Message "Could not re-register $package : $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        }
    }

    # --------------------------------------------------------------- Windows AI
    $tweaks += @{
        Id          = 'WindowsAI'
        Name        = 'Windows AI / Recall'
        Description = 'Hides the AI settings, disables the Recall feature and the AI services.'
        Source      = 'WinUtil: WPFTweaksWindowsAI (SIGAME adds the missing undo)'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'AI features are switched off'
        OffText     = 'AI features are still enabled'
        Registry    = @(
            @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'SettingsPageVisibility'; Type = 'String'; Value = 'hide:aicomponents' }
            @{ Path = 'HKLM:\SOFTWARE\Policies\WindowsNotepad'; Name = 'DisableAIFeatures'; Type = 'DWord'; Value = 1 }
        )
        Services    = @(
            # The AI service only exists on Windows 11 24H2 and newer. It is
            # optional, so that a Windows version without it is not an error.
            @{ Name = 'WSAIFabricSvc'; StartupType = 'Disabled'; Optional = $true }
        )
        # The AI settings page, the Recall feature and the AI service do not
        # exist before Windows 11 24H2 (build 26100). On those Windows
        # versions the tweak is "not available" and nothing is changed.
        AvailabilityScript = {
            param($option)
            $build = Get-SIWindowsBuild
            if ($build -lt 22000) {
                return ('not available on ' + (Get-SIWindowsFamily) + ': there is no AI settings page, no Recall and no AI service')
            }
            if ($build -lt 26100) {
                return ('not available on this Windows version: the AI settings page, Recall and the AI service need Windows 11 24H2 (build 26100) or newer')
            }
            return ''
        }
        StateScript = {
            param($option)
            $hidden = Get-SIRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'SettingsPageVisibility'
            $hiddenValue = if ($hidden.Exists) { [string]$hidden.Value } else { '' }
            $recall = Get-SIRecallState

            if ($hiddenValue -like '*hide:aicomponents*') {
                return @{ Status = 'Applied'; Text = "AI settings hidden, Recall: $recall" }
            }
            return @{ Status = 'NotApplied'; Text = "AI settings visible, Recall: $recall" }
        }
        SnapshotScript = {
            $recallEnabled = $false
            $recallFound = $false
            if ((Get-SIWindowsBuild) -ge 26100) {
                try {
                    $feature = Get-WindowsOptionalFeature -Online -FeatureName 'Recall' -ErrorAction Stop
                    $recallFound = $true
                    $recallEnabled = ($feature.State -eq 'Enabled')
                } catch { }
            }
            return @{ RecallFound = $recallFound; RecallEnabled = $recallEnabled }
        }
        ApplyScript = {
            if ((Get-SIWindowsBuild) -ge 26100) {
                try {
                    $feature = Get-WindowsOptionalFeature -Online -FeatureName 'Recall' -ErrorAction Stop
                    if ($feature.State -eq 'Enabled') {
                        Disable-WindowsOptionalFeature -Online -FeatureName 'Recall' -NoRestart -ErrorAction Stop | Out-Null
                        Write-SILog -Component 'Feature' -Message 'Disabled the Recall optional feature.'
                    }
                } catch {
                    Write-SILog -Level 'WARN' -Component 'Feature' -Message "Recall feature not changed: $($_.Exception.Message)"
                }
            }

            $removed = @()
            foreach ($pattern in @('MicrosoftWindows.Client.CoreAI', '*Copilot*')) {
                $packages = Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue
                if (-not $packages) { $packages = Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue }
                foreach ($pkg in $packages) {
                    try {
                        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                        $removed += $pkg.PackageFullName
                        Write-SILog -Component 'AppX' -Message "Removed $($pkg.PackageFullName)."
                    } catch {
                        Write-SILog -Level 'WARN' -Component 'AppX' -Message "Could not remove $($pkg.PackageFullName) : $($_.Exception.Message)"
                    }
                    # The window is pumped, so that it stays alive while the
                    # packages are removed.
                    Invoke-SIUIPump
                }
            }
            return @{ RemovedPackages = $removed }
        }
        UndoScript = {
            param($Extra)
            if ($Extra -and $Extra.Contains('RecallFound') -and $Extra.RecallFound -and $Extra.RecallEnabled) {
                try {
                    Enable-WindowsOptionalFeature -Online -FeatureName 'Recall' -NoRestart -ErrorAction Stop | Out-Null
                    Write-SILog -Component 'Feature' -Message 'Re-enabled the Recall optional feature.'
                } catch {
                    Write-SILog -Level 'WARN' -Component 'Feature' -Message "Could not re-enable Recall: $($_.Exception.Message)"
                }
            }
            $packages = @()
            if ($Extra -and $Extra.Contains('RemovedPackages')) { $packages = @($Extra.RemovedPackages) }
            foreach ($fullName in $packages) {
                # The full name carries the version, so the package is looked up by
                # comparing the whole name and not with the -Name filter.
                $installed = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
                    Where-Object { $_.PackageFullName -eq $fullName }
                if (-not $installed) {
                    $installed = Get-AppxPackage -ErrorAction SilentlyContinue |
                        Where-Object { $_.PackageFullName -eq $fullName }
                }
                foreach ($pkg in $installed) {
                    $manifest = Join-Path $pkg.InstallLocation 'AppXManifest.xml'
                    if (Test-Path -LiteralPath $manifest) {
                        try {
                            Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
                            Write-SILog -Component 'AppX' -Message "Re-registered $fullName."
                        } catch {
                            Write-SILog -Level 'WARN' -Component 'AppX' -Message "Could not re-register $fullName : $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
    }

    # ---------------------------------------------------- Ultimate performance
    $tweaks += @{
        Id          = 'UltimatePerformance'
        Name        = 'Ultimate Performance'
        Description = 'Adds and activates the Ultimate Performance power plan. Skipped on laptops.'
        Source      = 'WinUtil: WPFAddUltPerf (SIGAME adds the missing undo)'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        CacheKeys   = @('PowerSchemes')
        OnText      = 'Ultimate Performance is available'
        OffText     = 'Ultimate Performance is not installed'
        StateScript = {
            param($option)
            $info = Get-SIPowerSchemeInfo
            if ($info.UltimatePresent) {
                if ($info.UltimateGuid -and ($info.Active -ieq $info.UltimateGuid)) {
                    return @{ Status = 'Applied'; Text = 'Ultimate Performance is installed and active' }
                }
                return @{ Status = 'NotApplied'; Text = 'Ultimate Performance is installed but not active' }
            }
            return @{ Status = 'NotApplied'; Text = 'Ultimate Performance is not installed' }
        }
        SnapshotScript = {
            $info = Get-SIPowerSchemeInfo
            return @{ PreviousScheme = $info.Active }
        }
        ApplyScript = {
            $info = Get-SIPowerSchemeInfo
            $guid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
            $created = $false
            if ($info.UltimatePresent -and $info.UltimateGuid) {
                $guid = $info.UltimateGuid
            } else {
                $output = (powercfg /duplicatescheme $guid) -join "`n"
                $new = ([regex]::Match($output, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')).Value
                if (-not $new) { throw 'powercfg did not report a new scheme GUID.' }
                $guid = $new
                $created = $true
            }
            (powercfg /setactive $guid) | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "powercfg could not activate the new scheme (exit code $LASTEXITCODE)." }
            Write-SILog -Component 'Power' -Message "Activated the Ultimate Performance plan $guid."
            if ($created) { return @{ NewScheme = $guid } }
            # The plan was already on the machine, so it must not be deleted on undo.
            return @{ NewScheme = '' }
        }
        UndoScript = {
            param($Extra)
            if ($Extra -and $Extra.Contains('NewScheme') -and $Extra.NewScheme) {
                (powercfg /delete $Extra.NewScheme) | Out-Null
            }
            if ($Extra -and $Extra.Contains('PreviousScheme') -and $Extra.PreviousScheme) {
                (powercfg /setactive $Extra.PreviousScheme) | Out-Null
                Write-SILog -Component 'Power' -Message "Restored the previous power plan $($Extra.PreviousScheme)."
            }
        }
    }

    # --------------------------------------------- Game Bar background capture
    $tweaks += @{
        Id          = 'GameDVR'
        Name        = 'Game Bar capture'
        Description = 'Turns the Game Bar background recording off, so the game is not recorded behind the scenes.'
        Source      = 'New for 2026 (not in WinUtil) - Microsoft: support.microsoft.com/windows/record-with-game-bar'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        Options     = @('Background capture OFF', 'Background capture ON')
        GamingOption = 'Background capture OFF'
        OnText      = 'Background capture is OFF'
        OffText     = 'Background capture is ON'
        DetectOption = {
            $capture = Get-SIRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled'
            if ($capture.Exists -and [int]$capture.Value -eq 0) { return 'Background capture OFF' }
            return 'Background capture ON'
        }
        RegistryScript = {
            param($option)
            if ($option -eq 'Background capture ON') {
                return @(
                    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Type = 'DWord'; Value = 1 }
                    @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Type = 'DWord'; Value = 1 }
                )
            }
            return @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Type = 'DWord'; Value = 0 }
                @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Type = 'DWord'; Value = 0 }
            )
        }
    }

    # ------------------------------------------- Hardware accelerated GPU sched
    $tweaks += @{
        Id          = 'HAGS'
        Name        = 'Hardware GPU scheduling'
        Description = 'Hardware accelerated GPU scheduling (HAGS). A restart is needed for it to take effect.'
        Source      = 'New for 2026 (not in WinUtil) - Microsoft: HwSchMode under GraphicsDrivers'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        Options     = @('HAGS ON', 'HAGS OFF')
        GamingOption = 'HAGS ON'
        OnText      = 'Hardware scheduling is ON'
        OffText     = 'Hardware scheduling is OFF'
        DetectOption = {
            $value = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode'
            if ($value.Exists -and [int]$value.Value -eq 1) { return 'HAGS ON' }
            return 'HAGS OFF'
        }
        RegistryScript = {
            param($option)
            $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
            if ($option -eq 'HAGS ON') {
                return @(@{ Path = $path; Name = 'HwSchMode'; Type = 'DWord'; Value = 1 })
            }
            return @(@{ Path = $path; Name = 'HwSchMode'; Type = 'DWord'; Remove = $true })
        }
        StateScript = {
            param($option)
            $value = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode'
            $current = if ($value.Exists) { [int]$value.Value } else { 0 }
            if ($option -eq 'HAGS ON') {
                if ($current -eq 1) { return @{ Status = 'Applied'; Text = 'Hardware scheduling is ON (HwSchMode=1)' } }
                return @{ Status = 'NotApplied'; Text = 'Hardware scheduling is not switched on' }
            }
            if ($current -eq 2) { return @{ Status = 'Applied'; Text = 'Hardware scheduling is OFF (HwSchMode=2)' } }
            if ($current -eq 0) { return @{ Status = 'Applied'; Text = 'Hardware scheduling is not configured, the driver decides' } }
            return @{ Status = 'NotApplied'; Text = "Hardware scheduling is in another state (HwSchMode=$current)" }
        }
    }

    # ---------------------------------------- Optimizations for windowed games
    $tweaks += @{
        Id          = 'WindowedGameOptimizations'
        Name        = 'Windowed game optimizations'
        Description = 'Lets Windows apply the fullscreen optimizations to games that run in a window.'
        Source      = 'New for 2026 (not in WinUtil) - GameDVR_FSEBehaviorMode, see NOTES.md for the reference'
        Group       = 'Gaming'
        Gaming      = $true
        Optimize    = $true
        Options     = @('Optimizations ON', 'Optimizations OFF')
        GamingOption = 'Optimizations ON'
        OnText      = 'Windowed optimizations are ON'
        OffText     = 'Windowed optimizations are OFF'
        DetectOption = {
            $value = Get-SIRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode'
            if ($value.Exists -and [int]$value.Value -eq 2) { return 'Optimizations ON' }
            return 'Optimizations OFF'
        }
        RegistryScript = {
            param($option)
            $path = 'HKCU:\System\GameConfigStore'
            if ($option -eq 'Optimizations ON') {
                return @(@{ Path = $path; Name = 'GameDVR_FSEBehaviorMode'; Type = 'DWord'; Value = 2 })
            }
            return @(@{ Path = $path; Name = 'GameDVR_FSEBehaviorMode'; Type = 'DWord'; Value = 0 })
        }
        StateScript = {
            param($option)
            $value = Get-SIRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode'
            $current = if ($value.Exists) { [int]$value.Value } else { -1 }
            if ($option -eq 'Optimizations ON') {
                if ($current -eq 2) { return @{ Status = 'Applied'; Text = 'Windowed optimizations are ON (mode 2)' } }
                return @{ Status = 'NotApplied'; Text = 'Windowed optimizations are not switched on' }
            }
            if ($current -eq 0) { return @{ Status = 'Applied'; Text = 'Windowed optimizations are OFF (mode 0)' } }
            if ($current -eq -1) { return @{ Status = 'Applied'; Text = 'Windowed optimizations are OFF (not set)' } }
            if ($current -eq 2) { return @{ Status = 'NotApplied'; Text = 'Windowed optimizations are ON (mode 2)' } }
            return @{ Status = 'NotApplied'; Text = 'Not set, Windows default is used' }
        }
    }

    # --------------------------------------------------------- Memory integrity
    $tweaks += @{
        Id          = 'MemoryIntegrity'
        Name        = 'Memory integrity'
        Description = 'Core isolation (HVCI). Shown for information only, SIGAME never switches it.'
        Source      = 'New for 2026 (not in WinUtil) - Microsoft: DeviceGuard / HypervisorEnforcedCodeIntegrity'
        Group       = 'Security'
        Gaming      = $false
        ShowOnly    = $true
        StateScript = {
            param($option)
            $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
            $value = Get-SIRegistryValue -Path $path -Name 'Enabled'
            $vbsValue = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity'

            $enabled = $false
            if ($value.Exists -and [int]$value.Value -eq 1) { $enabled = $true }
            $vbs = $false
            if ($vbsValue.Exists -and [int]$vbsValue.Value -eq 1) { $vbs = $true }

            $running = 'unknown'
            $guardState = Get-SIDeviceGuardState
            if ($guardState -eq 2) { $running = 'running' }
            elseif ($guardState -eq 1) { $running = 'enabled, not running' }
            elseif ($guardState -eq 0) { $running = 'off' }

            if ($enabled) {
                return @{ Status = 'Applied'; Text = "Memory integrity is ON (VBS $running) - keep it, it blocks kernel level malware" }
            }
            if ($vbs) {
                return @{ Status = 'Partial'; Text = "Memory integrity is OFF, VBS is $running - turning it on costs a little performance" }
            }
            return @{ Status = 'NotApplied'; Text = 'Memory integrity is OFF and VBS is not enabled' }
        }
    }

    # ------------------------------------------------- Round 5: TCP auto-tuning
    $tweaks += @{
        Id          = 'TCPAutoTuning'
        Name        = 'TCP receive window auto-tuning'
        Description = 'Lets the receive window of TCP grow to suit almost every situation. Windows sets it to "normal" by default.'
        Source      = 'Microsoft: learn.microsoft.com netgeeks - a word about autotuninglevel TCP receive auto tuning level explained'
        Group       = 'Network & downloads'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'TCP auto-tuning is normal'
        OffText     = 'TCP auto-tuning is not normal'
        AvailabilityScript = {
            param($option)
            if (-not (Test-SIHasCommand 'Get-NetTCPSetting')) {
                return 'not available on this Windows version: the TCP settings cannot be read'
            }
            return ''
        }
        StateScript = {
            param($option)
            $level = Get-SITcpAutoTuningLevel
            if (-not $level) {
                return @{ Status = 'NotAvailable'; Text = 'not available: the TCP settings cannot be read' }
            }
            if ($level -eq 'Normal') {
                return @{ Status = 'Applied'; Text = 'TCP auto-tuning is normal'; Details = "AutoTuningLevelLocal = $level" }
            }
            return @{ Status = 'NotApplied'; Text = "TCP auto-tuning is $level"; Details = 'Windows recommends Normal' }
        }
        SnapshotScript = {
            return @{ PreviousLevel = (Get-SITcpAutoTuningLevel) }
        }
        ApplyScript = {
            $previous = Get-SITcpAutoTuningLevel
            if ($previous -eq 'Normal') {
                return @{ PreviousLevel = $previous; Changed = $false }
            }
            Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal Normal -ErrorAction Stop | Out-Null
            Write-SILog -Component 'Network' -Message 'TCP auto-tuning set to Normal.'
            return @{ PreviousLevel = $previous; Changed = $true }
        }
        UndoScript = {
            param($Extra)
            if ($Extra -and $Extra.Contains('PreviousLevel') -and $Extra.PreviousLevel) {
                Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal $Extra.PreviousLevel -ErrorAction Stop | Out-Null
                Write-SILog -Component 'Network' -Message "TCP auto-tuning put back to $($Extra.PreviousLevel)."
            }
        }
    }

    # ---------------------------------------------------- Round 5: DNS server
    $tweaks += @{
        Id          = 'DNSServer'
        Name        = 'DNS server'
        Description = 'Sets the DNS of the network adapter that is used right now. Run the DNS test in the Advanced section first.'
        Source      = 'SIGAME (own feature) - the DNS benchmark measures the answer time of the servers'
        Group       = 'Network & downloads'
        Gaming      = $false
        OnText      = 'The DNS server is set'
        OffText     = 'The DNS server is the one of Windows'
        AvailabilityScript = {
            param($option)
            if (-not (Test-SIHasCommand 'Get-DnsClientServerAddress')) {
                return 'not available on this Windows version: the DNS of the adapter cannot be read'
            }
            $state = Get-SIDnsState
            if ($state.Index -le 0) {
                return 'not available: this computer has no network adapter with a default route'
            }
            return ''
        }
        StateScript = {
            param($option)
            $state = Get-SIDnsState
            if ($state.Index -le 0) {
                return @{ Status = 'NotAvailable'; Text = 'not available: no network adapter with a default route' }
            }
            $servers = @($state.Servers)
            if ($servers.Count -eq 0) { $servers = @($state.Saved) }
            if ($servers.Count -eq 0) {
                return @{ Status = 'NotApplied'; Text = 'The DNS comes from the network (DHCP)'; Details = $state.Alias }
            }
            return @{ Status = 'Applied'; Text = ('DNS: ' + ($servers -join ', ')); Details = $state.Alias }
        }
        SnapshotScript = {
            $state = Get-SIDnsState
            return @{
                PreviousServers = @($state.Saved)
                WasDhcp         = [bool]$state.Dhcp
                InterfaceIndex  = [int]$state.Index
            }
        }
        ApplyScript = {
            $server = [string]$script:SISelectedDns
            if (-not $server) { throw 'no DNS server was chosen. Run the DNS test in the Advanced section first.' }
            $state = Get-SIDnsState
            if ($state.Index -le 0) { throw 'there is no network adapter with a default route.' }
            Set-DnsClientServerAddress -InterfaceIndex $state.Index -ServerAddresses @($server) -ErrorAction Stop | Out-Null
            Write-SILog -Component 'Network' -Message "The DNS of $($state.Alias) is now $server."
            return @{ UsedServer = $server }
        }
        UndoScript = {
            param($Extra)
            if (-not $Extra) { return }
            $index = 0
            if ($Extra.Contains('InterfaceIndex')) { $index = [int]$Extra['InterfaceIndex'] }
            if ($index -le 0) { return }
            $wasDhcp = $true
            if ($Extra.Contains('WasDhcp')) { $wasDhcp = [bool]$Extra['WasDhcp'] }
            $servers = @()
            if ($Extra.Contains('PreviousServers')) { $servers = @($Extra['PreviousServers']) }
            if ($wasDhcp -or $servers.Count -eq 0) {
                Set-DnsClientServerAddress -InterfaceIndex $index -ResetServerAddresses -ErrorAction Stop | Out-Null
                Write-SILog -Component 'Network' -Message 'The DNS of the adapter goes back to the DHCP server of the network.'
            } else {
                Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $servers -ErrorAction Stop | Out-Null
                Write-SILog -Component 'Network' -Message "The DNS of the adapter goes back to $($servers -join ', ')."
            }
        }
    }

    # ------------------------------------------- Round 5: network throttling
    $tweaks += @{
        Id          = 'NetworkThrottling'
        Name        = 'Network throttling index'
        Description = 'Windows takes 10 % of the network for the background. This takes that away. A restart is needed.'
        Source      = 'Microsoft: learn.microsoft.com multimedia class scheduler service (MMCSS)'
        Group       = 'FPS'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'The network throttling is off (0xFFFFFFFF)'
        OffText     = 'The network throttling is at the Windows default (10)'
        Registry    = @(
            # 0xFFFFFFFF means "no throttling at all". The registry keeps the
            # four bytes, so the signed number -1 is the same value.
            @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'NetworkThrottlingIndex'; Type = 'DWord'; Value = 4294967295 }
        )
        StateScript = {
            param($option)
            $value = Get-SIRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex'
            if (-not $value.Exists) {
                return @{ Status = 'NotApplied'; Text = 'The network throttling is at the Windows default (10)'; Details = 'A restart is needed' }
            }
            $number = [int]$value.Value
            if ($number -eq -1) {
                return @{ Status = 'Applied'; Text = 'The network throttling is off (0xFFFFFFFF)'; Details = 'A restart is needed' }
            }
            return @{ Status = 'NotApplied'; Text = "The network throttling index is $number (Windows default 10)"; Details = 'A restart is needed' }
        }
    }

    # ------------------------------------------- Round 5: system responsiveness
    $tweaks += @{
        Id          = 'SystemResponsiveness'
        Name        = 'System responsiveness'
        Description = 'Windows keeps 20 % of the processor for the background. This leaves 10 % for it, so the game gets more. A restart is needed.'
        Source      = 'Microsoft: learn.microsoft.com multimedia class scheduler service (MMCSS)'
        Group       = 'FPS'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'The system responsiveness is 10 (Windows default 20)'
        OffText     = 'The system responsiveness is at the Windows default (20)'
        Registry    = @(
            @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Type = 'DWord'; Value = 10 }
        )
        StateScript = {
            param($option)
            $value = Get-SIRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness'
            if (-not $value.Exists) {
                return @{ Status = 'NotApplied'; Text = 'The system responsiveness is at the Windows default (20)'; Details = 'A restart is needed' }
            }
            $number = [int]$value.Value
            if ($number -eq 10) {
                return @{ Status = 'Applied'; Text = 'The system responsiveness is 10 (Windows default 20)'; Details = 'A restart is needed' }
            }
            return @{ Status = 'NotApplied'; Text = "The system responsiveness is $number (Windows default 20)"; Details = 'A restart is needed' }
        }
    }

    # ------------------------------------------ Round 5: transparency effects
    $tweaks += @{
        Id          = 'TransparencyEffects'
        Name        = 'Transparency effects'
        Description = 'Switches the transparent windows off. This is the same box as in Settings > Personalization > Colors.'
        Source      = 'Microsoft: Settings > Personalization > Colors (EnableTransparency)'
        Group       = 'Windows speed'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'The transparency effects are OFF'
        OffText     = 'The transparency effects are ON'
        Registry    = @(
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name = 'EnableTransparency'; Type = 'DWord'; Value = 0 }
        )
    }

    # ------------------------------------------------ Round 5: hibernation off
    $tweaks += @{
        Id          = 'HibernationOff'
        Name        = 'Hibernation'
        Description = 'Switches the hibernation off and frees the space of the file hiberfil.sys. Not recommended on a laptop.'
        Source      = 'WinUtil: WPFTweaksHiber (powercfg /hibernate off)'
        Group       = 'Windows speed'
        Gaming      = $true
        Optimize    = $true
        OnText      = 'The hibernation is off'
        OffText     = 'The hibernation is on'
        AvailabilityScript = {
            param($option)
            if (Get-SIIsLaptop) {
                return 'not recommended on a laptop'
            }
            return ''
        }
        StateScript = {
            param($option)
            $value = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HibernateEnabled'
            $enabled = $true
            if ($value.Exists -and [int]$value.Value -eq 0) { $enabled = $false }
            $size = Get-SIHiberFileSize
            $text = ''
            if ($size -gt 0) { $text = ('{0:0.0} GB are used by the hibernation file' -f ($size / 1GB)) }
            if ($enabled) {
                return @{ Status = 'NotApplied'; Text = 'The hibernation is on'; Details = $text }
            }
            return @{ Status = 'Applied'; Text = 'The hibernation is off'; Details = 'The space of the hibernation file is free' }
        }
        SnapshotScript = {
            $value = Get-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HiberFileSizePercent'
            $percent = 0
            if ($value.Exists) { $percent = [int]$value.Value }
            return @{ HiberFileSizePercent = $percent; FileSize = (Get-SIHiberFileSize) }
        }
        ApplyScript = {
            $free = Get-SIHiberFileSize
            (powercfg /hibernate off) | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "powercfg could not switch the hibernation off (exit code $LASTEXITCODE)." }
            Write-SILog -Component 'Power' -Message ('The hibernation is off, {0:0.0} GB are free.' -f ($free / 1GB))
            return @{ FreedBytes = $free }
        }
        UndoScript = {
            param($Extra)
            (powercfg /hibernate on) | Out-Null
            if ($Extra -and $Extra.Contains('HiberFileSizePercent') -and [int]$Extra.HiberFileSizePercent -gt 0) {
                Set-SIRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HiberFileSizePercent' -Value ([int]$Extra.HiberFileSizePercent) -Type 'DWord' | Out-Null
            }
            Write-SILog -Component 'Power' -Message 'The hibernation is on again.'
        }
    }

    $script:SITweakTableCache = $tweaks
    return $tweaks
}

