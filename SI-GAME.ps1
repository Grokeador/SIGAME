#Requires -Version 5.1
<#
.SYNOPSIS
    SIGAME - High-Performance Loader (Hard Optimized).
#>

param(
    [switch]$Worker,
    [string]$WorkerMode = 'prepare',
    [string]$WorkerRequest = '',
    [string]$WorkerResult = ''
)

# ============================ 1. THE CLOCK & FAST UAC =====================

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

# Resolucao ultra-rapida de caminhos via .NET nativo (evita overhead de Join-Path/Split-Path)
$script:SIRoot = $PSScriptRoot
if ([string]::IsNullOrEmpty($script:SIRoot)) {
    $script:SIRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
}
$script:SIModulesPath   = [System.IO.Path]::Combine($script:SIRoot, 'modules')
$script:SILogoPath      = [System.IO.Path]::Combine($script:SIRoot, 'logo.png')
$script:SICurrentScript = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Definition }

# FAST UAC CHECK: Eleva ANTES de carregar WPF ou abrir janelas (evita abrir 2 janelas e poupa ~1s)
$script:SIHandedOver   = $false
$script:SIWithoutAdmin = $false

if (-not $Worker) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        try {
            $psi = [System.Diagnostics.ProcessStartInfo]::new('powershell.exe')
            $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$script:SICurrentScript`""
            $psi.Verb = 'runas'
            $psi.WorkingDirectory = $script:SIRoot
            $psi.UseShellExecute = $true
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            [void][System.Diagnostics.Process]::Start($psi)
            [System.Environment]::Exit(0)
        } catch {
            # Utilizador cancelou o UAC ou falhou: continua sem admin
            $script:SIWithoutAdmin = $true
        }
    }
}

# ==================== 2. COLOURS & STATE VARIABLES ========================

$script:SIColors = @{
    Background = '#1b1f29'
    Panel      = '#232838'
    PanelAlt   = '#272d3f'
    Accent     = '#ffd23f'
    Text       = '#e9eaf0'
    Muted      = '#98a0b3'
    Ok         = '#5ad08a'
    Off        = '#8b91a3'
    Warn       = '#ff9f43'
    Danger     = '#ff6b6b'
}

$script:SILoadingWindow       = $null
$script:SILoadingStep         = $null
$script:SILoadingLogo         = $null
$script:SIFirstWindowOnScreen = $null
$script:SIAssembliesAt        = $null
$script:SIWindowBuiltAt       = $null
$script:SIBrushCache          = @{}
$script:SILogAvailable        = $false

function Write-SILoaderLine {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [string]$Level = 'INFO'
    )
    if ($script:SILogAvailable) {
        try { Write-SILog -Level $Level -Component 'Load' -Message $Message; return } catch { }
    }
    [System.Console]::WriteLine("[{0:yyyy-MM-dd HH:mm:ss.fff}] [{1}] {2}" -f [datetime]::Now, $Level, $Message)
}

# ========================= 3. THE WPF ASSEMBLIES ==========================

if (-not $Worker) {
    try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } catch { }
}
$script:SIAssembliesAt = [datetime]::Now

# ========================= 4. THE LOADING WINDOW ==========================

function New-SILoadingBrush {
    param([string]$Hex)
    $brush = $script:SIBrushCache[$Hex]
    if (-not $brush) {
        $color = [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
        $brush = [System.Windows.Media.SolidColorBrush]::new($color)
        $brush.Freeze()
        $script:SIBrushCache[$Hex] = $brush
    }
    return $brush
}

function New-SILoadingWindow {
    $c = $script:SIColors

    $window = [System.Windows.Window]::new()
    $window.Title = 'SIGAME'
    $window.Width = 480
    $window.Height = 320
    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $window.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $window.Background = New-SILoadingBrush $c.Background
    $window.Foreground = New-SILoadingBrush $c.Text
    $window.FontFamily = [System.Windows.Media.FontFamily]::new('Segoe UI')

    $panel = [System.Windows.Controls.StackPanel]::new()
    $panel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $panel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $window.Content = $panel

    $logo = [System.Windows.Controls.Image]::new()
    $logo.Width = 96
    $logo.Height = 96
    $logo.Margin = [System.Windows.Thickness]::new(0, 0, 0, 16)
    $logo.Stretch = [System.Windows.Media.Stretch]::Uniform
    [void]$panel.Children.Add($logo)
    $script:SILoadingLogo = $logo

    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Text = 'SIGAME'
    $title.FontSize = 34
    $title.FontWeight = [System.Windows.FontWeights]::Bold
    $title.Foreground = New-SILoadingBrush $c.Accent
    $title.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    [void]$panel.Children.Add($title)

    $loading = [System.Windows.Controls.TextBlock]::new()
    $loading.Text = 'Loading ...'
    $loading.FontSize = 15
    $loading.Foreground = New-SILoadingBrush $c.Text
    $loading.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)
    $loading.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    [void]$panel.Children.Add($loading)

    $step = [System.Windows.Controls.TextBlock]::new()
    $step.Text = ''
    $step.FontSize = 11
    $step.Foreground = New-SILoadingBrush $c.Muted
    $step.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    $step.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    [void]$panel.Children.Add($step)
    $script:SILoadingStep = $step

    return $window
}

function Set-SILoadingLogo {
    if (-not $script:SILoadingWindow -or -not $script:SILoadingLogo) { return }
    if (-not [System.IO.File]::Exists($script:SILogoPath)) { return }

    try {
        $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bitmap.BeginInit()
        $bitmap.UriSource = [System.Uri]::new($script:SILogoPath, [System.UriKind]::Absolute)
        $bitmap.DecodePixelWidth = 96
        $bitmap.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $bitmap.Freeze()
        $script:SILoadingLogo.Source = $bitmap
    } catch { }
}

function Set-SILoadingStep {
    param([string]$Text)
    if ($script:SILoadingStep) {
        $script:SILoadingStep.Text = $Text
    }
}

function Invoke-SILoadingPump {
    <#
    .SYNOPSIS
        Drena a fila de renderizacao do WPF instantaneamente (<1ms) sem criar Timers
        nem bloquear a thread com esperas fixas de 30-120ms.
    #>
    if (-not $script:SILoadingWindow) { return }
    try {
        [void]$script:SILoadingWindow.Dispatcher.Invoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]{}
        )
    } catch { }
}

function Set-SIFirstWindowOnScreenTime {
    if ($script:SIFirstWindowOnScreen) { return }
    try {
        $script:SIFirstWindowOnScreen = [datetime]::Now.Subtract($script:SIProcessStart)
    } catch { }
}

function Close-SILoadingWindow {
    if (-not $script:SILoadingWindow) { return }
    try { $script:SILoadingWindow.Close() } catch { }
    $script:SILoadingWindow = $null
    $script:SILoadingStep   = $null
    $script:SILoadingLogo   = $null
}

# ===================== 5. THE LOADING WINDOW IS OPENED ====================

if (-not $Worker) {
    try {
        $script:SILoadingWindow = New-SILoadingWindow
        $script:SIWindowBuiltAt = [datetime]::Now
        [void]$script:SILoadingWindow.Add_ContentRendered({ Set-SIFirstWindowOnScreenTime })
        $script:SILoadingWindow.Show()
        
        # Forca o primeiro render imediato na placa grafica sem sleep artificial
        Invoke-SILoadingPump
        
        # Carrega o logo ja com a janela visivel
        Set-SILoadingLogo
        Invoke-SILoadingPump
    } catch {
        [System.Console]::WriteLine("The loading window could not be opened: $($_.Exception.Message)")
        $script:SILoadingWindow = $null
    }
}

# ============================== 6. THE MODULES ============================

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
)

$firstModule = $true
$script:SIModuleError = ''

foreach ($module in $script:SIModuleList) {
    if ($Worker -and $module -eq '06-window.ps1') { continue }

    $path = [System.IO.Path]::Combine($script:SIModulesPath, $module)
    if (-not [System.IO.File]::Exists($path)) {
        $errMsg = "The module $module is not in $($script:SIModulesPath)."
        Write-SILoaderLine -Level 'ERROR' -Message $errMsg
        if (-not $script:SIModuleError) { $script:SIModuleError = $errMsg }
        continue
    }

    if (-not $Worker) {
        Set-SILoadingStep -Text $module
        Invoke-SILoadingPump
    }

    $before = [datetime]::Now
    try {
        . $path
    } catch {
        $errMsg = "The module $module could not be loaded: $($_.Exception.Message)"
        Write-SILoaderLine -Level 'ERROR' -Message $errMsg
        if (-not $script:SIModuleError) { $script:SIModuleError = $errMsg }
    }
    $after = [datetime]::Now

    if ($firstModule) {
        $firstModule = $false
        $script:SILogAvailable = $true

        $powerShell = $script:SIScriptStart.Subtract($script:SIProcessStart).TotalSeconds
        $assemblies = if ($script:SIAssembliesAt) { $script:SIAssembliesAt.Subtract($script:SIScriptStart).TotalSeconds } else { 0 }
        $built      = if ($script:SIWindowBuiltAt) {
            $from = if ($script:SIAssembliesAt) { $script:SIAssembliesAt } else { $script:SIScriptStart }
            $script:SIWindowBuiltAt.Subtract($from).TotalSeconds
        } else { 0 }

        if ($script:SIFirstWindowOnScreen) {
            Write-SILoaderLine -Message ("the start: PowerShell {0:0.00} s, the WPF assemblies {1:0.00} s, the loading window {2:0.00} s, the first window on the screen {3:0.00} s after the start of the process." -f $powerShell, $assemblies, $built, $script:SIFirstWindowOnScreen.TotalSeconds)
        } else {
            Write-SILoaderLine -Message ("the start: PowerShell {0:0.00} s, the WPF assemblies {1:0.00} s, the loading window {2:0.00} s, the first window on the screen was not measured." -f $powerShell, $assemblies, $built)
        }

        if ($script:SIWithoutAdmin) {
            Write-SILoaderLine -Level 'WARN' -Message 'SIGAME opens without administrator rights, some tweaks will not work.'
        }
    }

    $spent = $after.Subtract($before).TotalSeconds
    $total = $after.Subtract($script:SIProcessStart).TotalSeconds
    Write-SILoaderLine -Message ("the module {0} was loaded in {1:0.00} s, {2:0.00} s after the start." -f $module, $spent, $total)
}

# =============================== 7. RUN IT =================================

if ($script:SIModuleError) {
    Close-SILoadingWindow
    try { Write-SILog -Level 'ERROR' -Component 'Load' -Message $script:SIModuleError } catch { }
    
    $logPath = [string]$script:SILogPath
    if (-not $logPath) { $logPath = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME.log') }
    
    if (-not $Worker) {
        try {
            [void][System.Windows.MessageBox]::Show(
                ("SIGAME cannot start.`n`n{0}`n`nThe details are in the log file:`n{1}" -f $script:SIModuleError,$logPath),
                'SIGAME',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error)
        } catch { }
    }
    [System.Console]::WriteLine($script:SIModuleError)
} else {
    try {
        Invoke-SIRun
    } catch {
        Close-SILoadingWindow
        $why = "SIGAME could not start: " + [string]$_.Exception.Message
        try { Write-SILog -Level 'ERROR' -Component 'Start' -Message $why } catch { }
        [System.Console]::WriteLine($why)
    }
}

try {
    [System.Environment]::Exit(0)
} catch {
    exit 0
}