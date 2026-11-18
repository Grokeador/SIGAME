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
        FpsUndoAsk  = "The FPS went DOWN after SI PRESET {0}.`n`nPut your original config back now (Undo)? Then restart the game and measure again."
        FpsUndoDone = 'SI PRESET {0} undone: your original config is back. Restart the game and measure again.'
        FpsCard     = "`n`nResult card saved in {0} and copied: paste it in Discord or Reddit with Ctrl+V."
        FpsBoundGPU = "`n`nBOTTLENECK: GPU (the graphics card is busy {0}% of each frame). Lower resolution, shadows or upscaling quality to gain FPS; CPU tweaks will not help."
        FpsBoundCPU = "`n`nBOTTLENECK: CPU or an FPS cap (the graphics card is busy only {0}% of each frame). Check FPS cap / V-Sync first; higher graphics settings cost almost no FPS here."
        FpsBoundBal = "`n`nBOTTLENECK: balanced (the graphics card is busy {0}% of each frame)."
        FpsInput    = "`nInput to photon: {0} ms (median, from your key and mouse presses during the measure)."
        FpsAutoAsk  = "Measure FPS automatically every time you start a game with PLAY?`n`nSIGAME waits 90 s for the game to load, measures 60 s with no popup, then shows a short notice and saves the result card. YES = on, NO = off (the FPS button still works)."
        FpsAutoDone = '{0}: {1} FPS average, {2} FPS 1% low.'
        FpsKeyStart = '{0}: measuring {1} s, keep playing.'
        FpsKeyNoGame = 'No game of your SIGAME list is running.'
        FpsKeyNoTool = 'Press FPS in SIGAME once first, to get PresentMon.'
        FpsAutoVBetter = 'FASTER than last time.'
        FpsAutoVWorse  = 'SLOWER than last time: when you close the game, SIGAME offers to Undo the presets added since then.'
        FpsAutoVMixed  = 'Mixed vs last time.'
        FpsAutoVNoise  = 'No real change vs last time.'
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
        FpsUndoAsk  = "Gli FPS sono SCESI dopo il SI PRESET {0}.`n`nRimettere adesso la tua configurazione originale (Undo)? Poi riavvia il gioco e misura di nuovo."
        FpsUndoDone = 'SI PRESET {0} annullato: la tua configurazione originale e'' tornata. Riavvia il gioco e misura di nuovo.'
        FpsCard     = "`n`nScheda risultato salvata in {0} e copiata: incollala su Discord o Reddit con Ctrl+V."
        FpsBoundGPU = "`n`nCOLLO DI BOTTIGLIA: GPU (la scheda video lavora il {0}% di ogni frame). Abbassa risoluzione, ombre o qualita' dell'upscaling per guadagnare FPS; i tweak della CPU non aiutano."
        FpsBoundCPU = "`n`nCOLLO DI BOTTIGLIA: CPU o un limite FPS (la scheda video lavora solo il {0}% di ogni frame). Controlla prima limite FPS / V-Sync; qui la grafica piu' alta non costa quasi FPS."
        FpsBoundBal = "`n`nCOLLO DI BOTTIGLIA: bilanciato (la scheda video lavora il {0}% di ogni frame)."
        FpsInput    = "`nDall'input allo schermo: {0} ms (mediana, dai tuoi tasti e clic durante la misura)."
        FpsAutoAsk  = "Misurare gli FPS in automatico ogni volta che avvii un gioco con GIOCA?`n`nSIGAME aspetta 90 s che il gioco carichi, misura 60 s senza popup, poi mostra un breve avviso e salva la scheda risultato. SI' = attivo, NO = spento (il tasto FPS funziona sempre)."
        FpsAutoDone = '{0}: {1} FPS media, {2} FPS 1% low.'
        FpsKeyStart = '{0}: misuro {1} s, continua a giocare.'
        FpsKeyNoGame = 'Nessun gioco della tua lista SIGAME e'' in esecuzione.'
        FpsKeyNoTool = 'Premi prima una volta FPS in SIGAME, per scaricare PresentMon.'
        FpsAutoVBetter = "PIU' VELOCE dell'ultima volta."
        FpsAutoVWorse  = "PIU' LENTO dell'ultima volta: quando chiudi il gioco, SIGAME propone di annullare i preset aggiunti da allora."
        FpsAutoVMixed  = "Misto rispetto all'ultima volta."
        FpsAutoVNoise  = "Nessun cambiamento reale rispetto all'ultima volta."
    }
}
$script:SIFpsText['pt-BR'] = @{
    BtnFps      = "FPS"
    FpsTip      = "Mede o FPS deste jogo enquanto voce joga (60 s). Meca antes e depois de um SI PRESET."
    FpsGetTool  = "Para medir o FPS, o SIGAME baixa o PresentMon (Intel, codigo aberto MIT, 1 MB) da pagina oficial no GitHub e confere a impressao digital SHA-256.`n`nBaixar agora?"
    FpsToolBad  = "O download do PresentMon falhou ou a impressao digital nao confere: nada foi executado."
    FpsNotRun   = "{0} nao esta aberto.`n`nAbra o jogo e clique em FPS: o SIGAME espera {1} s para voce voltar ao jogo e mede {2} s enquanto voce joga."
    FpsStart    = "Medicao de FPS de {0}`n`nVolte ao jogo agora e jogue normalmente. Comeca em {1} s e dura {2} s. O SIGAME mostra o resultado no final."
    FpsBusy     = "Ja existe uma medicao de FPS em andamento."
    FpsStatus   = "Medindo o FPS de {0}... volte ao jogo e jogue."
    FpsNoFrames = "Nenhum frame de {0}: deixe o jogo na tela durante a medicao e tente de novo."
    FpsResult   = "{0}`n`nMedia: {1} FPS`n1% low: {2} FPS`n({3} frames em {4} s)"
    FpsCompare  = "`n`nMedicao anterior ({0}): {1} FPS de media, {2} FPS 1% low`nDiferenca: {3} na media, {4} no 1% low"
    FpsPresets  = "`n`nSI PRESETS ativos: {0}"
    FpsShared   = "`n`nEstatisticas anonimas ON: estes numeros vao para o SI NEWS com o modelo de CPU/GPU (sem arquivos, sem id)."
    FpsTitle    = "SIGAME FPS"
    FpsPro      = "`n0.1% low: {0} FPS`nFrame mais lento: {1} ms`nTravadas: {2} (frames mais lentos que 2x o frame mediano)"
    FpsProShort = "`nFrame mais lento: {0} ms`nTravadas: {1} (frames mais lentos que 2x o frame mediano)"
    FpsStutCmp  = "`nTravadas antes: {0}, agora: {1}"
    FpsVNoise   = "`n`nVEREDITO: nenhuma mudanca real. O SIGAME so conta uma mudanca a partir de {0}%, na media ou no 1% low."
    FpsVUnsteady = "`n`nVEREDITO: nenhuma mudanca real que se possa afirmar. Dentro de uma mesma captura, sem mudar nada, a media variou {0}% e o 1% low {1}%: uma diferenca menor nao conta. Meca de novo na mesma cena sem mais nada aberto."
    FpsVBetter  = "`n`nVEREDITO: MAIS RAPIDO que a medicao anterior."
    FpsVWorse   = "`n`nVEREDITO: MAIS LENTO que a medicao anterior. Desfaca o ultimo preset ou ajuste e meca de novo."
    FpsVMixed   = "`n`nVEREDITO: misto. Media e 1% low foram em direcoes opostas: meca de novo no mesmo lugar do jogo."
    FpsBest     = "`n`nMelhor das suas ultimas {0} medicoes: {1} FPS de media, {2} FPS 1% low ({3}){4}"
    FpsBestSet  = ", SI PRESETS: {0}"
    FpsUndoAsk  = "O FPS CAIU depois do SI PRESET {0}.`n`nVoltar a sua config original agora (Desfazer)? Depois reinicie o jogo e meca de novo."
    FpsUndoDone = "SI PRESET {0} desfeito: sua config original voltou. Reinicie o jogo e meca de novo."
    FpsCard     = "`n`nCartao do resultado salvo em {0} e copiado: cole no Discord ou Reddit com Ctrl+V."
    FpsBoundGPU = "`n`nGARGALO: GPU (a placa de video fica ocupada {0}% de cada frame). Baixe resolucao, sombras ou a qualidade do upscaling para ganhar FPS; ajustes de CPU nao vao ajudar."
    FpsBoundCPU = "`n`nGARGALO: CPU ou limite de FPS (a placa de video fica ocupada so {0}% de cada frame). Confira primeiro o limite de FPS / V-Sync; graficos mais altos quase nao custam FPS aqui."
    FpsBoundBal = "`n`nGARGALO: equilibrado (a placa de video fica ocupada {0}% de cada frame)."
    FpsInput    = "`nInput to photon: {0} ms (mediana, das teclas e cliques durante a medicao)."
    FpsAutoAsk  = "Medir o FPS automaticamente toda vez que voce abrir um jogo com JOGAR?`n`nO SIGAME espera 90 s o jogo carregar, mede 60 s sem popup, depois mostra um aviso curto e salva o cartao do resultado. SIM = ligado, NAO = desligado (o botao FPS continua funcionando)."
    FpsAutoDone = "{0}: {1} FPS de media, {2} FPS 1% low."
    FpsKeyStart = "{0}: medindo {1} s, continue jogando."
    FpsKeyNoGame = "Nenhum jogo da sua lista do SIGAME esta aberto."
    FpsKeyNoTool = "Clique em FPS no SIGAME uma vez antes, para baixar o PresentMon."
    FpsAutoVBetter = "MAIS RAPIDO que da ultima vez."
    FpsAutoVWorse  = "MAIS LENTO que da ultima vez: quando voce fechar o jogo, o SIGAME oferece Desfazer os presets adicionados desde entao."
    FpsAutoVMixed  = "Misto em relacao a ultima vez."
    FpsAutoVNoise  = "Nenhuma mudanca real em relacao a ultima vez."
}
$script:SIFpsText['es'] = @{
    BtnFps      = "FPS"
    FpsTip      = "Mide los FPS de este juego mientras juegas (60 s). Mide antes y despues de un SI PRESET."
    FpsGetTool  = "Para medir los FPS, SIGAME descarga PresentMon (Intel, codigo abierto MIT, 1 MB) de su pagina oficial de GitHub y comprueba su huella SHA-256.`n`nDescargarlo ahora?"
    FpsToolBad  = "La descarga de PresentMon fallo o su huella no coincide: no se ejecuto nada."
    FpsNotRun   = "{0} no esta abierto.`n`nAbre el juego y pulsa FPS: SIGAME espera {1} s para que vuelvas al juego y mide {2} s mientras juegas."
    FpsStart    = "Medicion de FPS de {0}`n`nVuelve al juego ahora y juega normal. Empieza en {1} s y dura {2} s. SIGAME muestra el resultado al terminar."
    FpsBusy     = "Ya hay una medicion de FPS en curso."
    FpsStatus   = "Midiendo los FPS de {0}... vuelve al juego y juega."
    FpsNoFrames = "Ningun frame de {0}: deja el juego en pantalla mientras mide y prueba otra vez."
    FpsResult   = "{0}`n`nMedia: {1} FPS`n1% low: {2} FPS`n({3} frames en {4} s)"
    FpsCompare  = "`n`nMedicion anterior ({0}): {1} FPS de media, {2} FPS 1% low`nCambio: {3} en la media, {4} en el 1% low"
    FpsPresets  = "`n`nSI PRESETS activos: {0}"
    FpsShared   = "`n`nEstadisticas anonimas ON: estos numeros van a SI NEWS con el modelo de CPU/GPU (sin archivos, sin id)."
    FpsTitle    = "SIGAME FPS"
    FpsPro      = "`n0.1% low: {0} FPS`nFrame mas lento: {1} ms`nTirones: {2} (frames mas lentos que 2x el frame mediano)"
    FpsProShort = "`nFrame mas lento: {0} ms`nTirones: {1} (frames mas lentos que 2x el frame mediano)"
    FpsStutCmp  = "`nTirones antes: {0}, ahora: {1}"
    FpsVNoise   = "`n`nVEREDICTO: ningun cambio real. SIGAME solo cuenta un cambio desde {0}%, en la media o en el 1% low."
    FpsVUnsteady = "`n`nVEREDICTO: ningun cambio real que se pueda afirmar. Dentro de una misma captura, sin cambiar nada, la media se movio {0}% y el 1% low {1}%: una diferencia menor no cuenta. Mide otra vez en la misma escena sin nada mas abierto."
    FpsVBetter  = "`n`nVEREDICTO: MAS RAPIDO que la medicion anterior."
    FpsVWorse   = "`n`nVEREDICTO: MAS LENTO que la medicion anterior. Deshaz el ultimo preset o ajuste y mide otra vez."
    FpsVMixed   = "`n`nVEREDICTO: mixto. La media y el 1% low fueron en direcciones opuestas: mide otra vez en el mismo lugar del juego."
    FpsBest     = "`n`nMejor de tus ultimas {0} mediciones: {1} FPS de media, {2} FPS 1% low ({3}){4}"
    FpsBestSet  = ", SI PRESETS: {0}"
    FpsUndoAsk  = "Los FPS BAJARON despues del SI PRESET {0}.`n`nVolver a tu config original ahora (Deshacer)? Luego reinicia el juego y mide otra vez."
    FpsUndoDone = "SI PRESET {0} deshecho: tu config original volvio. Reinicia el juego y mide otra vez."
    FpsCard     = "`n`nTarjeta del resultado guardada en {0} y copiada: pegala en Discord o Reddit con Ctrl+V."
    FpsBoundGPU = "`n`nCUELLO DE BOTELLA: GPU (la tarjeta grafica esta ocupada {0}% de cada frame). Baja resolucion, sombras o calidad del escalado para ganar FPS; los ajustes de CPU no ayudaran."
    FpsBoundCPU = "`n`nCUELLO DE BOTELLA: CPU o limite de FPS (la tarjeta grafica esta ocupada solo {0}% de cada frame). Revisa primero el limite de FPS / V-Sync; graficos mas altos casi no cuestan FPS aqui."
    FpsBoundBal = "`n`nCUELLO DE BOTELLA: equilibrado (la tarjeta grafica esta ocupada {0}% de cada frame)."
    FpsInput    = "`nInput to photon: {0} ms (mediana, de tus teclas y clics durante la medicion)."
    FpsAutoAsk  = "Medir los FPS automaticamente cada vez que abras un juego con JUGAR?`n`nSIGAME espera 90 s a que cargue el juego, mide 60 s sin popup, luego muestra un aviso corto y guarda la tarjeta del resultado. SI = activado, NO = desactivado (el boton FPS sigue funcionando)."
    FpsAutoDone = "{0}: {1} FPS de media, {2} FPS 1% low."
    FpsKeyStart = "{0}: midiendo {1} s, sigue jugando."
    FpsKeyNoGame = "Ningun juego de tu lista de SIGAME esta abierto."
    FpsKeyNoTool = "Pulsa FPS en SIGAME una vez antes, para descargar PresentMon."
    FpsAutoVBetter = "MAS RAPIDO que la ultima vez."
    FpsAutoVWorse  = "MAS LENTO que la ultima vez: al cerrar el juego, SIGAME ofrece Deshacer los presets agregados desde entonces."
    FpsAutoVMixed  = "Mixto respecto a la ultima vez."
    FpsAutoVNoise  = "Ningun cambio real respecto a la ultima vez."
}
$script:SIFpsText['de'] = @{
    BtnFps      = "FPS"
    FpsTip      = "Misst die FPS dieses Spiels waehrend du spielst (60 s). Miss vor und nach einem SI PRESET."
    FpsGetTool  = "Zum Messen der FPS laedt SIGAME PresentMon (Intel, Open Source MIT, 1 MB) von der offiziellen GitHub-Seite und prueft den SHA-256-Fingerabdruck.`n`nJetzt herunterladen?"
    FpsToolBad  = "Der Download von PresentMon ist fehlgeschlagen oder der Fingerabdruck passt nicht: nichts wurde ausgefuehrt."
    FpsNotRun   = "{0} laeuft nicht.`n`nStarte das Spiel und klicke auf FPS: SIGAME wartet {1} s, damit du ins Spiel zurueckkehrst, und misst dann {2} s waehrend du spielst."
    FpsStart    = "FPS-Messung von {0}`n`nGeh jetzt zurueck ins Spiel und spiel normal. Start in {1} s, Dauer {2} s. SIGAME zeigt das Ergebnis am Ende."
    FpsBusy     = "Eine FPS-Messung laeuft bereits."
    FpsStatus   = "Messe FPS von {0}... geh zurueck ins Spiel und spiel."
    FpsNoFrames = "Keine Frames von {0}: lass das Spiel waehrend der Messung im Vordergrund und versuch es erneut."
    FpsResult   = "{0}`n`nDurchschnitt: {1} FPS`n1% low: {2} FPS`n({3} Frames in {4} s)"
    FpsCompare  = "`n`nVorherige Messung ({0}): {1} FPS Durchschnitt, {2} FPS 1% low`nAenderung: {3} Durchschnitt, {4} 1% low"
    FpsPresets  = "`n`nAktive SI PRESETS: {0}"
    FpsShared   = "`n`nAnonyme Statistik AN: diese Werte gehen mit deinem CPU/GPU-Modell an SI NEWS (keine Dateien, keine ID)."
    FpsTitle    = "SIGAME FPS"
    FpsPro      = "`n0.1% low: {0} FPS`nLangsamster Frame: {1} ms`nRuckler: {2} (Frames langsamer als 2x der Median-Frame)"
    FpsProShort = "`nLangsamster Frame: {0} ms`nRuckler: {1} (Frames langsamer als 2x der Median-Frame)"
    FpsStutCmp  = "`nRuckler vorher: {0}, jetzt: {1}"
    FpsVNoise   = "`n`nERGEBNIS: keine echte Aenderung. SIGAME zaehlt eine Aenderung erst ab {0}%, im Durchschnitt oder beim 1% low."
    FpsVUnsteady = "`n`nERGEBNIS: keine sicher erkennbare Aenderung. Innerhalb einer Aufnahme, ohne etwas zu aendern, schwankte der Durchschnitt um {0}% und der 1% low um {1}%: ein kleinerer Unterschied zaehlt nicht. Miss erneut in derselben Szene ohne andere offene Programme."
    FpsVBetter  = "`n`nERGEBNIS: SCHNELLER als die vorherige Messung."
    FpsVWorse   = "`n`nERGEBNIS: LANGSAMER als die vorherige Messung. Mach das letzte Preset oder die letzte Einstellung rueckgaengig und miss erneut."
    FpsVMixed   = "`n`nERGEBNIS: gemischt. Durchschnitt und 1% low haben sich gegensaetzlich bewegt: miss erneut an derselben Stelle im Spiel."
    FpsBest     = "`n`nBeste deiner letzten {0} Messungen: {1} FPS Durchschnitt, {2} FPS 1% low ({3}){4}"
    FpsBestSet  = ", SI PRESETS: {0}"
    FpsUndoAsk  = "Die FPS sind nach SI PRESET {0} GESUNKEN.`n`nJetzt deine Original-Config zurueckholen (Rueckgaengig)? Dann starte das Spiel neu und miss erneut."
    FpsUndoDone = "SI PRESET {0} rueckgaengig gemacht: deine Original-Config ist zurueck. Starte das Spiel neu und miss erneut."
    FpsCard     = "`n`nErgebniskarte gespeichert in {0} und kopiert: fuege sie mit Strg+V in Discord oder Reddit ein."
    FpsBoundGPU = "`n`nENGPASS: GPU (die Grafikkarte ist {0}% jedes Frames beschaeftigt). Senke Aufloesung, Schatten oder Upscaling-Qualitaet fuer mehr FPS; CPU-Tweaks helfen nicht."
    FpsBoundCPU = "`n`nENGPASS: CPU oder FPS-Limit (die Grafikkarte ist nur {0}% jedes Frames beschaeftigt). Pruefe zuerst FPS-Limit / V-Sync; hoehere Grafik kostet hier kaum FPS."
    FpsBoundBal = "`n`nENGPASS: ausgeglichen (die Grafikkarte ist {0}% jedes Frames beschaeftigt)."
    FpsInput    = "`nInput to photon: {0} ms (Median, aus deinen Tasten- und Mausklicks waehrend der Messung)."
    FpsAutoAsk  = "FPS automatisch messen, jedes Mal wenn du ein Spiel mit SPIELEN startest?`n`nSIGAME wartet 90 s bis das Spiel geladen ist, misst 60 s ohne Popup, zeigt dann einen kurzen Hinweis und speichert die Ergebniskarte. JA = an, NEIN = aus (der FPS-Button funktioniert weiter)."
    FpsAutoDone = "{0}: {1} FPS Durchschnitt, {2} FPS 1% low."
    FpsKeyStart = "{0}: messe {1} s, spiel weiter."
    FpsKeyNoGame = "Kein Spiel aus deiner SIGAME-Liste laeuft."
    FpsKeyNoTool = "Klicke zuerst einmal auf FPS in SIGAME, um PresentMon zu laden."
    FpsAutoVBetter = "SCHNELLER als beim letzten Mal."
    FpsAutoVWorse  = "LANGSAMER als beim letzten Mal: wenn du das Spiel schliesst, bietet SIGAME an, die seitdem hinzugefuegten Presets rueckgaengig zu machen."
    FpsAutoVMixed  = "Gemischt im Vergleich zum letzten Mal."
    FpsAutoVNoise  = "Keine echte Aenderung zum letzten Mal."
}
$script:SIFpsText['fr'] = @{
    BtnFps      = "FPS"
    FpsTip      = "Mesure les FPS de ce jeu pendant que tu joues (60 s). Mesure avant et apres un SI PRESET."
    FpsGetTool  = "Pour mesurer les FPS, SIGAME telecharge PresentMon (Intel, open source MIT, 1 Mo) depuis sa page GitHub officielle et verifie son empreinte SHA-256.`n`nLe telecharger maintenant ?"
    FpsToolBad  = "Le telechargement de PresentMon a echoue ou son empreinte ne correspond pas : rien n'a ete lance."
    FpsNotRun   = "{0} n'est pas lance.`n`nLance le jeu puis clique sur FPS : SIGAME attend {1} s pour que tu reviennes au jeu, puis mesure {2} s pendant que tu joues."
    FpsStart    = "Mesure FPS de {0}`n`nRetourne au jeu maintenant et joue normalement. Debut dans {1} s, duree {2} s. SIGAME affiche le resultat a la fin."
    FpsBusy     = "Une mesure FPS est deja en cours."
    FpsStatus   = "Mesure des FPS de {0}... retourne au jeu et joue."
    FpsNoFrames = "Aucune image de {0} : garde le jeu a l'ecran pendant la mesure, puis reessaie."
    FpsResult   = "{0}`n`nMoyenne : {1} FPS`n1% low : {2} FPS`n({3} images en {4} s)"
    FpsCompare  = "`n`nMesure precedente ({0}) : {1} FPS de moyenne, {2} FPS 1% low`nChangement : {3} moyenne, {4} 1% low"
    FpsPresets  = "`n`nSI PRESETS actifs : {0}"
    FpsShared   = "`n`nStatistiques anonymes ON : ces chiffres vont a SI NEWS avec ton modele de CPU/GPU (aucun fichier, aucun id)."
    FpsTitle    = "SIGAME FPS"
    FpsPro      = "`n0.1% low : {0} FPS`nImage la plus lente : {1} ms`nSaccades : {2} (images plus lentes que 2x l'image mediane)"
    FpsProShort = "`nImage la plus lente : {0} ms`nSaccades : {1} (images plus lentes que 2x l'image mediane)"
    FpsStutCmp  = "`nSaccades avant : {0}, maintenant : {1}"
    FpsVNoise   = "`n`nVERDICT : aucun vrai changement. SIGAME ne compte un changement qu'a partir de {0}%, en moyenne ou en 1% low."
    FpsVUnsteady = "`n`nVERDICT : aucun vrai changement mesurable. Dans une meme capture, sans rien changer, la moyenne a varie de {0}% et le 1% low de {1}% : une difference plus petite ne compte pas. Mesure a nouveau dans la meme scene sans rien d'autre d'ouvert."
    FpsVBetter  = "`n`nVERDICT : PLUS RAPIDE que la mesure precedente."
    FpsVWorse   = "`n`nVERDICT : PLUS LENT que la mesure precedente. Annule le dernier preset ou reglage et mesure a nouveau."
    FpsVMixed   = "`n`nVERDICT : mitige. La moyenne et le 1% low sont alles en sens opposes : mesure a nouveau au meme endroit du jeu."
    FpsBest     = "`n`nMeilleure de tes {0} dernieres mesures : {1} FPS de moyenne, {2} FPS 1% low ({3}){4}"
    FpsBestSet  = ", SI PRESETS : {0}"
    FpsUndoAsk  = "Les FPS ont BAISSE apres le SI PRESET {0}.`n`nRemettre ta config d'origine maintenant (Annuler) ? Puis relance le jeu et mesure a nouveau."
    FpsUndoDone = "SI PRESET {0} annule : ta config d'origine est revenue. Relance le jeu et mesure a nouveau."
    FpsCard     = "`n`nCarte du resultat enregistree dans {0} et copiee : colle-la sur Discord ou Reddit avec Ctrl+V."
    FpsBoundGPU = "`n`nGOULOT : GPU (la carte graphique est occupee {0}% de chaque image). Baisse la resolution, les ombres ou la qualite de l'upscaling pour gagner des FPS ; les reglages CPU n'aideront pas."
    FpsBoundCPU = "`n`nGOULOT : CPU ou limite de FPS (la carte graphique n'est occupee que {0}% de chaque image). Verifie d'abord la limite de FPS / V-Sync ; des graphismes plus hauts ne coutent presque rien ici."
    FpsBoundBal = "`n`nGOULOT : equilibre (la carte graphique est occupee {0}% de chaque image)."
    FpsInput    = "`nInput to photon : {0} ms (mediane, de tes touches et clics pendant la mesure)."
    FpsAutoAsk  = "Mesurer les FPS automatiquement chaque fois que tu lances un jeu avec JOUER ?`n`nSIGAME attend 90 s que le jeu charge, mesure 60 s sans popup, puis affiche un court avis et enregistre la carte du resultat. OUI = active, NON = desactive (le bouton FPS marche toujours)."
    FpsAutoDone = "{0} : {1} FPS de moyenne, {2} FPS 1% low."
    FpsKeyStart = "{0} : mesure de {1} s, continue a jouer."
    FpsKeyNoGame = "Aucun jeu de ta liste SIGAME n'est lance."
    FpsKeyNoTool = "Clique d'abord une fois sur FPS dans SIGAME pour obtenir PresentMon."
    FpsAutoVBetter = "PLUS RAPIDE que la derniere fois."
    FpsAutoVWorse  = "PLUS LENT que la derniere fois : quand tu fermes le jeu, SIGAME propose d'annuler les presets ajoutes depuis."
    FpsAutoVMixed  = "Mitige par rapport a la derniere fois."
    FpsAutoVNoise  = "Aucun vrai changement par rapport a la derniere fois."
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
    $gpu = [System.Collections.Generic.List[double]]::new()
    $inp = [System.Collections.Generic.List[double]]::new()
    $fl = [System.Globalization.NumberStyles]::Float
    foreach ($r in $chain) {
        $v = 0.0
        if ([double]::TryParse([string]$r.MsBetweenPresents, $fl, $inv, [ref]$v) -and $v -gt 0) { $ms.Add($v) }
        $g = 0.0
        if ([double]::TryParse([string]$r.MsGPUBusy, $fl, $inv, [ref]$g) -and $g -gt 0) { $gpu.Add($g) }
        $l = 0.0
        if ([double]::TryParse([string]$r.MsAllInputToPhotonLatency, $fl, $inv, [ref]$l) -and $l -gt 0) { $inp.Add($l) }
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
        # GPU busy share: median GPU busy time / median frame time (PresentMon MsGPUBusy). 0 = not measured.
        GpuShare = $(if ($gpu.Count -ge 50) { $ga = $gpu.ToArray(); [array]::Sort($ga); [math]::Round($ga[[int][math]::Floor($ga.Length / 2)] / $median, 2) } else { 0 })
        # Input to photon (PresentMon MsAllInputToPhotonLatency): median ms, only when the player pressed keys/mouse.
        InputMs  = $(if ($inp.Count -ge 5) { $ia = $inp.ToArray(); [array]::Sort($ia); [math]::Round($ia[[int][math]::Floor($ia.Length / 2)], 1) } else { 0 })
    }
}

