# ---------------------------------------------------------------------------
#  SIGAME - module 00: the core
#
#  The texts of the window, the state that everything shares and the small
#  helpers (the cache, the brush, the pump of the window, the language).
#
#  This file is loaded by SI-GAME.ps1 (the loader) with a dot-source, right
#  after the loading window is on the screen. It is the FIRST module, so the
#  log, the administrator rights and the helpers of the dates are here: the
#  loader must not do anything else before the loading window is on the
#  screen.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
#  1a. THE FILES, THE LOG AND THE RIGHTS
#
#  These three things are here and not in the loader, because the loader
#  must open the loading window as the very first thing it does.
# ---------------------------------------------------------------------------

#The files that SIGAME writes. They all go next to the script, as the header
# of the loader promises.
$script:SILogPath      = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME.log')
$script:SIBackupPath   = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-backup.json')
$script:SIMeasuresPath = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-measures.json')
$script:SIBoostPath    = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-boost.json')
$script:SISharePath    = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-result.png')
$script:SIIconPath     = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME.ico')
$script:SIDesktopFlag  = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-desktop.flag')

# $true when the folder of the log was already looked at.
$script:SILogFolderChecked = $false

function Write-SILog {
    <#
    .SYNOPSIS
        Appends one timestamped line to the log file next to the script and to
        the log window.

    .PARAMETER Raw
        The line is already finished. It is then written as it is, without the
        timestamp and without the level. The background copy of SIGAME uses
        this to hand its own lines over to the window.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')][string]$Level = 'INFO',
        [string]$Component = 'SIGAME',
        [switch]$Raw
    )

    if ($Raw) {
        $line = $Message
    } else {
        $line = '[{0:yyyy-MM-dd HH:mm:ss.fff}] [{1}] [{2}] {3}' -f [datetime]::Now, $Level, $Component, $Message
    }

    # In the background copy the lines are collected and given to the window,
    # so that only one process writes to the log file.
    if ($null -ne $script:SILogCapture) {
        [void]$script:SILogCapture.Add($line)
        return
    }

    try {
        # The folder is looked at only once: every line of the log would
        # otherwise pay for a file system check.
        if (-not $script:SILogFolderChecked) {
            $folder = [System.IO.Path]::GetDirectoryName($script:SILogPath)
            if ($folder -and -not [System.IO.Directory]::Exists($folder)) {
                [void][System.IO.Directory]::CreateDirectory($folder)
            }
            $script:SILogFolderChecked = $true
        }
        [System.IO.File]::AppendAllText($script:SILogPath, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
    } catch {
        [System.Console]::WriteLine($line)
    }

    if ($script:SILogBox) {
        try {
            $script:SILogBox.AppendText($line + [Environment]::NewLine)
            $script:SILogBox.ScrollToEnd()
        } catch { }
    }
}

function Test-SIAdmin {
    <#
    .SYNOPSIS
        True when SIGAME already runs with administrator rights.
    #>
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-SIElevate {
    <#
    .SYNOPSIS
        Starts SIGAME again with administrator rights through UAC.

    .DESCRIPTION
        $true when the copy with administrator rights was started, $false when
        it was not. The caller opens the window without rights in that case,
        so that a window that never appears is not the answer.

        The copy that is started is the LOADER (SI-GAME.ps1) and never a
        module of the modules folder.
    #>
    $path = $script:SICurrentScript
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $PSCommandPath }
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $MyInvocation.MyCommand.Path }
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Host 'SIGAME could not find its own file, so it cannot ask for administrator rights.'
        return $false
    }

    $exe = Join-Path $PSHOME 'powershell.exe'
    # The copy with the rights is started the NORMAL way, with -File and the
    # path of the loader.
    #
    # The old version loaded the WPF assemblies in a thread of the new
    # process, to save a fraction of a second. That thread had NO try/catch
    # around the load: an unhandled exception in a thread ends the whole
    # process in .NET, so a single failure there killed the copy with the
    # rights before its window was on the screen. The log of the owner says
    # that the assemblies take only 0,22 s to 0,32 s, so the thread brought
    # nothing and the risk was not worth it.
    #
    # The console of the new copy is hidden: the user must see the window of
    # SIGAME and nothing else. The window of the copy itself is opened by
    # the loader, so nothing is lost.
    #
    # The command line is built inside a try: a failure here must never stop
    # the script, otherwise the window of SIGAME would never appear.
    # The path is in double quotes: a double quote is not allowed in the name
    # of a folder or of a file on Windows, so this is always safe.
    try {
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-WindowStyle', 'Hidden', '-File', ('"{0}"' -f $path))
        Start-Process -FilePath $exe -Verb RunAs -ArgumentList $arguments -WindowStyle Hidden -ErrorAction Stop | Out-Null
        return $true
    } catch {
        # The request was cancelled or Windows did not allow it. The reason
        # goes to the log and the window opens without rights.
        Write-SILog -Level 'WARN' -Component 'Start' -Message ('The request for administrator rights did not work: ' + [string]$_.Exception.Message)
        return $false
    }
}


# ---------------------------------------------------------------------------
#  1b. THE TEXTS OF THE WINDOW
#
#  Every text the user reads is in this table, one block per language, so a
#  new language is only a new block. The language of Windows decides which
#  block is used; a language that is not in the table gets the English one.
# ---------------------------------------------------------------------------

$script:SIText = @{}

