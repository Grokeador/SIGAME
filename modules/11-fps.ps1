# ================= 11. FPS MEASURE: BEFORE / AFTER A SI PRESET ==================
# Owner 27/10/2026: "Ci fidiamo su quello che ci dicono". The FPS button of a game card measures the RUNNING game
# with PresentMon (Intel GameTechDev, MIT, github.com/GameTechDev/PresentMon), the same capture tool used by
# reviewers. SIGAME downloads the official v2.6.0 console exe once from its GitHub release and runs it only when its
# SHA-256 matches the one GitHub publishes for that asset. Each measure is kept in SI-GAME-fps.json, compared with
# the previous one of the same game with a verdict (changes under 3% are not counted), and (anonymous stats ON) sent to SI NEWS as kind 'fps_measured' with the
# presets applied at that moment: real numbers from real players, never ours.

$script:SIFpsPath   = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-fps.json')
$script:SIToolsPath = [System.IO.Path]::Combine($script:SIRoot, 'tools')
$script:SIPresentMon = @{
    File   = 'PresentMon-2.6.0-x64.exe'
    Url    = 'https://github.com/GameTechDev/PresentMon/releases/download/v2.6.0/PresentMon-2.6.0-x64.exe'
    Sha256 = 'B2A706BC6AD475749E3B7E3409263AA1E6906D45BDCF993F6DBC0F660188F1AF'
}
$script:SIFpsDelay   = 10      # seconds to go back to the game
$script:SIFpsSeconds = 60      # seconds measured
$script:SIFpsNoise   = 3.0     # percent: a smaller change is not counted as a change
$script:SIFpsRun     = $null
$script:SIFpsTimer   = $null