function Get-SIFpsBound {
    <#
    .SYNOPSIS
        What holds the FPS back, from the GPU busy share: GPU (the graphics card works >= 90% of each frame),
        CPU (<= 70%: the card waits for the processor, or for an FPS cap / V-Sync), Balanced in between, '' unknown.
    #>
    param([double]$Share)
    if ($Share -le 0) { return '' }
    if ($Share -ge 0.9) { return 'GPU' }
    if ($Share -le 0.7) { return 'CPU' }
    return 'Balanced'
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

function New-SIFpsCard {
    <#
    .SYNOPSIS
        A 1200x630 PNG of one measure (only the measured numbers), saved in Pictures\SIGAME and copied to the
        clipboard, so a player can paste the proof in Discord or Reddit. Returns the path, or $null.
    #>
    param([string]$Name, $St, $Prev, [string]$Verdict, $DeltaAvg, $DeltaLow, [string]$Presets)
    try {
        Add-Type -AssemblyName System.Drawing
        $dir = [System.IO.Path]::Combine([Environment]::GetFolderPath('MyPictures'), 'SIGAME')
        [void][System.IO.Directory]::CreateDirectory($dir)
        $safe = ($Name -replace '[^A-Za-z0-9 _-]', '').Trim()
        if (-not $safe) { $safe = 'game' }
        $path = [System.IO.Path]::Combine($dir, ('{0}-{1}.png' -f $safe, [datetime]::Now.ToString('yyyyMMdd-HHmmss')))

        $bmp = New-Object System.Drawing.Bitmap 1200, 630
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
        $bg   = [System.Drawing.Color]::FromArgb(11, 15, 23)
        $gold = [System.Drawing.Color]::FromArgb(245, 184, 46)
        $grey = [System.Drawing.Color]::FromArgb(150, 160, 175)
        $g.Clear($bg)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush $gold), 0, 0, 1200, 10)
        $fTitle = New-Object System.Drawing.Font 'Segoe UI', 40, ([System.Drawing.FontStyle]::Bold)
        $fBig   = New-Object System.Drawing.Font 'Segoe UI', 64, ([System.Drawing.FontStyle]::Bold)
        $fMid   = New-Object System.Drawing.Font 'Segoe UI', 22
        $fSmall = New-Object System.Drawing.Font 'Segoe UI', 18
        $white = [System.Drawing.Brushes]::White
        $bGold = New-Object System.Drawing.SolidBrush $gold
        $bGrey = New-Object System.Drawing.SolidBrush $grey

        $g.DrawString($Name, $fTitle, $white, 50, 40)
        $g.DrawString(('Measured with PresentMon, {0} s, {1} frames' -f $St.Sec, $St.Frames), $fSmall, $bGrey, 54, 108)
        $cols = @(
            @('AVERAGE FPS', $St.Avg), @('1% LOW', $St.Low1), @('0.1% LOW', $St.Low01), @('STUTTERS', $St.Stutters)
        )
        for ($i = 0; $i -lt $cols.Count; $i++) {
            $x = 50 + $i * 280
            $g.DrawString([string]$cols[$i][1], $fBig, $bGold, $x, 170)
            $g.DrawString($cols[$i][0], $fMid, $bGrey, $x + 6, 268)
        }
        $y = 350
        if ($Prev) {
            $fmt = { param($d) if ($d -ge 0) { "+$d%" } else { "$d%" } }
            $line = [string]::Format([cultureinfo]::InvariantCulture, 'Before: {0} avg, {1} 1% low   ->   change {2} avg, {3} 1% low', $Prev.Avg, $Prev.Low1, (& $fmt $DeltaAvg), (& $fmt $DeltaLow))
            $g.DrawString($line, $fMid, $white, 54, $y)
            $y += 50
            $vText = @{ Better = 'VERDICT: FASTER'; Worse = 'VERDICT: SLOWER'; Mixed = 'VERDICT: MIXED'; Noise = 'VERDICT: NO REAL CHANGE' }[$Verdict]
            if ($vText) { $g.DrawString($vText, $fTitle, $bGold, 50, $y); $y += 70 }
        }
        $bnd = Get-SIFpsBound -Share $St.GpuShare
        $extra = @()
        if ($bnd) { $extra += ('Bottleneck: {0} ({1}% GPU busy)' -f $bnd, [math]::Round(100 * $St.GpuShare)) }
        if ($St.InputMs -gt 0) { $extra += [string]::Format([cultureinfo]::InvariantCulture, 'Input to photon: {0} ms', $St.InputMs) }
        if ($extra.Count) { $g.DrawString(($extra -join '    '), $fMid, $white, 54, $y); $y += 45 }
        if ($Presets) { $g.DrawString(('SI PRESETS: {0}' -f $Presets.Replace(',', ', ')), $fSmall, $bGrey, 54, $y) }
        $g.DrawString('SIGAME by SI NEWS  -  github.com/Grokeador/SIGAME', $fSmall, $bGold, 50, 570)
        $g.DrawString([datetime]::Now.ToString('yyyy-MM-dd'), $fSmall, $bGrey, 1020, 570)
        $g.Dispose()
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()

        try {
            $img = New-Object System.Windows.Media.Imaging.BitmapImage
            $img.BeginInit(); $img.CacheOption = 'OnLoad'; $img.UriSource = New-Object System.Uri $path; $img.EndInit()
            [System.Windows.Clipboard]::SetImage($img)
        } catch { }
        Write-SILog -Component 'FPS' -Message "Result card: $path"
        return $path
    } catch {
        Write-SILog -Level 'WARN' -Component 'FPS' -Message "Result card failed: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-SIFpsAutoUndo {
    <#
    .SYNOPSIS
        After a SLOWER verdict: the SI PRESETS applied between the two measures, which have an Undo, are offered
        for Undo in one click. Nothing is undone without the player's YES.
    #>
    param([string]$Name, [string[]]$Now, [string]$Before)
    $old = @(([string]$Before) -split ',' | Where-Object { $_ })
    $added = @($Now | Where-Object { $_ -and ($old -notcontains $_) })
    foreach ($id in $added) {
        $entry = Get-SIPresetCatalog | Where-Object { [string]$_.Id -eq $id } | Select-Object -First 1
        if (-not $entry -or -not $entry.Undo) { continue }
        if (-not (Show-SIMessage -Window $script:SIWindow -Title (Get-SIFpsText 'FpsTitle') -Text ((Get-SIFpsText 'FpsUndoAsk') -f $entry.Title))) { continue }
        $r = Invoke-SIPresetScript -Entry $entry -Undo
        if ($r.Ok) {
            $state = Get-SICommunityState
            $state.Applied.PSObject.Properties.Remove($id)
            Save-SICommunityState -State $state
            Send-SITelemetry -Event (New-SITelemetryEvent -Kind 'preset_undo' -Preset $id -Message 'auto undo after slower fps')
            [void][System.Windows.MessageBox]::Show($script:SIWindow, ((Get-SIFpsText 'FpsUndoDone') -f $entry.Title), (Get-SIFpsText 'FpsTitle'))
        } else {
            [void][System.Windows.MessageBox]::Show($script:SIWindow, (@($r.Lines) -join "`n"), "SI PRESET $($entry.Title)")
        }
        Write-SILog -Component 'FPS' -Message "Auto undo $id after slower verdict: ok=$($r.Ok)"
    }
}

