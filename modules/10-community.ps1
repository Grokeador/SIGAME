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

$script:SIGameVersion     = '2026.11.18.7'
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
        UpdateAsk       = "SIGAME {0} is on GitHub (this copy is {1}).`n`n{2}`n`nUpdate now? Your settings, backups and presets stay as they are."
        UpdateBusy      = 'Downloading SIGAME {0}...'
        UpdateDone      = 'SIGAME {0} is installed. SIGAME restarts now.'
        UpdateFail      = 'The update was not installed, nothing was changed: {0}'
        UpdatedTo       = 'SIGAME updated itself to {0}.'
        TrayTitle       = 'SIGAME is running in the tray'
        TrayText        = 'Auto-Boost is watching for your games in the background.'
        WhatsNew        = 'SIGAME updated itself to {0}.`n`nWhat is new:`n{1}'
        PresetsAuto     = 'New SI PRESETS downloaded: {0}'
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
        UpdateAsk       = "SIGAME {0} e su GitHub (questa copia e la {1}).`n`n{2}`n`nAggiornare adesso? Impostazioni, backup e preset restano come sono."
        UpdateBusy      = 'Scarico SIGAME {0}...'
        UpdateDone      = 'SIGAME {0} e installato. SIGAME si riavvia adesso.'
        UpdateFail      = 'Aggiornamento non installato, niente e cambiato: {0}'
        UpdatedTo       = 'SIGAME si e aggiornato da solo alla {0}.'
        TrayTitle       = 'SIGAME e attivo nella barra delle icone'
        TrayText        = 'Auto-Boost controlla i tuoi giochi in background.'
        WhatsNew        = 'SIGAME si e aggiornato da solo alla {0}.`n`nNovita:`n{1}'
        PresetsAuto     = 'Nuovi SI PRESETS scaricati: {0}'
    }
}

