# ---------------------------------------------------------------------------
#  SIGAME - module 06: the WPF window
#
#  The window is built in code, so that every tweak can be added from the
#  table without touching the layout again. The XAML of Get-SIWindowXaml is
#  only the fallback.
# ---------------------------------------------------------------------------
# ============================ 9. THE WPF WINDOW ============================
#
#  The window is built in code so every tweak can be added from the table
#  above without touching the layout again.

function Get-SIWindowXaml {
    <#
    .SYNOPSIS
        The XAML of the SIGAME window. The SI NEWS look: dark #1b1f29 with
        the yellow #ffd23f.
    #>
    $c = $script:SIColors
    return @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SIGAME - gaming tweaks by SI NEWS"
        Width="1080" Height="760" MinWidth="980" MinHeight="580"
        WindowStartupLocation="CenterScreen"
        Background="$($c.Background)"
        Foreground="$($c.Text)"
        FontFamily="Segoe UI" FontSize="13"
        UseLayoutRounding="True">
  <Window.Resources>
    <Style TargetType="TextBlock">
      <Setter Property="Foreground" Value="$($c.Text)"/>
    </Style>
    <Style x:Key="AccentButton" TargetType="Button">
      <Setter Property="Background" Value="$($c.Accent)"/>
      <Setter Property="Foreground" Value="$($c.Background)"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="12,5,12,5"/>
      <Setter Property="MinWidth" Value="86"/>
      <Setter Property="Margin" Value="0,0,8,0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Opacity" Value="0.85"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="Bd" Property="Opacity" Value="0.35"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="GhostButton" TargetType="Button">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="$($c.Accent)"/>
      <Setter Property="BorderBrush" Value="$($c.Accent)"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="12,5,12,5"/>
      <Setter Property="MinWidth" Value="86"/>
      <Setter Property="Margin" Value="0,0,8,0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="$($c.PanelAlt)"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="Bd" Property="Opacity" Value="0.35"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Background="$($c.Panel)" Padding="16,10,16,10">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <Image x:Name="LogoImage" Grid.Column="0" Width="54" Height="54" Margin="0,0,14,0" Stretch="Uniform"/>
        <StackPanel Grid.Column="1" VerticalAlignment="Center">
          <TextBlock Text="SIGAME" FontSize="26" FontWeight="Bold" Foreground="$($c.Accent)"/>
          <TextBlock x:Name="SubtitleText" FontSize="12" Foreground="$($c.Muted)"/>
        </StackPanel>
        <StackPanel Grid.Column="3" VerticalAlignment="Center" HorizontalAlignment="Right">
          <TextBlock x:Name="HeaderSystem" FontSize="12" Foreground="$($c.Muted)" HorizontalAlignment="Right"/>
          <TextBlock x:Name="HeaderRestore" FontSize="12" Foreground="$($c.Muted)" HorizontalAlignment="Right" Text="Restore point: waiting ..."/>
          <TextBlock x:Name="HeaderBackup" FontSize="12" Foreground="$($c.Muted)" HorizontalAlignment="Right" Text="Backup: waiting ..."/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Grid.Row="1" Background="$($c.Panel)" Padding="16,12,16,12">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <Button x:Name="BtnOptimize" Content="OPTIMIZE" Style="{StaticResource AccentButton}" Width="258" Height="64" FontSize="23"/>
          <WrapPanel Margin="0,8,0,0">
            <Button x:Name="BtnBoost" Content="GAME BOOST" Style="{StaticResource AccentButton}" Width="125" Height="32" FontSize="12"/>
            <Button x:Name="BtnGameOver" Content="GAME OVER" Style="{StaticResource GhostButton}" Width="125" Height="32" FontSize="12"/>
          </WrapPanel>
          <TextBlock x:Name="OptimizeResult" FontSize="12" Foreground="$($c.Muted)" Width="258" TextWrapping="Wrap" Margin="0,6,0,0"/>
        </StackPanel>

        <Border Grid.Column="1" Background="$($c.PanelAlt)" Padding="16,8,16,8" Margin="16,0,16,0">
          <StackPanel>
            <TextBlock x:Name="ProveTitle" FontSize="13" FontWeight="Bold" Foreground="$($c.Accent)"/>
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
              </Grid.ColumnDefinitions>
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
              </Grid.RowDefinitions>
              <TextBlock Grid.Row="0" Grid.Column="0" x:Name="ProveLabel_FreeRamMB" FontSize="12" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="0,0,16,0"/>
              <TextBlock Grid.Row="0" Grid.Column="1" x:Name="ProveBefore_FreeRamMB" Text="-" FontSize="21" FontWeight="Bold" Width="108" TextAlignment="Right" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="0" Grid.Column="2" Text="-&gt;" FontSize="18" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="10,0,10,0"/>
              <TextBlock Grid.Row="0" Grid.Column="3" x:Name="ProveAfter_FreeRamMB" Text="-" FontSize="21" FontWeight="Bold" Foreground="$($c.Ok)" Width="108" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="1" Grid.Column="0" x:Name="ProveLabel_StartupAppsOn" FontSize="12" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="0,0,16,0"/>
              <TextBlock Grid.Row="1" Grid.Column="1" x:Name="ProveBefore_StartupAppsOn" Text="-" FontSize="21" FontWeight="Bold" Width="108" TextAlignment="Right" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="1" Grid.Column="2" Text="-&gt;" FontSize="18" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="10,0,10,0"/>
              <TextBlock Grid.Row="1" Grid.Column="3" x:Name="ProveAfter_StartupAppsOn" Text="-" FontSize="21" FontWeight="Bold" Foreground="$($c.Ok)" Width="108" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="2" Grid.Column="0" x:Name="ProveLabel_DnsMs" FontSize="12" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="0,0,16,0"/>
              <TextBlock Grid.Row="2" Grid.Column="1" x:Name="ProveBefore_DnsMs" Text="-" FontSize="21" FontWeight="Bold" Width="108" TextAlignment="Right" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="2" Grid.Column="2" Text="-&gt;" FontSize="18" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="10,0,10,0"/>
              <TextBlock Grid.Row="2" Grid.Column="3" x:Name="ProveAfter_DnsMs" Text="-" FontSize="21" FontWeight="Bold" Foreground="$($c.Ok)" Width="108" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="3" Grid.Column="0" x:Name="ProveLabel_SpeedMbps" FontSize="12" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="0,0,16,0"/>
              <TextBlock Grid.Row="3" Grid.Column="1" x:Name="ProveBefore_SpeedMbps" Text="-" FontSize="21" FontWeight="Bold" Width="108" TextAlignment="Right" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="3" Grid.Column="2" Text="-&gt;" FontSize="18" Foreground="$($c.Muted)" VerticalAlignment="Center" Margin="10,0,10,0"/>
              <TextBlock Grid.Row="3" Grid.Column="3" x:Name="ProveAfter_SpeedMbps" Text="-" FontSize="21" FontWeight="Bold" Foreground="$($c.Ok)" Width="108" VerticalAlignment="Center"/>
            </Grid>
            <TextBlock x:Name="ProveLine" FontSize="13" FontWeight="SemiBold" Foreground="$($c.Text)" Margin="0,6,0,0"/>
          </StackPanel>
        </Border>

        <StackPanel Grid.Column="2" VerticalAlignment="Center">
          <Button x:Name="BtnUndoAllBig" Content="UNDO ALL" Style="{StaticResource GhostButton}" Width="200" Height="64" FontSize="20" Margin="0,0,0,8"/>
          <Button x:Name="BtnMeasure" Content="Measure" Style="{StaticResource GhostButton}" Width="200" Height="30" Margin="0,0,0,6"/>
          <Button x:Name="BtnSaveCard" Content="Save my result" Style="{StaticResource AccentButton}" Width="200" Height="30" Margin="0,0,0,6"/>
          <TextBlock x:Name="BoostResult" FontSize="12" FontWeight="Bold" Foreground="$($c.Ok)" Width="200" TextWrapping="Wrap"/>
          <TextBlock x:Name="BoostPlan" FontSize="10" Foreground="$($c.Muted)" Width="200" TextWrapping="Wrap"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Grid.Row="2" Background="$($c.Panel)" Padding="16,6,16,6">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <ProgressBar x:Name="ProgressBar" Grid.Column="0" Height="8" Minimum="0" Maximum="100" Value="0"
                     Background="$($c.PanelAlt)" Foreground="$($c.Accent)" BorderThickness="0" VerticalAlignment="Center"/>
        <TextBlock x:Name="ProgressText" Grid.Column="1" FontSize="11" Foreground="$($c.Muted)" Margin="12,0,0,0" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
      </Grid>
    </Border>

    <Expander x:Name="AdvancedExpander" Grid.Row="3" Header="Advanced" Foreground="$($c.Accent)" IsExpanded="False" Margin="4,0,4,0">
      <Grid x:Name="AdvancedHost" Height="300"/>
    </Expander>

    <Border Grid.Row="4" Padding="16,6,16,6" Background="$($c.Panel)">
      <DockPanel>
        <TextBlock x:Name="BackupInfo" DockPanel.Dock="Right" FontSize="11" Foreground="$($c.Muted)" Margin="10,0,0,0"/>
        <TextBlock x:Name="StatusText" FontSize="12" TextTrimming="CharacterEllipsis"/>
      </DockPanel>
    </Border>

    <Border Grid.Row="5" Background="#151824" BorderBrush="$($c.Panel)" BorderThickness="0,1,0,1">
      <TextBox x:Name="LogBox" Background="Transparent" Foreground="#c9cede" BorderThickness="0" Padding="12,8,12,8"
               FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="NoWrap"
               VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"/>
    </Border>

    <Border Grid.Row="6" Background="$($c.Panel)" Padding="16,6,16,6">
      <StackPanel>
        <TextBlock x:Name="TrustText" FontSize="11" Foreground="$($c.Ok)"/>
        <TextBlock x:Name="FooterText" FontSize="11" Foreground="$($c.Muted)"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
"@
}

function Add-SIGridRow {
    <#
    .SYNOPSIS
        Adds one line to a grid.
    #>
    param(
        $Grid,
        [string]$Type = 'Auto',
        [double]$Value = 0
    )
    $definition = [System.Windows.Controls.RowDefinition]::new()
    if ($Type -eq 'Star') {
        $definition.Height = [System.Windows.GridLength]::new($Value, [System.Windows.GridUnitType]::Star)
    } elseif ($Type -eq 'Fixed') {
        $definition.Height = [System.Windows.GridLength]::new($Value)
    } else {
        $definition.Height = [System.Windows.GridLength]::new([double]0, [System.Windows.GridUnitType]::Auto)
    }
    $null = $Grid.RowDefinitions.Add($definition)
}

function Add-SIGridColumn {
    <#
    .SYNOPSIS
        Adds one column to a grid.
    #>
    param(
        $Grid,
        [string]$Type = 'Auto',
        [double]$Value = 0
    )
    $definition = [System.Windows.Controls.ColumnDefinition]::new()
    if ($Type -eq 'Star') {
        $definition.Width = [System.Windows.GridLength]::new($Value, [System.Windows.GridUnitType]::Star)
    } elseif ($Type -eq 'Fixed') {
        $definition.Width = [System.Windows.GridLength]::new($Value)
    } else {
        $definition.Width = [System.Windows.GridLength]::new([double]0, [System.Windows.GridUnitType]::Auto)
    }
    $null = $Grid.ColumnDefinitions.Add($definition)
}

function Get-SIButtonTemplate {
    <#
    .SYNOPSIS
        The flat button of SI NEWS, built in code.

    .DESCRIPTION
        A rounded border that dims itself when the mouse is on it and when
        the button is switched off. The template is built once and then
        shared by every button of the window.

        If anything of this does not work on the machine of the owner, the
        button simply keeps the normal WPF look. That is why every step is
        inside a try.
    #>
    if ($script:SIButtonTemplate) { return $script:SIButtonTemplate }

    $template = $null
    try {
        $border = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Border])
        $border.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(4))
        $border.SetValue([System.Windows.Controls.Border]::PaddingProperty, [System.Windows.Thickness]::new(12, 5, 12, 5))
        $border.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, [System.Windows.Thickness]::new(1))
        $border.AttachTemplateBinding([System.Windows.Controls.Border]::BackgroundProperty, [System.Windows.Controls.Border]::BackgroundProperty)
        $border.AttachTemplateBinding([System.Windows.Controls.Border]::BorderBrushProperty, [System.Windows.Controls.Border]::BorderBrushProperty)
        $border.AttachTemplateBinding([System.Windows.Controls.Border]::BorderThicknessProperty, [System.Windows.Controls.Border]::BorderThicknessProperty)
        $border.AttachTemplateBinding([System.Windows.Controls.Border]::PaddingProperty, [System.Windows.Controls.Border]::PaddingProperty)

        $presenter = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.ContentPresenter])
        $presenter.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
        $presenter.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)
        $null = $border.AppendChild($presenter)

        $template = [System.Windows.Controls.ControlTemplate]::new([System.Windows.Controls.Button])
        $template.VisualTree = $border

        # The button dims itself when the mouse is on it ...
        $hover = [System.Windows.Trigger]::new()
        $hover.Property = [System.Windows.UIElement]::IsMouseOverProperty
        $hover.Value = $true
        $hoverSetter = [System.Windows.Setter]::new()
        $hoverSetter.Property = [System.Windows.UIElement]::OpacityProperty
        $hoverSetter.Value = 0.85
        $null = $hover.Setters.Add($hoverSetter)
        $null = $template.Triggers.Add($hover)

        # ... and when it is switched off.
        $off = [System.Windows.Trigger]::new()
        $off.Property = [System.Windows.UIElement]::IsEnabledProperty
        $off.Value = $false
        $offSetter = [System.Windows.Setter]::new()
        $offSetter.Property = [System.Windows.UIElement]::OpacityProperty
        $offSetter.Value = 0.35
        $null = $off.Setters.Add($offSetter)
        $null = $template.Triggers.Add($off)

        $template.Seal()
    } catch {
        $template = $null
    }

    $script:SIButtonTemplate = $template
    return $template
}