function Register-SIFpsHotkey {
    <#
    .SYNOPSIS
        Ctrl+Shift+F10, anywhere (also inside the game): measures the game of the list that is running now, 60 s,
        no popup over the game, result in a tray notice. Works when PresentMon is already verified (FPS button once).
    #>
    if ($script:SIFpsHotkeyOn -or -not $script:SIWindow) { return }
    if (-not ('SIGameHotkey' -as [type])) {
        Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class SIGameHotkey {
    [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h, int id, uint mods, uint vk);
    [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr h, int id);
    public const int Id = 0x5347;
    public static event Action Fired;
    public static IntPtr Hook(IntPtr h, int msg, IntPtr w, IntPtr l, ref bool handled) {
        if (msg == 0x0312 && w.ToInt32() == Id) { handled = true; var f = Fired; if (f != null) f(); }
        return IntPtr.Zero;
    }
}
'@
    }
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($script:SIWindow)
    $src = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
    if (-not $src) { return }
    # MOD_CONTROL 0x2 + MOD_SHIFT 0x4 + MOD_NOREPEAT 0x4000, VK_F10 0x79
    if (-not [SIGameHotkey]::RegisterHotKey($helper.Handle, [SIGameHotkey]::Id, 0x4006, 0x79)) {
        Write-SILog -Level 'WARN' -Component 'FPS' -Message 'Ctrl+Shift+F10 is used by another program, no FPS hotkey.'
        return
    }
    $src.AddHook([System.Windows.Interop.HwndSourceHook][SIGameHotkey].GetMethod('Hook').CreateDelegate([System.Windows.Interop.HwndSourceHook]))
    [SIGameHotkey]::add_Fired([Action]{ try { Invoke-SIFpsHotkey } catch { Write-SILog -Level 'WARN' -Component 'FPS' -Message "Hotkey: $($_.Exception.Message)" } })
    $script:SIFpsHotkeyOn = $true
    Write-SILog -Component 'FPS' -Message 'FPS hotkey Ctrl+Shift+F10 ready.'
}