# Same texts in the other languages of the window (18/11): before, pt-BR, es, de and fr
# windows showed these lines in English. ASCII only, like the rest of the file.
$script:SICommunityText['pt-BR'] = @{
    BtnPresets      = 'SI PRESETS'
    BtnRequest      = 'PEDIR'
    BtnPreset       = 'SI PRESET'
    BtnFeedback     = 'Pedir um jogo / Feedback'
    ReqTitle        = 'Pedir um SI PRESET'
    ReqIntro        = 'Diga ao SI NEWS qual jogo voce quer otimizar e o que quer dele. Os jogos mais pedidos ganham um preset extremo dentro do SIGAME.'
    ReqGame         = 'Jogo (tambem um que o SIGAME nao ve):'
    ReqWants        = 'O que voce quer?'
    WantFps         = 'Mais FPS'
    WantUltra       = 'Graficos alem dos limites do menu'
    WantWide        = 'Ultrawide / 144 Hz+'
    WantLoad        = 'Carregamento mais rapido'
    WantStutter     = 'Tirar travadas / crashes'
    WantLowEnd      = 'Jogavel em PC fraco'
    ReqMessage      = 'Mais alguma coisa? (opcional)'
    ReqPreview      = 'O que sera enviado:'
    ReqSend         = 'ENVIAR'
    ReqCancel       = 'Cancelar'
    ReqNoGame       = 'Escreva primeiro o nome do jogo.'
    ReqSent         = 'Pedido enviado ao SI NEWS: {0}. Obrigado!'
    TelemetryOn     = 'Estatisticas anonimas ON: uma vez por semana o SI NEWS recebe os nomes dos seus jogos + modelo de CPU/GPU e RAM (sem id, sem arquivos) para escolher os proximos SI PRESETS.'
    TelemetryOff    = 'Estatisticas anonimas OFF.'
    TelemetryTurnOff = 'Desligar'
    TelemetryTurnOn  = 'Ligar'
    AskAfterAdd     = 'Jogo adicionado: {0}. Quer que o SI NEWS faca um SI PRESET extremo para ele?'
    PresetConfirm   = "{0} - {1}`n`n{2}`n`nAplicar agora?"
    PresetDone      = 'SI PRESET {0} aplicado. Detalhes em SI-GAME.log.'
    PresetFail      = 'SI PRESET {0} nao foi aplicado: {1}'
    PresetUndoAsk   = "O SI PRESET {0} ja esta aplicado.`n`nSIM = volta a sua configuracao original (Desfazer)`nNAO = aplica de novo"
    PresetsTitle    = 'SI PRESETS'
    PresetsIntro    = 'Configuracoes extremas feitas nos videos do SI NEWS. Encontrado = o jogo esta neste PC.'
    PresetFound     = 'encontrado neste PC'
    PresetNotFound  = 'nao encontrado'
    PresetApply     = 'APLICAR'
    PresetsUpdate   = 'Buscar novos presets'
    PresetsUpToDate = 'Presets atualizados ({0}).'
    PresetsNew      = "{0} SI PRESETS novos ou atualizados estao no GitHub:`n`n{1}`n`nBaixar agora?"
    PresetsGot      = '{0} SI PRESETS baixados.'
    PresetsOffline  = 'Nao foi possivel acessar o GitHub: {0}'
    UpdateAsk       = "SIGAME {0} esta no GitHub (esta copia e a {1}).`n`n{2}`n`nAtualizar agora? Suas configuracoes, backups e presets ficam como estao."
    UpdateBusy      = 'Baixando SIGAME {0}...'
    UpdateDone      = 'SIGAME {0} instalado. O SIGAME reinicia agora.'
    UpdateFail      = 'A atualizacao nao foi instalada, nada mudou: {0}'
    UpdatedTo       = 'O SIGAME se atualizou sozinho para a {0}.'
    TrayTitle       = 'O SIGAME esta rodando na bandeja'
    TrayText        = 'O Auto-Boost esta de olho nos seus jogos em segundo plano.'
    WhatsNew        = 'O SIGAME se atualizou sozinho para a {0}.`n`nNovidades:`n{1}'
    PresetsAuto     = 'Novos SI PRESETS baixados: {0}'
    PresetsSearch   = 'Buscar jogo...'
    PresetApplied   = 'APLICADO'
    PresetsNone     = 'Nenhum preset para esta busca.'
}
$script:SICommunityText['es'] = @{
    BtnPresets      = 'SI PRESETS'
    BtnRequest      = 'PEDIR'
    BtnPreset       = 'SI PRESET'
    BtnFeedback     = 'Pedir un juego / Feedback'
    ReqTitle        = 'Pedir un SI PRESET'
    ReqIntro        = 'Dile a SI NEWS que juego quieres optimizar y que quieres de el. Los juegos mas pedidos reciben un preset extremo dentro de SIGAME.'
    ReqGame         = 'Juego (tambien uno que SIGAME no ve):'
    ReqWants        = 'Que quieres?'
    WantFps         = 'Mas FPS'
    WantUltra       = 'Graficos mas alla de los limites del menu'
    WantWide        = 'Ultrawide / 144 Hz+'
    WantLoad        = 'Cargas mas rapidas'
    WantStutter     = 'Quitar tirones / crashes'
    WantLowEnd      = 'Jugable en PC debil'
    ReqMessage      = 'Algo mas? (opcional)'
    ReqPreview      = 'Lo que se enviara:'
    ReqSend         = 'ENVIAR'
    ReqCancel       = 'Cancelar'
    ReqNoGame       = 'Escribe primero el nombre del juego.'
    ReqSent         = 'Pedido enviado a SI NEWS: {0}. Gracias!'
    TelemetryOn     = 'Estadisticas anonimas ON: una vez por semana SI NEWS recibe los nombres de tus juegos + modelo de CPU/GPU y RAM (sin id, sin archivos) para elegir los proximos SI PRESETS.'
    TelemetryOff    = 'Estadisticas anonimas OFF.'
    TelemetryTurnOff = 'Desactivar'
    TelemetryTurnOn  = 'Activar'
    AskAfterAdd     = 'Juego agregado: {0}. Quieres que SI NEWS haga un SI PRESET extremo para el?'
    PresetConfirm   = "{0} - {1}`n`n{2}`n`nAplicarlo ahora?"
    PresetDone      = 'SI PRESET {0} aplicado. Detalles en SI-GAME.log.'
    PresetFail      = 'SI PRESET {0} no se aplico: {1}'
    PresetUndoAsk   = "El SI PRESET {0} ya esta aplicado.`n`nSI = vuelve tu configuracion original (Deshacer)`nNO = aplicarlo de nuevo"
    PresetsTitle    = 'SI PRESETS'
    PresetsIntro    = 'Configuraciones extremas hechas en los videos de SI NEWS. Encontrado = el juego esta en este PC.'
    PresetFound     = 'encontrado en este PC'
    PresetNotFound  = 'no encontrado'
    PresetApply     = 'APLICAR'
    PresetsUpdate   = 'Buscar nuevos presets'
    PresetsUpToDate = 'Presets al dia ({0}).'
    PresetsNew      = "Hay {0} SI PRESETS nuevos o actualizados en GitHub:`n`n{1}`n`nDescargarlos ahora?"
    PresetsGot      = '{0} SI PRESETS descargados.'
    PresetsOffline  = 'No se pudo llegar a GitHub: {0}'
    UpdateAsk       = "SIGAME {0} esta en GitHub (esta copia es la {1}).`n`n{2}`n`nActualizar ahora? Tus ajustes, backups y presets quedan como estan."
    UpdateBusy      = 'Descargando SIGAME {0}...'
    UpdateDone      = 'SIGAME {0} instalado. SIGAME se reinicia ahora.'
    UpdateFail      = 'La actualizacion no se instalo, nada cambio: {0}'
    UpdatedTo       = 'SIGAME se actualizo solo a la {0}.'
    TrayTitle       = 'SIGAME se esta ejecutando en la bandeja'
    TrayText        = 'Auto-Boost vigila tus juegos en segundo plano.'
    WhatsNew        = 'SIGAME se actualizo solo a la {0}.`n`nNovedades:`n{1}'
    PresetsAuto     = 'Nuevos SI PRESETS descargados: {0}'
    PresetsSearch   = 'Buscar juego...'
    PresetApplied   = 'APLICADO'
    PresetsNone     = 'Ningun preset para esta busqueda.'
}
$script:SICommunityText['de'] = @{
    BtnPresets      = 'SI PRESETS'
    BtnRequest      = 'ANFRAGEN'
    BtnPreset       = 'SI PRESET'
    BtnFeedback     = 'Spiel anfragen / Feedback'
    ReqTitle        = 'SI PRESET anfragen'
    ReqIntro        = 'Sag SI NEWS, welches Spiel optimiert werden soll und was du davon willst. Die meistgefragten Spiele bekommen ein extremes Preset in SIGAME.'
    ReqGame         = 'Spiel (auch eins, das SIGAME nicht sieht):'
    ReqWants        = 'Was willst du?'
    WantFps         = 'Mehr FPS'
    WantUltra       = 'Grafik ueber die Menue-Grenzen hinaus'
    WantWide        = 'Ultrawide / 144 Hz+'
    WantLoad        = 'Schnelleres Laden'
    WantStutter     = 'Ruckler / Abstuerze beheben'
    WantLowEnd      = 'Spielbar auf schwachem PC'
    ReqMessage      = 'Sonst noch etwas? (optional)'
    ReqPreview      = 'Was gesendet wird:'
    ReqSend         = 'SENDEN'
    ReqCancel       = 'Abbrechen'
    ReqNoGame       = 'Schreib zuerst den Namen des Spiels.'
    ReqSent         = 'Anfrage an SI NEWS gesendet: {0}. Danke!'
    TelemetryOn     = 'Anonyme Statistik AN: einmal pro Woche bekommt SI NEWS die Namen deiner Spiele + CPU/GPU-Modell und RAM (keine ID, keine Dateien), um die naechsten SI PRESETS zu waehlen.'
    TelemetryOff    = 'Anonyme Statistik AUS.'
    TelemetryTurnOff = 'Ausschalten'
    TelemetryTurnOn  = 'Einschalten'
    AskAfterAdd     = 'Spiel hinzugefuegt: {0}. Soll SI NEWS ein extremes SI PRESET dafuer machen?'
    PresetConfirm   = "{0} - {1}`n`n{2}`n`nJetzt anwenden?"
    PresetDone      = 'SI PRESET {0} angewendet. Details in SI-GAME.log.'
    PresetFail      = 'SI PRESET {0} wurde nicht angewendet: {1}'
    PresetUndoAsk   = "SI PRESET {0} ist schon angewendet.`n`nJA = deine Original-Konfiguration zurueck (Rueckgaengig)`nNEIN = erneut anwenden"
    PresetsTitle    = 'SI PRESETS'
    PresetsIntro    = 'Extreme Konfigurationen aus den SI NEWS Videos. Gefunden = das Spiel ist auf diesem PC.'
    PresetFound     = 'auf diesem PC gefunden'
    PresetNotFound  = 'nicht gefunden'
    PresetApply     = 'ANWENDEN'
    PresetsUpdate   = 'Nach neuen Presets suchen'
    PresetsUpToDate = 'Presets sind aktuell ({0}).'
    PresetsNew      = "{0} neue oder aktualisierte SI PRESETS sind auf GitHub:`n`n{1}`n`nJetzt herunterladen?"
    PresetsGot      = '{0} SI PRESETS heruntergeladen.'
    PresetsOffline  = 'GitHub nicht erreichbar: {0}'
    UpdateAsk       = "SIGAME {0} ist auf GitHub (diese Kopie ist {1}).`n`n{2}`n`nJetzt aktualisieren? Einstellungen, Backups und Presets bleiben, wie sie sind."
    UpdateBusy      = 'Lade SIGAME {0} herunter...'
    UpdateDone      = 'SIGAME {0} ist installiert. SIGAME startet jetzt neu.'
    UpdateFail      = 'Das Update wurde nicht installiert, nichts wurde geaendert: {0}'
    UpdatedTo       = 'SIGAME hat sich selbst auf {0} aktualisiert.'
    TrayTitle       = 'SIGAME laeuft im Infobereich'
    TrayText        = 'Auto-Boost achtet im Hintergrund auf deine Spiele.'
    WhatsNew        = 'SIGAME hat sich selbst auf {0} aktualisiert.`n`nNeu:`n{1}'
    PresetsAuto     = 'Neue SI PRESETS heruntergeladen: {0}'
    PresetsSearch   = 'Spiel suchen...'
    PresetApplied   = 'ANGEWENDET'
    PresetsNone     = 'Kein Preset fuer diese Suche.'
}
$script:SICommunityText['fr'] = @{
    BtnPresets      = 'SI PRESETS'
    BtnRequest      = 'DEMANDER'
    BtnPreset       = 'SI PRESET'
    BtnFeedback     = 'Demander un jeu / Feedback'
    ReqTitle        = 'Demander un SI PRESET'
    ReqIntro        = 'Dis a SI NEWS quel jeu tu veux optimiser et ce que tu en attends. Les jeux les plus demandes recoivent un preset extreme dans SIGAME.'
    ReqGame         = 'Jeu (meme un que SIGAME ne voit pas):'
    ReqWants        = 'Que veux-tu?'
    WantFps         = 'Plus de FPS'
    WantUltra       = 'Graphismes au-dela des limites du menu'
    WantWide        = 'Ultrawide / 144 Hz+'
    WantLoad        = 'Chargements plus rapides'
    WantStutter     = 'Corriger saccades / crashs'
    WantLowEnd      = 'Jouable sur un PC faible'
    ReqMessage      = 'Autre chose? (facultatif)'
    ReqPreview      = 'Ce qui sera envoye:'
    ReqSend         = 'ENVOYER'
    ReqCancel       = 'Annuler'
    ReqNoGame       = "Ecris d'abord le nom du jeu."
    ReqSent         = 'Demande envoyee a SI NEWS: {0}. Merci!'
    TelemetryOn     = 'Stats anonymes ON: une fois par semaine SI NEWS recoit les noms de tes jeux + modele CPU/GPU et RAM (pas d id, pas de fichiers) pour choisir les prochains SI PRESETS.'
    TelemetryOff    = 'Stats anonymes OFF.'
    TelemetryTurnOff = 'Desactiver'
    TelemetryTurnOn  = 'Activer'
    AskAfterAdd     = 'Jeu ajoute: {0}. Veux-tu que SI NEWS fasse un SI PRESET extreme pour lui?'
    PresetConfirm   = "{0} - {1}`n`n{2}`n`nL'appliquer maintenant?"
    PresetDone      = 'SI PRESET {0} applique. Details dans SI-GAME.log.'
    PresetFail      = "SI PRESET {0} n'a pas ete applique: {1}"
    PresetUndoAsk   = "Le SI PRESET {0} est deja applique.`n`nOUI = remettre ta configuration d'origine (Annuler)`nNON = l'appliquer de nouveau"
    PresetsTitle    = 'SI PRESETS'
    PresetsIntro    = 'Configurations extremes faites dans les videos SI NEWS. Trouve = le jeu est sur ce PC.'
    PresetFound     = 'trouve sur ce PC'
    PresetNotFound  = 'non trouve'
    PresetApply     = 'APPLIQUER'
    PresetsUpdate   = 'Chercher de nouveaux presets'
    PresetsUpToDate = 'Presets a jour ({0}).'
    PresetsNew      = "{0} SI PRESETS nouveaux ou mis a jour sont sur GitHub:`n`n{1}`n`nLes telecharger maintenant?"
    PresetsGot      = '{0} SI PRESETS telecharges.'
    PresetsOffline  = 'GitHub injoignable: {0}'
    UpdateAsk       = "SIGAME {0} est sur GitHub (cette copie est la {1}).`n`n{2}`n`nMettre a jour maintenant? Tes reglages, sauvegardes et presets restent tels quels."
    UpdateBusy      = 'Telechargement de SIGAME {0}...'
    UpdateDone      = 'SIGAME {0} est installe. SIGAME redemarre maintenant.'
    UpdateFail      = "La mise a jour n'a pas ete installee, rien n'a change: {0}"
    UpdatedTo       = "SIGAME s'est mis a jour tout seul vers {0}."
    TrayTitle       = 'SIGAME tourne dans la zone de notification'
    TrayText        = 'Auto-Boost surveille tes jeux en arriere-plan.'
    WhatsNew        = "SIGAME s'est mis a jour tout seul vers {0}.`n`nNouveautes :`n{1}"
    PresetsAuto     = 'Nouveaux SI PRESETS telecharges: {0}'
    PresetsSearch   = 'Chercher un jeu...'
    PresetApplied   = 'APPLIQUE'
    PresetsNone     = 'Aucun preset pour cette recherche.'
}
$script:SICommunityText['en'].PresetsSearch = 'Search game...'
$script:SICommunityText['en'].PresetApplied = 'APPLIED'
$script:SICommunityText['en'].PresetsNone   = 'No preset for this search.'
$script:SICommunityText['it'].PresetsSearch = 'Cerca gioco...'
$script:SICommunityText['it'].PresetApplied = 'APPLICATO'
$script:SICommunityText['it'].PresetsNone   = 'Nessun preset per questa ricerca.'
$script:SICommunityText['pt-BR'].GamesScanning = 'Procurando jogos neste PC...'
$script:SICommunityText['es'].GamesScanning = 'Buscando juegos en este PC...'
$script:SICommunityText['de'].GamesScanning = 'Suche Spiele auf diesem PC...'
$script:SICommunityText['fr'].GamesScanning = 'Recherche des jeux sur ce PC...'
$script:SICommunityText['en'].GamesScanning = 'Looking for games on this PC...'
$script:SICommunityText['it'].GamesScanning = 'Cerco i giochi su questo PC...'
$script:SICommunityText['en'].AddTitle    = 'Select the game executable (.exe) to add'
$script:SICommunityText['en'].AddDone     = 'Game added to the list: {0}. Press OPTIMIZE or PLAY to optimize it.'
$script:SICommunityText['en'].AddFail     = 'The game could not be added: {0}'
$script:SICommunityText['en'].AddLauncher = "{0} looks like a launcher, not the game. SIGAME needs the exe of the game itself (inside the game folder, often in a Bin or Binaries folder).`n`nAdd {0} anyway?"
$script:SICommunityText['it'].AddTitle    = 'Scegli l''eseguibile del gioco (.exe) da aggiungere'
$script:SICommunityText['it'].AddDone     = 'Gioco aggiunto alla lista: {0}. Premi OTTIMIZZA o GIOCA per ottimizzarlo.'
$script:SICommunityText['it'].AddFail     = 'Il gioco non e stato aggiunto: {0}'
$script:SICommunityText['it'].AddLauncher = "{0} sembra un launcher, non il gioco. SIGAME ha bisogno dell'exe del gioco stesso (nella cartella del gioco, spesso in Bin o Binaries).`n`nAggiungere {0} lo stesso?"
$script:SICommunityText['pt-BR'].AddTitle    = 'Escolha o executavel do jogo (.exe) para adicionar'
$script:SICommunityText['pt-BR'].AddDone     = 'Jogo adicionado a lista: {0}. Pressione OTIMIZAR ou JOGAR para otimiza-lo.'
$script:SICommunityText['pt-BR'].AddFail     = 'Nao foi possivel adicionar o jogo: {0}'
$script:SICommunityText['pt-BR'].AddLauncher = "{0} parece um launcher, nao o jogo. O SIGAME precisa do exe do proprio jogo (na pasta do jogo, muitas vezes em Bin ou Binaries).`n`nAdicionar {0} mesmo assim?"
$script:SICommunityText['es'].AddTitle    = 'Elige el ejecutable del juego (.exe) para agregar'
$script:SICommunityText['es'].AddDone     = 'Juego agregado a la lista: {0}. Pulsa OPTIMIZAR o JUGAR para optimizarlo.'
$script:SICommunityText['es'].AddFail     = 'No se pudo agregar el juego: {0}'
$script:SICommunityText['es'].AddLauncher = "{0} parece un launcher, no el juego. SIGAME necesita el exe del propio juego (en la carpeta del juego, a menudo en Bin o Binaries).`n`nAgregar {0} de todos modos?"
$script:SICommunityText['de'].AddTitle    = 'Waehle die Exe-Datei des Spiels (.exe)'
$script:SICommunityText['de'].AddDone     = 'Spiel zur Liste hinzugefuegt: {0}. Druecke OPTIMIEREN oder SPIELEN, um es zu optimieren.'
$script:SICommunityText['de'].AddFail     = 'Das Spiel konnte nicht hinzugefuegt werden: {0}'
$script:SICommunityText['de'].AddLauncher = "{0} sieht wie ein Launcher aus, nicht wie das Spiel. SIGAME braucht die Exe des Spiels selbst (im Spielordner, oft in Bin oder Binaries).`n`n{0} trotzdem hinzufuegen?"
$script:SICommunityText['fr'].AddTitle    = 'Choisis l''executable du jeu (.exe) a ajouter'
$script:SICommunityText['fr'].AddDone     = 'Jeu ajoute a la liste: {0}. Appuie sur OPTIMISER ou JOUER pour l''optimiser.'
$script:SICommunityText['fr'].AddFail     = 'Le jeu n''a pas pu etre ajoute: {0}'
$script:SICommunityText['fr'].AddLauncher = "{0} ressemble a un launcher, pas au jeu. SIGAME a besoin de l'exe du jeu lui-meme (dans le dossier du jeu, souvent dans Bin ou Binaries).`n`nAjouter {0} quand meme?"

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
            # the entry's own Match: Find-SIGamePreset gives only the FIRST preset of a game with several
            $hay = @([string]$g.Name, [System.IO.Path]::GetFileName([string]$g.Exe),
                     [System.IO.Path]::GetFileName([string]$g.Folder)) -join ' | '
            if ($Entry.Match -and $g.Exe -and $hay -match [string]$Entry.Match) { $argLine += " -GameExe `"$($g.Exe)`""; break }
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
        $undoNote = ''
        if ($undo) {
            # how long the preset stayed: tells a quick test from a real try (no reason is asked to the player)
            try {
                $secs = [int]([datetime]::Now - [datetime]$state.Applied.([string]$Entry.Id)).TotalSeconds
                if ($secs -ge 0) { $undoNote = "undo after $secs s" }
            } catch { }
            $state.Applied.PSObject.Properties.Remove([string]$Entry.Id)
        } else {
            $state.Applied | Add-Member ([string]$Entry.Id) ([datetime]::Now.ToString('s')) -Force
        }
        Save-SICommunityState -State $state
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetDone') -f $Entry.Title)
        [void][System.Windows.MessageBox]::Show($win, (@($r.Lines) -join "`n"), "SI PRESET $($Entry.Title)")
        $kind = if ($undo) { 'preset_undo' } else { 'preset_applied' }
        Send-SITelemetry -Event (New-SITelemetryEvent -Kind $kind -Preset ([string]$Entry.Id) -Message $undoNote)
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
    # -Auto = the start of SIGAME: no question, silent when offline or up to date.
    # Downloading only adds files: nothing runs before the player presses APPLY.
    param([switch]$Auto, [string]$RemoteText = '')
    if (-not $Auto -and (Test-SIUpdateNow)) { return }
    $base = Get-SIPresetsBase
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $remoteText = $RemoteText
        if (-not $remoteText) { $remoteText = (Invoke-WebRequest -Uri ($base + 'catalog.json') -UseBasicParsing -TimeoutSec 10).Content }
        $remote = $remoteText | ConvertFrom-Json
    } catch {
        if ($Auto) { Write-SILog -Level 'WARN' -Component 'Presets' -Message "Auto check: $($_.Exception.Message)"; return }
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetsOffline') -f $_.Exception.Message)
        return
    }
    $local = @{}
    foreach ($e in (Get-SIPresetCatalog -Reload)) { $local[[string]$e.Id] = [int]$e.Version }
    $todo = @($remote.Presets | Where-Object {
            ([string]$_.Script -match '^[A-Za-z0-9_.-]+\.ps1$') -and
            ((-not $local.ContainsKey([string]$_.Id)) -or ([int]$_.Version -gt $local[[string]$_.Id])) })
    if ($todo.Count -eq 0) {
        # only texts changed (summaries, translations): keep the local catalog current
        try {
            $localUpd = ''
            if (Test-Path -LiteralPath $script:SICatalogPath) {
                $localUpd = [string]((Get-Content -LiteralPath $script:SICatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json).Updated)
            }
            if ([string]$remote.Updated -and ([string]$remote.Updated -ne $localUpd)) {
                [void][System.IO.Directory]::CreateDirectory($script:SIPresetsPath)
                [System.IO.File]::WriteAllText($script:SICatalogPath, $remoteText)
                [void](Get-SIPresetCatalog -Reload)
                Write-SILog -Component 'Presets' -Message "Catalog texts refreshed to $($remote.Updated)"
            }
        } catch { Write-SILog -Level 'WARN' -Component 'Presets' -Message "Catalog refresh: $($_.Exception.Message)" }
        if ($Auto) { return }
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetsUpToDate') -f $remote.Updated)
        return
    }
    $names = ($todo | ForEach-Object { "- $($_.Title): $($_.Game)" }) -join "`n"
    if (-not $Auto -and -not (Show-SIMessage -Window $script:SIWindow -Title 'SI PRESETS' -Text ((Get-SICommunityText 'PresetsNew') -f $todo.Count, $names))) { return }
    try {
        [void][System.IO.Directory]::CreateDirectory($script:SIPresetsPath)
        foreach ($e in $todo) {
            $dest = [System.IO.Path]::Combine($script:SIPresetsPath, [string]$e.Script)
            Invoke-WebRequest -Uri ($base + [string]$e.Script) -UseBasicParsing -TimeoutSec 15 -OutFile $dest
            Write-SILog -Component 'Presets' -Message "Downloaded $($e.Script) v$($e.Version)"
        }
        [System.IO.File]::WriteAllText($script:SICatalogPath, $remoteText)
        [void](Get-SIPresetCatalog -Reload)
        if ($Auto) { Set-SIStatusText -Text ((Get-SICommunityText 'PresetsAuto') -f (($todo | ForEach-Object { [string]$_.Game }) -join ', ')) }
        else { Set-SIStatusText -Text ((Get-SICommunityText 'PresetsGot') -f $todo.Count) }
        try { Update-SIAutoDashboard } catch { }
    } catch {
        if ($Auto) { Write-SILog -Level 'WARN' -Component 'Presets' -Message "Auto download: $($_.Exception.Message)"; return }
        Set-SIStatusText -Text ((Get-SICommunityText 'PresetsOffline') -f $_.Exception.Message)
    }
}

