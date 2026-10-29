# ===========================================================================
#  10-community.ps1 - SI PRESETS per game + game requests and feedback
# ===========================================================================
#  Two things live here:
#   1. The SI PRESET library (presets\catalog.json): the extreme configs made
#      in the SI NEWS videos, applied from SIGAME with one click and a backup.
#   2. Anonymous telemetry to SI NEWS (owner 26/10/2026): once a week the
#      names of the detected games + the hardware class, plus events (a game
#      added by hand, a REQUEST, a preset applied). ON by default with a fixed
#      notice in the window and a one-click "Turn off" (SI-GAME-community.json
#      "Telemetry": false). It goes to our Cloudflare Worker (TelemetryUrl in
#      SI-GAME-feedback.json); only SI NEWS can read it.
#
#  Privacy rules of this file (read them before changing it):
#   - No id of any kind (no install id, no hardware serial, no PC/user name),
#     never a path: only game names + store, exe FILE names, CPU/GPU model,
#     RAM in GB, Windows build, SIGAME version and language.
#   - Sending never blocks the window and never shows an error to the player.
# ===========================================================================

$script:SIGameVersion     = '2026.10.27.2'
$script:SIPresetsPath     = [System.IO.Path]::Combine($script:SIRoot, 'presets')
$script:SICatalogPath     = [System.IO.Path]::Combine($script:SIPresetsPath, 'catalog.json')
$script:SIFeedbackCfgPath = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-feedback.json')
$script:SICommunityPath   = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-community.json')
$script:SICatalog         = $null