$script:SIText['en'] = @{
    Subtitle         = 'Gaming tweaks for Windows 10 and Windows 11'
    BtnOptimize      = 'OPTIMIZE'
    BtnBoost         = 'GAME BOOST'
    BtnGameOver      = 'GAME OVER'
    BtnUndoAll       = 'UNDO ALL'
    BtnMeasure       = 'Measure'
    BtnSaveCard      = 'Save my result'
    BtnRefresh       = 'Refresh states'
    BtnRestorePoint  = 'Restore point'
    BtnOpenLog       = 'Open log folder'
    BtnGaming        = 'GAMING preset'
    BtnApplyChecked  = 'Apply checked'
    BtnPickGame      = 'Add a game'
    Advanced         = 'Advanced'
    ProveIt          = 'PROVE IT'
    LabelFreeRam     = 'Free RAM'
    LabelStartupApps = 'Startup apps on'
    LabelDns         = 'DNS answer'
    LabelSpeed       = 'Download speed'
    OptimizeHint     = 'One click: every safe tweak for this computer.'
    StatusReady      = 'Ready. Tick a tweak and press Apply, or use the GAMING preset.'
    StatusStarting   = 'SIGAME is starting ...'
    StatusWorking    = 'SIGAME is still starting up, please wait a moment.'
    StatusPreparing  = 'Creating the System Restore point and the JSON backup, reading the real state of every tweak ...'
    StatusMeasuring  = 'Measuring ...'
    StatusDone       = 'DONE'
    StatusProgress   = '{0} of {1}'
    TrustFooter      = 'Open source. Every change can be undone. Restore point created: {0}'
    FooterBase       = 'Based on Chris Titus WinUtil (MIT). Log: {0}'
    SectionBoost     = 'BOOST LIST'
    SectionGames     = 'YOUR GAMES'
    SectionMachine   = 'YOUR MACHINE'
    SectionNetwork   = 'NETWORK & DOWNLOADS'
    SectionPerGame   = 'PER GAME'
    SectionStartup   = 'STARTUP APPS'
    SectionTemp      = 'TEMPORARY FILES'
    BoostHint        = 'Tick the programs that should be closed while you play. Nothing is ticked by default.'
    BoostNothing     = 'No common background program is running right now.'
    BoostNoApps      = 'No program is ticked, so nothing will be closed.'
    BoostPickFirst   = 'Nothing is ticked: tick the programs you want to close in the BOOST LIST and press GAME BOOST again.'
    BoostPickLabel   = 'Tick the programs in the BOOST LIST.'
    GameNothing      = 'No Steam or Epic game was found on this computer.'
    GameGpu          = 'GPU high performance'
    GameFullscreen   = 'Fullscreen optimizations off'
    GameSteam        = 'Steam'
    GameEpic         = 'Epic Games'
    LimitRam         = '{0} GB of RAM'
    LimitHdd         = 'a hard disk (HDD) as system disk'
    LimitDisk        = 'less than 15% free space on the system disk'
    LimitGpu         = 'the integrated graphics card'
    LimitNone        = 'nothing big: {0}'
    BoostDiscord     = 'The Discord overlay is never closed.'
    BoostPlan        = 'Power plan: {0}'
    BoostResult      = '+{0} MB RAM free'
    BottleneckLine   = 'Your biggest limit: {0}'
    BottleneckOk     = 'Your biggest limit: none. This machine looks fine.'
    BottleneckDetails = 'CPU {0} - GPU {1} - RAM {2} - Disk {3}'
    TrustFooterWaiting = 'Open source. Every change can be undone. Restore point: waiting ...'
    CardTitle        = 'SIGAME - my result'
    CardMade         = 'made with SIGAME - YouTube @SINEWS-q5x'
    CardBefore       = 'BEFORE'
    CardAfter        = 'AFTER'
    CardNoMeasure    = 'no measurement yet'
    GameOverDone     = 'The power plan and the closed programs are back.'
    CardSaved        = 'The share card was saved: {0}'
    BoostDone        = 'GAME BOOST is on.'
    AutoBoost        = 'AUTO-BOOST'
}

$script:SIText['pt-BR'] = @{
    Subtitle         = 'Ajustes de jogos para Windows 10 e Windows 11'
    BtnOptimize      = 'OTIMIZAR'
    BtnBoost         = 'BOOST DE JOGO'
    BtnGameOver      = 'FIM DE JOGO'
    BtnUndoAll       = 'DESFAZER TUDO'
    BtnMeasure       = 'Medir'
    BtnSaveCard      = 'Salvar meu resultado'
    BtnRefresh       = 'Atualizar estados'
    BtnRestorePoint  = 'Ponto de restauracao'
    BtnOpenLog       = 'Abrir a pasta do log'
    BtnGaming        = 'Predefinicao JOGOS'
    BtnApplyChecked  = 'Aplicar os marcados'
    BtnPickGame      = 'Adicionar um jogo'
    Advanced         = 'Avancado'
    ProveIt          = 'PROVE'
    LabelFreeRam     = 'Memoria livre'
    LabelStartupApps = 'Programas na inicializacao'
    LabelDns         = 'Resposta do DNS'
    LabelSpeed       = 'Velocidade de download'
    OptimizeHint     = 'Um clique: todos os ajustes seguros deste computador.'
    StatusReady      = 'Pronto. Marque um ajuste e pressione Aplicar, ou use a predefinicao JOGOS.'
    StatusStarting   = 'O SIGAME esta iniciando ...'
    StatusWorking    = 'O SIGAME ainda esta iniciando, aguarde um momento.'
    StatusPreparing  = 'Criando o ponto de restauracao e o backup JSON, lendo o estado real de cada ajuste ...'
    StatusMeasuring  = 'Medindo ...'
    StatusDone       = 'PRONTO'
    StatusProgress   = '{0} de {1}'
    TrustFooter      = 'Codigo aberto. Toda mudanca pode ser desfeita. Ponto de restauracao criado: {0}'
    FooterBase       = 'Baseado no Chris Titus WinUtil (MIT). Log: {0}'
    SectionBoost     = 'LISTA DE BOOST'
    SectionGames     = 'SEUS JOGOS'
    SectionMachine   = 'SEU COMPUTADOR'
    SectionNetwork   = 'REDE E DOWNLOADS'
    SectionPerGame   = 'POR JOGO'
    SectionStartup   = 'PROGRAMAS NA INICIALIZACAO'
    SectionTemp      = 'ARQUIVOS TEMPORARIOS'
    BoostHint        = 'Marque os programas que devem ser fechados enquanto voce joga. Nada vem marcado por padrao.'
    BoostNothing     = 'Nenhum programa comum esta rodando agora.'
    BoostNoApps      = 'Nenhum programa esta marcado, entao nada sera fechado.'
    BoostPickFirst   = 'Nada esta marcado: marque os programas que quer fechar na LISTA DE BOOST e aperte BOOST DE JOGO de novo.'
    BoostPickLabel   = 'Marque os programas na LISTA DE BOOST.'
    GameNothing      = 'Nenhum jogo da Steam ou da Epic foi encontrado neste computador.'
    GameGpu          = 'GPU de alto desempenho'
    GameFullscreen   = 'Otimizacoes de tela cheia desligadas'
    GameSteam        = 'Steam'
    GameEpic         = 'Epic Games'
    LimitRam         = '{0} GB de RAM'
    LimitHdd         = 'um disco rigido (HDD) como disco do sistema'
    LimitDisk        = 'menos de 15% de espaco livre no disco do sistema'
    LimitGpu         = 'a placa de video integrada'
    LimitNone        = 'nada grande: {0}'
    BoostDiscord     = 'A sobreposicao do Discord nunca e fechada.'
    BoostPlan        = 'Plano de energia: {0}'
    BoostResult      = '+{0} MB de RAM livre'
    BottleneckLine   = 'Seu maior limite: {0}'
    BottleneckOk     = 'Seu maior limite: nenhum. Esta maquina parece boa.'
    BottleneckDetails = 'CPU {0} - GPU {1} - RAM {2} - Disco {3}'
    TrustFooterWaiting = 'Codigo aberto. Toda mudanca pode ser desfeita. Ponto de restauracao: aguardando ...'
    CardTitle        = 'SIGAME - meu resultado'
    CardMade         = 'feito com SIGAME - YouTube @SINEWS-q5x'
    CardBefore       = 'ANTES'
    CardAfter        = 'DEPOIS'
    CardNoMeasure    = 'sem medicao ainda'
    GameOverDone     = 'O plano de energia e os programas fechados voltaram.'
    CardSaved        = 'O cartao de resultado foi salvo: {0}'
    BoostDone        = 'O BOOST DE JOGO esta ligado.'
    AutoBoost        = 'AUTO-BOOST'
}