function Invoke-SIFpsHotkey {
    Write-SILog -Component 'FPS' -Message 'Hotkey Ctrl+Shift+F10 pressed.'
    $tell = { param($t) try { Show-SITrayBalloon -Title (Get-SIFpsText 'FpsTitle') -Text $t } catch { } }
    if ($script:SIFpsRun) { & $tell (Get-SIFpsText 'FpsBusy'); return }
    $game = @($script:SIGameLibrary) | Where-Object { $_ -and (Get-SIGameProcess -Game $_) } | Select-Object -First 1
    if (-not $game) { & $tell (Get-SIFpsText 'FpsKeyNoGame'); return }
    $pm = [System.IO.Path]::Combine($script:SIToolsPath, $script:SIPresentMon.File)
    if (-not [System.IO.File]::Exists($pm)) { & $tell (Get-SIFpsText 'FpsKeyNoTool'); return }
    Start-SIFpsMeasure -Game $game -Auto
    if ($script:SIFpsRun) { & $tell ((Get-SIFpsText 'FpsKeyStart') -f $game.Name, $script:SIFpsSeconds) }
}

function Start-SIFpsAutoWatch {
    <#
    .SYNOPSIS
        After PLAY: waits for the game process (up to 5 min), lets it load for 90 s, then measures 60 s with no
        popup over the game. Asked once (YES/NO, saved as AutoFps); works only when PresentMon is already verified.
    #>
    param($Game)
    $state = Get-SICommunityState
    if (-not ($state.PSObject.Properties.Name -contains 'AutoFps')) {
        $yes = Show-SIMessage -Window $script:SIWindow -Title (Get-SIFpsText 'FpsTitle') -Text (Get-SIFpsText 'FpsAutoAsk')
        $state | Add-Member 'AutoFps' ([bool]$yes) -Force
        Save-SICommunityState -State $state
        if ($yes) { [void](Get-SIPresentMonPath) }
    }
    if ($state.AutoFps -ne $true) { return }
    $script:SIFpsWatch = @{ Game = $Game; Since = [datetime]::Now; Found = $null }
    if (-not $script:SIFpsWatchTimer) {
        $script:SIFpsWatchTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:SIFpsWatchTimer.Interval = [TimeSpan]::FromSeconds(5)
        $script:SIFpsWatchTimer.Add_Tick({ Step-SIFpsAutoWatch })
    }
    $script:SIFpsWatchTimer.Start()
    Write-SILog -Component 'FPS' -Message "Auto measure armed: $($Game.Name)"
}