$script:SICommunityText = @{
    'en' = @{
        BtnPresets      = 'SI PRESETS'
        BtnRequest      = 'REQUEST'
        BtnPreset       = 'SI PRESET'
        BtnFeedback     = 'Request a game / Feedback'
        ReqTitle        = 'Request a SI PRESET'
        ReqIntro        = 'Tell SI NEWS which game you want tuned and what you want from it. The most requested games get an extreme preset inside SIGAME.'
        ReqGame         = 'Game (also one SIGAME does not see):'
        ReqWants        = 'What do you want?'
        WantFps         = 'More FPS'
        WantUltra       = 'Graphics past the menu limits'
        WantWide        = 'Ultrawide / 144 Hz+'
        WantLoad        = 'Faster loading'
        WantStutter     = 'Fix stutter / crashes'
        WantLowEnd      = 'Playable on a weak PC'
        ReqMessage      = 'Anything else? (optional)'
        ReqPreview      = 'What will be sent:'
        ReqSend         = 'SEND'
        ReqCancel       = 'Cancel'
        ReqNoGame       = 'Write the name of the game first.'
        ReqSent         = 'Request sent to SI NEWS: {0}. Thank you!'
        TelemetryOn     = 'Anonymous stats ON: once a week SI NEWS gets the names of your games + CPU/GPU model and RAM (no id, no files) to choose the next SI PRESETS.'
        TelemetryOff    = 'Anonymous stats OFF.'
        TelemetryTurnOff = 'Turn off'
        TelemetryTurnOn  = 'Turn on'
        AskAfterAdd     = 'Game added: {0}. Do you want SI NEWS to make an extreme SI PRESET for it?'
        PresetConfirm   = "{0} - {1}`n`n{2}`n`nApply it now?"
        PresetDone      = 'SI PRESET {0} applied. Details in SI-GAME.log.'
        PresetFail      = 'SI PRESET {0} did not apply: {1}'
        PresetUndoAsk   = "SI PRESET {0} is already applied.`n`nYES = put your original config back (Undo)`nNO = apply it again"
        PresetsTitle    = 'SI PRESETS'
        PresetsIntro    = 'Extreme configs made in the SI NEWS videos. Found = the game is on this PC.'
        PresetFound     = 'found on this PC'
        PresetNotFound  = 'not found'
        PresetApply     = 'APPLY'
        PresetsUpdate   = 'Check for new presets'
        PresetsUpToDate = 'Presets are up to date ({0}).'
        PresetsNew      = "{0} new or updated SI PRESETS are on GitHub:`n`n{1}`n`nDownload them now?"
        PresetsGot      = '{0} SI PRESETS downloaded.'
        PresetsOffline  = 'Could not reach GitHub: {0}'
    }
    'it' = @{
        BtnPresets      = 'SI PRESETS'
        BtnRequest      = 'RICHIEDI'
        BtnPreset       = 'SI PRESET'
        BtnFeedback     = 'Richiedi un gioco / Feedback'
        ReqTitle        = 'Richiedi un SI PRESET'
        ReqIntro        = "Di' a SI NEWS quale gioco vuoi ottimizzare e cosa vuoi ottenere. I giochi piu' richiesti ricevono un preset estremo dentro SIGAME."
        ReqGame         = 'Gioco (anche uno che SIGAME non vede):'
        ReqWants        = 'Cosa vuoi?'
        WantFps         = 'Piu FPS'
        WantUltra       = 'Grafica oltre i limiti del menu'
        WantWide        = 'Ultrawide / 144 Hz+'
        WantLoad        = 'Caricamenti piu veloci'
        WantStutter     = 'Togliere scatti / crash'
        WantLowEnd      = 'Giocabile su PC debole'
        ReqMessage      = 'Altro? (facoltativo)'
        ReqPreview      = 'Cosa verra inviato:'
        ReqSend         = 'INVIA'
        ReqCancel       = 'Annulla'
        ReqNoGame       = 'Scrivi prima il nome del gioco.'
        ReqSent         = 'Richiesta inviata a SI NEWS: {0}. Grazie!'
        TelemetryOn     = 'Statistiche anonime ATTIVE: una volta a settimana SI NEWS riceve i nomi dei tuoi giochi + modello CPU/GPU e RAM (nessun id, nessun file) per scegliere i prossimi SI PRESET.'
        TelemetryOff    = 'Statistiche anonime DISATTIVATE.'
        TelemetryTurnOff = 'Disattiva'
        TelemetryTurnOn  = 'Attiva'
        AskAfterAdd     = 'Gioco aggiunto: {0}. Vuoi che SI NEWS crei un SI PRESET estremo per questo gioco?'
        PresetConfirm   = "{0} - {1}`n`n{2}`n`nApplicarlo adesso?"
        PresetDone      = 'SI PRESET {0} applicato. Dettagli in SI-GAME.log.'
        PresetFail      = 'SI PRESET {0} non applicato: {1}'
        PresetUndoAsk   = "Il SI PRESET {0} e gia applicato.`n`nSI = rimetti la tua configurazione originale (Undo)`nNO = applicalo di nuovo"
        PresetsTitle    = 'SI PRESETS'
        PresetsIntro    = 'Configurazioni estreme create nei video di SI NEWS. Trovato = il gioco e su questo PC.'
        PresetFound     = 'trovato su questo PC'
        PresetNotFound  = 'non trovato'
        PresetApply     = 'APPLICA'
        PresetsUpdate   = 'Cerca nuovi preset'
        PresetsUpToDate = 'Preset aggiornati ({0}).'
        PresetsNew      = "Su GitHub ci sono {0} SI PRESETS nuovi o aggiornati:`n`n{1}`n`nScaricarli adesso?"
        PresetsGot      = '{0} SI PRESETS scaricati.'
        PresetsOffline  = 'GitHub non raggiungibile: {0}'
    }
}

function Get-SICommunityText {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    if ($script:SICommunityText.ContainsKey($lang) -and $script:SICommunityText[$lang].ContainsKey($Key)) {
        return $script:SICommunityText[$lang][$Key]
    }
    return $script:SICommunityText['en'][$Key]
}

# ------------------------------- small files -------------------------------

function Read-SIJsonFile {
    param([string]$Path)
    if (-not [System.IO.File]::Exists($Path)) { return $null }
    try { return ([System.IO.File]::ReadAllText($Path) | ConvertFrom-Json) } catch { return $null }
}

function Get-SICommunityState {
    $s = Read-SIJsonFile -Path $script:SICommunityPath
    if (-not $s) { $s = [pscustomobject]@{} }
    foreach ($p in @(
            @{ N = 'Telemetry'; V = $true },
            @{ N = 'LastWeek';  V = '' },
            @{ N = 'Applied';   V = [pscustomobject]@{} })) {
        if (-not ($s.PSObject.Properties.Name -contains $p.N)) { $s | Add-Member $p.N $p.V -Force }
    }
    if ($s.PSObject.Properties.Name -contains 'InstallId') { $s.PSObject.Properties.Remove('InstallId') }
    return $s
}