$script:SIText['es'] = @{
    Subtitle         = 'Ajustes de juegos para Windows 10 y Windows 11'
    BtnOptimize      = 'OPTIMIZAR'
    BtnBoost         = 'BOOST DE JUEGO'
    BtnGameOver      = 'FIN DE JUEGO'
    BtnUndoAll       = 'DESHACER TODO'
    BtnMeasure       = 'Medir'
    BtnSaveCard      = 'Guardar mi resultado'
    BtnRefresh       = 'Actualizar estados'
    BtnRestorePoint  = 'Punto de restauracion'
    BtnOpenLog       = 'Abrir la carpeta del registro'
    BtnGaming        = 'Preajuste de JUEGOS'
    BtnApplyChecked  = 'Aplicar los marcados'
    BtnPickGame      = 'Agregar un juego'
    Advanced         = 'Avanzado'
    ProveIt          = 'PRUEBA'
    LabelFreeRam     = 'Memoria libre'
    LabelStartupApps = 'Programas de inicio'
    LabelDns         = 'Respuesta del DNS'
    LabelSpeed       = 'Velocidad de descarga'
    OptimizeHint     = 'Un clic: todos los ajustes seguros de este equipo.'
    StatusReady      = 'Listo. Marca un ajuste y pulsa Aplicar, o usa el preajuste de JUEGOS.'
    StatusStarting   = 'SIGAME se esta iniciando ...'
    StatusWorking    = 'SIGAME todavia se esta iniciando, espera un momento.'
    StatusPreparing  = 'Creando el punto de restauracion y la copia JSON, leyendo el estado real de cada ajuste ...'
    StatusMeasuring  = 'Midiendo ...'
    StatusDone       = 'LISTO'
    StatusProgress   = '{0} de {1}'
    TrustFooter      = 'Codigo abierto. Todo cambio se puede deshacer. Punto de restauracion creado: {0}'
    FooterBase       = 'Basado en Chris Titus WinUtil (MIT). Registro: {0}'
    SectionBoost     = 'LISTA DE BOOST'
    SectionGames     = 'TUS JUEGOS'
    SectionMachine   = 'TU EQUIPO'
    SectionNetwork   = 'RED Y DESCARGAS'
    SectionPerGame   = 'POR JUEGO'
    SectionStartup   = 'PROGRAMAS DE INICIO'
    SectionTemp      = 'ARCHIVOS TEMPORALES'
    BoostHint        = 'Marca los programas que se deben cerrar mientras juegas. Por defecto no viene marcado ninguno.'
    BoostNothing     = 'Ahora mismo no se esta ejecutando ningun programa comun.'
    BoostNoApps      = 'No hay ningun programa marcado, asi que no se cerrara nada.'
    BoostPickFirst   = 'No hay nada marcado: marca los programas que quieres cerrar en la LISTA DE BOOST y pulsa BOOST DE JUEGO otra vez.'
    BoostPickLabel   = 'Marca los programas en la LISTA DE BOOST.'
    GameNothing      = 'No se ha encontrado ningun juego de Steam o Epic en este equipo.'
    GameGpu          = 'GPU de alto rendimiento'
    GameFullscreen   = 'Optimizaciones de pantalla completa desactivadas'
    GameSteam        = 'Steam'
    GameEpic         = 'Epic Games'
    LimitRam         = '{0} GB de RAM'
    LimitHdd         = 'un disco duro (HDD) como disco del sistema'
    LimitDisk        = 'menos del 15% de espacio libre en el disco del sistema'
    LimitGpu         = 'la tarjeta grafica integrada'
    LimitNone        = 'nada grande: {0}'
    BoostDiscord     = 'La superposicion de Discord nunca se cierra.'
    BoostPlan        = 'Plan de energia: {0}'
    BoostResult      = '+{0} MB de RAM libre'
    BottleneckLine   = 'Tu mayor limite: {0}'
    BottleneckOk     = 'Tu mayor limite: ninguno. Este equipo parece bien.'
    BottleneckDetails = 'CPU {0} - GPU {1} - RAM {2} - Disco {3}'
    TrustFooterWaiting = 'Codigo abierto. Todo cambio se puede deshacer. Punto de restauracion: esperando ...'
    CardTitle        = 'SIGAME - mi resultado'
    CardMade         = 'hecho con SIGAME - YouTube @SINEWS-q5x'
    CardBefore       = 'ANTES'
    CardAfter        = 'DESPUES'
    CardNoMeasure    = 'sin medicion todavia'
    GameOverDone     = 'El plan de energia y los programas cerrados han vuelto.'
    CardSaved        = 'La tarjeta de resultado se ha guardado: {0}'
    BoostDone        = 'El BOOST DE JUEGO esta activado.'
    AutoBoost        = 'AUTO-BOOST'
}