function Step-SIFpsAutoWatch {
    $w = $script:SIFpsWatch
    if (-not $w) { $script:SIFpsWatchTimer.Stop(); return }
    $now = [datetime]::Now
    if ($w.UndoAfterExit) {
        if (Get-SIGameProcess -Game $w.Game) { return }
        $script:SIFpsWatch = $null
        $script:SIFpsWatchTimer.Stop()
        Invoke-SIFpsAutoUndo -Name $w.Name -Now $w.Now -Before $w.Before
        return
    }
    if (-not $w.Found) {
        if (Get-SIGameProcess -Game $w.Game) { $w.Found = $now }
        elseif (($now - $w.Since).TotalMinutes -ge 5) { $script:SIFpsWatch = $null; $script:SIFpsWatchTimer.Stop() }
        return
    }
    if (($now - $w.Found).TotalSeconds -lt 90) { return }
    $script:SIFpsWatch = $null
    $script:SIFpsWatchTimer.Stop()
    if (-not $script:SIFpsRun) { Start-SIFpsMeasure -Game $w.Game -Auto }
}

function Start-SIFpsMeasure {
    param($Game, [switch]$Auto)
    if ($script:SIFpsRun) {
        if (-not $Auto) { [void][System.Windows.MessageBox]::Show($script:SIWindow, (Get-SIFpsText 'FpsBusy'), (Get-SIFpsText 'FpsTitle')) }
        return
    }
    $proc = Get-SIGameProcess -Game $Game
    if (-not $proc) {
        if (-not $Auto) {
            [void][System.Windows.MessageBox]::Show($script:SIWindow,
                ((Get-SIFpsText 'FpsNotRun') -f $Game.Name, $script:SIFpsDelay, $script:SIFpsSeconds), (Get-SIFpsText 'FpsTitle'))
        }
        return
    }
    if ($Auto) {
        $pm = [System.IO.Path]::Combine($script:SIToolsPath, $script:SIPresentMon.File)
        if (-not ([System.IO.File]::Exists($pm) -and (Get-FileHash -LiteralPath $pm -Algorithm SHA256).Hash -eq $script:SIPresentMon.Sha256)) { return }
    } else {
        $pm = Get-SIPresentMonPath
    }
    if (-not $pm) { return }

    $csv = [System.IO.Path]::Combine($script:SIToolsPath, 'fps-last.csv')
    try { if ([System.IO.File]::Exists($csv)) { [System.IO.File]::Delete($csv) } } catch { }
    $delay = if ($Auto) { 0 } else { $script:SIFpsDelay }
    $argLine = "--process_id $($proc.Id) --delay $delay --timed $($script:SIFpsSeconds) --terminate_after_timed " +
               "--output_file `"$csv`" --no_console_stats --terminate_on_proc_exit " +
               "--session_name SIGAME_FPS --stop_existing_session"
    $p = Start-Process -FilePath $pm -ArgumentList $argLine -WindowStyle Hidden -PassThru
    $script:SIFpsRun = @{ Game = $Game; Process = $p; Csv = $csv; Auto = [bool]$Auto; Until = [datetime]::Now.AddSeconds($delay + $script:SIFpsSeconds + 30) }
    Write-SILog -Component 'FPS' -Message "Measure started: $($Game.Name) (pid $($proc.Id))"
    Set-SIStatusText -Text ((Get-SIFpsText 'FpsStatus') -f $Game.Name)

    if (-not $script:SIFpsTimer) {
        $script:SIFpsTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:SIFpsTimer.Interval = [TimeSpan]::FromSeconds(2)
        $script:SIFpsTimer.Add_Tick({ Step-SIFpsMeasure })
    }
    $script:SIFpsTimer.Start()
    if ($Auto) { return }
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
    Complete-SIFpsMeasure -Game $run.Game -CsvPath $run.Csv -Auto:$run.Auto
}

function Complete-SIFpsMeasure {
    param($Game, [string]$CsvPath, [switch]$Auto)
    $name = [string]$Game.Name
    $st = Get-SIFpsStats -CsvPath $CsvPath
    if (-not $st) {
        Set-SIStatusText -Text ((Get-SIFpsText 'FpsNoFrames') -f $name)
        if ($Auto) { return }
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
    $entry = [pscustomobject]@{ At = [datetime]::Now.ToString('s'); Avg = $st.Avg; Low1 = $st.Low1; Low01 = $st.Low01; WorstMs = $st.WorstMs; Stutters = $st.Stutters; SpreadAvg = $st.SpreadAvg; SpreadLow = $st.SpreadLow; Frames = $st.Frames; Sec = $st.Sec; GpuShare = $st.GpuShare; InputMs = $st.InputMs; Presets = ($presets -join ',') }
    $list = @($list + $entry | Select-Object -Last 10)
    $db | Add-Member $name $list -Force
    try { [System.IO.File]::WriteAllText($script:SIFpsPath, ($db | ConvertTo-Json -Depth 5)) } catch { }
    Write-SILog -Component 'FPS' -Message "$name avg $($st.Avg) low1 $($st.Low1) frames $($st.Frames) presets [$($entry.Presets)]"

    $msg = (Get-SIFpsText 'FpsResult') -f $name, $st.Avg, $st.Low1, $st.Frames, $st.Sec
    if ($st.Low01 -gt 0) { $msg += (Get-SIFpsText 'FpsPro') -f $st.Low01, $st.WorstMs, $st.Stutters }
    else { $msg += (Get-SIFpsText 'FpsProShort') -f $st.WorstMs, $st.Stutters }
    if ($st.InputMs -gt 0) { $msg += (Get-SIFpsText 'FpsInput') -f $st.InputMs }
    $bound = Get-SIFpsBound -Share $st.GpuShare
    if ($bound) { $msg += (Get-SIFpsText @{ GPU = 'FpsBoundGPU'; CPU = 'FpsBoundCPU'; Balanced = 'FpsBoundBal' }[$bound]) -f [math]::Round(100 * $st.GpuShare) }
    $info = [ordered]@{ avg = $st.Avg; low1 = $st.Low1; frames = $st.Frames; sec = $st.Sec; gpu_share = $st.GpuShare; input_ms = $st.InputMs }
    $verdict = ''; $dAvg = 0; $dLow = 0; $cardPrev = $null
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
        $cardPrev = $prev
    }
    if ($list.Count -ge 3) {
        $best = $list | Sort-Object { [double]$_.Avg } -Descending | Select-Object -First 1
        $bestSet = if ([string]$best.Presets) { (Get-SIFpsText 'FpsBestSet') -f ([string]$best.Presets).Replace(',', ', ') } else { '' }
        $msg += (Get-SIFpsText 'FpsBest') -f $list.Count, $best.Avg, $best.Low1, ([string]$best.At).Replace('T', ' '), $bestSet
    }
    if ($presets.Count) { $msg += (Get-SIFpsText 'FpsPresets') -f ($presets -join ', ') }
    if ((Get-SICommunityState).Telemetry -eq $true) { $msg += (Get-SIFpsText 'FpsShared') }
    $card = New-SIFpsCard -Name $name -St $st -Prev $cardPrev -Verdict $verdict -DeltaAvg $dAvg -DeltaLow $dLow -Presets ($presets -join ',')
    if ($card) { $msg += (Get-SIFpsText 'FpsCard') -f [System.IO.Path]::GetDirectoryName($card) }

    $exe = [System.IO.Path]::GetFileName([string]$Game.Exe)
    Send-SITelemetry -Event (New-SITelemetryEvent -Kind 'fps_measured' -Game $name -Store ([string]$Game.Store) -ExeName $exe `
        -Preset ($presets -join ',') -Message ($info | ConvertTo-Json -Compress))
    Set-SIStatusText -Text ("FPS {0}: {1} avg, {2} 1% low" -f $name, $st.Avg, $st.Low1)
    if ($Auto) {
        # No popup over the game: one tray notice; the full result is in the card, the log and the history.
        $short = (Get-SIFpsText 'FpsAutoDone') -f $name, $st.Avg, $st.Low1
        if ($verdict) { $short += ' ' + (Get-SIFpsText ('FpsAutoV' + $verdict)) }
        try { Show-SITrayBalloon -Title (Get-SIFpsText 'FpsTitle') -Text $short } catch { }
        # SLOWER: the Undo offer waits until the game is closed, so nothing pops up over the game.
        if ($verdict -eq 'Worse' -and $cardPrev) {
            $script:SIFpsWatch = @{ Game = $Game; Since = [datetime]::Now; Found = [datetime]::Now; UndoAfterExit = $true
                Name = $name; Now = $presets; Before = [string]$cardPrev.Presets }
            if ($script:SIFpsWatchTimer) { $script:SIFpsWatchTimer.Start() }
        }
        return
    }
    [void][System.Windows.MessageBox]::Show($script:SIWindow, $msg, (Get-SIFpsText 'FpsTitle'))
    if ($verdict -eq 'Worse' -and $cardPrev) { Invoke-SIFpsAutoUndo -Name $name -Now $presets -Before ([string]$cardPrev.Presets) }
}