function Get-SIPresetsBase {
    $cfg = Get-SIFeedbackConfig
    $base = ''
    if ($cfg) { $base = [string]$cfg.PresetsRawBase }
    if (-not $base) { $base = (Get-SIUpdateBase) + 'presets/' }
    return $base
}

# ------------------------------- app update --------------------------------
#  SIGAME itself updates from the same GitHub repo as the presets. version.json
#  (repo root) lists the version and the SHA-256 of every script. Nothing is
#  downloaded before the player says yes; every file is checked (hash + parse)
#  before one file of the installed copy is touched, and the old scripts are
#  kept in SI-GAME-update-backup.

$script:SIUpdateTask  = $null
$script:SIUpdateTimer = $null
$script:SIUpdateTicks = 0
$script:SICatalogTask = $null

function Get-SIUpdateBase {
    $cfg = Get-SIFeedbackConfig
    $repo = ''
    if ($cfg) { $repo = [string]$cfg.GitHubRepo }
    if ($repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { $repo = 'Grokeador/SIGAME' }
    return "https://raw.githubusercontent.com/$repo/main/"
}

function Test-SIUpdateNewer {
    param($Manifest)
    try { return ([version][string]$Manifest.Version -gt [version]$script:SIGameVersion) } catch { return $false }
}

function Install-SIUpdate {
    <#
    .SYNOPSIS
        Downloads the scripts of version.json to a temp folder, checks them,
        then swaps them in. Returns @{ Ok; Message }.
    #>
    param($Manifest)
    $base = Get-SIUpdateBase
    $files = @($Manifest.Files | Where-Object { $_ -and ([string]$_.Path -match '^(modules/)?[A-Za-z0-9_.-]+\.ps1$') -and ([string]$_.Sha256 -match '^[0-9A-Fa-f]{64}$') })
    if ($files.Count -eq 0 -or $files.Count -ne @($Manifest.Files).Count) { return @{ Ok = $false; Message = 'version.json is not valid' } }
    $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'sigame-update-' + [guid]::NewGuid().ToString('N'))
    $backup = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-update-backup', [string]$script:SIGameVersion)
    $done = @()
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $sha = [System.Security.Cryptography.SHA256]::Create()
        foreach ($f in $files) {
            $rel = ([string]$f.Path).Replace('/', '\')
            $dest = [System.IO.Path]::Combine($tmp, $rel)
            [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest))
            Invoke-WebRequest -Uri ($base + [string]$f.Path) -UseBasicParsing -TimeoutSec 30 -OutFile $dest
            $hash = ([System.BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($dest)))).Replace('-', '')
            if ($hash -ine [string]$f.Sha256) { throw "the download of $($f.Path) does not match its checksum" }
            $tok = $null; $errs = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($dest, [ref]$tok, [ref]$errs)
            if ($errs -and $errs.Count -gt 0) { throw "$($f.Path) does not parse" }
        }
        # Every file is good: only now the installed copy is touched.
        foreach ($f in $files) {
            $rel = ([string]$f.Path).Replace('/', '\')
            $live = [System.IO.Path]::Combine($script:SIRoot, $rel)
            if ([System.IO.File]::Exists($live)) {
                $keep = [System.IO.Path]::Combine($backup, $rel)
                [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($keep))
                [System.IO.File]::Copy($live, $keep, $true)
            }
            [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($live))
            [System.IO.File]::Copy([System.IO.Path]::Combine($tmp, $rel), $live, $true)
            $done += $rel
        }
        Write-SILog -Component 'Update' -Message "SIGAME $script:SIGameVersion -> $($Manifest.Version): $($files.Count) files, the old ones are in $backup"
        return @{ Ok = $true; Message = '' }
    } catch {
        $reason = [string]$_.Exception.Message
        # A half copy is put back, so that the old version still starts.
        foreach ($rel in $done) {
            try {
                $keep = [System.IO.Path]::Combine($backup, $rel)
                if ([System.IO.File]::Exists($keep)) { [System.IO.File]::Copy($keep, [System.IO.Path]::Combine($script:SIRoot, $rel), $true) }
            } catch { }
        }
        Write-SILog -Level 'WARN' -Component 'Update' -Message "The update to $($Manifest.Version) was not installed: $reason"
        return @{ Ok = $false; Message = $reason }
    } finally {
        try { if ([System.IO.Directory]::Exists($tmp)) { [System.IO.Directory]::Delete($tmp, $true) } } catch { }
    }
}