$script:SIText['it'] = @{
    Subtitle         = 'Ottimizzazioni gaming per Windows 10 e Windows 11'
    BtnOptimize      = 'OTTIMIZZA'
    BtnBoost         = 'BOOST GIOCO'
    BtnGameOver      = 'FINE GIOCO'
    BtnUndoAll       = 'ANNULLA TUTTO'
    BtnMeasure       = 'Misura'
    BtnSaveCard      = 'Salva il mio risultato'
    BtnRefresh       = 'Aggiorna gli stati'
    BtnRestorePoint  = 'Punto di ripristino'
    BtnOpenLog       = 'Apri la cartella del log'
    BtnGaming        = 'Preset GIOCHI'
    BtnApplyChecked  = 'Applica i selezionati'
    BtnPickGame      = 'Aggiungi un gioco'
    Advanced         = 'Avanzate'
    ProveIt          = 'PROVA'
    LabelFreeRam     = 'Memoria libera'
    LabelStartupApps = 'Programmi all''avvio'
    LabelDns         = 'Risposta del DNS'
    LabelSpeed       = 'Velocita di download'
    OptimizeHint     = 'Un clic: tutte le ottimizzazioni sicure di questo computer.'
    StatusReady      = 'Pronto. Spunta un''ottimizzazione e premi Applica, oppure usa il preset GIOCHI.'
    StatusStarting   = 'SIGAME si sta avviando ...'
    StatusWorking    = 'SIGAME si sta ancora avviando, aspetta un momento.'
    StatusPreparing  = 'Creazione del punto di ripristino e del backup JSON, lettura dello stato reale di ogni ottimizzazione ...'
    StatusMeasuring  = 'Misurazione ...'
    StatusDone       = 'PRONTO'
    StatusProgress   = '{0} di {1}'
    TrustFooter      = 'Codice aperto. Ogni modifica puo essere annullata. Punto di ripristino creato: {0}'
    FooterBase       = 'Basato su Chris Titus WinUtil (MIT). Log: {0}'
    SectionBoost     = 'ELENCO BOOST'
    SectionGames     = 'I TUOI GIOCHI'
    SectionMachine   = 'IL TUO COMPUTER'
    SectionNetwork   = 'RETE E DOWNLOAD'
    SectionPerGame   = 'PER GIOCO'
    SectionStartup   = 'PROGRAMMI ALL''AVVIO'
    SectionTemp      = 'FILE TEMPORANEI'
    BoostHint        = 'Spunta i programmi da chiudere mentre giochi. Per default non e spuntato nessuno.'
    BoostNothing     = 'Adesso non sta girando nessun programma comune.'
    BoostNoApps      = 'Non e spuntato nessun programma, quindi non verra chiuso niente.'
    BoostPickFirst   = 'Nessuno e spuntato: spunta i programmi che vuoi chiudere nell ELENCO BOOST e premi BOOST GIOCO di nuovo.'
    BoostPickLabel   = 'Spunta i programmi nell ELENCO BOOST.'
    GameNothing      = 'Su questo computer non e stato trovato nessun gioco di Steam o Epic.'
    GameGpu          = 'GPU ad alte prestazioni'
    GameFullscreen   = 'Ottimizzazioni a schermo intero disattivate'
    GameSteam        = 'Steam'
    GameEpic         = 'Epic Games'
    LimitRam         = '{0} GB di RAM'
    LimitHdd         = 'un hard disk (HDD) come disco di sistema'
    LimitDisk        = 'meno del 15% di spazio libero sul disco di sistema'
    LimitGpu         = 'la scheda grafica integrata'
    LimitNone        = 'niente di grosso: {0}'
    BoostDiscord     = 'L''overlay di Discord non viene mai chiuso.'
    BoostPlan        = 'Piano di alimentazione: {0}'
    BoostResult      = '+{0} MB di RAM libera'
    BottleneckLine   = 'Il tuo limite maggiore: {0}'
    BottleneckOk     = 'Il tuo limite maggiore: nessuno. Questo computer sembra a posto.'
    BottleneckDetails = 'CPU {0} - GPU {1} - RAM {2} - Disco {3}'
    TrustFooterWaiting = 'Codice aperto. Ogni modifica puo essere annullata. Punto di ripristino: in attesa ...'
    CardTitle        = 'SIGAME - il mio risultato'
    CardMade         = 'fatto con SIGAME - YouTube @SINEWS-q5x'
    CardBefore       = 'PRIMA'
    CardAfter        = 'DOPO'
    CardNoMeasure    = 'nessuna misura ancora'
    GameOverDone     = 'Il piano di alimentazione e i programmi chiusi sono tornati.'
    CardSaved        = 'La scheda del risultato e stata salvata: {0}'
    BoostDone        = 'Il BOOST GIOCO e attivo.'
    AutoBoost        = 'AUTO-BOOST'
}