function New-SIStyleButton {
    <#
    .SYNOPSIS
        One flat button in the SI NEWS colours.
    #>
    param(
        [string]$Text,
        [string]$StyleKey,
        $Window,
        [int]$Width = 0
    )
    $button = [System.Windows.Controls.Button]::new()
    $button.Content = $Text
    $button.Height = 30
    $button.MinWidth = 86
    $button.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
    $button.Padding = [System.Windows.Thickness]::new(12, 5, 12, 5)
    $button.FontWeight = 'SemiBold'
    if ($Width -gt 0) { $button.Width = $Width }

    $accent = Get-SIBrush $script:SIColors.Accent
    if ($StyleKey -eq 'GhostButton') {
        $button.Background = [System.Windows.Media.Brushes]::Transparent
        $button.Foreground = $accent
        $button.BorderBrush = $accent
    } else {
        $button.Background = $accent
        $button.Foreground = Get-SIBrush $script:SIColors.Background
        $button.BorderBrush = $accent
    }
    $button.BorderThickness = [System.Windows.Thickness]::new(1)

    $template = Get-SIButtonTemplate
    if ($template) { $button.Template = $template }

    return $button
}

function New-SITweakRow {
    <#
    .SYNOPSIS
        Builds the row of one tweak: tick box, name, state, option and the
        Apply and Undo buttons.
    #>
    param($Tweak, $Window)

    $c = $script:SIColors

    $border = [System.Windows.Controls.Border]::new()
    $border.Background = Get-SIBrush $c.Panel
    $border.Padding = [System.Windows.Thickness]::new(10, 8, 10, 8)
    $border.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)

    $grid = [System.Windows.Controls.Grid]::new()
    # The six columns have to fit into the window together with the padding of
    # the row, the padding of the scroll area and the scroll bar, otherwise the
    # Undo button is cut off on a narrow window.
    $widths = @(34, 250, 220, 185, 92, 92)
    for ($index = 0; $index -lt $widths.Count; $index++) {
        # ColumnDefinition lives in System.Windows.Controls, not in
        # System.Windows. The wrong namespace does not exist in WPF for
        # .NET Framework, so "[System.Windows.ColumnDefinition]::new()"
        # is a runtime error and the window never opened.
        $column = [System.Windows.Controls.ColumnDefinition]::new()
        $column.Width = [System.Windows.GridLength]::new([double]$widths[$index])
        $null = $grid.ColumnDefinitions.Add($column)
    }

    # --- tick box ---------------------------------------------------------
    $tick = [System.Windows.Controls.CheckBox]::new()
    $tick.VerticalAlignment = 'Center'
    $tick.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)
    $tick.ToolTip = 'Tick this tweak and use "Apply checked" to apply it together with the other ticked tweaks.'
    [System.Windows.Controls.Grid]::SetColumn($tick, 0)
    $null = $grid.Children.Add($tick)

    # --- name and description ---------------------------------------------
    $names = [System.Windows.Controls.StackPanel]::new()
    $nameText = [System.Windows.Controls.TextBlock]::new()
    $nameText.Text = $Tweak.Name
    $nameText.FontWeight = 'SemiBold'
    $nameText.FontSize = 13
    $names.Children.Add($nameText) | Out-Null

    $descriptionText = [System.Windows.Controls.TextBlock]::new()
    $descriptionText.Text = $Tweak.Description
    $descriptionText.FontSize = 11
    $descriptionText.Foreground = Get-SIBrush $c.Muted
    # The text is NOT wrapped. A wrapped TextBlock has to be measured again
    # and again, and that is the most expensive thing in the whole window on
    # a slow machine. The full text stays reachable through the tool tip.
    $descriptionText.TextWrapping = 'NoWrap'
    $descriptionText.TextTrimming = 'CharacterEllipsis'
    $descriptionText.ToolTip = $Tweak.Description
    $descriptionText.Margin = [System.Windows.Thickness]::new(0, 2, 8, 0)
    $names.Children.Add($descriptionText) | Out-Null

    $sourceText = [System.Windows.Controls.TextBlock]::new()
    $sourceText.Text = $Tweak.Source
    $sourceText.FontSize = 10
    $sourceText.Foreground = Get-SIBrush '#5d6577'
    $sourceText.TextWrapping = 'NoWrap'
    $sourceText.TextTrimming = 'CharacterEllipsis'
    $sourceText.ToolTip = $Tweak.Source
    $names.Children.Add($sourceText) | Out-Null

    [System.Windows.Controls.Grid]::SetColumn($names, 1)
    $grid.Children.Add($names) | Out-Null

    # --- the real current state -------------------------------------------
    $stateStack = [System.Windows.Controls.StackPanel]::new()
    $stateText = [System.Windows.Controls.TextBlock]::new()
    # The real state is read by the background copy of SIGAME, so the row
    # starts with a "loading ..." and is filled in as soon as the answer is
    # there.
    $stateText.Text = 'loading ...'
    $stateText.FontSize = 12
    $stateText.TextWrapping = 'Wrap'
    $stateStack.Children.Add($stateText) | Out-Null

    $detailText = [System.Windows.Controls.TextBlock]::new()
    $detailText.Text = ''
    $detailText.FontSize = 10
    $detailText.Foreground = Get-SIBrush $c.Muted
    $detailText.TextWrapping = 'Wrap'
    $stateStack.Children.Add($detailText) | Out-Null

    [System.Windows.Controls.Grid]::SetColumn($stateStack, 2)
    $grid.Children.Add($stateStack) | Out-Null

    # --- the option combo box ----------------------------------------------
    $combo = $null
    if ($Tweak.Contains('Options') -and $Tweak.Options) {
        $combo = [System.Windows.Controls.ComboBox]::new()
        $combo.Width = 180
        $combo.VerticalAlignment = 'Center'
        $combo.Background = Get-SIBrush $c.PanelAlt
        $combo.Foreground = Get-SIBrush $c.Text
        foreach ($option in $Tweak.Options) { $combo.Items.Add([string]$option) | Out-Null }
        $combo.SelectedIndex = 0
        # Show the option that matches the real current state of the system.
        if ($Tweak.Contains('DetectOption') -and $Tweak.DetectOption) {
            try {
                $current = & $Tweak.DetectOption
                if ($current) {
                    $index = $combo.Items.IndexOf([string]$current)
                    if ($index -ge 0) { $combo.SelectedIndex = $index }
                }
            } catch {
                Write-SILog -Level 'WARN' -Component 'UI' -Message "Could not read the current state of $($Tweak.Name): $($_.Exception.Message)"
            }
        }
        [System.Windows.Controls.Grid]::SetColumn($combo, 3)
        $grid.Children.Add($combo) | Out-Null
    }

    # --- Apply and Undo ----------------------------------------------------
    $applyButton = New-SIStyleButton -Text 'Apply' -StyleKey 'AccentButton' -Window $Window -Width 82
    $applyButton.ToolTip = 'Applies this tweak and saves the original values in the JSON backup.'
    $undoButton = New-SIStyleButton -Text 'Undo' -StyleKey 'GhostButton' -Window $Window -Width 82
    $undoButton.ToolTip = 'Puts back the values that were stored in the JSON backup.'

    # Nothing may be changed before the System Restore point and the JSON
    # backup are done, so the buttons stay off until then.
    $applyButton.IsEnabled = $false
    $undoButton.IsEnabled = $false

    if ($Tweak.Contains('ShowOnly') -and $Tweak.ShowOnly) {
        $applyButton.IsEnabled = $false
        $undoButton.IsEnabled = $false
        $applyButton.ToolTip = 'This one is shown for information only. SIGAME never switches memory integrity.'
        $undoButton.ToolTip = $applyButton.ToolTip
    }

    # A tweak that cannot work on this Windows version says so at once and
    # is never applied. The Undo button stays on, so that a change that was
    # made on another Windows version can still be put back.
    $available = $true
    $unavailable = Get-SITweakAvailability -Tweak $Tweak
    if ($unavailable) {
        $available = $false
        $stateText.Text = "Not available: $unavailable"
        $stateText.Foreground = Get-SIBrush $c.Muted
        $stateText.ToolTip = $unavailable
        $detailText.Text = ''
        $applyButton.IsEnabled = $false
        $applyButton.ToolTip = "Not available on this system: $unavailable"
        $tick.IsEnabled = $false
        $tick.ToolTip = "Not available on this system: $unavailable"
    }

    [System.Windows.Controls.Grid]::SetColumn($applyButton, 4)
    $grid.Children.Add($applyButton) | Out-Null
    [System.Windows.Controls.Grid]::SetColumn($undoButton, 5)
    $grid.Children.Add($undoButton) | Out-Null

    $border.Child = $grid

    # --- events -------------------------------------------------------------
    # The handlers are closed over the value of $tweakId. A script block of
    # WPF is not a closure: it runs later, when the function that made it is
    # long gone, and the variable would be empty. With GetNewClosure the
    # value of the variable of THIS row is taken with the handler, so that
    # the Apply and the Undo of every row always work on their own row.
    $tweakId = $Tweak.Id
    $null = $applyButton.Add_Click({ Invoke-SIApplyTweak -TweakId $tweakId }.GetNewClosure())
    $null = $undoButton.Add_Click({ Invoke-SIUndoTweak -TweakId $tweakId }.GetNewClosure())
    if ($combo) {
        $null = $combo.Add_SelectionChanged({ Update-SIStates -OnlyId $tweakId }.GetNewClosure())
    }

    return [pscustomobject]@{
        Border    = $border
        Tick      = $tick
        StateText = $stateText
        DetailText = $detailText
        Combo     = $combo
        Apply     = $applyButton
        Undo      = $undoButton
        Available = $available
        ShowOnly  = ($Tweak.Contains('ShowOnly') -and $Tweak.ShowOnly)
    }
}

function Set-SIButtonsEnabled {
    <#
    .SYNOPSIS
        Switches the Apply and Undo buttons of every row on or off.

    .DESCRIPTION
        The buttons stay off while SIGAME is still starting up, so that
        nothing can be changed before the System Restore point was made. A row
        that is only shown for information always stays off.
    #>
    param([bool]$Enabled)

    foreach ($id in @($script:SIRows.Keys)) {
        $row = $script:SIRows[$id]
        if (-not $row) { continue }
        $tweak = $script:SITweaks[$id]
        $showOnly = $false
        if ($tweak -and $tweak.Contains('ShowOnly') -and $tweak.ShowOnly) { $showOnly = $true }
        # A tweak that is not available on this system keeps its Apply
        # button off, whatever the rest of the window does.
        $available = $true
        if ($null -ne $row.Available) { $available = [bool]$row.Available }
        $on = ($Enabled -and -not $showOnly -and $available)
        if ($row.Apply) { $row.Apply.IsEnabled = $on }
        if ($row.Undo) { $row.Undo.IsEnabled = $on }
    }

    # The two big buttons on top change the machine as well, so they wait for
    # the System Restore point and the JSON backup as well.
    $window = $script:SIWindow
    if ($window) {
        foreach ($name in @('BtnGaming', 'BtnApplyChecked', 'BtnOptimize')) {
            $button = Get-SIElement -Name $name
            if ($button) { $button.IsEnabled = $Enabled }
        }
        # The measure only reads, so it is always allowed.
        $measure = Get-SIElement -Name 'BtnMeasure'
        if ($measure) { $measure.IsEnabled = $true }
        # The undo all also waits: without the backup there is nothing to undo.
        $undo = Get-SIElement -Name 'BtnUndoAllBig'
        if ($undo) { $undo.IsEnabled = $Enabled }
    }
}

function Set-SIRowState {
    <#
    .SYNOPSIS
        Writes the state of one tweak into its row.

    .DESCRIPTION
        Used by the two ways a state arrives: read in this process (Refresh,
        after an Apply) and read by the background copy of SIGAME.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [string]$Status = 'NotApplied',
        [string]$Text = '',
        [string]$Details = ''
    )

    if (-not $script:SIRows.ContainsKey($Id)) { return }
    $row = $script:SIRows[$Id]
    if (-not $row) { return }

    $row.StateText.Text = $Text
    switch ($Status) {
        'Applied'   { $row.StateText.Foreground = Get-SIBrush $script:SIColors.Ok }
        'Partial'   { $row.StateText.Foreground = Get-SIBrush $script:SIColors.Warn }
        'NotAvailable' { $row.StateText.Foreground = Get-SIBrush $script:SIColors.Muted }
        default     { $row.StateText.Foreground = Get-SIBrush $script:SIColors.Off }
    }
    $row.DetailText.Text = $Details
    $row.StateText.ToolTip = $Details

    # A tweak that is not available on this system cannot be applied. Its
    # Undo stays on, so that a change that was made on another Windows
    # version can still be put back.
    $row.Available = ($Status -ne 'NotAvailable')
    if ($row.Apply) {
        if (-not $row.Available) {
            $row.Apply.IsEnabled = $false
            $row.Apply.ToolTip = "Not available on this system: $Text"
        } elseif ($script:SIPrepared -and -not $row.ShowOnly) {
            $row.Apply.IsEnabled = $true
            $row.Apply.ToolTip = 'Applies this tweak and saves the original values in the JSON backup.'
        }
    }
}