function Restart-SISigame {
    try {
        Start-Process -FilePath 'powershell.exe' -WorkingDirectory $script:SIRoot -WindowStyle Hidden `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$script:SICurrentScript`""
    } catch {
        Write-SILog -Level 'WARN' -Component 'Update' -Message "SIGAME could not start itself again: $($_.Exception.Message)"
    }
    Exit-SISigame
}

function Invoke-SIUpdateOffer {
    <#
    .SYNOPSIS
        Asks the player, installs, restarts. $true = SIGAME is restarting.
    #>
    param($Manifest, [switch]$Quiet)
    if (-not (Test-SIUpdateNewer -Manifest $Manifest)) { return $false }
    $state = Get-SICommunityState
    $skipped = ''
    if ($state.PSObject.Properties.Name -contains 'UpdateSkipped') { $skipped = [string]$state.UpdateSkipped }
    # -Quiet = the start of SIGAME: installs by itself, no question (owner 18/11).
    # The button still asks. Every file is checked (SHA-256 + parse) before anything changes.
    $notes = Get-SIUpdateNotes -Manifest $Manifest
    $text = (Get-SICommunityText 'UpdateAsk') -f [string]$Manifest.Version, $script:SIGameVersion, $notes
    if (-not $Quiet -and -not (Show-SIMessage -Window $script:SIWindow -Title 'SIGAME' -Text $text)) {
        $state | Add-Member 'UpdateSkipped' ([string]$Manifest.Version) -Force
        Save-SICommunityState -State $state
        return $false
    }
    Set-SIStatusText -Text ((Get-SICommunityText 'UpdateBusy') -f [string]$Manifest.Version)
    try { Invoke-SIUIPump } catch { }
    $r = Install-SIUpdate -Manifest $Manifest
    if (-not $r.Ok) {
        Set-SIStatusText -Text ((Get-SICommunityText 'UpdateFail') -f $r.Message)
        Write-SILog -Level 'WARN' -Component 'Update' -Message "SIGAME $($Manifest.Version) not installed: $($r.Message)"
        return $false
    }
    if ($Quiet) {
        $state = Get-SICommunityState
        $state | Add-Member 'JustUpdated' ([string]$Manifest.Version) -Force
        $state | Add-Member 'JustUpdatedNotes' (Get-SIUpdateNotes -Manifest $Manifest) -Force
        Save-SICommunityState -State $state
        Write-SILog -Component 'Update' -Message "SIGAME $($Manifest.Version) installed by itself, restarting."
        Restart-SISigame
        return $true
    }
    Show-SIInfoBox -Text ((Get-SICommunityText 'UpdateDone') -f [string]$Manifest.Version)
    Restart-SISigame
    return $true
}