$script:SIFpsText = @{
    'en' = @{
        BtnFps      = 'FPS'
        FpsTip      = 'Measure the FPS of this game while you play (60 s). Measure before and after a SI PRESET.'
        FpsGetTool  = "To measure FPS, SIGAME downloads PresentMon (Intel, open source MIT, 1 MB) from its official GitHub page and checks its SHA-256 fingerprint.`n`nDownload it now?"
        FpsToolBad  = 'PresentMon download failed or its fingerprint does not match: nothing was run.'
        FpsNotRun   = "{0} is not running.`n`nStart the game, then click FPS: SIGAME waits {1} s so you can go back to the game, then measures {2} s while you play."
        FpsStart    = "FPS measure of {0}`n`nGo back to the game now and play normally. It starts in {1} s and lasts {2} s. SIGAME shows the result when it ends."
        FpsBusy     = 'A FPS measure is already running.'
        FpsStatus   = 'Measuring FPS of {0}... go back to the game and play.'
        FpsNoFrames = 'No frames from {0}: keep the game on screen while it measures, then try again.'
        FpsResult   = "{0}`n`nAverage: {1} FPS`n1% low: {2} FPS`n({3} frames in {4} s)"
        FpsCompare  = "`n`nPrevious measure ({0}): {1} FPS average, {2} FPS 1% low`nChange: {3} average, {4} 1% low"
        FpsPresets  = "`n`nActive SI PRESETS: {0}"
        FpsShared   = "`n`nAnonymous stats ON: these numbers go to SI NEWS with your CPU/GPU model (no files, no id)."
        FpsTitle    = 'SIGAME FPS'
        FpsPro      = "`n0.1% low: {0} FPS`nSlowest frame: {1} ms`nStutters: {2} (frames slower than 2x the median frame)"
        FpsProShort = "`nSlowest frame: {0} ms`nStutters: {1} (frames slower than 2x the median frame)"
        FpsStutCmp  = "`nStutters before: {0}, now: {1}"
        FpsVNoise   = "`n`nVERDICT: no real change. SIGAME counts a change only from {0}% up, in average or 1% low."
        FpsVUnsteady = "`n`nVERDICT: no real change that can be told. Inside one capture, with nothing changed, the average moved {0}% and the 1% low {1}%: a smaller difference is not counted. Measure again in the same scene with nothing else open."
        FpsVBetter  = "`n`nVERDICT: FASTER than the previous measure."
        FpsVWorse   = "`n`nVERDICT: SLOWER than the previous measure. Undo the last preset or tweak and measure again."
        FpsVMixed   = "`n`nVERDICT: mixed. Average and 1% low moved in opposite directions: measure again in the same place of the game."
        FpsBest     = "`n`nBest of your last {0} measures: {1} FPS average, {2} FPS 1% low ({3}){4}"
        FpsBestSet  = ', SI PRESETS: {0}'
    }
    'it' = @{
        BtnFps      = 'FPS'
        FpsTip      = 'Misura gli FPS di questo gioco mentre giochi (60 s). Misura prima e dopo un SI PRESET.'
        FpsGetTool  = "Per misurare gli FPS SIGAME scarica PresentMon (Intel, open source MIT, 1 MB) dalla sua pagina GitHub ufficiale e controlla la sua impronta SHA-256.`n`nScaricarlo adesso?"
        FpsToolBad  = 'Download di PresentMon fallito o impronta diversa: non e'' stato eseguito niente.'
        FpsNotRun   = "{0} non e' in esecuzione.`n`nAvvia il gioco, poi clicca FPS: SIGAME aspetta {1} s per farti tornare nel gioco, poi misura {2} s mentre giochi."
        FpsStart    = "Misura FPS di {0}`n`nTorna nel gioco adesso e gioca normalmente. Parte tra {1} s e dura {2} s. SIGAME mostra il risultato alla fine."
        FpsBusy     = 'Una misura FPS e'' gia'' in corso.'
        FpsStatus   = 'Misuro gli FPS di {0}... torna nel gioco e gioca.'
        FpsNoFrames = 'Nessun frame da {0}: tieni il gioco sullo schermo durante la misura e riprova.'
        FpsResult   = "{0}`n`nMedia: {1} FPS`n1% low: {2} FPS`n({3} frame in {4} s)"
        FpsCompare  = "`n`nMisura precedente ({0}): {1} FPS media, {2} FPS 1% low`nDifferenza: {3} media, {4} 1% low"
        FpsPresets  = "`n`nSI PRESET attivi: {0}"
        FpsShared   = "`n`nStatistiche anonime ON: questi numeri vanno a SI NEWS con il modello di CPU/GPU (niente file, niente id)."
        FpsTitle    = 'SIGAME FPS'
        FpsPro      = "`n0.1% low: {0} FPS`nFrame piu' lento: {1} ms`nScatti: {2} (frame piu' lenti di 2 volte il frame mediano)"
        FpsProShort = "`nFrame piu' lento: {0} ms`nScatti: {1} (frame piu' lenti di 2 volte il frame mediano)"
        FpsStutCmp  = "`nScatti prima: {0}, adesso: {1}"
        FpsVNoise   = "`n`nVERDETTO: nessun cambiamento reale. SIGAME conta un cambiamento solo dal {0}% in su, nella media o nell'1% low."
        FpsVUnsteady = "`n`nVERDETTO: nessun cambiamento reale distinguibile. Dentro una sola cattura, senza cambiare nulla, la media si muove del {0}% e l'1% low del {1}%: una differenza piu' piccola non conta. Misura di nuovo nella stessa scena con nient'altro aperto."
        FpsVBetter  = "`n`nVERDETTO: PIU' VELOCE della misura precedente."
        FpsVWorse   = "`n`nVERDETTO: PIU' LENTO della misura precedente. Annulla l'ultimo preset o tweak e misura di nuovo."
        FpsVMixed   = "`n`nVERDETTO: misto. Media e 1% low sono andati in direzioni opposte: misura di nuovo nello stesso punto del gioco."
        FpsBest     = "`n`nMigliore delle tue ultime {0} misure: {1} FPS media, {2} FPS 1% low ({3}){4}"
        FpsBestSet  = ', SI PRESET: {0}'
    }
}

function Get-SIFpsText {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    if ($script:SIFpsText.ContainsKey($lang) -and $script:SIFpsText[$lang].ContainsKey($Key)) {
        return $script:SIFpsText[$lang][$Key]
    }
    return $script:SIFpsText['en'][$Key]
}