function Update-SIStates {
    <#
    .SYNOPSIS
        Re-reads the real state of every tweak and refreshes the rows.

    .DESCRIPTION
        This runs in the window process, so it is only used for a single row
        (after an Apply or Undo) and for the small changes. The first reading
        of all the rows is done by the background copy of SIGAME, so that the
        window never freezes.
    #>
    param([string]$OnlyId)

    if ($script:SIUpdatingStates) { return }
    $script:SIUpdatingStates = $true
    try {
        foreach ($id in @($script:SITweaks.Keys)) {
            if ($OnlyId -and ($OnlyId -ne $id)) { continue }
            if (-not $script:SIRows.ContainsKey($id)) { continue }

            $tweak = $script:SITweaks[$id]
            $state = Get-SITweakState -Tweak $tweak

            Set-SIRowState -Id $id -Status $state.Status -Text $state.Text -Details $state.Details

            # Keep the window alive while the next row is read.
            Invoke-SIUIPump
        }
    } finally {
        $script:SIUpdatingStates = $false
    }
}

function Show-SIMessage {
    <#
    .SYNOPSIS
        A small message box that always comes back with Yes or No.
    #>
    param(
        $Window,
        [string]$Text,
        [string]$Title = 'SIGAME'
    )
    $answer = [System.Windows.MessageBox]::Show(
        $Window, $Text, $Title,
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question)
    return ($answer -eq [System.Windows.MessageBoxResult]::Yes)
}

function Invoke-SIGamingPreset {
    <#
    .SYNOPSIS
        The GAMING preset: every gaming tweak of SIGAME, one after the other.

    .DESCRIPTION
        It is a FUNCTION and not a script block inside the window, and that
        is not a style: a script block that was made with GetNewClosure() has
        its own scope and does NOT see the variables of the script scope.
        The table of the tweaks ($script:SITweaks) would be empty there, and
        the preset would apply nothing at all. A function always reads the
        state of the program.
    #>
    param($Window)

    $text = 'The GAMING preset applies the gaming tweaks of SIGAME. A System Restore point is not needed again, every original value is in the JSON backup and every tweak can be undone.'
    if (-not (Show-SIMessage -Window $Window -Text $text -Title 'GAMING preset')) { return }

    if (-not $script:SIPrepared) {
        Set-SIStatusText -Text 'SIGAME is still starting up, please wait a moment.'
        return
    }

    # The laptop test is a slow WMI query. The background copy has
    # already done it, so the window only asks when the answer is
    # not there yet.
    $isLaptop = $script:SIIsLaptop
    if ($null -eq $isLaptop) { $isLaptop = Test-SILaptop }

    foreach ($id in @($script:SITweaks.Keys)) {
        $tweak = $script:SITweaks[$id]
        if (-not $tweak) { continue }
        if (-not ($tweak.Contains('Gaming') -and $tweak.Gaming)) { continue }
        if ($tweak.Contains('ShowOnly') -and $tweak.ShowOnly) { continue }
        # A tweak that does not exist on this Windows version is
        # skipped, not applied and not failed.
        $unavailable = Get-SITweakAvailability -Tweak $tweak
        if ($unavailable) {
            Write-SILog -Component 'Tweak' -Message "$($tweak.Name) was skipped: $unavailable"
            Set-SIStatusText -Text "$($tweak.Name) skipped: not available on this system."
            continue
        }
        if ($id -eq 'UltimatePerformance' -and $isLaptop) {
            Write-SILog -Level 'WARN' -Component 'Tweak' -Message 'Ultimate Performance was skipped: this machine looks like a laptop.'
            Set-SIStatusText -Text 'Ultimate Performance skipped, this is a laptop.'
            continue
        }
        # A tweak with a choice gets the gaming choice before it is applied.
        if ($tweak.Contains('GamingOption') -and $tweak.GamingOption) {
            if ($script:SIRows.ContainsKey($id)) {
                $combo = $script:SIRows[$id].Combo
                if ($combo) {
                    $index = $combo.Items.IndexOf([string]$tweak.GamingOption)
                    if ($index -ge 0) { $combo.SelectedIndex = $index }
                }
                $script:SIRows[$id].Tick.IsChecked = $true
            }
            else {
                # The rows are not on the screen (the Advanced section was
                # never opened), so the choice is given to the apply
                # itself.
                $script:SIOptionOverride[$id] = [string]$tweak.GamingOption
            }
        }
        elseif ($script:SIRows.ContainsKey($id)) {
            $script:SIRows[$id].Tick.IsChecked = $true
        }
        Invoke-SIApplyTweak -TweakId $id
    }

    $script:SIOptionOverride = @{}
    Set-SIStatusText -Text 'The GAMING preset is applied.'
}