$script:SIText['de'] = @{
    Subtitle         = 'Gaming-Optimierungen fuer Windows 10 und Windows 11'
    BtnOptimize      = 'OPTIMIEREN'
    BtnBoost         = 'GAME BOOST'
    BtnGameOver      = 'GAME OVER'
    BtnUndoAll       = 'ALLES RUECKGANGIG'
    BtnMeasure       = 'Messen'
    BtnSaveCard      = 'Mein Ergebnis speichern'
    BtnRefresh       = 'Zustaende aktualisieren'
    BtnRestorePoint  = 'Wiederherstellungspunkt'
    BtnOpenLog       = 'Log-Ordner oeffnen'
    BtnGaming        = 'GAMING-Voreinstellung'
    BtnApplyChecked  = 'Markierte anwenden'
    BtnPickGame      = 'Ein Spiel hinzufuegen'
    Advanced         = 'Erweitert'
    ProveIt          = 'BEWEIS'
    LabelFreeRam     = 'Freier Arbeitsspeicher'
    LabelStartupApps = 'Autostart-Programme'
    LabelDns         = 'DNS-Antwortzeit'
    LabelSpeed       = 'Download-Geschwindigkeit'
    OptimizeHint     = 'Ein Klick: alle sicheren Optimierungen fuer diesen Rechner.'
    StatusReady      = 'Bereit. Haken Sie eine Optimierung an und druecken Sie Anwenden, oder nutzen Sie die GAMING-Voreinstellung.'
    StatusStarting   = 'SIGAME startet ...'
    StatusWorking    = 'SIGAME startet noch, bitte einen Moment warten.'
    StatusPreparing  = 'Wiederherstellungspunkt und JSON-Sicherung werden erstellt, der echte Zustand jeder Optimierung wird gelesen ...'
    StatusMeasuring  = 'Messen ...'
    StatusDone       = 'FERTIG'
    StatusProgress   = '{0} von {1}'
    TrustFooter      = 'Quelloffen. Jede Aenderung laesst sich rueckgaengig machen. Wiederherstellungspunkt erstellt: {0}'
    FooterBase       = 'Basierend auf Chris Titus WinUtil (MIT). Log: {0}'
    SectionBoost     = 'BOOST-LISTE'
    SectionGames     = 'DEINE SPIELE'
    SectionMachine   = 'DEIN RECHNER'
    SectionNetwork   = 'NETZWERK & DOWNLOADS'
    SectionPerGame   = 'PRO SPIEL'
    SectionStartup   = 'AUTOSTART-PROGRAMME'
    SectionTemp      = 'TEMPORAERE DATEIEN'
    BoostHint        = 'Haken Sie die Programme an, die waehrend des Spiels geschlossen werden sollen. Standardmaessig ist nichts angehakt.'
    BoostNothing     = 'Gerade laeuft kein uebliches Hintergrundprogramm.'
    BoostNoApps      = 'Es ist kein Programm angehakt, es wird also nichts geschlossen.'
    BoostPickFirst   = 'Nichts ist angehakt: haken Sie die Programme an, die geschlossen werden sollen, in der BOOST-LISTE und druecken Sie GAME BOOST noch einmal.'
    BoostPickLabel   = 'Haken Sie die Programme in der BOOST-LISTE an.'
    GameNothing      = 'Auf diesem Rechner wurde kein Steam- oder Epic-Spiel gefunden.'
    GameGpu          = 'GPU mit hoher Leistung'
    GameFullscreen   = 'Vollbild-Optimierungen deaktivieren'
    GameSteam        = 'Steam'
    GameEpic         = 'Epic Games'
    LimitRam         = '{0} GB RAM'
    LimitHdd         = 'eine Festplatte (HDD) als Systemlaufwerk'
    LimitDisk        = 'weniger als 15% freier Speicher auf dem Systemlaufwerk'
    LimitGpu         = 'die integrierte Grafikkarte'
    LimitNone        = 'nichts Grosses: {0}'
    BoostDiscord     = 'Das Discord-Overlay wird nie geschlossen.'
    BoostPlan        = 'Energiesparplan: {0}'
    BoostResult      = '+{0} MB RAM frei'
    BottleneckLine   = 'Dein groesstes Limit: {0}'
    BottleneckOk     = 'Dein groesstes Limit: keines. Dieser Rechner sieht gut aus.'
    BottleneckDetails = 'CPU {0} - GPU {1} - RAM {2} - Festplatte {3}'
    TrustFooterWaiting = 'Quelloffen. Jede Aenderung laesst sich rueckgaengig machen. Wiederherstellungspunkt: wartet ...'
    CardTitle        = 'SIGAME - mein Ergebnis'
    CardMade         = 'gemacht mit SIGAME - YouTube @SINEWS-q5x'
    CardBefore       = 'VORHER'
    CardAfter        = 'NACHHER'
    CardNoMeasure    = 'noch keine Messung'
    GameOverDone     = 'Der Energiesparplan und die geschlossenen Programme sind zurueck.'
    CardSaved        = 'Die Ergebniskarte wurde gespeichert: {0}'
    BoostDone        = 'GAME BOOST ist an.'
    AutoBoost        = 'AUTO-BOOST'
}

$script:SIText['fr'] = @{
    Subtitle         = 'Optimisations pour les jeux sur Windows 10 et Windows 11'
    BtnOptimize      = 'OPTIMISER'
    BtnBoost         = 'BOOST DE JEU'
    BtnGameOver      = 'FIN DE JEU'
    BtnUndoAll       = 'TOUT ANNULER'
    BtnMeasure       = 'Mesurer'
    BtnSaveCard      = 'Enregistrer mon resultat'
    BtnRefresh       = 'Actualiser les etats'
    BtnRestorePoint  = 'Point de restauration'
    BtnOpenLog       = 'Ouvrir le dossier du journal'
    BtnGaming        = 'Prereglage JEUX'
    BtnApplyChecked  = 'Appliquer la selection'
    BtnPickGame      = 'Ajouter un jeu'
    Advanced         = 'Avance'
    ProveIt          = 'PREUVE'
    LabelFreeRam     = 'Memoire libre'
    LabelStartupApps = 'Programmes de demarrage'
    LabelDns         = 'Reponse du DNS'
    LabelSpeed       = 'Vitesse de telechargement'
    OptimizeHint     = 'Un clic : toutes les optimisations sures de cet ordinateur.'
    StatusReady      = 'Pret. Cochez une optimisation et appuyez sur Appliquer, ou utilisez le prereglage JEUX.'
    StatusStarting   = 'SIGAME demarre ...'
    StatusWorking    = 'SIGAME demarre encore, attendez un instant.'
    StatusPreparing  = 'Creation du point de restauration et de la sauvegarde JSON, lecture de l''etat reel de chaque optimisation ...'
    StatusMeasuring  = 'Mesure ...'
    StatusDone       = 'TERMINE'
    StatusProgress   = '{0} sur {1}'
    TrustFooter      = 'Open source. Chaque changement peut etre annule. Point de restauration cree : {0}'
    FooterBase       = 'Base sur Chris Titus WinUtil (MIT). Journal : {0}'
    SectionBoost     = 'LISTE DE BOOST'
    SectionGames     = 'VOS JEUX'
    SectionMachine   = 'VOTRE ORDINATEUR'
    SectionNetwork   = 'RESEAU ET TELECHARGEMENTS'
    SectionPerGame   = 'PAR JEU'
    SectionStartup   = 'PROGRAMMES DE DEMARRAGE'
    SectionTemp      = 'FICHIERS TEMPORAIRES'
    BoostHint        = 'Cochez les programmes a fermer pendant que vous jouez. Par defaut, rien n''est coche.'
    BoostNothing     = 'Aucun programme courant ne tourne en ce moment.'
    BoostNoApps      = 'Aucun programme n''est coche, donc rien ne sera ferme.'
    BoostPickFirst   = 'Rien n''est coche : cochez les programmes a fermer dans la LISTE DE BOOST et appuyez encore sur BOOST DE JEU.'
    BoostPickLabel   = 'Cochez les programmes dans la LISTE DE BOOST.'
    GameNothing      = 'Aucun jeu Steam ou Epic n''a ete trouve sur cet ordinateur.'
    GameGpu          = 'GPU haute performance'
    GameFullscreen   = 'Optimisations plein ecran desactivees'
    GameSteam        = 'Steam'
    GameEpic         = 'Epic Games'
    LimitRam         = '{0} Go de RAM'
    LimitHdd         = 'un disque dur (HDD) comme disque systeme'
    LimitDisk        = 'moins de 15% d''espace libre sur le disque systeme'
    LimitGpu         = 'la carte graphique integree'
    LimitNone        = 'rien de grave : {0}'
    BoostDiscord     = 'L''overlay de Discord n''est jamais ferme.'
    BoostPlan        = 'Plan d''alimentation : {0}'
    BoostResult      = '+{0} Mo de RAM libre'
    BottleneckLine   = 'Votre plus grande limite : {0}'
    BottleneckOk     = 'Votre plus grande limite : aucune. Cet ordinateur a l''air correct.'
    BottleneckDetails = 'CPU {0} - GPU {1} - RAM {2} - Disque {3}'
    TrustFooterWaiting = 'Open source. Chaque changement peut etre annule. Point de restauration : en attente ...'
    CardTitle        = 'SIGAME - mon resultat'
    CardMade         = 'fait avec SIGAME - YouTube @SINEWS-q5x'
    CardBefore       = 'AVANT'
    CardAfter        = 'APRES'
    CardNoMeasure    = 'aucune mesure pour l''instant'
    GameOverDone     = 'Le plan d''alimentation et les programmes fermes sont revenus.'
    CardSaved        = 'La carte de resultat a ete enregistree : {0}'
    BoostDone        = 'Le BOOST DE JEU est active.'
    AutoBoost        = 'AUTO-BOOST'
}
# In-memory state shared between the UI thread and the helpers.
$script:SITweaks    = @{}   # Id -> tweak definition
$script:SIRows      = @{}   # Id -> UI controls of that row
$script:SIBackup    = $null  # hashtable, the JSON backup in memory
$script:SILogBox    = $null  # TextBlock / TextBox showing the log
$script:SIStatus    = $null  # TextBlock showing the last message
$script:SIWindow    = $null  # the WPF window
$script:SIUserPrefix = 'HKCU:'   # 'HKU:\<sid>' when the console user is not us
$script:SIUserSid   = $null
$script:SIRestorePointMade = $false
$script:SIRestorePointStatus = 'pending'   # pending | creating | created | recent | failed
$script:SIPrepared  = $false  # $true when the slow start-up work is done
$script:SIUpdatingStates = $false
$script:SISlowStartDone = $false
$script:SICache     = @{}   # slow readings (optional feature, AppX, power plans)
$script:SIBrushes   = @{}   # colour -> frozen brush, made once and kept
$script:SIWorkerStates = @{}  # Id -> the state the background copy has read
$script:SIWorkerFinished = $false  # $true when the background copy said 'done'
$script:SIIsLaptop  = $null  # $true/$false when the background copy knows it
$script:SIWindowOnScreen = $null  # how long the window needed (a TimeSpan)