function Get-SIPresentMonPath {
    <#
    .SYNOPSIS
        The verified PresentMon exe, downloaded once after the player says yes; $null if missing or not verified.
    #>
    $path = [System.IO.Path]::Combine($script:SIToolsPath, $script:SIPresentMon.File)
    if ([System.IO.File]::Exists($path) -and
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $script:SIPresentMon.Sha256) { return $path }
    if (-not (Show-SIMessage -Window $script:SIWindow -Title (Get-SIFpsText 'FpsTitle') -Text (Get-SIFpsText 'FpsGetTool'))) { return $null }
    $tmp = "$path.download"
    try {
        [void][System.IO.Directory]::CreateDirectory($script:SIToolsPath)
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $script:SIPresentMon.Url -UseBasicParsing -TimeoutSec 60 -OutFile $tmp
        if ((Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash -ne $script:SIPresentMon.Sha256) { throw 'SHA-256 mismatch' }
        Move-Item -LiteralPath $tmp -Destination $path -Force
        Write-SILog -Component 'FPS' -Message "PresentMon verified: $($script:SIPresentMon.File)"
        return $path
    } catch {
        Write-SILog -Level 'WARN' -Component 'FPS' -Message "PresentMon not ready: $($_.Exception.Message)"
        try { if ([System.IO.File]::Exists($tmp)) { [System.IO.File]::Delete($tmp) } } catch { }
        [void][System.Windows.MessageBox]::Show($script:SIWindow, (Get-SIFpsText 'FpsToolBad'), (Get-SIFpsText 'FpsTitle'))
        return $null
    }
}

function Get-SIGameProcess {
    <#
    .SYNOPSIS
        The running process of a game card: same exe name, the one with a window (else the biggest).
    #>
    param($Game)
    $name = [System.IO.Path]::GetFileNameWithoutExtension([string]$Game.Exe)
    if (-not $name) { return $null }
    $procs = @(Get-Process -Name $name -ErrorAction SilentlyContinue)
    if ($procs.Count -eq 0) { return $null }
    $win = @($procs | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero })
    $pick = if ($win.Count) { $win } else { $procs }
    return ($pick | Sort-Object WorkingSet64 -Descending | Select-Object -First 1)
}

function Get-SIFpsStats {
    <#
    .SYNOPSIS
        Average FPS and 1% low from a PresentMon CSV (MsBetweenPresents, swap chain with the most frames).
        1% low = 1000 / the average of the slowest 1% frame times (at least one frame).
    #>
    param([string]$CsvPath)
    if (-not [System.IO.File]::Exists($CsvPath)) { return $null }
    $rows = @(Import-Csv -LiteralPath $CsvPath)
    if ($rows.Count -lt 2) { return $null }
    $chain = ($rows | Group-Object SwapChainAddress | Sort-Object Count -Descending | Select-Object -First 1).Group
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    $ms = [System.Collections.Generic.List[double]]::new()
    foreach ($r in $chain) {
        $v = 0.0
        if ([double]::TryParse([string]$r.MsBetweenPresents, [System.Globalization.NumberStyles]::Float, $inv, [ref]$v) -and $v -gt 0) { $ms.Add($v) }
    }
    if ($ms.Count -lt 2) { return $null }
    $sum = 0.0; foreach ($v in $ms) { $sum += $v }
    $sorted = $ms.ToArray(); [array]::Sort($sorted)
    # Steadiness: the capture cut in 4 equal parts of time. The distance between the best and the worst
    # part (percent) says how much average and 1% low move inside ONE capture, with nothing changed.
    $spreadAvg = 0.0; $spreadLow = 0.0
    if ($ms.Count -ge 400) {
        $parts = @(); $cur = [System.Collections.Generic.List[double]]::new(); $acc = 0.0; $k = 1; $limit = $sum / 4.0
        foreach ($v in $ms) {
            $cur.Add($v); $acc += $v
            if ($k -lt 4 -and $acc -ge ($limit * $k)) { $parts += , $cur.ToArray(); $cur = [System.Collections.Generic.List[double]]::new(); $k++ }
        }
        if ($cur.Count) { $parts += , $cur.ToArray() }
        $qa = @(); $ql = @()
        foreach ($a in $parts) {
            if ($a.Length -lt 20) { continue }
            $t = 0.0; foreach ($v in $a) { $t += $v }
            $qa += 1000.0 * $a.Length / $t
            $c = [double[]]$a.Clone(); [array]::Sort($c)
            $m = [math]::Max(1, [int][math]::Floor($c.Length / 100))
            $w = 0.0; for ($i = $c.Length - $m; $i -lt $c.Length; $i++) { $w += $c[$i] }
            $ql += 1000.0 * $m / $w
        }
        if ($qa.Count -ge 2) {
            $sa = $qa | Measure-Object -Average -Maximum -Minimum
            $sl = $ql | Measure-Object -Average -Maximum -Minimum
            if ($sa.Average -gt 0) { $spreadAvg = [math]::Round(100.0 * ($sa.Maximum - $sa.Minimum) / $sa.Average, 1) }
            if ($sl.Average -gt 0) { $spreadLow = [math]::Round(100.0 * ($sl.Maximum - $sl.Minimum) / $sl.Average, 1) }
        }
    }
    $n1 = [math]::Max(1, [int][math]::Floor($sorted.Length / 100))
    $slow = 0.0; for ($i = $sorted.Length - $n1; $i -lt $sorted.Length; $i++) { $slow += $sorted[$i] }
    # 0.1% low only with 1000 frames or more (else it is one single frame).
    $low01 = 0.0
    $n01 = [int][math]::Floor($sorted.Length / 1000)
    if ($n01 -ge 1) {
        $slow01 = 0.0; for ($i = $sorted.Length - $n01; $i -lt $sorted.Length; $i++) { $slow01 += $sorted[$i] }
        $low01 = [math]::Round(1000.0 * $n01 / $slow01, 1)
    }
    # Stutters: frames slower than 2x the median frame time.
    $median = $sorted[[int][math]::Floor($sorted.Length / 2)]
    $stutters = 0
    for ($i = $sorted.Length - 1; $i -ge 0 -and $sorted[$i] -gt (2.0 * $median); $i--) { $stutters++ }
    return [pscustomobject]@{
        Avg      = [math]::Round(1000.0 * $ms.Count / $sum, 1)
        Low1     = [math]::Round(1000.0 * $n1 / $slow, 1)
        Low01    = $low01
        WorstMs  = [math]::Round($sorted[$sorted.Length - 1], 1)
        Stutters = $stutters
        SpreadAvg = $spreadAvg
        SpreadLow = $spreadLow
        Frames   = $ms.Count
        Sec      = [math]::Round($sum / 1000.0, 1)
    }
}