function Save-SICommunityState {
    param($State)
    try {
        [System.IO.File]::WriteAllText($script:SICommunityPath, ($State | ConvertTo-Json -Depth 6))
    } catch {
        Write-SILog -Level 'WARN' -Component 'Community' -Message "Could not save SI-GAME-community.json: $($_.Exception.Message)"
    }
}

function Get-SIFeedbackConfig {
    $cfg = Read-SIJsonFile -Path $script:SIFeedbackCfgPath
    if (-not $cfg) { $cfg = [pscustomobject]@{ TelemetryUrl = ''; GitHubRepo = 'Grokeador/SIGAME'; PresetsRawBase = '' } }
    return $cfg
}

# ------------------------------- SI PRESETS ---------------------------------

function Get-SIPresetCatalog {
    param([switch]$Reload)
    if ($script:SICatalog -and -not $Reload) { return $script:SICatalog }
    $cat = Read-SIJsonFile -Path $script:SICatalogPath
    $script:SICatalog = if ($cat -and $cat.Presets) { @($cat.Presets) } else { @() }
    return $script:SICatalog
}

function Get-SIPresetText {
    param($Entry)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    $sum = $Entry.Summary
    if ($sum -and $sum.PSObject.Properties.Name -contains $lang) { return [string]$sum.$lang }
    if ($sum -and $sum.en) { return [string]$sum.en }
    return ''
}

function Test-SIPresetDetected {
    param($Entry)
    if (-not $Entry.DetectPath) { return $false }
    $p = [System.Environment]::ExpandEnvironmentVariables([string]$Entry.DetectPath)
    return [System.IO.Directory]::Exists($p)
}

function Find-SIGamePreset {
    <#
    .SYNOPSIS
        The SI PRESET of one game card, matched on the game name, exe name and
        folder name (never on the full path, so a user name cannot match).
    #>
    param($Game)
    $hay = @([string]$Game.Name, [System.IO.Path]::GetFileName([string]$Game.Exe),
             [System.IO.Path]::GetFileName([string]$Game.Folder)) -join ' | '
    foreach ($e in (Get-SIPresetCatalog)) {
        if ($e.Match -and $hay -match [string]$e.Match) { return $e }
    }
    return $null
}