# Round 5 state.
$script:SIAdvancedBuilt = $false  # $true when the Advanced section has been filled
$script:SIAdvancedTimer = $null   # the safety net that builds the section when it is open
$script:SILastApplyStatus = ''    # applied | notavailable | failed | skipped
$script:SILastDnsMs      = -1     # the last DNS answer time in ms (-1 = not measured)
$script:SILastSpeedMbps  = -1     # the last speed test in Mbps (-1 = not measured)
$script:SILastSpeedAt    = ''
$script:SIDnsResults     = @()    # the rows of the DNS benchmark
$script:SISelectedDns    = ''     # the DNS server the user chose
$script:SISelectedGame   = ''     # the full path of the .exe the user chose
$script:SIMeasuresBefore = $null  # the PROVE IT numbers of before
$script:SIMeasuresAfter  = $null  # the PROVE IT numbers of after
$script:SIOptionOverride = @{}   # the option the OPTIMIZE button uses
$script:SITempBytes      = 0      # how much the temporary files take

# Round 6 state.
$script:SIProgress     = $null   # the progress bar of the window
$script:SIProgressText = $null   # the name of the step that is running now
$script:SILanguage     = ''      # the language of the window, read from Windows
$script:SIBoostState   = $null   # the boost list and the last boost (JSON)
$script:SIBoostApps    = @()     # the background programs that are running now
$script:SIGameLibrary  = @()     # the Steam and Epic games of this computer
$script:SIBottleneck   = $null   # the honest limit of this computer
$script:SIShareSaved   = $false  # $true when the share card is on the disk
$script:SIBoostRunning = $false  # $true while GAME BOOST is working
$script:SIRestorePointAt = ''    # when the restore point was made
$script:SIBoostTicks   = @()    # the boost list the user has ticked
$script:SIDrawingLoaded = $false  # $true when System.Drawing is loaded
$script:SIWithoutAdmin = [bool]$script:SIWithoutAdmin  # $true when the window opens without rights
$script:SINames        = @{}    # the parts of the window, by their name
$script:SIButtonTemplate = $null  # the button of the window, made only once

# Round 8 state (AUTO-BOOST, the icon of the tray, the shortcut).
$script:SIAutoBoostEnabled = $false  # $true when the AUTO-BOOST watches the games
$script:SIAutoBoostTimer   = $null   # the timer that checks the games every 5 s
$script:SIAutoBoostedGame  = ''     # the game that the AUTO-BOOST took care of
$script:SIAutoBoostAttempted = ''   # the game whose boost was already tried
$script:SIAutoBoostLastSeen = ''    # the last game that the AUTO-BOOST saw
$script:SIBoostIsActive    = $false  # $true while the GAME BOOST is really on
$script:SITrayIcon         = $null   # the icon of SIGAME in the tray
$script:SITrayAutoItem     = $null   # the AUTO-BOOST of the menu of the tray
$script:SIExiting          = $false  # $true when SIGAME is closing for good
# The time of the FIRST window is NOT set here: the loader opens the loading
# window before this module is read, and the moment it is on the screen is
# already known. Setting it here would throw that number away.

# The background copy collects its log lines here instead of writing them to
# the log file, so that only the window writes to the log.
$script:SILogCapture = $null
$script:SIWorkerProcess = $null
$script:SIWorkerResultPath = $null
$script:SIWorkerRequestPath = $null
$script:SIWorkerStamp = $null
$script:SIWorkerLogShown = 0
$script:SIWorkerMode = ''
$script:SIWorkerRunning = $false
$script:SIPendingModes = @()
$script:SIRestorePointWarned = $false
$script:SIPollTimer = $null
function Get-SICachedValue {
    <#
    .SYNOPSIS
        Reads a slow value only once and then remembers it.

    .DESCRIPTION
        Some readings are expensive: DISM for an optional feature, AppX for a
        package, powercfg for the power plans. They are asked once per session
        and then taken from the cache, so the second look at a state is instant.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][scriptblock]$Producer
    )

    if ($script:SICache.ContainsKey($Key)) { return $script:SICache[$Key] }
    $value = & $Producer
    $script:SICache[$Key] = $value
    return $value
}