function Get-SIFpsVerdict {
    <#
    .SYNOPSIS
        The honest verdict of a before/after: 'Noise', 'Better', 'Worse' or 'Mixed'.
        A change under $script:SIFpsNoise percent (average and 1% low) is not counted as a change.
        NoiseAvg / NoiseLow: how much the two captures moved by themselves (SpreadAvg / SpreadLow);
        when that is more than $script:SIFpsNoise, the change must be bigger than that to count.
    #>
    param([double]$DeltaAvg, [double]$DeltaLow, [double]$NoiseAvg = 0, [double]$NoiseLow = 0)
    $na = [math]::Max([double]$script:SIFpsNoise, $NoiseAvg)
    $nl = [math]::Max([double]$script:SIFpsNoise, $NoiseLow)
    $up   = ($DeltaAvg -ge $na) -or ($DeltaLow -ge $nl)
    $down = ($DeltaAvg -le -$na) -or ($DeltaLow -le -$nl)
    if ($up -and $down) { return 'Mixed' }
    if ($up) { return 'Better' }
    if ($down) { return 'Worse' }
    return 'Noise'
}

function Get-SIActivePresets {
    <#
    .SYNOPSIS
        The applied SI PRESETS that touch this game: its own preset and the global ones (no Match, e.g. SI DLSS).
    #>
    param($Game)
    $applied = @((Get-SICommunityState).Applied.PSObject.Properties.Name)
    $own = Find-SIGamePreset -Game $Game
    $ids = foreach ($e in (Get-SIPresetCatalog)) {
        if ($applied -notcontains [string]$e.Id) { continue }
        if (-not $e.Match -or ($own -and $own.Id -eq $e.Id)) { [string]$e.Id }
    }
    return @($ids)
}