function Build-SIRows {
    <#
    .SYNOPSIS
        Builds the row of every tweak of the table.

    .DESCRIPTION
        This runs AFTER the window is on the screen. Every row starts with
        "loading ..." and is filled in as soon as the background copy of
        SIGAME has read the real state of that tweak.

        The window is pumped after every row, so that the rows appear one
        after the other and the window never freezes.
    #>
    $window = $script:SIWindow
    if (-not $window) { return }
    $panel = Get-SIElement -Name 'TweakPanel'
    if (-not $panel) { return }

    $c = $script:SIColors
    $lastGroup = ''
    foreach ($tweak in (Get-SITweakTable)) {
        $script:SITweaks[$tweak.Id] = $tweak

        if ($tweak.Group -ne $lastGroup) {
            $lastGroup = $tweak.Group
            $heading = [System.Windows.Controls.TextBlock]::new()
            $heading.Text = $lastGroup
            $heading.FontSize = 12
            $heading.FontWeight = 'Bold'
            $heading.Foreground = Get-SIBrush $c.Accent
            $heading.Margin = [System.Windows.Thickness]::new(4, 12, 0, 2)
            $panel.Children.Add($heading) | Out-Null
        }

        $row = New-SITweakRow -Tweak $tweak -Window $window
        $script:SIRows[$tweak.Id] = $row
        $panel.Children.Add($row.Border) | Out-Null

        # A state that the background copy has already read is put into the
        # row right now, so that no row stays on "loading ...".
        if ($script:SIWorkerStates.ContainsKey($tweak.Id)) {
            $state = $script:SIWorkerStates[$tweak.Id]
            Set-SIRowState -Id $tweak.Id -Status ([string]$state['Status']) `
                           -Text ([string]$state['Text']) -Details ([string]$state['Details'])
        }

        # The window is pumped, so that the new row is painted right away
        # and the mouse still works.
        Invoke-SIUIPump -Milliseconds 20
    }
}

function Get-SIElement {
    <#
    .SYNOPSIS
        One named element of the window.

    .DESCRIPTION
        The window that is built in code keeps its elements in a table, the
        XAML window has them in its namescope. This function finds both.
    #>
    param([Parameter(Mandatory = $true)][string]$Name)

    if ($script:SINames -and $script:SINames.ContainsKey($Name)) { return $script:SINames[$Name] }
    $window = $script:SIWindow
    if ($window) { return $window.FindName($Name) }
    return $null
}

function New-SIWindowXaml {
    <#
    .SYNOPSIS
        Builds the window from the XAML of Get-SIWindowXaml.

    .DESCRIPTION
        This is the fallback for the case that the window cannot be built
        in code on the machine of the owner. It is the version that was
        measured before, so it is kept as it is.
    #>
    $xaml = Get-SIWindowXaml
    # The XAML reader needs System.Xaml, and the loader only asks for
    # PresentationFramework (the window in code does not need it). Without
    # this line the fallback fails with "Could not load file or assembly
    # 'System.Xaml'" and the program has no window at all.
    try { Add-Type -AssemblyName System.Xaml -ErrorAction Stop } catch { }
    $document = New-Object System.Xml.XmlDocument
    $document.LoadXml($xaml)
    $reader = New-Object System.Xml.XmlNodeReader $document
    return [System.Windows.Markup.XamlReader]::Load($reader)
}

function New-SIWindowCode {
    <#
    .SYNOPSIS
        Builds the SIGAME window in code, without the XAML reader.

    .DESCRIPTION
        The first time the XAML reader parses a window it needs seconds on
        a slow machine: it loads System.Xaml and looks at the whole type
        system of WPF. The window of SIGAME has to be on the screen in a
        couple of seconds, so it is built with the WPF controls directly.

        The layout is the same as the XAML of Get-SIWindowXaml: a header
        with the logo, a toolbar, the list of the tweaks, the status line,
        the log and the footer.
    #>
    $c = $script:SIColors
    $script:SINames = @{}

    $window = [System.Windows.Window]::new()
    $window.Title = 'SIGAME - gaming tweaks by SI NEWS'
    $window.Width = 1080
    $window.Height = 700
    $window.MinWidth = 900
    $window.MinHeight = 520
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $window.Background = Get-SIBrush $c.Background
    $window.Foreground = Get-SIBrush $c.Text
    $window.FontFamily = [System.Windows.Media.FontFamily]::new('Segoe UI')
    $window.FontSize = 13
    $window.UseLayoutRounding = $true

    $root = [System.Windows.Controls.Grid]::new()
    $window.Content = $root
    Add-SIGridRow -Grid $root -Type 'Auto'
    Add-SIGridRow -Grid $root -Type 'Auto'
    Add-SIGridRow -Grid $root -Type 'Auto'
    Add-SIGridRow -Grid $root -Type 'Auto'
    Add-SIGridRow -Grid $root -Type 'Auto'
    Add-SIGridRow -Grid $root -Type 'Star' -Value 1
    Add-SIGridRow -Grid $root -Type 'Auto'

    # --- the header ---------------------------------------------------------
    $header = [System.Windows.Controls.Border]::new()
    $header.Background = Get-SIBrush $c.Panel
    $header.Padding = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $headerGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridColumn -Grid $headerGrid -Type 'Auto'
    Add-SIGridColumn -Grid $headerGrid -Type 'Auto'
    Add-SIGridColumn -Grid $headerGrid -Type 'Star' -Value 1
    Add-SIGridColumn -Grid $headerGrid -Type 'Auto'
    $header.Child = $headerGrid

    $logo = [System.Windows.Controls.Image]::new()
    $logo.Width = 54
    $logo.Height = 54
    $logo.Margin = [System.Windows.Thickness]::new(0, 0, 14, 0)
    $logo.Stretch = [System.Windows.Media.Stretch]::Uniform
    [System.Windows.Controls.Grid]::SetColumn($logo, 0)
    $null = $headerGrid.Children.Add($logo)
    $script:SINames['LogoImage'] = $logo

    $titleStack = [System.Windows.Controls.StackPanel]::new()
    $titleStack.VerticalAlignment = 'Center'
    $titleText = [System.Windows.Controls.TextBlock]::new()
    $titleText.Text = 'SIGAME'
    $titleText.FontSize = 26
    $titleText.FontWeight = 'Bold'
    $titleText.Foreground = Get-SIBrush $c.Accent
    $null = $titleStack.Children.Add($titleText)
    $subtitleText = [System.Windows.Controls.TextBlock]::new()
    $subtitleText.Text = (Get-SIText -Key 'Subtitle')
    $subtitleText.FontSize = 12
    $subtitleText.Foreground = Get-SIBrush $c.Muted
    $script:SINames['SubtitleText'] = $subtitleText
    $null = $titleStack.Children.Add($subtitleText)
    [System.Windows.Controls.Grid]::SetColumn($titleStack, 1)
    $null = $headerGrid.Children.Add($titleStack)

    $headerStack = [System.Windows.Controls.StackPanel]::new()
    $headerStack.VerticalAlignment = 'Center'
    $headerStack.HorizontalAlignment = 'Right'
    foreach ($name in @('HeaderSystem', 'HeaderRestore', 'HeaderBackup')) {
        $label = [System.Windows.Controls.TextBlock]::new()
        $label.FontSize = 12
        $label.Foreground = Get-SIBrush $c.Muted
        $label.HorizontalAlignment = 'Right'
        if ($name -eq 'HeaderRestore') { $label.Text = 'Restore point: waiting ...' }
        if ($name -eq 'HeaderBackup') { $label.Text = 'Backup: waiting ...' }
        $null = $headerStack.Children.Add($label)
        $script:SINames[$name] = $label
    }
    [System.Windows.Controls.Grid]::SetColumn($headerStack, 3)
    $null = $headerGrid.Children.Add($headerStack)

    [System.Windows.Controls.Grid]::SetRow($header, 0)
    $null = $root.Children.Add($header)

    # --- the hero: OPTIMIZE, PROVE IT and UNDO ALL --------------------------
    $hero = [System.Windows.Controls.Border]::new()
    $hero.Background = Get-SIBrush $c.Panel
    $hero.Padding = [System.Windows.Thickness]::new(16, 12, 16, 12)
    $heroGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridColumn -Grid $heroGrid -Type 'Auto'
    Add-SIGridColumn -Grid $heroGrid -Type 'Star' -Value 1
    Add-SIGridColumn -Grid $heroGrid -Type 'Auto'
    $hero.Child = $heroGrid

    # --- the big yellow button ----------------------------------------------
    $heroLeft = [System.Windows.Controls.StackPanel]::new()
    $heroLeft.VerticalAlignment = 'Center'
    $optimizeButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnOptimize') -StyleKey 'AccentButton' -Window $window -Width 258
    $optimizeButton.Height = 64
    $optimizeButton.FontSize = 23
    $optimizeButton.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $optimizeButton.ToolTip = 'Applies every safe tweak for this computer in one go. The System Restore point and the JSON backup are made first, and UNDO ALL puts everything back.'
    $script:SINames['BtnOptimize'] = $optimizeButton
    $null = $heroLeft.Children.Add($optimizeButton)

    # --- GAME BOOST and GAME OVER -------------------------------------------
    $boostRow = [System.Windows.Controls.WrapPanel]::new()
    $boostButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnBoost') -StyleKey 'AccentButton' -Window $window -Width 125
    $boostButton.Height = 32
    $boostButton.FontSize = 12
    $boostButton.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
    $boostButton.ToolTip = 'Closes the programs that are ticked in the boost list and switches the power plan to the fastest one. GAME OVER puts everything back.'
    $script:SINames['BtnBoost'] = $boostButton
    $null = $boostRow.Children.Add($boostButton)

    $gameOverButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnGameOver') -StyleKey 'GhostButton' -Window $window -Width 125
    $gameOverButton.Height = 32
    $gameOverButton.FontSize = 12
    $gameOverButton.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $gameOverButton.ToolTip = 'Puts the power plan back and opens the programs that GAME BOOST closed.'
    $script:SINames['BtnGameOver'] = $gameOverButton
    $null = $boostRow.Children.Add($gameOverButton)
    $null = $heroLeft.Children.Add($boostRow)

    $optimizeResult = [System.Windows.Controls.TextBlock]::new()
    $optimizeResult.Text = (Get-SIText -Key 'OptimizeHint')
    $optimizeResult.FontSize = 12
    $optimizeResult.Foreground = Get-SIBrush $c.Muted
    $optimizeResult.TextWrapping = 'Wrap'
    $optimizeResult.Width = 258
    $script:SINames['OptimizeResult'] = $optimizeResult
    $null = $heroLeft.Children.Add($optimizeResult)
    [System.Windows.Controls.Grid]::SetColumn($heroLeft, 0)
    $null = $heroGrid.Children.Add($heroLeft)

    # --- the PROVE IT panel --------------------------------------------------
    $prove = [System.Windows.Controls.Border]::new()
    $prove.Background = Get-SIBrush $c.PanelAlt
    $prove.Padding = [System.Windows.Thickness]::new(16, 8, 16, 8)
    $prove.Margin = [System.Windows.Thickness]::new(16, 0, 16, 0)
    $proveStack = [System.Windows.Controls.StackPanel]::new()
    $proveTitle = [System.Windows.Controls.TextBlock]::new()
    $proveTitle.Text = (Get-SIText -Key 'ProveIt')
    $proveTitle.FontSize = 13
    $proveTitle.FontWeight = 'Bold'
    $proveTitle.Foreground = Get-SIBrush $c.Accent
    $script:SINames['ProveTitle'] = $proveTitle
    $null = $proveStack.Children.Add($proveTitle)

    $proveGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridColumn -Grid $proveGrid -Type 'Auto'
    Add-SIGridColumn -Grid $proveGrid -Type 'Auto'
    Add-SIGridColumn -Grid $proveGrid -Type 'Auto'
    Add-SIGridColumn -Grid $proveGrid -Type 'Auto'
    $measurements = @(
        @{ Key = 'FreeRamMB'; Label = (Get-SIText -Key 'LabelFreeRam') }
        @{ Key = 'StartupAppsOn'; Label = (Get-SIText -Key 'LabelStartupApps') }
        @{ Key = 'DnsMs'; Label = (Get-SIText -Key 'LabelDns') }
        @{ Key = 'SpeedMbps'; Label = (Get-SIText -Key 'LabelSpeed') }
    )
    $measureRow = 0
    foreach ($item in $measurements) {
        Add-SIGridRow -Grid $proveGrid -Type 'Auto'

        $label = [System.Windows.Controls.TextBlock]::new()
        $label.Text = $item.Label
        $label.FontSize = 12
        $label.Foreground = Get-SIBrush $c.Muted
        $label.VerticalAlignment = 'Center'
        $label.Margin = [System.Windows.Thickness]::new(0, 0, 16, 0)
        [System.Windows.Controls.Grid]::SetColumn($label, 0)
        [System.Windows.Controls.Grid]::SetRow($label, $measureRow)
        $null = $proveGrid.Children.Add($label)

        $before = [System.Windows.Controls.TextBlock]::new()
        $before.Text = '-'
        $before.FontSize = 21
        $before.FontWeight = 'Bold'
        $before.VerticalAlignment = 'Center'
        $before.Width = 108
        $before.TextAlignment = 'Right'
        [System.Windows.Controls.Grid]::SetColumn($before, 1)
        [System.Windows.Controls.Grid]::SetRow($before, $measureRow)
        $null = $proveGrid.Children.Add($before)
        $script:SINames['ProveBefore_' + $item.Key] = $before

        $arrow = [System.Windows.Controls.TextBlock]::new()
        $arrow.Text = '->'
        $arrow.FontSize = 18
        $arrow.Foreground = Get-SIBrush $c.Muted
        $arrow.VerticalAlignment = 'Center'
        $arrow.Margin = [System.Windows.Thickness]::new(10, 0, 10, 0)
        [System.Windows.Controls.Grid]::SetColumn($arrow, 2)
        [System.Windows.Controls.Grid]::SetRow($arrow, $measureRow)
        $null = $proveGrid.Children.Add($arrow)

        $after = [System.Windows.Controls.TextBlock]::new()
        $after.Text = '-'
        $after.FontSize = 21
        $after.FontWeight = 'Bold'
        $after.Foreground = Get-SIBrush $c.Ok
        $after.VerticalAlignment = 'Center'
        $after.Width = 108
        [System.Windows.Controls.Grid]::SetColumn($after, 3)
        [System.Windows.Controls.Grid]::SetRow($after, $measureRow)
        $null = $proveGrid.Children.Add($after)
        $script:SINames['ProveAfter_' + $item.Key] = $after

        $measureRow++
    }
    $null = $proveStack.Children.Add($proveGrid)

    $proveLine = [System.Windows.Controls.TextBlock]::new()
    $proveLine.Text = ''
    $proveLine.FontSize = 13
    $proveLine.FontWeight = 'SemiBold'
    $proveLine.Foreground = Get-SIBrush $c.Text
    $proveLine.Margin = [System.Windows.Thickness]::new(0, 6, 0, 0)
    $script:SINames['ProveLine'] = $proveLine
    $null = $proveStack.Children.Add($proveLine)

    $prove.Child = $proveStack
    [System.Windows.Controls.Grid]::SetColumn($prove, 1)
    $null = $heroGrid.Children.Add($prove)

    # --- UNDO ALL, the measurement and the share card ------------------------
    $heroRight = [System.Windows.Controls.StackPanel]::new()
    $heroRight.VerticalAlignment = 'Center'
    $undoBigButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnUndoAll') -StyleKey 'GhostButton' -Window $window -Width 200
    $undoBigButton.Height = 64
    $undoBigButton.FontSize = 20
    $undoBigButton.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $undoBigButton.ToolTip = 'Puts back every value that SIGAME changed. The original values are in the JSON backup.'
    $script:SINames['BtnUndoAllBig'] = $undoBigButton
    $null = $heroRight.Children.Add($undoBigButton)

    $measureButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnMeasure') -StyleKey 'GhostButton' -Window $window -Width 200
    $measureButton.Height = 30
    $measureButton.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
    $measureButton.ToolTip = 'Measures the free memory, the startup programs, the DNS and the speed again and writes them in SI-GAME-measures.json.'
    $script:SINames['BtnMeasure'] = $measureButton
    $null = $heroRight.Children.Add($measureButton)

    $saveCardButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnSaveCard') -StyleKey 'AccentButton' -Window $window -Width 200
    $saveCardButton.Height = 30
    $saveCardButton.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
    $saveCardButton.ToolTip = 'Writes a picture of 1200x630 pixels with the numbers before and after, next to this script, and opens the folder.'
    $script:SINames['BtnSaveCard'] = $saveCardButton
    $null = $heroRight.Children.Add($saveCardButton)

    $boostResult = [System.Windows.Controls.TextBlock]::new()
    $boostResult.Text = ''
    $boostResult.FontSize = 12
    $boostResult.FontWeight = 'Bold'
    $boostResult.Foreground = Get-SIBrush $c.Ok
    $boostResult.TextWrapping = 'Wrap'
    $boostResult.Width = 200
    $script:SINames['BoostResult'] = $boostResult
    $null = $heroRight.Children.Add($boostResult)

    $boostPlan = [System.Windows.Controls.TextBlock]::new()
    $boostPlan.Text = ''
    $boostPlan.FontSize = 10
    $boostPlan.Foreground = Get-SIBrush $c.Muted
    $boostPlan.TextWrapping = 'Wrap'
    $boostPlan.Width = 200
    $script:SINames['BoostPlan'] = $boostPlan
    $null = $heroRight.Children.Add($boostPlan)

    [System.Windows.Controls.Grid]::SetColumn($heroRight, 2)
    $null = $heroGrid.Children.Add($heroRight)

    [System.Windows.Controls.Grid]::SetRow($hero, 1)
    $null = $root.Children.Add($hero)

    # --- the progress bar ----------------------------------------------------
    # It fills while SIGAME works and says which step is running now. There
    # is no sound: the window only shows what is happening.
    $progressBorder = [System.Windows.Controls.Border]::new()
    $progressBorder.Background = Get-SIBrush $c.Panel
    $progressBorder.Padding = [System.Windows.Thickness]::new(16, 6, 16, 6)
    $progressGrid = [System.Windows.Controls.Grid]::new()
    Add-SIGridColumn -Grid $progressGrid -Type 'Star' -Value 1
    Add-SIGridColumn -Grid $progressGrid -Type 'Auto'

    $progressBar = [System.Windows.Controls.ProgressBar]::new()
    $progressBar.Height = 8
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressBar.Value = 0
    $progressBar.BorderThickness = [System.Windows.Thickness]::new(0)
    $progressBar.Background = Get-SIBrush $c.PanelAlt
    $progressBar.Foreground = Get-SIBrush $c.Accent
    $progressBar.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($progressBar, 0)
    $null = $progressGrid.Children.Add($progressBar)
    $script:SINames['ProgressBar'] = $progressBar

    $progressText = [System.Windows.Controls.TextBlock]::new()
    $progressText.Text = ''
    $progressText.FontSize = 11
    $progressText.Foreground = Get-SIBrush $c.Muted
    $progressText.Margin = [System.Windows.Thickness]::new(12, 0, 0, 0)
    $progressText.VerticalAlignment = 'Center'
    $progressText.TextTrimming = 'CharacterEllipsis'
    [System.Windows.Controls.Grid]::SetColumn($progressText, 1)
    $null = $progressGrid.Children.Add($progressText)
    $script:SINames['ProgressText'] = $progressText

    $progressBorder.Child = $progressGrid
    [System.Windows.Controls.Grid]::SetRow($progressBorder, 2)
    $null = $root.Children.Add($progressBorder)

    # --- the Advanced section ------------------------------------------------
    # Everything that is not the big button is in here, and it is closed when
    # the window opens. It is only built when it is opened for the first
    # time, so that the window is on the screen in a couple of seconds.
    $expander = [System.Windows.Controls.Expander]::new()
    $expander.Header = (Get-SIText -Key 'Advanced')
    $expander.IsExpanded = $false
    $expander.Foreground = Get-SIBrush $c.Accent
    $expander.Margin = [System.Windows.Thickness]::new(0)
    $expander.Padding = [System.Windows.Thickness]::new(0)
    $advancedHost = [System.Windows.Controls.Grid]::new()
    # The Advanced section has a fixed height, so that the log below it keeps
    # its size and the window does not jump when the section is opened.
    $advancedHost.Height = 300
    $expander.Content = $advancedHost
    $script:SINames['AdvancedHost'] = $advancedHost
    $script:SINames['AdvancedExpander'] = $expander
    # The handler of the Expander is added in New-SIWindow, for the window
    # that is built in code and for the XAML fallback, so that it is only
    # there once.
    [System.Windows.Controls.Grid]::SetRow($expander, 3)
    $null = $root.Children.Add($expander)

    # --- the status line -----------------------------------------------------
    $statusBorder = [System.Windows.Controls.Border]::new()
    $statusBorder.Background = Get-SIBrush $c.Panel
    $statusBorder.Padding = [System.Windows.Thickness]::new(16, 6, 16, 6)
    $dock = [System.Windows.Controls.DockPanel]::new()

    # The first child of a DockPanel is the one that is docked, the last one
    # fills the rest.
    $backupInfo = [System.Windows.Controls.TextBlock]::new()
    $backupInfo.FontSize = 11
    $backupInfo.Foreground = Get-SIBrush $c.Muted
    $backupInfo.Margin = [System.Windows.Thickness]::new(10, 0, 0, 0)
    [System.Windows.Controls.DockPanel]::SetDock($backupInfo, 'Right')
    $null = $dock.Children.Add($backupInfo)

    $statusText = [System.Windows.Controls.TextBlock]::new()
    $statusText.FontSize = 12
    $statusText.TextTrimming = 'CharacterEllipsis'
    $null = $dock.Children.Add($statusText)

    $statusBorder.Child = $dock
    $script:SINames['BackupInfo'] = $backupInfo
    $script:SINames['StatusText'] = $statusText
    [System.Windows.Controls.Grid]::SetRow($statusBorder, 4)
    $null = $root.Children.Add($statusBorder)

    # --- the log --------------------------------------------------------------
    $logBorder = [System.Windows.Controls.Border]::new()
    $logBorder.Background = Get-SIBrush '#151824'
    $logBorder.BorderBrush = Get-SIBrush $c.Panel
    $logBorder.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 1)
    $logBox = [System.Windows.Controls.TextBox]::new()
    $logBox.Background = [System.Windows.Media.Brushes]::Transparent
    $logBox.Foreground = Get-SIBrush '#c9cede'
    $logBox.BorderThickness = [System.Windows.Thickness]::new(0)
    $logBox.Padding = [System.Windows.Thickness]::new(12, 8, 12, 8)
    $logBox.FontFamily = [System.Windows.Media.FontFamily]::new('Consolas')
    $logBox.FontSize = 11
    $logBox.IsReadOnly = $true
    $logBox.TextWrapping = 'NoWrap'
    $logBox.VerticalScrollBarVisibility = 'Auto'
    $logBox.HorizontalScrollBarVisibility = 'Auto'
    $logBox.AcceptsReturn = $true
    $logBorder.Child = $logBox
    $script:SINames['LogBox'] = $logBox
    [System.Windows.Controls.Grid]::SetRow($logBorder, 5)
    $null = $root.Children.Add($logBorder)

    # --- the footer ------------------------------------------------------------
    # The line of trust comes first: "Open source. Every change can be undone.
    # Restore point created: <time>".
    $footer = [System.Windows.Controls.Border]::new()
    $footer.Background = Get-SIBrush $c.Panel
    $footer.Padding = [System.Windows.Thickness]::new(16, 6, 16, 6)
    $footerStack = [System.Windows.Controls.StackPanel]::new()

    $trustText = [System.Windows.Controls.TextBlock]::new()
    $trustText.Text = ''
    $trustText.FontSize = 11
    $trustText.Foreground = Get-SIBrush $c.Ok
    $null = $footerStack.Children.Add($trustText)
    $script:SINames['TrustText'] = $trustText

    $footerText = [System.Windows.Controls.TextBlock]::new()
    $footerText.FontSize = 11
    $footerText.Foreground = Get-SIBrush $c.Muted
    $null = $footerStack.Children.Add($footerText)
    $script:SINames['FooterText'] = $footerText

    $footer.Child = $footerStack
    [System.Windows.Controls.Grid]::SetRow($footer, 6)
    $null = $root.Children.Add($footer)

    return $window
}

function New-SIToolTitle {
    <#
    .SYNOPSIS
        The little yellow title of a tool of the Advanced section.
    #>
    param([Parameter(Mandatory = $true)][string]$Text)

    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Text = $Text
    $title.FontSize = 12
    $title.FontWeight = 'Bold'
    $title.Foreground = Get-SIBrush $script:SIColors.Accent
    $title.Margin = [System.Windows.Thickness]::new(0, 10, 0, 4)
    return $title
}

function New-SIToolText {
    <#
    .SYNOPSIS
        A small text under a tool of the Advanced section.
    #>
    param(
        [string]$Text = '',
        [int]$FontSize = 11
    )

    $block = [System.Windows.Controls.TextBlock]::new()
    $block.Text = $Text
    $block.FontSize = $FontSize
    $block.Foreground = Get-SIBrush $script:SIColors.Muted
    $block.TextWrapping = 'Wrap'
    $block.Margin = [System.Windows.Thickness]::new(0, 4, 0, 0)
    return $block
}

function Build-SIAdvancedContent {
    <#
    .SYNOPSIS
        Fills the Advanced section, the first time it is opened.

    .DESCRIPTION
        The section is closed when the window opens, so that the window is on
        the screen in a couple of seconds. Everything in here is built only
        when the user opens it: the toolbar, the tools of round 5 and the
        list of the tweaks.

        The whole build is inside a try/catch. A WPF event that throws is
        swallowed by PowerShell, so an error here would leave the section
        empty and nobody would know why. The error goes to the log and to the
        status line, and the section is built again the next time it is
        opened.
    #>
    if ($script:SIAdvancedBuilt) { return }
    $script:SIAdvancedBuilt = $true

    try {
        Build-SIAdvancedParts
    } catch {
        # The section is NOT marked as built, so that it is tried again the
        # next time the user opens it.
        $script:SIAdvancedBuilt = $false
        Write-SILog -Level 'ERROR' -Component 'UI' -Message "The Advanced section could not be built: $($_.Exception.Message)"
        Set-SIStatusText -Text 'The Advanced section could not be built, see the log.'
        $advancedHost = Get-SIElement -Name 'AdvancedHost'
        if ($advancedHost) {
            try {
                $advancedHost.Children.Clear()
                $text = New-SIToolText -Text ('The Advanced section could not be built: ' + [string]$_.Exception.Message)
                $text.Foreground = Get-SIBrush $script:SIColors.Danger
                $null = $advancedHost.Children.Add($text)
            } catch { }
        }
    }
}

function Build-SIAdvancedParts {
    <#
    .SYNOPSIS
        The real build of the Advanced section.

    .DESCRIPTION
        The name of the grid is NOT $host: $Host is an automatic variable of
        PowerShell and it cannot be written, so a function that used it died
        with "Cannot overwrite variable Host" before it built anything. That
        is why the section was empty when it was opened.
    #>
    $advancedHost = Get-SIElement -Name 'AdvancedHost'
    if (-not $advancedHost) {
        Write-SILog -Level 'ERROR' -Component 'UI' -Message 'The Advanced section has no grid, so it cannot be filled.'
        return
    }
    # A build that failed before is started from scratch, so that nothing is
    # shown twice.
    try { $advancedHost.Children.Clear() } catch { }
    $c = $script:SIColors
    $window = $script:SIWindow

    Add-SIGridRow -Grid $advancedHost -Type 'Auto'
    Add-SIGridRow -Grid $advancedHost -Type 'Star' -Value 1
    Add-SIGridColumn -Grid $advancedHost -Type 'Fixed' -Value 400
    Add-SIGridColumn -Grid $advancedHost -Type 'Star' -Value 1

    # --- the toolbar ---------------------------------------------------------
    $toolbar = [System.Windows.Controls.Border]::new()
    $toolbar.Padding = [System.Windows.Thickness]::new(10, 6, 10, 2)
    $toolbarRow = [System.Windows.Controls.WrapPanel]::new()
    foreach ($name in @('BtnGaming', 'BtnApplyChecked', 'BtnRefresh', 'BtnRestorePoint', 'BtnOpenLog')) {
        $button = Get-SIElement -Name $name
        if ($button) { $null = $toolbarRow.Children.Add($button) }
    }
    $toolbar.Child = $toolbarRow
    [System.Windows.Controls.Grid]::SetColumnSpan($toolbar, 2)
    [System.Windows.Controls.Grid]::SetRow($toolbar, 0)
    $null = $advancedHost.Children.Add($toolbar)

    # --- the tools of round 5 -------------------------------------------------
    $toolsScroller = [System.Windows.Controls.ScrollViewer]::new()
    $toolsScroller.VerticalScrollBarVisibility = 'Auto'
    $toolsScroller.HorizontalScrollBarVisibility = 'Disabled'
    $toolsScroller.Padding = [System.Windows.Thickness]::new(10, 0, 6, 0)
    $toolsPanel = [System.Windows.Controls.StackPanel]::new()
    $toolsScroller.Content = $toolsPanel
    [System.Windows.Controls.Grid]::SetColumn($toolsScroller, 0)
    [System.Windows.Controls.Grid]::SetRow($toolsScroller, 1)
    $null = $advancedHost.Children.Add($toolsScroller)

    # --- BOOST LIST (round 6) --------------------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text (Get-SIText -Key 'SectionBoost')))

    $boostHint = New-SIToolText -Text (Get-SIText -Key 'BoostHint')
    $null = $toolsPanel.Children.Add($boostHint)

    $boostScroller = [System.Windows.Controls.ScrollViewer]::new()
    $boostScroller.VerticalScrollBarVisibility = 'Auto'
    $boostScroller.HorizontalScrollBarVisibility = 'Disabled'
    $boostScroller.Height = 108
    $boostPanel = [System.Windows.Controls.StackPanel]::new()
    $boostScroller.Content = $boostPanel
    $script:SINames['BoostList'] = $boostPanel
    $script:SINames['BoostScroller'] = $boostScroller
    $null = $toolsPanel.Children.Add($boostScroller)

    $boostNote = New-SIToolText -Text (Get-SIText -Key 'BoostDiscord')
    $null = $toolsPanel.Children.Add($boostNote)

    # --- AUTO-BOOST (round 8) --------------------------------------------------
    $autoRow = [System.Windows.Controls.WrapPanel]::new()

    $autoBox = [System.Windows.Controls.CheckBox]::new()
    $autoBox.Content = (Get-SIText -Key 'AutoBoost')
    $autoBox.FontSize = 12
    $autoBox.Foreground = Get-SIBrush $c.Text
    $autoBox.Margin = [System.Windows.Thickness]::new(0, 2, 8, 2)
    $autoBox.ToolTip = 'SIGAME watches the games of this computer. When a game starts, the GAME BOOST is done by itself; when the game ends, the GAME OVER is done by itself. The check is made every 5 seconds and it is written in the log.'
    try { $autoBox.IsChecked = [bool](Get-SIAutoBoostEnabled) } catch { }
    $script:SINames['AutoBoostBox'] = $autoBox
    $autoHandler = {
        param($sender, $e)
        $on = ($sender.IsChecked -eq $true)
        Set-SIAutoBoostEnabled -Enabled $on
    }.GetNewClosure()
    $null = $autoBox.Add_Click($autoHandler)
    $null = $autoRow.Children.Add($autoBox)

    $null = $toolsPanel.Children.Add($autoRow)

    # --- YOUR GAMES (round 6) --------------------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text (Get-SIText -Key 'SectionGames')))

    $gameScroller = [System.Windows.Controls.ScrollViewer]::new()
    $gameScroller.VerticalScrollBarVisibility = 'Auto'
    $gameScroller.HorizontalScrollBarVisibility = 'Disabled'
    $gameScroller.Height = 150
    $gamePanel = [System.Windows.Controls.StackPanel]::new()
    $gameScroller.Content = $gamePanel
    $script:SINames['GameLibrary'] = $gamePanel
    $null = $toolsPanel.Children.Add($gameScroller)

    # --- YOUR MACHINE (round 6) ------------------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text (Get-SIText -Key 'SectionMachine')))

    $bottleneck = New-SIToolText -Text ''
    $bottleneck.FontSize = 13
    $bottleneck.Foreground = Get-SIBrush $c.Warn
    $script:SINames['Bottleneck'] = $bottleneck
    $null = $toolsPanel.Children.Add($bottleneck)

    $bottleneckDetails = New-SIToolText -Text ''
    $script:SINames['BottleneckDetails'] = $bottleneckDetails
    $null = $toolsPanel.Children.Add($bottleneckDetails)

    # --- NETWORK & DOWNLOADS ---------------------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text (Get-SIText -Key 'SectionNetwork')))

    $dnsRow = [System.Windows.Controls.WrapPanel]::new()
    $dnsTestButton = New-SIStyleButton -Text 'DNS test' -StyleKey 'AccentButton' -Window $window
    $dnsTestButton.ToolTip = 'Measures the answer time of your own DNS and of Cloudflare, Google and Quad9. It needs the internet and it takes a while.'
    $null = $dnsTestButton.Add_Click({ Invoke-SIDnsTest })
    $null = $dnsRow.Children.Add($dnsTestButton)

    $dnsApplyButton = New-SIStyleButton -Text 'Use the fastest' -StyleKey 'GhostButton' -Window $window
    $dnsApplyButton.ToolTip = 'Sets the fastest DNS on the network adapter that is used right now. UNDO ALL puts the old one back.'
    $null = $dnsApplyButton.Add_Click({ Invoke-SIDnsApply })
    $null = $dnsRow.Children.Add($dnsApplyButton)
    $null = $toolsPanel.Children.Add($dnsRow)

    $dnsResult = New-SIToolText -Text 'No DNS test yet.'
    $script:SINames['DnsResult'] = $dnsResult
    $null = $toolsPanel.Children.Add($dnsResult)

    $speedRow = [System.Windows.Controls.WrapPanel]::new()
    $speedButton = New-SIStyleButton -Text 'Speed test (25 MB)' -StyleKey 'AccentButton' -Window $window
    $speedButton.ToolTip = 'Downloads a 25 MB test file and shows how fast the internet is. It never runs by itself.'
    $null = $speedButton.Add_Click({ Invoke-SISpeedTestAction })
    $null = $speedRow.Children.Add($speedButton)
    $null = $toolsPanel.Children.Add($speedRow)

    $speedResult = New-SIToolText -Text 'No speed test yet.'
    $script:SINames['SpeedResult'] = $speedResult
    $null = $toolsPanel.Children.Add($speedResult)

    # --- PER GAME --------------------------------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text (Get-SIText -Key 'SectionPerGame')))

    $gameRow = [System.Windows.Controls.WrapPanel]::new()
    $chooseButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnPickGame') -StyleKey 'AccentButton' -Window $window
    $chooseButton.ToolTip = 'Choose the .exe of the game. The settings below are written for that file. The games of Steam and Epic are found by themselves, above.'
    $null = $chooseButton.Add_Click({ Invoke-SIChooseGame })
    $null = $gameRow.Children.Add($chooseButton)
    $null = $toolsPanel.Children.Add($gameRow)

    $gamePath = New-SIToolText -Text 'No game chosen yet.'
    $script:SINames['GamePath'] = $gamePath
    $null = $toolsPanel.Children.Add($gamePath)

    $gameButtons = [System.Windows.Controls.WrapPanel]::new()
    $gpuButton = New-SIStyleButton -Text (Get-SIText -Key 'GameGpu') -StyleKey 'GhostButton' -Window $window
    $gpuButton.ToolTip = 'Same value as Windows Settings > Graphics > High performance. UNDO ALL takes it away again.'
    $null = $gpuButton.Add_Click({ Invoke-SIGameGpu })
    $null = $gameButtons.Children.Add($gpuButton)

    $fullscreenButton = New-SIStyleButton -Text (Get-SIText -Key 'GameFullscreen') -StyleKey 'GhostButton' -Window $window
    $fullscreenButton.ToolTip = 'Same box as "Disable fullscreen optimizations" of the Compatibility tab of the game.'
    $null = $fullscreenButton.Add_Click({ Invoke-SIGameFullscreen })
    $null = $gameButtons.Children.Add($fullscreenButton)
    $null = $toolsPanel.Children.Add($gameButtons)

    $gameList = New-SIToolText -Text ''
    $script:SINames['GameList'] = $gameList
    $null = $toolsPanel.Children.Add($gameList)

    # --- STARTUP APPS ----------------------------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text (Get-SIText -Key 'SectionStartup')))

    $startupScroller = [System.Windows.Controls.ScrollViewer]::new()
    $startupScroller.VerticalScrollBarVisibility = 'Auto'
    $startupScroller.HorizontalScrollBarVisibility = 'Disabled'
    $startupScroller.Height = 150
    $startupPanel = [System.Windows.Controls.StackPanel]::new()
    $startupScroller.Content = $startupPanel
    $script:SINames['StartupList'] = $startupPanel
    $null = $toolsPanel.Children.Add($startupScroller)

    $startupCount = New-SIToolText -Text ''
    $script:SINames['StartupCount'] = $startupCount
    $null = $toolsPanel.Children.Add($startupCount)

    # --- TEMPORARY FILES -------------------------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text (Get-SIText -Key 'SectionTemp')))

    $tempInfo = New-SIToolText -Text 'The size of the temporary files is not known yet.'
    $script:SINames['TempInfo'] = $tempInfo
    $null = $toolsPanel.Children.Add($tempInfo)

    $tempRow = [System.Windows.Controls.WrapPanel]::new()
    $tempButton = New-SIStyleButton -Text 'Clean the temporary files' -StyleKey 'GhostButton' -Window $window
    $tempButton.ToolTip = 'Deletes the temporary files of your user and of Windows. It cannot be undone.'
    $null = $tempButton.Add_Click({ Invoke-SICleanTemp })
    $null = $tempRow.Children.Add($tempButton)
    $null = $toolsPanel.Children.Add($tempRow)

    # --- SIGAME ON THE DESKTOP (round 8) ----------------------------------------
    $null = $toolsPanel.Children.Add((New-SIToolTitle -Text 'SIGAME on the desktop'))

    $desktopRow = [System.Windows.Controls.WrapPanel]::new()
    $desktopButton = New-SIStyleButton -Text 'Create the shortcut of the desktop' -StyleKey 'GhostButton' -Window $window
    $desktopButton.ToolTip = 'Makes the shortcut SIGAME on your desktop, with the logo of SI NEWS. It starts the launcher of SIGAME. The first start of SIGAME makes it by itself; this button makes it again.'
    $null = $desktopButton.Add_Click({ Invoke-SIDesktopShortcut })
    $null = $desktopRow.Children.Add($desktopButton)
    $null = $toolsPanel.Children.Add($desktopRow)

    $desktopInfo = New-SIToolText -Text ''
    $script:SINames['DesktopInfo'] = $desktopInfo
    $null = $toolsPanel.Children.Add($desktopInfo)

    # --- the list of the tweaks -------------------------------------------------
    $scroller = [System.Windows.Controls.ScrollViewer]::new()
    $scroller.VerticalScrollBarVisibility = 'Auto'
    $scroller.HorizontalScrollBarVisibility = 'Disabled'
    $scroller.Padding = [System.Windows.Thickness]::new(4, 4, 12, 4)
    $tweakPanel = [System.Windows.Controls.StackPanel]::new()
    $scroller.Content = $tweakPanel
    $script:SINames['TweakPanel'] = $tweakPanel
    [System.Windows.Controls.Grid]::SetColumn($scroller, 1)
    [System.Windows.Controls.Grid]::SetRow($scroller, 1)
    $null = $advancedHost.Children.Add($scroller)

    # The rows of the tweaks are built now, with a pump between them.
    Build-SIRows

    # The lists of the tools are filled now.
    Build-SIStartupAppList
    Build-SIBoostList
    Build-SIGameLibrary
    Update-SIBottleneck
    Update-SIGameList
    Update-SISpeedText
    Update-SIDnsText

    # The buttons of the toolbar are only on when the start-up work is done.
    Set-SIButtonsEnabled -Enabled $script:SIPrepared
}

function Build-SIStartupAppList {
    <#
    .SYNOPSIS
        Fills the list of the startup programs with a box for each one.
    #>
    $panel = Get-SIElement -Name 'StartupList'
    if (-not $panel) { return }
    $c = $script:SIColors
    $panel.Children.Clear()

    $apps = @()
    try { $apps = @(Get-SIStartupApps) } catch { }
    if ($apps.Count -eq 0) {
        $empty = New-SIToolText -Text 'No startup program found.'
        $null = $panel.Children.Add($empty)
        Update-SIStartupCount
        return
    }

    foreach ($app in $apps) {
        $box = [System.Windows.Controls.CheckBox]::new()
        $box.Content = $app.Name
        $box.ToolTip = $app.Command
        $box.IsChecked = [bool]$app.Enabled
        $box.FontSize = 12
        $box.Foreground = Get-SIBrush $c.Text
        $box.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)

        # The values of this program are taken into the box, so that the
        # handler knows which one it belongs to.
        $approvedPath = [string]$app.ApprovedPath
        $approvedName = [string]$app.ApprovedName
        $wasEnabled = [bool]$app.Enabled
        $handler = {
            param($sender, $e)
            $enabled = ($sender.IsChecked -eq $true)
            try {
                # The original value is saved first, so that the undo can put
                # it back.
                Save-SIToolUndo -Key ('Startup|' + $approvedPath + '|' + $approvedName) -Path $approvedPath -Name $approvedName
                Set-SIStartupAppState -ApprovedPath $approvedPath -Name $approvedName -Enabled $enabled
                Write-SILog -Component 'User' -Message "Startup program $approvedName is now $(if ($enabled) { 'on' } else { 'off' })."
                Update-SIStartupCount
            } catch {
                Write-SILog -Level 'ERROR' -Component 'User' -Message "The startup program $approvedName could not be changed: $($_.Exception.Message)"
            }
        }.GetNewClosure()
        $null = $box.Add_Click($handler)

        $null = $panel.Children.Add($box)
    }
    Update-SIStartupCount
}

function Update-SIStartupCount {
    <#
    .SYNOPSIS
        Shows how many startup programs are on.
    #>
    $label = Get-SIElement -Name 'StartupCount'
    if (-not $label) { return }
    $count = Get-SIStartupAppsOnCount
    $label.Text = "$count startup program(s) are on. Untick one to switch it off, nothing is ever deleted."
}

# --- the boost list of the window ------------------------------------------

function Build-SIBoostList {
    <#
    .SYNOPSIS
        Fills the boost list with the background programs that are running.

    .DESCRIPTION
        The ticks of the user are remembered in SI-GAME-boost.json, so the
        list looks the same the next time. Nothing is ticked the first time.
    #>
    $panel = Get-SIElement -Name 'BoostList'
    if (-not $panel) { return }
    $c = $script:SIColors
    $panel.Children.Clear()

    $state = Get-SIBoostState
    $ticked = @($state['Ticked'])
    $script:SIBoostTicks = $ticked

    $apps = @()
    try { $apps = @(Get-SIBoostCandidates) } catch { }
    $script:SIBoostApps = $apps

    if ($apps.Count -eq 0) {
        $empty = New-SIToolText -Text (Get-SIText -Key 'BoostNothing')
        $null = $panel.Children.Add($empty)
        return
    }

    foreach ($app in $apps) {
        $box = [System.Windows.Controls.CheckBox]::new()
        $box.Content = [string]$app.Name
        $box.FontSize = 12
        $box.Foreground = Get-SIBrush $c.Text
        $box.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)
        $box.ToolTip = [string]$app.Path
        $id = [string]$app.Id
        $box.IsChecked = ($ticked -contains $id)

        $handler = {
            param($sender, $e)
            $on = ($sender.IsChecked -eq $true)
            $current = @()
            try { $current = @((Get-SIBoostState)['Ticked']) } catch { }
            if ($on) {
                if ($current -notcontains $id) { $current += $id }
            }
            else {
                $current = @($current | Where-Object { $_ -ne $id })
            }
            $newState = Get-SIBoostState
            $newState['Ticked'] = $current
            # The boost list was set at least once: the AUTO-BOOST (round 8)
            # is on by default from now on.
            $newState['Configured'] = $true
            Save-SIBoostState -State $newState | Out-Null
            # The switch of the AUTO-BOOST follows the new state, so that the
            # AUTO-BOOST starts watching the games as soon as the user has
            # set the boost list.
            # The state is set by a function and not by a line here: a script
            # block that was made with GetNewClosure() does NOT see the
            # variables of the script scope, so the state would be lost.
            try {
                Set-SIAutoBoostListState -Ticks $current
            } catch { }
            $what = 'out of'
            if ($on) { $what = 'in' }
            Write-SILog -Component 'Boost' -Message "The program $($app.Name) is $what the boost list."
        }.GetNewClosure()
        $null = $box.Add_Click($handler)

        $null = $panel.Children.Add($box)
    }
}

function Show-SIBoostList {
    <#
    .SYNOPSIS
        Shows the boost list to the user, with the programs that are running.

    .DESCRIPTION
        Used by GAME BOOST when nothing is ticked: the list of the background
        programs that are running now is built and shown, so that the user can
        tick the ones he wants to close and press GAME BOOST again.

        Nothing is closed here. The Advanced section is built if it does not
        exist yet and it is opened, so that the list can be seen at once.
    #>
    try {
        # The boost list lives inside the Advanced section, so that section
        # has to be there before the list can be shown.
        if (-not $script:SIAdvancedBuilt) { Build-SIAdvancedContent }
        $expander = Get-SIElement -Name 'AdvancedExpander'
        if ($expander) {
            if (-not $expander.IsExpanded) { $expander.IsExpanded = $true }
        }
        # The list is built again, so that a program that started after the
        # section was opened is on the list too.
        Build-SIBoostList
        $scroller = Get-SIElement -Name 'BoostScroller'
        if ($scroller) { try { $scroller.ScrollToTop() } catch { } }
    } catch {
        Write-SILog -Level 'WARN' -Component 'Boost' -Message "The boost list could not be shown: $($_.Exception.Message)"
    }
}

# --- the games of this computer --------------------------------------------

function Get-SIGameIcon {
    <#
    .SYNOPSIS
        The little picture of a game, taken from its .exe.

    .DESCRIPTION
        $null when the picture cannot be taken. A game without a picture is
        still shown, only the small image is missing.
    #>
    param([string]$ExePath)

    if (-not $ExePath) { return $null }
    if (-not (Test-Path -LiteralPath $ExePath)) { return $null }
    try {
        if (-not $script:SIDrawingLoaded) {
            try {
                Add-Type -AssemblyName System.Drawing -ErrorAction Stop
                $script:SIDrawingLoaded = $true
            } catch { $script:SIDrawingLoaded = $false }
        }
        if (-not $script:SIDrawingLoaded) { return $null }

        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExePath)
        if (-not $icon) { return $null }
        try {
            $bitmap = $icon.ToBitmap()
            try {
                $source = [System.Windows.Media.Imaging.Imaging]::CreateBitmapSourceFromBitmap(
                    $bitmap,
                    [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad,
                    [System.Windows.Media.Imaging.BitmapCreateOptions]::None)
                $source.Freeze()
                return $source
            } finally {
                $bitmap.Dispose()
            }
        } finally {
            $icon.Dispose()
        }
    } catch {
        return $null
    }
}

function Build-SIGameLibrary {
    <#
    .SYNOPSIS
        Fills the list of the games of this computer.

    .DESCRIPTION
        One row per game: the little picture of the game, its name and the
        store it comes from. Under it there are two boxes: the fast video
        card and the fullscreen optimizations off.

        A box that is ticked writes the value right away, the same value the
        Windows page "Settings > Graphics" writes.
    #>
    $panel = Get-SIElement -Name 'GameLibrary'
    if (-not $panel) { return }
    $c = $script:SIColors
    $panel.Children.Clear()

    $games = @()
    try { $games = @($script:SIGameLibrary) } catch { }
    if ($games.Count -eq 0) {
        $empty = New-SIToolText -Text (Get-SIText -Key 'GameNothing')
        $null = $panel.Children.Add($empty)
        return
    }

    foreach ($game in $games) {
        $exe = [string]$game.Exe
        $row = [System.Windows.Controls.StackPanel]::new()
        $row.Margin = [System.Windows.Thickness]::new(0, 2, 0, 6)

        # --- the head of the row --------------------------------------------
        $head = [System.Windows.Controls.Grid]::new()
        Add-SIGridColumn -Grid $head -Type 'Auto'
        Add-SIGridColumn -Grid $head -Type 'Star' -Value 1
        Add-SIGridColumn -Grid $head -Type 'Auto'

        $icon = [System.Windows.Controls.Image]::new()
        $icon.Width = 20
        $icon.Height = 20
        $icon.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
        $icon.VerticalAlignment = 'Center'
        $icon.Stretch = [System.Windows.Media.Stretch]::Uniform
        $picture = Get-SIGameIcon -ExePath $exe
        if ($picture) { $icon.Source = $picture }
        [System.Windows.Controls.Grid]::SetColumn($icon, 0)
        $null = $head.Children.Add($icon)

        $name = [System.Windows.Controls.TextBlock]::new()
        $name.Text = [string]$game.Name
        $name.FontSize = 12
        $name.FontWeight = 'SemiBold'
        $name.VerticalAlignment = 'Center'
        $name.TextTrimming = 'CharacterEllipsis'
        $name.ToolTip = ([string]$game.Name + ' - ' + $exe)
        [System.Windows.Controls.Grid]::SetColumn($name, 1)
        $null = $head.Children.Add($name)

        $store = [System.Windows.Controls.TextBlock]::new()
        $store.Text = [string]$game.Store
        $store.FontSize = 10
        $store.Foreground = Get-SIBrush $c.Muted
        $store.Margin = [System.Windows.Thickness]::new(6, 0, 0, 0)
        $store.VerticalAlignment = 'Center'
        [System.Windows.Controls.Grid]::SetColumn($store, 2)
        $null = $head.Children.Add($store)

        $null = $row.Children.Add($head)

        # --- the two boxes ---------------------------------------------------
        $gpuBox = [System.Windows.Controls.CheckBox]::new()
        $gpuBox.Content = (Get-SIText -Key 'GameGpu')
        $gpuBox.FontSize = 11
        $gpuBox.Foreground = Get-SIBrush $c.Text
        $gpuBox.Margin = [System.Windows.Thickness]::new(26, 0, 0, 0)
        $gpuBox.IsChecked = (Get-SIGameGpuState -ExePath $exe)
        $gpuBox.ToolTip = 'The same value that Windows Settings > Graphics > High performance writes. UNDO ALL takes it away again.'
        $gpuHandler = {
            param($sender, $e)
            $on = ($sender.IsChecked -eq $true)
            try {
                # The original value is saved first, so that the undo can put
                # it back.
                Save-SIToolUndo -Key ('GameGpu|' + $exe) -Path (Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences') -Name $exe
                if ($on) { Set-SIGameGpuPreference -ExePath $exe }
                else { Set-SIGameGpuPreferenceOff -ExePath $exe }
                $what = 'the Windows one'
                if ($on) { $what = 'high performance' }
                Write-SILog -Component 'Game' -Message "The video card of $exe is now $what."
            } catch {
                Write-SILog -Level 'ERROR' -Component 'Game' -Message "The video card of $exe could not be changed: $($_.Exception.Message)"
            }
        }.GetNewClosure()
        $null = $gpuBox.Add_Click($gpuHandler)
        $null = $row.Children.Add($gpuBox)

        $fullscreenBox = [System.Windows.Controls.CheckBox]::new()
        $fullscreenBox.Content = (Get-SIText -Key 'GameFullscreen')
        $fullscreenBox.FontSize = 11
        $fullscreenBox.Foreground = Get-SIBrush $c.Text
        $fullscreenBox.Margin = [System.Windows.Thickness]::new(26, 0, 0, 0)
        $fullscreenBox.IsChecked = (Get-SIGameFullscreenState -ExePath $exe)
        $fullscreenBox.ToolTip = 'The same box as "Disable fullscreen optimizations" of the Compatibility tab of the game.'
        $fullscreenHandler = {
            param($sender, $e)
            $on = ($sender.IsChecked -eq $true)
            try {
                # The original value is saved first, so that the undo can put
                # it back.
                Save-SIToolUndo -Key ('GameFullscreen|' + $exe) -Path (Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers') -Name $exe
                if ($on) { Set-SIGameFullscreenOptimizations -ExePath $exe }
                else { Set-SIGameFullscreenOptimizationsOn -ExePath $exe }
                $what = 'on'
                if ($on) { $what = 'off' }
                Write-SILog -Component 'Game' -Message "The fullscreen optimizations of $exe are $what."
            } catch {
                Write-SILog -Level 'ERROR' -Component 'Game' -Message "The fullscreen optimizations of $exe could not be changed: $($_.Exception.Message)"
            }
        }.GetNewClosure()
        $null = $fullscreenBox.Add_Click($fullscreenHandler)
        $null = $row.Children.Add($fullscreenBox)

        $null = $panel.Children.Add($row)
    }
}

function Update-SIBottleneck {
    <#
    .SYNOPSIS
        Writes the honest limit of this computer into the window.
    #>
    $line = Get-SIElement -Name 'Bottleneck'
    $details = Get-SIElement -Name 'BottleneckDetails'
    $info = $script:SIBottleneck
    if (-not $info) { return }
    if ($line) {
        try { $line.Text = [string]$info.Line } catch { }
    }
    if ($details) {
        try { $details.Text = [string]$info.Details } catch { }
    }
}

function Update-SIGameList {
    <#
    .SYNOPSIS
        Shows the games that already have a setting of SIGAME.
    #>
    $label = Get-SIElement -Name 'GameList'
    if (-not $label) { return }
    $games = @()
    try { $games = @(Get-SIGameSettings) } catch { }
    if ($games.Count -eq 0) {
        $label.Text = 'No game has a setting yet.'
        return
    }
    $lines = @()
    foreach ($game in $games) {
        $lines += ($game.Path + '  (' + $game.Kind + ')')
    }
    $label.Text = 'Games already set:' + [System.Environment]::NewLine + ($lines -join [System.Environment]::NewLine)
}

function Update-SISpeedText {
    <#
    .SYNOPSIS
        Shows the result of the last speed test.
    #>
    $label = Get-SIElement -Name 'SpeedResult'
    if (-not $label) { return }
    if ($script:SILastSpeedMbps -lt 0) {
        $label.Text = 'No speed test yet.'
        return
    }
    $label.Text = ('Last speed test: {0} Mbps ({1})' -f $script:SILastSpeedMbps, $script:SILastSpeedAt)
}

function Update-SIDnsText {
    <#
    .SYNOPSIS
        Shows the result of the last DNS test.
    #>
    $label = Get-SIElement -Name 'DnsResult'
    if (-not $label) { return }
    if (-not $script:SIDnsResults -or $script:SIDnsResults.Count -eq 0) {
        $label.Text = 'No DNS test yet.'
        return
    }
    $lines = @()
    foreach ($row in $script:SIDnsResults) {
        $text = 'did not answer'
        if ([double]$row.Ms -ge 0) { $text = ('{0:0.0} ms' -f [double]$row.Ms) }
        $lines += ('{0} ({1}): {2}' -f $row.Name, $row.Server, $text)
    }
    $label.Text = ($lines -join [System.Environment]::NewLine)
}

function Invoke-SIDnsTest {
    <#
    .SYNOPSIS
        Starts the DNS benchmark in the background copy of SIGAME.
    #>
    Set-SIStatusText -Text 'The DNS test is running in the background, it takes a while ...'
    Start-SIWorker -Mode 'dns'
}

function Invoke-SIDnsApply {
    <#
    .SYNOPSIS
        Sets the fastest DNS on the adapter that is used right now.
    #>
    if (-not $script:SIDnsResults -or $script:SIDnsResults.Count -eq 0) {
        Set-SIStatusText -Text 'Run the DNS test first.'
        return
    }
    $best = $null
    foreach ($row in $script:SIDnsResults) {
        if ([double]$row.Ms -lt 0) { continue }
        if ((-not $best) -or ([double]$row.Ms -lt [double]$best.Ms)) { $best = $row }
    }
    if (-not $best) {
        Set-SIStatusText -Text 'No DNS server answered, so nothing was changed.'
        return
    }
    $script:SISelectedDns = [string]$best.Server
    Invoke-SIApplyTweak -TweakId 'DNSServer'
}

function Invoke-SISpeedTestAction {
    <#
    .SYNOPSIS
        Starts the speed test in the background copy of SIGAME.
    #>
    Set-SIStatusText -Text 'The speed test is running in the background, it downloads 25 MB ...'
    Start-SIWorker -Mode 'speed'
}

function Invoke-SIChooseGame {
    <#
    .SYNOPSIS
        Lets the user pick the .exe of a game.
    #>
    try {
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = 'Choose the game'
        $dialog.Filter = 'Programs (*.exe)|*.exe|All files (*.*)|*.*'
        $dialog.Multiselect = $false
        $answer = $dialog.ShowDialog($script:SIWindow)
        if ($answer -ne $true) { return }
        $script:SISelectedGame = [string]$dialog.FileName
        $label = Get-SIElement -Name 'GamePath'
        if ($label) { $label.Text = $script:SISelectedGame }
        # The game is added to the list that the AUTO-BOOST watches, so that
        # the boost is done by itself when this game starts.
        try {
            if (Add-SIAutoBoostGame -Path $script:SISelectedGame) {
                Write-SILog -Component 'AutoBoost' -Message "the game $($script:SISelectedGame) was added to the list of the AUTO-BOOST."
            }
        } catch {
            Write-SILog -Level 'WARN' -Component 'AutoBoost' -Message "the game could not be added to the list of the AUTO-BOOST: $($_.Exception.Message)"
        }
    } catch {
        Write-SILog -Level 'WARN' -Component 'UI' -Message "The game could not be chosen: $($_.Exception.Message)"
    }
}

function Invoke-SIGameGpu {
    <#
    .SYNOPSIS
        Sets the fast video card for the chosen game.
    #>
    if (-not $script:SISelectedGame) {
        Set-SIStatusText -Text 'Choose a game first.'
        return
    }
    $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    try {
        # The original value is saved first, so that the undo can put it back.
        Save-SIToolUndo -Key ('GameGpu|' + $script:SISelectedGame) -Path $path -Name $script:SISelectedGame
        Set-SIGameGpuPreference -ExePath $script:SISelectedGame
        Write-SILog -Component 'Registry' -Message "The high performance video card is set for $($script:SISelectedGame)."
        Set-SIStatusText -Text 'The high performance video card is set for the game.'
        Update-SIGameList
    } catch {
        Write-SILog -Level 'ERROR' -Component 'Registry' -Message "The video card could not be set: $($_.Exception.Message)"
        Set-SIStatusText -Text 'The video card could not be set, see the log.'
    }
}

function Invoke-SIGameFullscreen {
    <#
    .SYNOPSIS
        Switches the fullscreen optimizations off for the chosen game.
    #>
    if (-not $script:SISelectedGame) {
        Set-SIStatusText -Text 'Choose a game first.'
        return
    }
    $path = Get-SIUserRegistryPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    try {
        # The original value is saved first, so that the undo can put it back.
        Save-SIToolUndo -Key ('GameFullscreen|' + $script:SISelectedGame) -Path $path -Name $script:SISelectedGame
        Set-SIGameFullscreenOptimizations -ExePath $script:SISelectedGame
        Write-SILog -Component 'Registry' -Message "The fullscreen optimizations are off for $($script:SISelectedGame)."
        Set-SIStatusText -Text 'The fullscreen optimizations are off for the game.'
        Update-SIGameList
    } catch {
        Write-SILog -Level 'ERROR' -Component 'Registry' -Message "The fullscreen optimizations could not be switched off: $($_.Exception.Message)"
        Set-SIStatusText -Text 'The fullscreen optimizations could not be switched off, see the log.'
    }
}

function Invoke-SICleanTemp {
    <#
    .SYNOPSIS
        Shows how much the temporary files take and asks before deleting them.
    #>
    Set-SIStatusText -Text 'The temporary files are being counted ...'
    Start-SIWorker -Mode 'temp'
}

function Save-SIToolUndo {
    <#
    .SYNOPSIS
        Remembers the original value of a setting that SIGAME changed, so
        that the UNDO ALL can put it back.

    .DESCRIPTION
        The per game settings and the startup programs are not tweaks of the
        table, so they have their own place in the JSON backup.

        This has to be called BEFORE the value is changed, because it reads
        the value that is there at that moment. A value that is already in
        the backup is not written again, so that the ORIGINAL value is kept
        and not the one of a later change.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $backup = $script:SIBackup
    if (-not $backup) {
        $script:SIBackup = Get-SIBackup
        $backup = $script:SIBackup
    }
    if (-not $backup) { return }
    if (-not ($backup.Contains('Tools'))) { $backup['Tools'] = @{} }
    if (-not $backup['Tools']) { $backup['Tools'] = @{} }
    if ($backup['Tools'].Contains($Key)) { return }

    $current = Get-SIRegistryValue -Path $Path -Name $Name
    $backup['Tools'][$Key] = @{
        Path    = $Path
        Name    = $Name
        Existed = [bool]$current.Exists
        Value   = $current.Value
        Kind    = [string]$current.Kind
    }
    Save-SIBackup -Backup $backup | Out-Null
}

function Invoke-SIUndoTools {
    <#
    .SYNOPSIS
        Puts back the per game settings and the startup programs that SI
        GAME changed.
    #>
    $backup = $script:SIBackup
    if (-not $backup) {
        $script:SIBackup = Get-SIBackup
        $backup = $script:SIBackup
    }
    if (-not ($backup.Contains('Tools'))) { return }
    $tools = $backup['Tools']
    if (-not $tools) { return }

    foreach ($key in @($tools.Keys)) {
        $record = $tools[$key]
        if (-not $record) { continue }
        try {
            $path = [string]$record['Path']
            $name = [string]$record['Name']
            if ([bool]$record['Existed']) {
                $type = ConvertTo-SIKind ([string]$record['Kind'])
                if (-not $type) { $type = 'String' }
                Set-SIRegistryValue -Path $path -Name $name -Value $record['Value'] -Type $type | Out-Null
                Write-SILog -Component 'Registry' -Message "Put back $path\$name"
            } else {
                Remove-SIRegistryValue -Path $path -Name $name | Out-Null
                Write-SILog -Component 'Registry' -Message "Removed $path\$name (it was not there before SIGAME ran)"
            }
        } catch {
            Write-SILog -Level 'ERROR' -Component 'Registry' -Message "A value could not be put back: $($_.Exception.Message)"
        }
        Invoke-SIUIPump
    }
    $backup['Tools'] = @{}
    Save-SIBackup -Backup $backup | Out-Null
}

function New-SIWindow {
    <#
    .SYNOPSIS
        Builds the window, wires the buttons and fills the rows.
    #>
    # Only load WPF assemblies if not already loaded by the loader.
    if (-not ('System.Windows.Window' -as [type])) {
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction Stop
    }

    # The window is built in code: the XAML reader needs seconds the first
    # time it parses a window, and the window of SIGAME has to be on the
    # screen quickly. The XAML of Get-SIWindowXaml is the fallback, for the
    # case that the code does not work on the machine of the owner.
    $script:SINames = @{}
    $window = $null
    try {
        $window = New-SIWindowCode
    } catch {
        Write-SILog -Level 'WARN' -Component 'UI' -Message "The window could not be built in code, the XAML is used instead: $($_.Exception.Message)"
        $script:SINames = @{}
        $window = $null
    }
    if (-not $window) {
        try {
            $window = New-SIWindowXaml
        } catch {
            Write-SILog -Level 'ERROR' -Component 'UI' -Message "The window could not be built at all: $($_.Exception.Message)"
            $window = $null
        }
    }
    if (-not $window) {
        # Nothing can be shown. The log says what happened, so that the owner
        # can send it.
        Write-SILog -Level 'ERROR' -Component 'UI' -Message 'SIGAME cannot open a window on this computer.'
        # The console of the launcher is hidden, so the reason is also shown
        # in a message box: without it the user would see nothing at all.
        try {
            Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
            [System.Windows.MessageBox]::Show(
                "SIGAME cannot open a window on this computer.`n`nThe details are in the log file:`n$script:SILogPath",
                'SIGAME',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error) | Out-Null
        } catch { }
        return $null
    }
    $script:SIWindow = $window

    # --- the buttons of the toolbar of the Advanced section ------------------
    # They are made here and not in the window itself, so that the window that
    # is built in code and the XAML fallback both have them. They are put in
    # the toolbar when the Advanced section is built.
    $gamingButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnGaming') -StyleKey 'AccentButton' -Window $window
    $gamingButton.IsEnabled = $false
    $script:SINames['BtnGaming'] = $gamingButton

    $applyCheckedButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnApplyChecked') -StyleKey 'AccentButton' -Window $window
    $applyCheckedButton.IsEnabled = $false
    $script:SINames['BtnApplyChecked'] = $applyCheckedButton

    $refreshButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnRefresh') -StyleKey 'GhostButton' -Window $window
    $script:SINames['BtnRefresh'] = $refreshButton

    $restoreButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnRestorePoint') -StyleKey 'GhostButton' -Window $window
    $script:SINames['BtnRestorePoint'] = $restoreButton

    $openLogButton = New-SIStyleButton -Text (Get-SIText -Key 'BtnOpenLog') -StyleKey 'GhostButton' -Window $window
    $script:SINames['BtnOpenLog'] = $openLogButton

    # The Advanced section is built when it is opened for the first time. The
    # handler is added here, for the window that is built in code and for the
    # XAML fallback, so that it is only there once. The function itself only
    # builds the section once.
    $advancedExpander = Get-SIElement -Name 'AdvancedExpander'
    if ($advancedExpander) {
        try { $null = $advancedExpander.Add_Expanded({ Build-SIAdvancedContent }) } catch { }
    }

    # The safety net of the Advanced section. If the event of the Expander
    # does not come (or comes before the section is really opened), the
    # section is built anyway as soon as it is open, so that it is never
    # empty. The timer is stopped when the window is closed.
    if ($script:SIAdvancedTimer) {
        try { $script:SIAdvancedTimer.Stop() } catch { }
    }
    $script:SIAdvancedTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:SIAdvancedTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $null = $script:SIAdvancedTimer.Add_Tick({
        try {
            $expander = Get-SIElement -Name 'AdvancedExpander'
            if ($expander -and $expander.IsExpanded -and -not $script:SIAdvancedBuilt) {
                Build-SIAdvancedContent
            }
        } catch { }
    })
    $script:SIAdvancedTimer.Start()

    # The texts of the window are put in the language of Windows.
    Set-SIWindowTexts

    # The table of the tweaks is read right away: it is cheap, and the big
    # OPTIMIZE button needs it even when the Advanced section is never
    # opened. The rows of the window are only built when the section is
    # opened, so the window is on the screen in a couple of seconds.
    foreach ($tweak in (Get-SITweakTable)) {
        $script:SITweaks[$tweak.Id] = $tweak
    }

    $c = $script:SIColors

    # --- the SI NEWS logo ---------------------------------------------------
    $logoImage = Get-SIElement -Name 'LogoImage'
    if ($logoImage) {
        if ($script:SILoadingLogo -and $script:SILoadingLogo.Source) {
            $logoImage.Source = $script:SILoadingLogo.Source
        } elseif ([System.IO.File]::Exists($script:SILogoPath)) {
            try {
                $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
                $bitmap.BeginInit()
                $bitmap.UriSource = [System.Uri]::new($script:SILogoPath, [System.UriKind]::Absolute)
                $bitmap.DecodePixelWidth = 96
                $bitmap.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
                $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bitmap.EndInit()
                $bitmap.Freeze()
                $logoImage.Source = $bitmap
            } catch {
                Write-SILog -Level 'WARN' -Component 'UI' -Message "The logo could not be loaded: $($_.Exception.Message)"
            }
        }
    }

    # --- header --------------------------------------------------------------
    $systemText = 'Windows version unknown'
    try {
        $version = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $build = [int]$version.CurrentBuild
        $family = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
        $systemText = '{0} {1} (build {2}.{3})' -f $family, $version.DisplayVersion, $build, $version.UBR
    } catch { }
    $headerSystem = Get-SIElement -Name 'HeaderSystem'
    if ($headerSystem) { $headerSystem.Text = $systemText }

    Update-SIRestorePointHeader

    $backupInfo = Get-SIElement -Name 'BackupInfo'
    if ($backupInfo) { $backupInfo.Text = 'Backup: {0}' -f (Split-Path -Path $script:SIBackupPath -Leaf) }
    $footerText = Get-SIElement -Name 'FooterText'
    if ($footerText) { $footerText.Text = Get-SITextFormat -Key 'FooterBase' -Arguments @($script:SILogPath) }
    $script:SIStatus = Get-SIElement -Name 'StatusText'
    $script:SILogBox = Get-SIElement -Name 'LogBox'
    $script:SIProgress = Get-SIElement -Name 'ProgressBar'
    $script:SIProgressText = Get-SIElement -Name 'ProgressText'
    Update-SITrustFooter

    # --- the rows ------------------------------------------------------------
    # The rows are NOT built here. They are built by Build-SIRows, after the
    # window is on the screen, so that the window appears in about a second
    # instead of waiting for the whole tweak table.

    # --- the buttons ---------------------------------------------------------
    # Every button is looked up by name and only hooked up when it is really
    # there. A button that is missing must not stop the window from opening.
    $gamingButton = Get-SIElement -Name 'BtnGaming'
    if ($gamingButton) {
    $null = $gamingButton.Add_Click({ Invoke-SIGamingPreset -Window $window }.GetNewClosure())
    }

    $applyCheckedButton = Get-SIElement -Name 'BtnApplyChecked'
    if ($applyCheckedButton) {
    $null = $applyCheckedButton.Add_Click({
        if (-not $script:SIPrepared) {
            Set-SIStatusText -Text 'SIGAME is still starting up, please wait a moment.'
            return
        }
        $count = 0
        foreach ($id in @($script:SITweaks.Keys)) {
            if (-not $script:SIRows.ContainsKey($id)) { continue }
            $row = $script:SIRows[$id]
            if (-not $row) { continue }
            if ($row.Tick.IsChecked -ne $true) { continue }
            $tweak = $script:SITweaks[$id]
            if ($tweak.Contains('ShowOnly') -and $tweak.ShowOnly) { continue }
            $unavailable = Get-SITweakAvailability -Tweak $tweak
            if ($unavailable) {
                Write-SILog -Component 'Tweak' -Message "$($tweak.Name) was skipped: $unavailable"
                continue
            }
            $count++
            Invoke-SIApplyTweak -TweakId $id
        }
        Set-SIStatusText -Text ("Applied {0} tweak(s)." -f $count)
    })
    }

    # The old small UNDO ALL of the toolbar. It is not in the window of the
    # code any more, but the XAML fallback still has it.
    $undoAllButton = Get-SIElement -Name 'BtnUndoAll'
    if ($undoAllButton) {
        $null = $undoAllButton.Add_Click({
            $text = 'Undo all puts back every value that SIGAME changed and that is recorded in the JSON backup.'
            if (Show-SIMessage -Window $window -Text $text -Title 'Undo all') {
                Invoke-SIUndoAll
            }
        }.GetNewClosure())
    }

    # The big UNDO ALL of the main screen. It is always there.
    $undoBigButton = Get-SIElement -Name 'BtnUndoAllBig'
    if ($undoBigButton) {
        $null = $undoBigButton.Add_Click({
            $text = 'Undo all puts back every value that SIGAME changed and that is recorded in the JSON backup.'
            if (Show-SIMessage -Window $window -Text $text -Title 'Undo all') {
                Invoke-SIUndoAll
            }
        }.GetNewClosure())
    }

    # The big yellow OPTIMIZE button.
    $optimizeButton = Get-SIElement -Name 'BtnOptimize'
    if ($optimizeButton) {
        $null = $optimizeButton.Add_Click({ Invoke-SIOptimize })
    }

    # The measurement of the PROVE IT panel.
    $measureButton = Get-SIElement -Name 'BtnMeasure'
    if ($measureButton) {
        $null = $measureButton.Add_Click({
            Set-SIStatusText -Text 'Measuring ...'
            Invoke-SIUIPump
            $now = Measure-SISystem
            if (-not $script:SIMeasuresBefore) { $script:SIMeasuresBefore = $now }
            $script:SIMeasuresAfter = $now
            Save-SIMeasures -Before $script:SIMeasuresBefore -After $now | Out-Null
            Update-SIProvePanel
            Set-SIStatusText -Text 'The measurement is done.'
            Write-SILog -Component 'UI' -Message 'The PROVE IT measurement was made.'
        })
    }

    # GAME BOOST: closes the ticked programs and switches the power plan.
    $boostButton = Get-SIElement -Name 'BtnBoost'
    if ($boostButton) {
        $null = $boostButton.Add_Click({ Invoke-SIBoost })
    }

    # GAME OVER: puts the power plan back and opens the programs again.
    $gameOverButton = Get-SIElement -Name 'BtnGameOver'
    if ($gameOverButton) {
        $null = $gameOverButton.Add_Click({ Invoke-SIGameOver })
    }

    # The share card: a picture of the result.
    $saveCardButton = Get-SIElement -Name 'BtnSaveCard'
    if ($saveCardButton) {
        $null = $saveCardButton.Add_Click({
            Set-SIStatusText -Text 'Writing the share card ...'
            Invoke-SIUIPump
            if (Save-SIShareCard) {
                Set-SIStatusText -Text (Get-SITextFormat -Key 'CardSaved' -Arguments @($script:SISharePath))
            } else {
                Set-SIStatusText -Text 'The share card could not be written, see the log.'
            }
        })
    }

    $refreshButton = Get-SIElement -Name 'BtnRefresh'
    if ($refreshButton) {
    $null = $refreshButton.Add_Click({
        Clear-SICache
        # Every row goes back to "loading ..." and is filled in again as soon
        # as the background copy has read it.
        foreach ($id in @($script:SIRows.Keys)) {
            $row = $script:SIRows[$id]
            if ($row) { $row.StateText.Text = 'loading ...' }
        }
        Set-SIStatusText -Text 'Reading the real state of every tweak ...'
        Start-SIWorker -Mode 'refresh'
    })
    }

    $restoreButton = Get-SIElement -Name 'BtnRestorePoint'
    if ($restoreButton) {
    $null = $restoreButton.Add_Click({
        Update-SIRestorePointHeader -Status 'creating'
        Set-SIStatusText -Text 'Creating a System Restore point ...'
        Start-SIWorker -Mode 'restorepoint'
    })
    }

    $openLogButton = Get-SIElement -Name 'BtnOpenLog'
    if ($openLogButton) {
    $null = $openLogButton.Add_Click({
        try {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ('/select,"{0}"' -f $script:SILogPath) -ErrorAction Stop | Out-Null
        } catch {
            try { Start-Process -FilePath (Split-Path -Path $script:SILogPath -Parent) -ErrorAction Stop | Out-Null } catch { }
        }
    })
    }

    # --- the last lines of the log ------------------------------------------
    # The last lines of the log are put into the window AFTER it is on the
    # screen (Show-SILogTail), so that reading the file is not on the way
    # to the window.

    # The real states are read after the window was painted, in
    # Start-SISlowStart. Reading them here would hold back the window for
    # half a minute on a slow machine.
    return $window
}