function Show-SIInfoBox {
    # One OK box for the update messages (the tests replace it).
    param([string]$Text)
    [void][System.Windows.MessageBox]::Show($script:SIWindow, $Text, 'SIGAME')
}

function Get-SIUpdateNotes {
    # version.json: Notes (English) + optional NotesLang.<language>
    param($Manifest)
    $lang = Get-SISILanguage
    if ($Manifest.PSObject.Properties.Name -contains 'NotesLang' -and $Manifest.NotesLang -and
        $Manifest.NotesLang.PSObject.Properties.Name -contains $lang) { return [string]$Manifest.NotesLang.$lang }
    if ($Manifest.PSObject.Properties.Name -contains 'Notes') { return [string]$Manifest.Notes }
    return ''
}

function Test-SIUpdateNow {
    # The button "Check for new presets" looks for a new SIGAME first.
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $manifest = (Invoke-WebRequest -Uri ((Get-SIUpdateBase) + 'version.json') -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
    } catch { return $false }
    return (Invoke-SIUpdateOffer -Manifest $manifest)
}

function Start-SIUpdateCheck {
    <#
    .SYNOPSIS
        The check of every start, in the background (the window never waits for
        the network), silent when offline: a newer SIGAME installs by itself and
        restarts; otherwise new SI PRESETS are downloaded by themselves.
    #>
    try {
        $state = Get-SICommunityState
        if ($state.PSObject.Properties.Name -contains 'JustUpdated') {
            Set-SIStatusText -Text ((Get-SICommunityText 'UpdatedTo') -f [string]$state.JustUpdated)
            # 18/11: what is new, once, after the window has finished its start-up work
            $wn = ''
            if ($state.PSObject.Properties.Name -contains 'JustUpdatedNotes') { $wn = [string]$state.JustUpdatedNotes; $state.PSObject.Properties.Remove('JustUpdatedNotes') }
            if ($wn -and $script:SIWindow) {
                $script:SIWhatsNewText = (Get-SICommunityText 'WhatsNew') -f [string]$state.JustUpdated, $wn
                [void]$script:SIWindow.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::ApplicationIdle, [action]{
                    try { Show-SIInfoBox -Text $script:SIWhatsNewText } catch { }
                })
            }
            $state.PSObject.Properties.Remove('JustUpdated')
            Save-SICommunityState -State $state
        }
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $client = [System.Net.WebClient]::new()
        $client.Encoding = [System.Text.Encoding]::UTF8
        $script:SIUpdateTask  = $client.DownloadStringTaskAsync(((Get-SIUpdateBase) + 'version.json'))
        $client2 = [System.Net.WebClient]::new()
        $client2.Encoding = [System.Text.Encoding]::UTF8
        $script:SICatalogTask = $client2.DownloadStringTaskAsync(((Get-SIPresetsBase) + 'catalog.json'))
        $script:SIUpdateTicks = 0
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2)
        $null = $timer.Add_Tick({
            $task = $script:SIUpdateTask
            $script:SIUpdateTicks++
            $ctask = $script:SICatalogTask
            if ((($task -and -not $task.IsCompleted) -or ($ctask -and -not $ctask.IsCompleted)) -and $script:SIUpdateTicks -lt 15) { return }
            # The question waits until the start-up work (restore point, backup) is over.
            if ($task -and $task.IsCompleted -and -not $script:SIPrepared -and $script:SIUpdateTicks -lt 150) { return }
            try { $script:SIUpdateTimer.Stop() } catch { }
            $script:SIUpdateTask = $null
            $script:SICatalogTask = $null
            $ok = [System.Threading.Tasks.TaskStatus]::RanToCompletion
            if ($task -and $task.Status -eq $ok) {
                try {
                    $manifest = $task.Result | ConvertFrom-Json
                    if (Test-SIUpdateNewer -Manifest $manifest) {
                        Write-SILog -Component 'Update' -Message "SIGAME $($manifest.Version) is on GitHub, this copy is $script:SIGameVersion."
                        if (Invoke-SIUpdateOffer -Manifest $manifest -Quiet) { return }
                    }
                } catch { }
            }
            if ($ctask -and $ctask.Status -eq $ok) {
                try { Update-SIPresetLibrary -Auto -RemoteText ([string]$ctask.Result) } catch { }
            }
        })
        $script:SIUpdateTimer = $timer
        $timer.Start()
    } catch { }
}