function Clear-SICache {
    <#
    .SYNOPSIS
        Throws the cached slow readings away, used by the Refresh button and
        after a tweak changed something the cache knows about.
    #>
    param([string[]]$Keys)

    if (-not $Keys -or $Keys.Count -eq 0) {
        $script:SICache = @{}
        return
    }
    # Hashtable.Remove() answers with a boolean. That boolean must not leave
    # the function, or it lands in the output of whoever called it.
    foreach ($key in $Keys) { $null = $script:SICache.Remove($key) }
}

# ---------------------------------------------------------------------------
#  THE DATES
#
#  Every date that comes from outside PowerShell is a STRING: the restore
#  points of Windows give "20261020220411000.000000-000", and the JSON files
#  of SIGAME give "2026-10-21T10:37:01". A string cannot be subtracted from a
#  date, and PowerShell 5.1 then throws
#  'Cannot find an overload for "Subtract" and the argument count: "1"'.
#
#  So every date goes through ConvertTo-SIDateTime first, and every
#  subtraction goes through Subtract() with a real DateTime, never with the
#  "-" operator (which would be ambiguous between DateTime and TimeSpan).
# ---------------------------------------------------------------------------

function ConvertTo-SIDateTime {
    <#
    .SYNOPSIS
        Turns a date that comes from outside PowerShell into a real DateTime.

    .DESCRIPTION
        The CreationTime of a restore point comes from the WMI class
        "SystemRestore", where it is stored as a STRING such as
        "20261020220411000.000000-000". The dates of the JSON files are
        strings too ("2026-10-21T10:37:01"). Neither of them is a DateTime.

        That is the reason of the error
        "Multiple ambiguous overloads found for op_Subtraction and the
        argument count: 2" that the owner's machine produced: a plain
        "(Get-Date) - $restorePoint.CreationTime" lets PowerShell convert the
        string into a DateTime AND into a TimeSpan, and then it cannot decide
        which of the two "op_Subtraction" overloads to use.

        Here the string is parsed on purpose, and every arithmetic operation
        afterwards works on two real DateTime values. $null is returned when
        the value is not a date at all, and the caller decides what to do.
    #>
    param($Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [datetime]) { return [datetime]$Value }

    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }

    # The WMI format: 20261020220411000.000000-000
    if ($text.Length -ge 14) {
        $digits = $text.Substring(0, 14)
        if ($digits -match '^[0-9]{14}$') {
            try {
                return [datetime]::ParseExact($digits, 'yyyyMMddHHmmss', [System.Globalization.CultureInfo]::InvariantCulture)
            } catch { }
        }
    }

    # The format of the JSON files: 2026-10-21T10:37:01
    $parsed = [datetime]::MinValue
    $styles = [System.Globalization.DateTimeStyles]::None
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    if ([datetime]::TryParse($text, $culture, $styles, [ref]$parsed)) { return $parsed }
    if ([datetime]::TryParse($text, [ref]$parsed)) { return $parsed }
    return $null
}

function Get-SIElapsedSinceStart {
    <#
    .SYNOPSIS
        How long the program has been running, as a TimeSpan.

    .DESCRIPTION
        It never fails and it never throws. The start of the process can be a
        DateTime, a string that was read from a JSON file or $null, and the
        answer is always a TimeSpan, so that the caller can ask for its
        TotalSeconds without a check of its own.
    #>
    $stamp = $script:SIProcessStart
    if ($null -eq $stamp) { return [timespan]::Zero }

    if ($stamp -isnot [datetime]) {
        $parsed = ConvertTo-SIDateTime $stamp
        if (-not $parsed) { return [timespan]::Zero }
        $stamp = $parsed
    }

    $now = [datetime]::Now
    # A clock that went back must not give a negative time.
    if ($stamp -gt $now) { $stamp = $now }
    return $now.Subtract([datetime]$stamp)
}

function Set-SIWindowOnScreenTime {
    <#
    .SYNOPSIS
        Remembers how long the program needed to put the real window on the
        screen.

    .DESCRIPTION
        It is a function and not a line inside a timer: a script block that
        was made with GetNewClosure() does not see the variables of the
        script scope, and the value would be lost. The function is called from
        everywhere and the time always lands in the right place.

        The time is written only once: the first call is the one that counts.
    #>
    if ($script:SIWindowOnScreen) { return }
    $script:SIWindowOnScreen = Get-SIElapsedSinceStart
}

function Get-SIWindowsBuild {
    <#
    .SYNOPSIS
        The Windows build number, 0 when it cannot be read.
    #>
    if ($null -ne $script:SIWindowsBuildCache) { return $script:SIWindowsBuildCache }
    try {
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion', $false)
        if ($key) {
            try {
                $val = $key.GetValue('CurrentBuild', 0)
                $script:SIWindowsBuildCache = [int]$val
                return $script:SIWindowsBuildCache
            } finally {
                $key.Close()
            }
        }
    } catch { }
    $script:SIWindowsBuildCache = 0
    return 0
}

function Get-SIWindowsFamily {
    <#
    .SYNOPSIS
        'Windows 11' for build 22000 and newer, 'Windows 10' below it.

    .DESCRIPTION
        Several tweaks only exist on one of the two Windows versions. The
        name of the family is what the messages use, so that a tweak that
        cannot work on this machine can say so in the words of the owner.
    #>
    $build = Get-SIWindowsBuild
    if ($build -ge 22000) { return 'Windows 11' }
    return 'Windows 10'
}