function Start-SIFpsMeasure {
    param($Game)
    if ($script:SIFpsRun) {
        [void][System.Windows.MessageBox]::Show($script:SIWindow, (Get-SIFpsText 'FpsBusy'), (Get-SIFpsText 'FpsTitle'))
        return
    }
    $proc = Get-SIGameProcess -Game $Game
    if (-not $proc) {
        [void][System.Windows.MessageBox]::Show($script:SIWindow,
            ((Get-SIFpsText 'FpsNotRun') -f $Game.Name, $script:SIFpsDelay, $script:SIFpsSeconds), (Get-SIFpsText 'FpsTitle'))
        return
    }
    $pm = Get-SIPresentMonPath
    if (-not $pm) { return }

    $csv = [System.IO.Path]::Combine($script:SIToolsPath, 'fps-last.csv')
    try { if ([System.IO.File]::Exists($csv)) { [System.IO.File]::Delete($csv) } } catch { }
    $argLine = "--process_id $($proc.Id) --delay $($script:SIFpsDelay) --timed $($script:SIFpsSeconds) --terminate_after_timed " +
               "--output_file `"$csv`" --no_console_stats --no_track_input --no_track_gpu " +
               "--session_name SIGAME_FPS --stop_existing_session"
    $p = Start-Process -FilePath $pm -ArgumentList $argLine -WindowStyle Hidden -PassThru
    $script:SIFpsRun = @{ Game = $Game; Process = $p; Csv = $csv; Until = [datetime]::Now.AddSeconds($script:SIFpsDelay + $script:SIFpsSeconds + 30) }
    Write-SILog -Component 'FPS' -Message "Measure started: $($Game.Name) (pid $($proc.Id))"
    Set-SIStatusText -Text ((Get-SIFpsText 'FpsStatus') -f $Game.Name)

    if (-not $script:SIFpsTimer) {
        $script:SIFpsTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:SIFpsTimer.Interval = [TimeSpan]::FromSeconds(2)
        $script:SIFpsTimer.Add_Tick({ Step-SIFpsMeasure })
    }
    $script:SIFpsTimer.Start()
    [void][System.Windows.MessageBox]::Show($script:SIWindow,
        ((Get-SIFpsText 'FpsStart') -f $Game.Name, $script:SIFpsDelay, $script:SIFpsSeconds), (Get-SIFpsText 'FpsTitle'))
}

function Step-SIFpsMeasure {
    $run = $script:SIFpsRun
    if (-not $run) { $script:SIFpsTimer.Stop(); return }
    if (-not $run.Process.HasExited) {
        if ([datetime]::Now -lt $run.Until) { return }
        try { $run.Process.Kill() } catch { }
    }
    $script:SIFpsTimer.Stop()
    $script:SIFpsRun = $null
    Complete-SIFpsMeasure -Game $run.Game -CsvPath $run.Csv
}

function Complete-SIFpsMeasure {
    param($Game, [string]$CsvPath)
    $name = [string]$Game.Name
    $st = Get-SIFpsStats -CsvPath $CsvPath
    if (-not $st) {
        Set-SIStatusText -Text ((Get-SIFpsText 'FpsNoFrames') -f $name)
        [void][System.Windows.MessageBox]::Show($script:SIWindow, ((Get-SIFpsText 'FpsNoFrames') -f $name), (Get-SIFpsText 'FpsTitle'))
        return
    }
    $presets = Get-SIActivePresets -Game $Game

    # History per game (last 10), compared with the previous measure.
    $db = Read-SIJsonFile -Path $script:SIFpsPath
    if (-not $db) { $db = [pscustomobject]@{} }
    $list = @()
    if ($db.PSObject.Properties.Name -contains $name) { $list = @($db.$name) }
    $prev = $list | Select-Object -Last 1
    $entry = [pscustomobject]@{ At = [datetime]::Now.ToString('s'); Avg = $st.Avg; Low1 = $st.Low1; Low01 = $st.Low01; WorstMs = $st.WorstMs; Stutters = $st.Stutters; SpreadAvg = $st.SpreadAvg; SpreadLow = $st.SpreadLow; Frames = $st.Frames; Sec = $st.Sec; Presets = ($presets -join ',') }
    $list = @($list + $entry | Select-Object -Last 10)
    $db | Add-Member $name $list -Force
    try { [System.IO.File]::WriteAllText($script:SIFpsPath, ($db | ConvertTo-Json -Depth 5)) } catch { }
    Write-SILog -Component 'FPS' -Message "$name avg $($st.Avg) low1 $($st.Low1) frames $($st.Frames) presets [$($entry.Presets)]"

    $msg = (Get-SIFpsText 'FpsResult') -f $name, $st.Avg, $st.Low1, $st.Frames, $st.Sec
    if ($st.Low01 -gt 0) { $msg += (Get-SIFpsText 'FpsPro') -f $st.Low01, $st.WorstMs, $st.Stutters }
    else { $msg += (Get-SIFpsText 'FpsProShort') -f $st.WorstMs, $st.Stutters }
    $info = [ordered]@{ avg = $st.Avg; low1 = $st.Low1; frames = $st.Frames; sec = $st.Sec }
    if ($prev -and $prev.Avg -gt 0 -and $prev.Low1 -gt 0) {
        $dAvg = [math]::Round(100.0 * ($st.Avg - $prev.Avg) / $prev.Avg, 1)
        $dLow = [math]::Round(100.0 * ($st.Low1 - $prev.Low1) / $prev.Low1, 1)
        $fmt = { param($d) if ($d -ge 0) { "+$d%" } else { "$d%" } }
        $msg += (Get-SIFpsText 'FpsCompare') -f ([string]$prev.At).Replace('T', ' '), $prev.Avg, $prev.Low1, (& $fmt $dAvg), (& $fmt $dLow)
        if ($prev.PSObject.Properties.Name -contains 'Stutters') { $msg += (Get-SIFpsText 'FpsStutCmp') -f $prev.Stutters, $st.Stutters }
        $nAvg = [double]$st.SpreadAvg; $nLow = [double]$st.SpreadLow
        if ($prev.PSObject.Properties.Name -contains 'SpreadAvg') {
            $nAvg = [math]::Max($nAvg, [double]$prev.SpreadAvg); $nLow = [math]::Max($nLow, [double]$prev.SpreadLow)
        }
        $verdict = Get-SIFpsVerdict -DeltaAvg $dAvg -DeltaLow $dLow -NoiseAvg $nAvg -NoiseLow $nLow
        $unsteady = ($nAvg -gt $script:SIFpsNoise) -or ($nLow -gt $script:SIFpsNoise)
        if ($verdict -eq 'Noise' -and $unsteady) { $msg += (Get-SIFpsText 'FpsVUnsteady') -f $nAvg, $nLow }
        elseif ($verdict -eq 'Noise') { $msg += (Get-SIFpsText 'FpsVNoise') -f $script:SIFpsNoise }
        else { $msg += (Get-SIFpsText ('FpsV' + $verdict)) }
        Write-SILog -Component 'FPS' -Message "$name verdict $verdict (avg $dAvg%, 1% low $dLow%, unsteady avg $nAvg% low $nLow%)"
        $info['prev_avg'] = $prev.Avg; $info['prev_low1'] = $prev.Low1; $info['prev_presets'] = [string]$prev.Presets
    }
    if ($list.Count -ge 3) {
        $best = $list | Sort-Object { [double]$_.Avg } -Descending | Select-Object -First 1
        $bestSet = if ([string]$best.Presets) { (Get-SIFpsText 'FpsBestSet') -f ([string]$best.Presets).Replace(',', ', ') } else { '' }
        $msg += (Get-SIFpsText 'FpsBest') -f $list.Count, $best.Avg, $best.Low1, ([string]$best.At).Replace('T', ' '), $bestSet
    }
    if ($presets.Count) { $msg += (Get-SIFpsText 'FpsPresets') -f ($presets -join ', ') }
    if ((Get-SICommunityState).Telemetry -eq $true) { $msg += (Get-SIFpsText 'FpsShared') }

    $exe = [System.IO.Path]::GetFileName([string]$Game.Exe)
    Send-SITelemetry -Event (New-SITelemetryEvent -Kind 'fps_measured' -Game $name -Store ([string]$Game.Store) -ExeName $exe `
        -Preset ($presets -join ',') -Message ($info | ConvertTo-Json -Compress))
    Set-SIStatusText -Text ("FPS {0}: {1} avg, {2} 1% low" -f $name, $st.Avg, $st.Low1)
    [void][System.Windows.MessageBox]::Show($script:SIWindow, $msg, (Get-SIFpsText 'FpsTitle'))
}