function Test-SIPresetFound {
    <#
    .SYNOPSIS
        Found = the preset's folder exists OR a game card of this PC matches the
        preset's Match (Steam/Epic/GOG games in any library folder count too).
    #>
    param($Entry)
    if (Test-SIPresetDetected -Entry $Entry) { return $true }
    if (-not $Entry.Match) { return $false }
    foreach ($g in @($script:SIGameLibrary)) {
        $hay = @([string]$g.Name, [System.IO.Path]::GetFileName([string]$g.Exe),
                 [System.IO.Path]::GetFileName([string]$g.Folder)) -join ' | '
        if ($hay -match [string]$Entry.Match) { return $true }
    }
    return $false
}

function Show-SIPresetsWindow {
    <#
    .SYNOPSIS
        The SI PRESETS list: search box, the games of this PC first, APPLIED
        badge on the presets that are on (press APPLY again to Undo).
    #>
    param([switch]$NoShow)  # NoShow: build only (tests and screenshots)
    $c = $script:SIColors
    $w = [System.Windows.Window]::new()
    $w.Title = (Get-SICommunityText 'PresetsTitle')
    $w.Width = 600
    $w.SizeToContent = 'Height'
    $w.MaxHeight = 700
    $w.WindowStartupLocation = 'CenterOwner'
    if ($script:SIWindow) { $w.Owner = $script:SIWindow }
    $w.Background = Get-SIBrush $c.Background
    $root = [System.Windows.Controls.StackPanel]::new()
    $root.Margin = [System.Windows.Thickness]::new(16)

    $intro = [System.Windows.Controls.TextBlock]::new()
    $intro.Text = (Get-SICommunityText 'PresetsIntro')
    $intro.Foreground = Get-SIBrush $c.Muted
    $intro.TextWrapping = 'Wrap'
    $intro.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    [void]$root.Children.Add($intro)

    # search: a hint drawn under a transparent box (no placeholder in WPF)
    $sGrid = [System.Windows.Controls.Grid]::new()
    $sGrid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $hint = [System.Windows.Controls.TextBlock]::new()
    $hint.Text = (Get-SICommunityText 'PresetsSearch')
    $hint.Foreground = Get-SIBrush $c.Muted
    $hint.Margin = [System.Windows.Thickness]::new(9, 6, 0, 0)
    $hint.IsHitTestVisible = $false
    $box = [System.Windows.Controls.TextBox]::new()
    $box.Height = 28
    $box.Padding = [System.Windows.Thickness]::new(5, 4, 5, 0)
    $box.Background = [System.Windows.Media.Brushes]::Transparent
    $box.Foreground = Get-SIBrush $c.Text
    $box.CaretBrush = Get-SIBrush $c.Text
    $box.BorderBrush = Get-SIBrush $c.BorderGold
    $back = [System.Windows.Controls.Border]::new()
    $back.Background = Get-SIBrush $c.PanelAlt
    $back.CornerRadius = [System.Windows.CornerRadius]::new(4)
    [void]$sGrid.Children.Add($back)
    [void]$sGrid.Children.Add($hint)
    [void]$sGrid.Children.Add($box)
    [void]$root.Children.Add($sGrid)

    $list = [System.Windows.Controls.StackPanel]::new()
    $scroll = [System.Windows.Controls.ScrollViewer]::new()
    $scroll.MaxHeight = 480
    $scroll.VerticalScrollBarVisibility = 'Auto'
    $scroll.Content = $list
    [void]$root.Children.Add($scroll)

    # found once per window (folder checks), the games of this PC first, then A-Z
    $all = @(foreach ($e in (Get-SIPresetCatalog)) { [pscustomobject]@{ Entry = $e; Found = (Test-SIPresetFound -Entry $e) } })
    $all = @($all | Sort-Object -Property @{ Expression = { -not $_.Found } }, @{ Expression = { [string]$_.Entry.Game } })
    $script:SIPresetsRows = $all
    $script:SIPresetsList = $list
    $script:SIPresetsWin = $w

    $fill = {
        param([string]$Query)
        $c = $script:SIColors
        $list = $script:SIPresetsList
        $list.Children.Clear()
        $applied = @()
        try { $applied = @((Get-SICommunityState).Applied.PSObject.Properties.Name) } catch { }
        $shown = 0
        foreach ($item in $script:SIPresetsRows) {
            $e = $item.Entry
            if ($Query -and ("$($e.Title) $($e.Game)" -notlike "*$Query*")) { continue }
            $shown++
            $isOn = ($applied -contains [string]$e.Id)
            $row = [System.Windows.Controls.Border]::new()
            $row.Background = Get-SIBrush $c.PanelAlt
            $row.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $row.Padding = [System.Windows.Thickness]::new(10, 8, 10, 8)
            $row.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
            if ($isOn) { $row.BorderBrush = Get-SIBrush $c.Ok; $row.BorderThickness = [System.Windows.Thickness]::new(1) }
            $dock = [System.Windows.Controls.DockPanel]::new()
            $btn = New-SIStyleButton -Text (Get-SICommunityText 'PresetApply') -StyleKey 'AccentButton' -Window $script:SIPresetsWin -Width 96
            $btn.Height = 28
            $btn.VerticalAlignment = 'Center'
            [System.Windows.Controls.DockPanel]::SetDock($btn, 'Right')
            $captured = $e
            $null = $btn.Add_Click({
                Invoke-SIGamePreset -Entry $captured
                & $script:SIPresetsFill $script:SIPresetsQuery
            }.GetNewClosure())
            [void]$dock.Children.Add($btn)
            $txt = [System.Windows.Controls.StackPanel]::new()
            $head = [System.Windows.Controls.WrapPanel]::new()
            $t1 = [System.Windows.Controls.TextBlock]::new()
            $t1.Text = "$($e.Title)  -  $($e.Game)"
            $t1.FontWeight = 'SemiBold'
            $t1.Foreground = Get-SIBrush $c.Text
            $t1.TextWrapping = 'Wrap'
            [void]$head.Children.Add($t1)
            if ($isOn) {
                $badge = [System.Windows.Controls.Border]::new()
                $badge.Background = Get-SIBrush $c.Ok
                $badge.CornerRadius = [System.Windows.CornerRadius]::new(3)
                $badge.Padding = [System.Windows.Thickness]::new(5, 0, 5, 0)
                $badge.Margin = [System.Windows.Thickness]::new(8, 1, 0, 0)
                $bt = [System.Windows.Controls.TextBlock]::new()
                $bt.Text = (Get-SICommunityText 'PresetApplied')
                $bt.FontSize = 10
                $bt.FontWeight = 'Bold'
                $bt.Foreground = [System.Windows.Media.Brushes]::Black
                $badge.Child = $bt
                [void]$head.Children.Add($badge)
            }
            [void]$txt.Children.Add($head)
            $t2 = [System.Windows.Controls.TextBlock]::new()
            $t2.Text = if ($item.Found) { (Get-SICommunityText 'PresetFound') } else { (Get-SICommunityText 'PresetNotFound') }
            $t2.Foreground = if ($item.Found) { Get-SIBrush $c.Ok } else { Get-SIBrush $c.Off }
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
        if ($shown -eq 0) {
            $none = [System.Windows.Controls.TextBlock]::new()
            $none.Text = (Get-SICommunityText 'PresetsNone')
            $none.Foreground = Get-SIBrush $c.Muted
            $none.Margin = [System.Windows.Thickness]::new(4, 6, 0, 6)
            [void]$list.Children.Add($none)
        }
    }
    $script:SIPresetsFill = $fill
    $script:SIPresetsQuery = ''
    & $fill ''
    $null = $box.Add_TextChanged({
        param($s, $ev)
        $q = ([string]$s.Text).Trim()
        $script:SIPresetsQuery = $q
        $hint.Visibility = if ($s.Text) { 'Collapsed' } else { 'Visible' }
        & $script:SIPresetsFill $q
    }.GetNewClosure())

    $bar = [System.Windows.Controls.WrapPanel]::new()
    $bar.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    $bUpd = New-SIStyleButton -Text (Get-SICommunityText 'PresetsUpdate') -StyleKey 'GhostButton' -Window $w
    $bUpd.Height = 28
    $bUpd.Padding = [System.Windows.Thickness]::new(10, 0, 10, 0)
    $null = $bUpd.Add_Click({ param($s, $ev) [System.Windows.Window]::GetWindow($s).Close(); Update-SIPresetLibrary })
    [void]$bar.Children.Add($bUpd)
    $bReq = New-SIStyleButton -Text (Get-SICommunityText 'BtnFeedback') -StyleKey 'GhostButton' -Window $w
    $bReq.Height = 28
    $bReq.Padding = [System.Windows.Thickness]::new(10, 0, 10, 0)
    $bReq.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    $null = $bReq.Add_Click({ param($s, $ev) [System.Windows.Window]::GetWindow($s).Close(); Invoke-SIRequestGame })
    [void]$bar.Children.Add($bReq)
    [void]$root.Children.Add($bar)

    $w.Content = $root
    $null = $w.Add_ContentRendered({ $box.Focus() | Out-Null }.GetNewClosure())
    if ($NoShow) { return $w }
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