function Get-SIBrush {
    <#
    .SYNOPSIS
        Turns a #rrggbb string into a frozen WPF brush.

    .DESCRIPTION
        The same colour is asked for again and again (every row needs four
        of them). A frozen brush can be shared, so it is made once and then
        kept. That saves a lot of work while the rows are built.
    #>
    param([string]$Hex)

    if ($script:SIBrushes.ContainsKey($Hex)) { return $script:SIBrushes[$Hex] }
    if ($script:SIBrushCache -and $script:SIBrushCache.ContainsKey($Hex)) {
        $script:SIBrushes[$Hex] = $script:SIBrushCache[$Hex]
        return $script:SIBrushes[$Hex]
    }

    $color = [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    $brush = [System.Windows.Media.SolidColorBrush]::new($color)
    $brush.Freeze()
    $script:SIBrushes[$Hex] = $brush
    return $brush
}

function Invoke-SIUIPump {
    <#
    .SYNOPSIS
        Keeps the WPF window alive while a long operation runs.

    .DESCRIPTION
        Drains the WPF dispatcher queue at Background priority without
        blocking on a fixed 20-40ms timer.
    #>
    param([int]$Milliseconds = 0)
    try {
        if ($script:SIWindow -and $script:SIWindow.Dispatcher) {
            [void]$script:SIWindow.Dispatcher.Invoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                [action]{}
            )
        }
    } catch {
        # Never let a cosmetic helper break a real operation.
    }
}

function Set-SIStatusText {
    param([string]$Text)
    if ($script:SIStatus) { $script:SIStatus.Text = $Text }
}

# ---------------------------------------------------------------------------
#  THE LANGUAGE OF THE WINDOW (round 6, point 5)
# ---------------------------------------------------------------------------

function Get-SISILanguage {
    <#
    .SYNOPSIS
        The language of the window, taken from the display language of Windows.

    .DESCRIPTION
        Only en, pt-BR, es, it, de and fr are in the table of the texts. Every
        other language gets English. The result is kept, so that the language
        is read only once.
    #>
    if ($script:SILanguage) { return $script:SILanguage }

    $name = ''
    try { $name = [string](Get-UICulture).Name } catch { }
    if ([string]::IsNullOrWhiteSpace($name)) {
        try { $name = [string](Get-Culture).Name } catch { }
    }

    $script:SILanguage = 'en'
    if (-not [string]::IsNullOrWhiteSpace($name)) {
        $lower = $name.ToLowerInvariant()
        if ($lower -eq 'pt' -or $lower.StartsWith('pt-')) { $script:SILanguage = 'pt-BR' }
        elseif ($lower -eq 'es' -or $lower.StartsWith('es-')) { $script:SILanguage = 'es' }
        elseif ($lower -eq 'it' -or $lower.StartsWith('it-')) { $script:SILanguage = 'it' }
        elseif ($lower -eq 'de' -or $lower.StartsWith('de-')) { $script:SILanguage = 'de' }
        elseif ($lower -eq 'fr' -or $lower.StartsWith('fr-')) { $script:SILanguage = 'fr' }
        elseif ($lower -eq 'en' -or $lower.StartsWith('en-')) { $script:SILanguage = 'en' }
    }
    return $script:SILanguage
}

function Get-SIText {
    <#
    .SYNOPSIS
        One text of the window, in the language of Windows.

    .DESCRIPTION
        Looks the key up in the block of the language of Windows. If the key
        is not there, the English text is used, so a translation that is not
        complete never leaves an empty label on the screen.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [string]$Fallback = ''
    )
    $language = Get-SISILanguage
    $table = $script:SIText[$language]
    if ($table -and $table.ContainsKey($Key)) { return [string]$table[$Key] }
    $english = $script:SIText['en']
    if ($english -and $english.ContainsKey($Key)) { return [string]$english[$Key] }
    return $Fallback
}

function Get-SITextFormat {
    <#
    .SYNOPSIS
        One text of the window with its placeholders filled in.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [object[]]$Arguments = @()
    )
    $text = Get-SIText -Key $Key
    if ([string]::IsNullOrWhiteSpace($text)) { return '' }
    try {
        return ($text -f $Arguments)
    } catch {
        return $text
    }
}

function Set-SIWindowTexts {
    <#
    .SYNOPSIS
        Puts the texts of the window in the language of Windows.

    .DESCRIPTION
        The window that is built in code gets its texts when it is built. The
        XAML fallback has English texts in the XAML itself, and this function
        puts the right ones in it. It works on both windows: the elements
        that are not there are simply skipped.
    #>
    $map = @{
        'SubtitleText'             = 'Subtitle'
        'ProveTitle'               = 'ProveIt'
        'OptimizeResult'           = 'OptimizeHint'
        'BtnOptimize'              = 'BtnOptimize'
        'BtnBoost'                 = 'BtnBoost'
        'BtnGameOver'              = 'BtnGameOver'
        'BtnUndoAllBig'            = 'BtnUndoAll'
        'BtnMeasure'               = 'BtnMeasure'
        'BtnSaveCard'              = 'BtnSaveCard'
        'BtnGaming'                = 'BtnGaming'
        'BtnApplyChecked'          = 'BtnApplyChecked'
        'BtnRefresh'               = 'BtnRefresh'
        'BtnRestorePoint'          = 'BtnRestorePoint'
        'BtnOpenLog'               = 'BtnOpenLog'
        'AdvancedExpander'         = 'Advanced'
        'ProveLabel_FreeRamMB'     = 'LabelFreeRam'
        'ProveLabel_StartupAppsOn' = 'LabelStartupApps'
        'ProveLabel_DnsMs'         = 'LabelDns'
        'ProveLabel_SpeedMbps'     = 'LabelSpeed'
    }
    foreach ($name in $map.Keys) {
        $element = Get-SIElement -Name $name
        if (-not $element) { continue }
        $text = Get-SIText -Key $map[$name]
        if ([string]::IsNullOrWhiteSpace($text)) { continue }
        try {
            if ($element -is [System.Windows.Controls.Button]) { $element.Content = $text }
            elseif ($element -is [System.Windows.Controls.Expander]) { $element.Header = $text }
            else { $element.Text = $text }
        } catch {
            Write-SILog -Level 'WARN' -Component 'UI' -Message "The text of $name could not be set: $($_.Exception.Message)"
        }
    }
}

function Show-SILogTail {
    <#
    .SYNOPSIS
        Puts the last lines of the log file into the log window.

    .DESCRIPTION
        This is done AFTER the window is on the screen, so that reading the
        file is not on the way to the window.
    #>
    try {
        if (-not $script:SILogBox) { return }
        if (-not (Test-Path -LiteralPath $script:SILogPath)) { return }
        $lines = @(Get-Content -LiteralPath $script:SILogPath -Tail 200 -ErrorAction SilentlyContinue)
        if ($lines.Count -gt 0) {
            $script:SILogBox.AppendText(($lines -join [Environment]::NewLine) + [Environment]::NewLine)
            $script:SILogBox.ScrollToEnd()
        }
    } catch { }
}