function Invoke-SIPresetScript {
    param($Entry, [switch]$Undo)
    $script = [System.IO.Path]::Combine($script:SIPresetsPath, [string]$Entry.Script)
    if (-not [System.IO.File]::Exists($script)) { return @{ Ok = $false; Lines = @("missing $($Entry.Script)") } }
    $out = [System.IO.Path]::GetTempFileName()
    $argLine = "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
    if ($Undo) { $argLine += ' -Undo' }
    # Catalog extras (SIGAME 2026.10.27.2+): fixed arguments, and the exe of the game card for presets that install
    # into the game folder (SI OPTI).
    if ($Entry.PSObject.Properties.Name -contains 'Args' -and $Entry.Args) { $argLine += ' ' + [string]$Entry.Args }
    if ($Entry.PSObject.Properties.Name -contains 'NeedsGame' -and $Entry.NeedsGame) {
        foreach ($g in @($script:SIGameLibrary)) {
            $hit = Find-SIGamePreset -Game $g
            if ($hit -and $hit.Id -eq $Entry.Id -and $g.Exe) { $argLine += " -GameExe `"$($g.Exe)`""; break }
        }
    }
    # Game-folder presets may download (SI OPTI: 55 MB): a visible console shows the download progress bar.
    $style = 'Hidden'
    if ($Entry.PSObject.Properties.Name -contains 'NeedsGame' -and $Entry.NeedsGame) { $style = 'Normal' }
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $argLine -WindowStyle $style -Wait -PassThru `
        -RedirectStandardOutput $out -WorkingDirectory $script:SIPresetsPath
    $lines = @()
    try { $lines = @([System.IO.File]::ReadAllLines($out)) } catch { }
    try { [System.IO.File]::Delete($out) } catch { }
    foreach ($l in $lines) { if ($l) { Write-SILog -Component "Preset $($Entry.Id)" -Message $l } }
    return @{ Ok = ($p.ExitCode -eq 0); Lines = $lines }
}

function Invoke-SIGamePreset {
    param($Entry)
    # the SI PRESETS list is a modal child: own the boxes from it, or the result box opens hidden behind it
    $win = $script:SIWindow
    $top = @($win.OwnedWindows | Where-Object { $_.IsVisible }) | Select-Object -Last 1
    if ($top) { $win = $top }
    $state = Get-SICommunityState
    $already = ($state.Applied.PSObject.Properties.Name -contains [string]$Entry.Id)

    $undo = $false
    if ($already -and $Entry.Undo) {
        $undo = Show-SIMessage -Window $win -Title 'SI PRESET' -Text ((Get-SICommunityText 'PresetUndoAsk') -f $Entry.Title)
    }
    if (-not $undo) {
        $msg = (Get-SICommunityText 'PresetConfirm') -f $Entry.Title, $Entry.Game, (Get-SIPresetText -Entry $Entry)
        if (-not (Show-SIMessage -Window $win -Title 'SI PRESET' -Text $msg)) { return }
    }

    $r = Invoke-SIPresetScript -Entry $Entry -Undo:$undo
    [void]$win.Activate()
    $last = (@($r.Lines | Where-Object { $_ }) | Select-Object -Last 1)
    if ($r.Ok) {
        if ($undo) {
            $state.Applied.PSObject.Properties.Remove([string]$Entry.Id)
        } else {
            $state.Applied | Add-Member ([string]$Entry.Id) ([datetime]::Now.ToString('s')) -Force
        }
        Save-SICommunityState -State $state
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetDone') -f $Entry.Title)
        [void][System.Windows.MessageBox]::Show($win, (@($r.Lines) -join "`n"), "SI PRESET $($Entry.Title)")
        $kind = if ($undo) { 'preset_undo' } else { 'preset_applied' }
        Send-SITelemetry -Event (New-SITelemetryEvent -Kind $kind -Preset ([string]$Entry.Id))
    } else {
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetFail') -f $Entry.Title, $last)
        [void][System.Windows.MessageBox]::Show($win, (@($r.Lines) -join "`n"), "SI PRESET $($Entry.Title)")
        Send-SITelemetry -Event (New-SITelemetryEvent -Kind 'preset_failed' -Preset ([string]$Entry.Id) -Message ([string]$last))
    }
}

function Update-SIPresetLibrary {
    <#
    .SYNOPSIS
        Downloads new or updated SI PRESETS from the SIGAME GitHub repo, after
        the player said yes. Only files listed in catalog.json, only .ps1.
    #>
    $cfg = Get-SIFeedbackConfig
    $base = [string]$cfg.PresetsRawBase
    if (-not $base) { $base = "https://raw.githubusercontent.com/$($cfg.GitHubRepo)/main/presets/" }
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $remoteText = (Invoke-WebRequest -Uri ($base + 'catalog.json') -UseBasicParsing -TimeoutSec 10).Content
        $remote = $remoteText | ConvertFrom-Json
    } catch {
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetsOffline') -f $_.Exception.Message)
        return
    }
    $local = @{}
    foreach ($e in (Get-SIPresetCatalog -Reload)) { $local[[string]$e.Id] = [int]$e.Version }
    $todo = @($remote.Presets | Where-Object {
            ([string]$_.Script -match '^[A-Za-z0-9_.-]+\.ps1$') -and
            ((-not $local.ContainsKey([string]$_.Id)) -or ([int]$_.Version -gt $local[[string]$_.Id])) })
    if ($todo.Count -eq 0) {
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetsUpToDate') -f $remote.Updated)
        return
    }
    $names = ($todo | ForEach-Object { "- $($_.Title): $($_.Game)" }) -join "`n"
    if (-not (Show-SIMessage -Window $script:SIWindow -Title 'SI PRESETS' -Text ((Get-SICommunityText 'PresetsNew') -f $todo.Count, $names))) { return }
    try {
        [void][System.IO.Directory]::CreateDirectory($script:SIPresetsPath)
        foreach ($e in $todo) {
            $dest = [System.IO.Path]::Combine($script:SIPresetsPath, [string]$e.Script)
            Invoke-WebRequest -Uri ($base + [string]$e.Script) -UseBasicParsing -TimeoutSec 15 -OutFile $dest
            Write-SILog -Component 'Presets' -Message "Downloaded $($e.Script) v$($e.Version)"
        }
        [System.IO.File]::WriteAllText($script:SICatalogPath, $remoteText)
        [void](Get-SIPresetCatalog -Reload)
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetsGot') -f $todo.Count)
        try { Update-SIAutoDashboard } catch { }
    } catch {
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetsOffline') -f $_.Exception.Message)
    }
}

function Show-SIPresetsWindow {
    $c = $script:SIColors
    $w = [System.Windows.Window]::new()
    $w.Title = (Get-SICommunityText 'PresetsTitle')
    $w.Width = 560
    $w.SizeToContent = 'Height'
    $w.MaxHeight = 640
    $w.WindowStartupLocation = 'CenterOwner'
    if ($script:SIWindow) { $w.Owner = $script:SIWindow }
    $w.Background = Get-SIBrush $c.Background
    $root = [System.Windows.Controls.StackPanel]::new()
    $root.Margin = [System.Windows.Thickness]::new(16)

    $intro = [System.Windows.Controls.TextBlock]::new()
    $intro.Text = (Get-SICommunityText 'PresetsIntro')
    $intro.Foreground = Get-SIBrush $c.Muted
    $intro.TextWrapping = 'Wrap'
    $intro.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    [void]$root.Children.Add($intro)

    $list = [System.Windows.Controls.StackPanel]::new()
    $scroll = [System.Windows.Controls.ScrollViewer]::new()
    $scroll.MaxHeight = 460
    $scroll.VerticalScrollBarVisibility = 'Auto'
    $scroll.Content = $list
    [void]$root.Children.Add($scroll)

    foreach ($e in (Get-SIPresetCatalog)) {
        $row = [System.Windows.Controls.Border]::new()
        $row.Background = Get-SIBrush $c.PanelAlt
        $row.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $row.Padding = [System.Windows.Thickness]::new(10, 8, 10, 8)
        $row.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
        $dock = [System.Windows.Controls.DockPanel]::new()
        $btn = New-SIStyleButton -Text (Get-SICommunityText 'PresetApply') -StyleKey 'AccentButton' -Window $w -Width 80
        $btn.Height = 26
        $btn.VerticalAlignment = 'Center'
        [System.Windows.Controls.DockPanel]::SetDock($btn, 'Right')
        $captured = $e
        $null = $btn.Add_Click({ Invoke-SIGamePreset -Entry $captured }.GetNewClosure())
        [void]$dock.Children.Add($btn)
        $txt = [System.Windows.Controls.StackPanel]::new()
        $t1 = [System.Windows.Controls.TextBlock]::new()
        $t1.Text = "$($e.Title)  -  $($e.Game)"
        $t1.FontWeight = 'SemiBold'
        $t1.Foreground = Get-SIBrush $c.Text
        $t1.TextWrapping = 'Wrap'
        [void]$txt.Children.Add($t1)
        $found = Test-SIPresetDetected -Entry $e
        $t2 = [System.Windows.Controls.TextBlock]::new()
        $t2.Text = if ($found) { (Get-SICommunityText 'PresetFound') } else { (Get-SICommunityText 'PresetNotFound') }
        $t2.Foreground = if ($found) { Get-SIBrush $c.Ok } else { Get-SIBrush $c.Off }
        $t2.FontSize = 10.5
        [void]$txt.Children.Add($t2)
        $t3 = [System.Windows.Controls.TextBlock]::new()
        $t3.Text = (Get-SIPresetText -Entry $e)
        $t3.Foreground = Get-SIBrush $c.Muted
        $t3.FontSize = 10.5
        $t3.TextWrapping = 'Wrap'
        $t3.Margin = [System.Windows.Thickness]::new(0, 3, 8, 0)
        [void]$txt.Children.Add($t3)
        [void]$dock.Children.Add($txt)
        $row.Child = $dock
        [void]$list.Children.Add($row)
    }

    $bar = [System.Windows.Controls.StackPanel]::new()
    $bar.Orientation = 'Horizontal'
    $bar.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    $bUpd = New-SIStyleButton -Text (Get-SICommunityText 'PresetsUpdate') -StyleKey 'GhostButton' -Window $w
    $bUpd.Height = 26
    $null = $bUpd.Add_Click({ param($s, $ev) [System.Windows.Window]::GetWindow($s).Close(); Update-SIPresetLibrary })
    [void]$bar.Children.Add($bUpd)
    $bReq = New-SIStyleButton -Text (Get-SICommunityText 'BtnFeedback') -StyleKey 'GhostButton' -Window $w
    $bReq.Height = 26
    $bReq.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    $null = $bReq.Add_Click({ param($s, $ev) [System.Windows.Window]::GetWindow($s).Close(); Invoke-SIRequestGame })
    [void]$bar.Children.Add($bReq)
    [void]$root.Children.Add($bar)

    $w.Content = $root
    [void]$w.ShowDialog()
}

# ------------------------------- telemetry ----------------------------------

function Get-SIAnonHardware {
    $b = $script:SIBottleneck
    $build = ''
    try {
        $v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $build = "$($v.CurrentBuild).$($v.UBR)"
    } catch { }
    return [ordered]@{
        cpu   = if ($b -and $b.Cpu) { ([string]$b.Cpu -replace '\s+', ' ').Trim() } else { 'unknown' }
        gpu   = if ($b -and $b.Gpu) { ([string]$b.Gpu -replace '\s+', ' ').Trim() } else { 'unknown' }
        ram   = if ($b -and $b.RamGB) { [int]$b.RamGB } else { 0 }
        build = $build
    }
}

function Get-SIIsoWeek {
    $now = [datetime]::Now
    $cal = [System.Globalization.CultureInfo]::InvariantCulture.Calendar
    $w = $cal.GetWeekOfYear($now, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
    return ('{0}-W{1:00}' -f $now.Year, $w)
}

function New-SITelemetryEvent {
    param([string]$Kind, [string]$Game = '', [string]$Store = '', [string]$ExeName = '',
          [string]$Wants = '', [string]$Message = '', [string]$Preset = '', $Games = $null)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    $e = [ordered]@{
        kind    = $Kind
        week    = (Get-SIIsoWeek)
        version = $script:SIGameVersion
        lang    = $lang
        hw      = (Get-SIAnonHardware)
    }
    if ($Game)    { $e['game'] = [ordered]@{ name = $Game; store = $Store; exe = $ExeName } }
    if ($Wants)   { $e['wants'] = $Wants }
    if ($Message) { $e['message'] = $Message }
    if ($Preset)  { $e['preset'] = $Preset }
    if ($Games)   { $e['games'] = @($Games) }
    return $e
}

function Format-SITelemetryPreview {
    param($Event)
    $lines = @()
    foreach ($k in $Event.Keys) {
        $v = $Event[$k]
        if ($v -is [System.Collections.IDictionary]) {
            $lines += ($k + ' = ' + (($v.Keys | Where-Object { $v[$_] } | ForEach-Object { "$_ $($v[$_])" }) -join ' | '))
        } elseif ($v) {
            $lines += "$k = $v"
        }
    }
    return ($lines -join "`n")
}

function Send-SITelemetry {
    <#
    .SYNOPSIS
        Posts one event to the SI NEWS Worker in a background runspace: the
        window never waits and the player never sees a network error.
        -Force sends even with telemetry off (a REQUEST the player typed).
    #>
    param($Event, [switch]$Force)
    try {
        $uri = [string](Get-SIFeedbackConfig).TelemetryUrl
        if (-not $uri) { return }
        if (-not $Force -and (Get-SICommunityState).Telemetry -ne $true) { return }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(($Event | ConvertTo-Json -Depth 5 -Compress))
        $ps = [powershell]::Create()
        $null = $ps.AddScript({
                param($Uri, $Bytes, $Agent)
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
                try {
                    $null = Invoke-WebRequest -Uri $Uri -Method Post -Body $Bytes -UseBasicParsing -TimeoutSec 30 `
                        -ContentType 'application/json; charset=utf-8' -UserAgent $Agent
                } catch { }
            }).AddArgument($uri).AddArgument($bytes).AddArgument("SIGAME/$($script:SIGameVersion)")
        $null = $ps.BeginInvoke()
        Write-SILog -Component 'Telemetry' -Message "Sent: $($Event.kind)"
    } catch { }
}

function Invoke-SITelemetryWeekly {
    <#
    .SYNOPSIS
        Once per ISO week: the names + stores of the games SIGAME found.
    #>
    try {
        $state = Get-SICommunityState
        if ($state.Telemetry -ne $true -or -not (Get-SIFeedbackConfig).TelemetryUrl) { return }
        $week = Get-SIIsoWeek
        if ([string]$state.LastWeek -eq $week) { return }
        $lib = @($script:SIGameLibrary)
        $games = @($lib | ForEach-Object { [ordered]@{ name = [string]$_.Name; store = [string]$_.Store } })
        Send-SITelemetry -Event (New-SITelemetryEvent -Kind 'weekly' -Games $games)
        $state.LastWeek = $week
        Save-SICommunityState -State $state
    } catch { }
}

function Send-SICustomGameTelemetry {
    param([string]$ExePath)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($ExePath)
    $folder = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($ExePath))
    Send-SITelemetry -Event (New-SITelemetryEvent -Kind 'custom_game' -Game $name -Store 'Manuale' `
        -ExeName ([System.IO.Path]::GetFileName($ExePath)) -Message "folder: $folder")
}

function Set-SITelemetryEnabled {
    param([bool]$On)
    $state = Get-SICommunityState
    $state.Telemetry = $On
    Save-SICommunityState -State $state
    Write-SILog -Component 'Telemetry' -Message "Anonymous stats: $On"
    Update-SITelemetryNotice
}

function Update-SITelemetryNotice {
    $tb = $script:SITelemetryNotice
    if (-not $tb) { return }
    $on = ((Get-SICommunityState).Telemetry -eq $true)
    $tb.Inlines.Clear()
    $text = if ($on) { (Get-SICommunityText 'TelemetryOn') } else { (Get-SICommunityText 'TelemetryOff') }
    [void]$tb.Inlines.Add([System.Windows.Documents.Run]::new($text + '  '))
    $label = if ($on) { (Get-SICommunityText 'TelemetryTurnOff') } else { (Get-SICommunityText 'TelemetryTurnOn') }
    $link = [System.Windows.Documents.Hyperlink]::new([System.Windows.Documents.Run]::new($label))
    $link.Foreground = Get-SIBrush $script:SIColors.Accent
    $target = -not $on
    $null = $link.Add_Click({ Set-SITelemetryEnabled -On $target }.GetNewClosure())
    [void]$tb.Inlines.Add($link)
}

function New-SITelemetryNotice {
    <#
    .SYNOPSIS
        The fixed one-line notice under the games list (no dialog, no click
        needed): what is sent, and a link that turns it off or on.
    #>
    $tb = [System.Windows.Controls.TextBlock]::new()
    $tb.FontSize = 10
    $tb.TextWrapping = 'Wrap'
    $tb.Foreground = Get-SIBrush $script:SIColors.Muted
    $tb.Margin = [System.Windows.Thickness]::new(0, 6, 0, 0)
    $script:SITelemetryNotice = $tb
    Update-SITelemetryNotice
    return $tb
}

function Show-SIRequestDialog {
    <#
    .SYNOPSIS
        The request window: game, wishes, free text, and a live preview of the
        exact text that will be sent. Returns the payload or $null.
    #>
    param([string]$Game = '', [string]$Store = '', [string]$ExeName = '')
    $c = $script:SIColors
    $w = [System.Windows.Window]::new()
    $w.Title = (Get-SICommunityText 'ReqTitle')
    $w.Width = 500
    $w.SizeToContent = 'Height'
    $w.WindowStartupLocation = 'CenterOwner'
    if ($script:SIWindow) { $w.Owner = $script:SIWindow }
    $w.Background = Get-SIBrush $c.Background
    $root = [System.Windows.Controls.StackPanel]::new()
    $root.Margin = [System.Windows.Thickness]::new(16)

    function Add-Label([string]$text, [string]$color, [double]$size = 12) {
        $t = [System.Windows.Controls.TextBlock]::new()
        $t.Text = $text
        $t.TextWrapping = 'Wrap'
        $t.FontSize = $size
        $t.Foreground = Get-SIBrush $color
        $t.Margin = [System.Windows.Thickness]::new(0, 6, 0, 4)
        [void]$root.Children.Add($t)
    }

    Add-Label (Get-SICommunityText 'ReqIntro') $c.Muted 11.5
    Add-Label (Get-SICommunityText 'ReqGame') $c.Accent
    $tbGame = [System.Windows.Controls.TextBox]::new()
    $tbGame.Text = $Game
    $tbGame.Padding = [System.Windows.Thickness]::new(4)
    [void]$root.Children.Add($tbGame)

    Add-Label (Get-SICommunityText 'ReqWants') $c.Accent
    $wrap = [System.Windows.Controls.WrapPanel]::new()
    $boxes = @()
    foreach ($k in @('WantFps', 'WantUltra', 'WantWide', 'WantLoad', 'WantStutter', 'WantLowEnd')) {
        $cb = [System.Windows.Controls.CheckBox]::new()
        $cb.Content = (Get-SICommunityText $k)
        $cb.Tag = $k.Substring(4).ToLowerInvariant()
        $cb.Foreground = Get-SIBrush $c.Text
        $cb.Margin = [System.Windows.Thickness]::new(0, 2, 14, 2)
        [void]$wrap.Children.Add($cb)
        $boxes += $cb
    }
    [void]$root.Children.Add($wrap)

    Add-Label (Get-SICommunityText 'ReqMessage') $c.Accent
    $tbMsg = [System.Windows.Controls.TextBox]::new()
    $tbMsg.AcceptsReturn = $true
    $tbMsg.TextWrapping = 'Wrap'
    $tbMsg.Height = 70
    $tbMsg.MaxLength = 1000
    [void]$root.Children.Add($tbMsg)

    Add-Label (Get-SICommunityText 'ReqPreview') $c.Muted 11
    $preview = [System.Windows.Controls.TextBox]::new()
    $preview.IsReadOnly = $true
    $preview.TextWrapping = 'Wrap'
    $preview.FontFamily = 'Consolas'
    $preview.FontSize = 10.5
    $preview.Background = Get-SIBrush $c.PanelAlt
    $preview.Foreground = Get-SIBrush $c.Muted
    [void]$root.Children.Add($preview)

    $build = {
        $wants = (@($boxes | Where-Object { $_.IsChecked } | ForEach-Object { $_.Tag }) -join ',')
        New-SITelemetryEvent -Kind 'request' -Game $tbGame.Text.Trim() -Store $Store -ExeName $ExeName `
            -Wants $wants -Message $tbMsg.Text.Trim()
    }.GetNewClosure()
    $refresh = {
        $p = & $build
        $preview.Text = (Format-SITelemetryPreview -Event $p)
    }.GetNewClosure()
    $null = $tbGame.Add_TextChanged($refresh)
    $null = $tbMsg.Add_TextChanged($refresh)
    foreach ($cb in $boxes) { $null = $cb.Add_Click($refresh) }
    & $refresh

    $bar = [System.Windows.Controls.StackPanel]::new()
    $bar.Orientation = 'Horizontal'
    $bar.HorizontalAlignment = 'Right'
    $bar.Margin = [System.Windows.Thickness]::new(0, 12, 0, 0)
    $bCancel = New-SIStyleButton -Text (Get-SICommunityText 'ReqCancel') -StyleKey 'GhostButton' -Window $w -Width 90
    $bCancel.Height = 28
    $null = $bCancel.Add_Click({ param($s, $ev) [System.Windows.Window]::GetWindow($s).DialogResult = $false })
    [void]$bar.Children.Add($bCancel)
    $bSend = New-SIStyleButton -Text (Get-SICommunityText 'ReqSend') -StyleKey 'AccentButton' -Window $w -Width 110
    $bSend.Height = 28
    $bSend.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    $noGame = (Get-SICommunityText 'ReqNoGame')
    $null = $bSend.Add_Click({
        param($s, $ev)
        if (-not $tbGame.Text.Trim()) { [void][System.Windows.MessageBox]::Show($noGame); return }
        [System.Windows.Window]::GetWindow($s).DialogResult = $true
    }.GetNewClosure())
    [void]$bar.Children.Add($bSend)
    [void]$root.Children.Add($bar)

    $w.Content = $root
    if ($w.ShowDialog() -ne $true) { return $null }
    return (& $build)
}

function Invoke-SIRequestGame {
    <#
    .SYNOPSIS
        A request typed by the player goes straight to SI NEWS: pressing SEND
        is the consent for this one message, even with telemetry off.
    #>
    param($Game)
    $name = ''; $store = ''; $exe = ''
    if ($Game) {
        $name = [string]$Game.Name
        $store = [string]$Game.Store
        $exe = [System.IO.Path]::GetFileName([string]$Game.Exe)
    }
    $payload = Show-SIRequestDialog -Game $name -Store $store -ExeName $exe
    if (-not $payload) { return }
    Write-SILog -Component 'Community' -Message "Request: $($payload.game.name) wants=$($payload.wants)"
    Send-SITelemetry -Event $payload -Force
    Set-SIStatusText -Text ((Get-SICommunityText 'ReqSent') -f $payload.game.name)
}
