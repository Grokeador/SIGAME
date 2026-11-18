# ---------------------------------------------------------------------------
#  SIGAME - module 13: the tweak names and descriptions in the languages
#  of SIGAME. English stays in 02-tweaks.ps1; a missing text falls back to it.
# ---------------------------------------------------------------------------

$script:SITweakText = @{
    'it' = @{
        GameMode = @('Modalita gioco', 'Windows da la priorita al gioco in esecuzione e libera risorse per lui.')
        MouseAcceleration = @('Accelerazione del mouse', 'Spegne l''accelerazione del mouse, cosi il puntatore non supera mai il bersaglio.')
        BackgroundApps = @('App in background', 'Impedisce alle app del Microsoft Store di girare in background.')
        VisualEffects = @('Effetti visivi', 'Imposta gli effetti visivi sul profilo prestazioni migliori.')
        DeliveryOptimization = @('Ottimizzazione recapito', 'Impedisce a Windows di usare la tua banda per inviare aggiornamenti ad altri PC.')
        Telemetry = @('Telemetria', 'Disattiva la telemetria Microsoft, il servizio di segnalazione errori e l''ID pubblicitario.')
        ActivityHistory = @('Cronologia attivita', 'Impedisce a Windows di pubblicare o caricare le tue attivita.')
        MultiplaneOverlay = @('Multiplane Overlay', 'Alcune schede video funzionano male con l''overlay di Windows. Scegli come deve comportarsi MPO.')
        Widgets = @('Widget', 'Toglie il pannello Widget dalla barra delle applicazioni. Annulla lo rimette.')
        WindowsAI = @('IA di Windows / Recall', 'Nasconde le impostazioni IA, disattiva la funzione Recall e i servizi IA.')
        UltimatePerformance = @('Prestazioni eccellenti', 'Aggiunge e attiva la combinazione di risparmio energia Prestazioni eccellenti. Saltato sui portatili.')
        GameDVR = @('Registrazione Game Bar', 'Spegne la registrazione in background della Game Bar, cosi il gioco non viene registrato di nascosto.')
        HAGS = @('Pianificazione GPU hardware', 'Pianificazione GPU con accelerazione hardware (HAGS). Serve un riavvio.')
        WindowedGameOptimizations = @('Ottimizzazioni giochi in finestra', 'Permette a Windows di applicare le ottimizzazioni a schermo intero ai giochi in finestra.')
        MemoryIntegrity = @('Integrita della memoria', 'Isolamento core (HVCI). Solo informativo, SIGAME non lo cambia mai.')
        TCPAutoTuning = @('Auto-tuning finestra TCP', 'Lascia crescere la finestra di ricezione TCP in quasi ogni situazione. Windows la imposta su "normal" di default.')
        DNSServer = @('Server DNS', 'Imposta il DNS della scheda di rete in uso. Prima fai il test DNS nella sezione Avanzate.')
        NetworkThrottling = @('Indice di limitazione rete', 'Windows riserva il 10 % della rete al background. Questo lo toglie. Serve un riavvio.')
        SystemResponsiveness = @('Reattivita del sistema', 'Windows tiene il 20 % del processore per il background. Questo gliene lascia il 10 %, cosi il gioco ne ha di piu. Serve un riavvio.')
        TransparencyEffects = @('Effetti di trasparenza', 'Spegne le finestre trasparenti. E la stessa casella di Impostazioni > Personalizzazione > Colori.')
        HibernationOff = @('Ibernazione', 'Spegne l''ibernazione e libera lo spazio del file hiberfil.sys. Sconsigliato sui portatili.')
        TaskbarEndTask = @('Termina attivita sulla barra', 'Aggiunge Termina attivita al menu del tasto destro della barra, cosi un gioco bloccato si chiude con un clic. Solo Windows 11.')
        MmcssGamesTask = @('Priorita del task Games (MMCSS)', 'Da al task Games di Windows la categoria High, priorita 6 e priorita I/O alta. UNDO rimette i tuoi valori. Serve un riavvio.')
    }
    'pt-BR' = @{
        GameMode = @('Modo de jogo', 'O Windows prioriza o jogo em execucao e libera recursos para ele.')
        MouseAcceleration = @('Aceleracao do mouse', 'Desliga a aceleracao do mouse, para o ponteiro nunca passar do alvo.')
        BackgroundApps = @('Apps em segundo plano', 'Impede os apps da Microsoft Store de rodarem em segundo plano.')
        VisualEffects = @('Efeitos visuais', 'Coloca os efeitos visuais no perfil de melhor desempenho.')
        DeliveryOptimization = @('Otimizacao de entrega', 'Impede o Windows de usar sua banda para enviar atualizacoes a outros PCs.')
        Telemetry = @('Telemetria', 'Desativa a telemetria da Microsoft, o servico de relatorio de erros e o ID de publicidade.')
        ActivityHistory = @('Historico de atividades', 'Impede o Windows de publicar ou enviar suas atividades.')
        MultiplaneOverlay = @('Multiplane Overlay', 'Algumas placas de video se comportam mal com o overlay do Windows. Escolha como o MPO deve agir.')
        Widgets = @('Widgets', 'Remove o painel de Widgets da barra de tarefas. Desfazer coloca de volta.')
        WindowsAI = @('IA do Windows / Recall', 'Oculta as configuracoes de IA, desativa o recurso Recall e os servicos de IA.')
        UltimatePerformance = @('Desempenho maximo', 'Adiciona e ativa o plano de energia Desempenho Maximo. Ignorado em notebooks.')
        GameDVR = @('Captura da Game Bar', 'Desliga a gravacao em segundo plano da Game Bar, para o jogo nao ser gravado escondido.')
        HAGS = @('Agendamento de GPU por hardware', 'Agendamento de GPU acelerado por hardware (HAGS). Precisa reiniciar.')
        WindowedGameOptimizations = @('Otimizacoes para jogos em janela', 'Deixa o Windows aplicar as otimizacoes de tela cheia aos jogos em janela.')
        MemoryIntegrity = @('Integridade de memoria', 'Isolamento de nucleo (HVCI). So informativo, o SIGAME nunca muda isso.')
        TCPAutoTuning = @('Ajuste automatico da janela TCP', 'Deixa a janela de recepcao do TCP crescer em quase toda situacao. O Windows usa "normal" por padrao.')
        DNSServer = @('Servidor DNS', 'Define o DNS do adaptador de rede em uso agora. Faca antes o teste de DNS na secao Avancado.')
        NetworkThrottling = @('Indice de limitacao de rede', 'O Windows reserva 10 % da rede para o segundo plano. Isso tira essa reserva. Precisa reiniciar.')
        SystemResponsiveness = @('Responsividade do sistema', 'O Windows guarda 20 % do processador para o segundo plano. Isso deixa 10 %, entao o jogo ganha mais. Precisa reiniciar.')
        TransparencyEffects = @('Efeitos de transparencia', 'Desliga as janelas transparentes. E a mesma opcao de Configuracoes > Personalizacao > Cores.')
        HibernationOff = @('Hibernacao', 'Desliga a hibernacao e libera o espaco do arquivo hiberfil.sys. Nao recomendado em notebooks.')
        TaskbarEndTask = @('Finalizar tarefa na barra', 'Adiciona Finalizar tarefa ao menu do botao direito da barra de tarefas, para fechar um jogo travado com um clique. So Windows 11.')
        MmcssGamesTask = @('Prioridade da tarefa Games (MMCSS)', 'Da a tarefa Games do Windows a categoria High, prioridade 6 e prioridade de E/S alta. UNDO devolve seus valores. Precisa reiniciar.')
    }
    'es' = @{
        GameMode = @('Modo juego', 'Windows prioriza el juego en ejecucion y libera recursos para el.')
        MouseAcceleration = @('Aceleracion del raton', 'Apaga la aceleracion del raton, para que el puntero nunca se pase del objetivo.')
        BackgroundApps = @('Apps en segundo plano', 'Impide que las apps de Microsoft Store se ejecuten en segundo plano.')
        VisualEffects = @('Efectos visuales', 'Pone los efectos visuales en el perfil de mejor rendimiento.')
        DeliveryOptimization = @('Optimizacion de distribucion', 'Impide que Windows use tu ancho de banda para enviar actualizaciones a otros PC.')
        Telemetry = @('Telemetria', 'Desactiva la telemetria de Microsoft, el servicio de informe de errores y el id de publicidad.')
        ActivityHistory = @('Historial de actividad', 'Impide que Windows publique o suba tus actividades.')
        MultiplaneOverlay = @('Multiplane Overlay', 'Algunas tarjetas graficas fallan con el overlay de Windows. Elige como debe comportarse MPO.')
        Widgets = @('Widgets', 'Quita el panel de Widgets de la barra de tareas. Deshacer lo vuelve a poner.')
        WindowsAI = @('IA de Windows / Recall', 'Oculta los ajustes de IA, desactiva la funcion Recall y los servicios de IA.')
        UltimatePerformance = @('Maximo rendimiento', 'Agrega y activa el plan de energia Maximo rendimiento. Se omite en portatiles.')
        GameDVR = @('Captura de Game Bar', 'Apaga la grabacion en segundo plano de la Game Bar, para que el juego no se grabe a escondidas.')
        HAGS = @('Programacion de GPU por hardware', 'Programacion de GPU acelerada por hardware (HAGS). Hace falta reiniciar.')
        WindowedGameOptimizations = @('Optimizaciones para juegos en ventana', 'Deja que Windows aplique las optimizaciones de pantalla completa a los juegos en ventana.')
        MemoryIntegrity = @('Integridad de memoria', 'Aislamiento del nucleo (HVCI). Solo informativo, SIGAME nunca lo cambia.')
        TCPAutoTuning = @('Ajuste automatico de la ventana TCP', 'Deja crecer la ventana de recepcion TCP en casi cualquier situacion. Windows la pone en "normal" por defecto.')
        DNSServer = @('Servidor DNS', 'Pone el DNS del adaptador de red que se usa ahora. Haz antes la prueba de DNS en la seccion Avanzado.')
        NetworkThrottling = @('Indice de limitacion de red', 'Windows reserva el 10 % de la red para el segundo plano. Esto lo quita. Hace falta reiniciar.')
        SystemResponsiveness = @('Capacidad de respuesta del sistema', 'Windows guarda el 20 % del procesador para el segundo plano. Esto le deja el 10 %, asi el juego recibe mas. Hace falta reiniciar.')
        TransparencyEffects = @('Efectos de transparencia', 'Apaga las ventanas transparentes. Es la misma casilla de Configuracion > Personalizacion > Colores.')
        HibernationOff = @('Hibernacion', 'Apaga la hibernacion y libera el espacio del archivo hiberfil.sys. No recomendado en portatiles.')
        TaskbarEndTask = @('Finalizar tarea en la barra', 'Agrega Finalizar tarea al menu del clic derecho de la barra de tareas, para cerrar un juego colgado con un clic. Solo Windows 11.')
        MmcssGamesTask = @('Prioridad de la tarea Games (MMCSS)', 'Da a la tarea Games de Windows la categoria High, prioridad 6 y prioridad de E/S alta. UNDO devuelve tus valores. Hace falta reiniciar.')
    }
    'de' = @{
        GameMode = @('Spielmodus', 'Windows bevorzugt das laufende Spiel und gibt Ressourcen dafuer frei.')
        MouseAcceleration = @('Mausbeschleunigung', 'Schaltet die Mausbeschleunigung aus, damit der Zeiger nie ueber das Ziel hinausschiesst.')
        BackgroundApps = @('Hintergrund-Apps', 'Verhindert, dass Microsoft-Store-Apps im Hintergrund laufen.')
        VisualEffects = @('Visuelle Effekte', 'Stellt die visuellen Effekte auf das Profil fuer beste Leistung.')
        DeliveryOptimization = @('Uebermittlungsoptimierung', 'Verhindert, dass Windows deine Bandbreite nutzt, um Updates an andere PCs zu senden.')
        Telemetry = @('Telemetrie', 'Deaktiviert die Microsoft-Telemetrie, den Fehlerberichtsdienst und die Werbe-ID.')
        ActivityHistory = @('Aktivitaetsverlauf', 'Verhindert, dass Windows deine Aktivitaeten veroeffentlicht oder hochlaedt.')
        MultiplaneOverlay = @('Multiplane Overlay', 'Manche Grafikkarten haben Probleme mit dem Windows-Overlay. Waehle, wie sich MPO verhalten soll.')
        Widgets = @('Widgets', 'Entfernt das Widgets-Panel aus der Taskleiste. Rueckgaengig bringt es zurueck.')
        WindowsAI = @('Windows-KI / Recall', 'Blendet die KI-Einstellungen aus, deaktiviert die Recall-Funktion und die KI-Dienste.')
        UltimatePerformance = @('Ultimative Leistung', 'Fuegt den Energiesparplan Ultimative Leistung hinzu und aktiviert ihn. Auf Laptops uebersprungen.')
        GameDVR = @('Game-Bar-Aufnahme', 'Schaltet die Hintergrundaufnahme der Game Bar aus, damit das Spiel nicht heimlich aufgenommen wird.')
        HAGS = @('Hardwarebeschleunigte GPU-Planung', 'Hardwarebeschleunigte GPU-Planung (HAGS). Ein Neustart ist noetig.')
        WindowedGameOptimizations = @('Optimierungen fuer Spiele im Fenster', 'Laesst Windows die Vollbildoptimierungen auf Spiele im Fenster anwenden.')
        MemoryIntegrity = @('Speicherintegritaet', 'Kernisolierung (HVCI). Nur zur Information, SIGAME aendert sie nie.')
        TCPAutoTuning = @('TCP-Empfangsfenster-Autotuning', 'Laesst das TCP-Empfangsfenster in fast jeder Lage wachsen. Windows stellt es standardmaessig auf "normal".')
        DNSServer = @('DNS-Server', 'Setzt den DNS des gerade genutzten Netzwerkadapters. Fuehre vorher den DNS-Test im Bereich Erweitert aus.')
        NetworkThrottling = @('Netzwerkdrosselungsindex', 'Windows reserviert 10 % des Netzwerks fuer den Hintergrund. Das hebt es auf. Ein Neustart ist noetig.')
        SystemResponsiveness = @('Systemreaktionsfaehigkeit', 'Windows haelt 20 % des Prozessors fuer den Hintergrund frei. Das laesst ihm 10 %, damit das Spiel mehr bekommt. Ein Neustart ist noetig.')
        TransparencyEffects = @('Transparenzeffekte', 'Schaltet die transparenten Fenster aus. Das ist derselbe Schalter wie unter Einstellungen > Personalisierung > Farben.')
        HibernationOff = @('Ruhezustand', 'Schaltet den Ruhezustand aus und gibt den Platz der Datei hiberfil.sys frei. Nicht empfohlen auf Laptops.')
        TaskbarEndTask = @('Task beenden in der Taskleiste', 'Fuegt Task beenden zum Rechtsklickmenue der Taskleiste hinzu, damit ein haengendes Spiel mit einem Klick schliesst. Nur Windows 11.')
        MmcssGamesTask = @('Prioritaet der Games-Aufgabe (MMCSS)', 'Gibt der Windows-Aufgabe Games die Kategorie High, Prioritaet 6 und hohe E/A-Prioritaet. UNDO stellt deine Werte wieder her. Ein Neustart ist noetig.')
    }
    'fr' = @{
        GameMode = @('Mode jeu', 'Windows donne la priorite au jeu lance et libere des ressources pour lui.')
        MouseAcceleration = @('Acceleration de la souris', 'Desactive l''acceleration de la souris, pour que le pointeur ne depasse jamais la cible.')
        BackgroundApps = @('Applis en arriere-plan', 'Empeche les applis du Microsoft Store de tourner en arriere-plan.')
        VisualEffects = @('Effets visuels', 'Regle les effets visuels sur le profil meilleures performances.')
        DeliveryOptimization = @('Optimisation de la distribution', 'Empeche Windows d''utiliser ta bande passante pour envoyer des mises a jour a d''autres PC.')
        Telemetry = @('Telemetrie', 'Desactive la telemetrie Microsoft, le service de rapport d''erreurs et l''identifiant publicitaire.')
        ActivityHistory = @('Historique des activites', 'Empeche Windows de publier ou d''envoyer tes activites.')
        MultiplaneOverlay = @('Multiplane Overlay', 'Certaines cartes graphiques fonctionnent mal avec l''overlay de Windows. Choisis comment MPO doit se comporter.')
        Widgets = @('Widgets', 'Retire le panneau Widgets de la barre des taches. Annuler le remet.')
        WindowsAI = @('IA de Windows / Recall', 'Masque les parametres IA, desactive la fonction Recall et les services IA.')
        UltimatePerformance = @('Performances optimales', 'Ajoute et active le mode d''alimentation Performances optimales. Ignore sur les portables.')
        GameDVR = @('Capture Game Bar', 'Desactive l''enregistrement en arriere-plan de la Game Bar, pour que le jeu ne soit pas enregistre en cachette.')
        HAGS = @('Planification GPU materielle', 'Planification GPU acceleree par le materiel (HAGS). Un redemarrage est necessaire.')
        WindowedGameOptimizations = @('Optimisations des jeux en fenetre', 'Laisse Windows appliquer les optimisations plein ecran aux jeux en fenetre.')
        MemoryIntegrity = @('Integrite de la memoire', 'Isolation du noyau (HVCI). Pour information seulement, SIGAME ne la change jamais.')
        TCPAutoTuning = @('Reglage auto de la fenetre TCP', 'Laisse la fenetre de reception TCP grandir dans presque toutes les situations. Windows la regle sur "normal" par defaut.')
        DNSServer = @('Serveur DNS', 'Regle le DNS de la carte reseau utilisee en ce moment. Lance d''abord le test DNS dans la section Avance.')
        NetworkThrottling = @('Indice de limitation reseau', 'Windows reserve 10 % du reseau a l''arriere-plan. Ceci l''enleve. Un redemarrage est necessaire.')
        SystemResponsiveness = @('Reactivite du systeme', 'Windows garde 20 % du processeur pour l''arriere-plan. Ceci lui en laisse 10 %, le jeu en recoit plus. Un redemarrage est necessaire.')
        TransparencyEffects = @('Effets de transparence', 'Desactive les fenetres transparentes. C''est la meme case que Parametres > Personnalisation > Couleurs.')
        HibernationOff = @('Hibernation', 'Desactive l''hibernation et libere la place du fichier hiberfil.sys. Deconseille sur un portable.')
        TaskbarEndTask = @('Fin de tache dans la barre', 'Ajoute Fin de tache au menu clic droit de la barre des taches, pour fermer un jeu bloque en un clic. Windows 11 seulement.')
        MmcssGamesTask = @('Priorite de la tache Games (MMCSS)', 'Donne a la tache Games de Windows la categorie High, la priorite 6 et une priorite E/S haute. UNDO remet tes valeurs. Un redemarrage est necessaire.')
    }
}

# the texts of the state line (OnText / OffText), same languages
$script:SITweakStateText = @{
    'it' = @{
        GameMode = @('Modalita gioco ATTIVA', 'Modalita gioco SPENTA')
        MouseAcceleration = @('Accelerazione SPENTA', 'Accelerazione ATTIVA')
        BackgroundApps = @('App in background SPENTE', 'App in background permesse')
        VisualEffects = @('Prestazioni migliori impostate', 'Non impostato su prestazioni migliori')
        DeliveryOptimization = @('Ottimizzazione recapito SPENTA', 'Ottimizzazione recapito permessa')
        Telemetry = @('Telemetria ridotta', 'Telemetria non ridotta')
        ActivityHistory = @('Cronologia attivita SPENTA', 'Cronologia attivita ATTIVA')
        MultiplaneOverlay = @('Multiplane Overlay disattivato', 'Multiplane Overlay in modalita predefinita di Windows')
        Widgets = @('Widget rimossi', 'Widget installati')
        WindowsAI = @('Funzioni IA spente', 'Funzioni IA ancora attive')
        UltimatePerformance = @('Prestazioni eccellenti disponibile', 'Prestazioni eccellenti non installato')
        GameDVR = @('Registrazione in background SPENTA', 'Registrazione in background ATTIVA')
        HAGS = @('Pianificazione hardware ATTIVA', 'Pianificazione hardware SPENTA')
        WindowedGameOptimizations = @('Ottimizzazioni in finestra ATTIVE', 'Ottimizzazioni in finestra SPENTE')
        TCPAutoTuning = @('Auto-tuning TCP su normal', 'Auto-tuning TCP non su normal')
        DNSServer = @('Server DNS impostato', 'Server DNS di Windows')
        NetworkThrottling = @('Limitazione rete spenta (0xFFFFFFFF)', 'Limitazione rete al valore predefinito di Windows (10)')
        SystemResponsiveness = @('Reattivita del sistema a 10 (Windows: 20)', 'Reattivita del sistema al valore di Windows (20)')
        TransparencyEffects = @('Effetti di trasparenza SPENTI', 'Effetti di trasparenza ATTIVI')
        HibernationOff = @('Ibernazione spenta', 'Ibernazione attiva')
        TaskbarEndTask = @('Termina attivita e nel menu della barra', 'Termina attivita non e nel menu della barra')
        MmcssGamesTask = @('Task Games su High, priorita 6', 'Task Games non su High, priorita 6')
    }
    'pt-BR' = @{
        GameMode = @('Modo de jogo LIGADO', 'Modo de jogo DESLIGADO')
        MouseAcceleration = @('Aceleracao DESLIGADA', 'Aceleracao LIGADA')
        BackgroundApps = @('Apps em segundo plano DESLIGADOS', 'Apps em segundo plano permitidos')
        VisualEffects = @('Melhor desempenho definido', 'Nao esta em melhor desempenho')
        DeliveryOptimization = @('Otimizacao de entrega DESLIGADA', 'Otimizacao de entrega permitida')
        Telemetry = @('Telemetria reduzida', 'Telemetria nao reduzida')
        ActivityHistory = @('Historico de atividades DESLIGADO', 'Historico de atividades LIGADO')
        MultiplaneOverlay = @('Multiplane Overlay desativado', 'Multiplane Overlay no modo padrao do Windows')
        Widgets = @('Widgets removidos', 'Widgets instalados')
        WindowsAI = @('Recursos de IA desligados', 'Recursos de IA ainda ativos')
        UltimatePerformance = @('Desempenho Maximo disponivel', 'Desempenho Maximo nao instalado')
        GameDVR = @('Captura em segundo plano DESLIGADA', 'Captura em segundo plano LIGADA')
        HAGS = @('Agendamento por hardware LIGADO', 'Agendamento por hardware DESLIGADO')
        WindowedGameOptimizations = @('Otimizacoes em janela LIGADAS', 'Otimizacoes em janela DESLIGADAS')
        TCPAutoTuning = @('Ajuste automatico TCP em normal', 'Ajuste automatico TCP fora de normal')
        DNSServer = @('Servidor DNS definido', 'Servidor DNS do Windows')
        NetworkThrottling = @('Limitacao de rede desligada (0xFFFFFFFF)', 'Limitacao de rede no padrao do Windows (10)')
        SystemResponsiveness = @('Responsividade do sistema em 10 (Windows: 20)', 'Responsividade do sistema no padrao do Windows (20)')
        TransparencyEffects = @('Efeitos de transparencia DESLIGADOS', 'Efeitos de transparencia LIGADOS')
        HibernationOff = @('Hibernacao desligada', 'Hibernacao ligada')
        TaskbarEndTask = @('Finalizar tarefa esta no menu da barra', 'Finalizar tarefa nao esta no menu da barra')
        MmcssGamesTask = @('Tarefa Games em High, prioridade 6', 'Tarefa Games fora de High, prioridade 6')
    }
    'es' = @{
        GameMode = @('Modo juego ACTIVADO', 'Modo juego DESACTIVADO')
        MouseAcceleration = @('Aceleracion DESACTIVADA', 'Aceleracion ACTIVADA')
        BackgroundApps = @('Apps en segundo plano DESACTIVADAS', 'Apps en segundo plano permitidas')
        VisualEffects = @('Mejor rendimiento aplicado', 'No esta en mejor rendimiento')
        DeliveryOptimization = @('Optimizacion de distribucion DESACTIVADA', 'Optimizacion de distribucion permitida')
        Telemetry = @('Telemetria reducida', 'Telemetria no reducida')
        ActivityHistory = @('Historial de actividad DESACTIVADO', 'Historial de actividad ACTIVADO')
        MultiplaneOverlay = @('Multiplane Overlay desactivado', 'Multiplane Overlay en el modo predeterminado de Windows')
        Widgets = @('Widgets quitados', 'Widgets instalados')
        WindowsAI = @('Funciones de IA apagadas', 'Funciones de IA todavia activas')
        UltimatePerformance = @('Maximo rendimiento disponible', 'Maximo rendimiento no instalado')
        GameDVR = @('Captura en segundo plano DESACTIVADA', 'Captura en segundo plano ACTIVADA')
        HAGS = @('Programacion por hardware ACTIVADA', 'Programacion por hardware DESACTIVADA')
        WindowedGameOptimizations = @('Optimizaciones en ventana ACTIVADAS', 'Optimizaciones en ventana DESACTIVADAS')
        TCPAutoTuning = @('Ajuste automatico TCP en normal', 'Ajuste automatico TCP no esta en normal')
        DNSServer = @('Servidor DNS configurado', 'Servidor DNS de Windows')
        NetworkThrottling = @('Limitacion de red apagada (0xFFFFFFFF)', 'Limitacion de red en el valor de Windows (10)')
        SystemResponsiveness = @('Capacidad de respuesta en 10 (Windows: 20)', 'Capacidad de respuesta en el valor de Windows (20)')
        TransparencyEffects = @('Efectos de transparencia DESACTIVADOS', 'Efectos de transparencia ACTIVADOS')
        HibernationOff = @('Hibernacion apagada', 'Hibernacion activada')
        TaskbarEndTask = @('Finalizar tarea esta en el menu de la barra', 'Finalizar tarea no esta en el menu de la barra')
        MmcssGamesTask = @('Tarea Games en High, prioridad 6', 'Tarea Games no esta en High, prioridad 6')
    }
    'de' = @{
        GameMode = @('Spielmodus ist AN', 'Spielmodus ist AUS')
        MouseAcceleration = @('Beschleunigung ist AUS', 'Beschleunigung ist AN')
        BackgroundApps = @('Hintergrund-Apps sind AUS', 'Hintergrund-Apps sind erlaubt')
        VisualEffects = @('Beste Leistung ist gesetzt', 'Nicht auf beste Leistung gesetzt')
        DeliveryOptimization = @('Uebermittlungsoptimierung ist AUS', 'Uebermittlungsoptimierung ist erlaubt')
        Telemetry = @('Telemetrie ist reduziert', 'Telemetrie ist nicht reduziert')
        ActivityHistory = @('Aktivitaetsverlauf ist AUS', 'Aktivitaetsverlauf ist AN')
        MultiplaneOverlay = @('Multiplane Overlay ist deaktiviert', 'Multiplane Overlay ist im Windows-Standardmodus')
        Widgets = @('Widgets sind entfernt', 'Widgets sind installiert')
        WindowsAI = @('KI-Funktionen sind aus', 'KI-Funktionen sind noch aktiv')
        UltimatePerformance = @('Ultimative Leistung ist verfuegbar', 'Ultimative Leistung ist nicht installiert')
        GameDVR = @('Hintergrundaufnahme ist AUS', 'Hintergrundaufnahme ist AN')
        HAGS = @('Hardwareplanung ist AN', 'Hardwareplanung ist AUS')
        WindowedGameOptimizations = @('Fensteroptimierungen sind AN', 'Fensteroptimierungen sind AUS')
        TCPAutoTuning = @('TCP-Autotuning ist normal', 'TCP-Autotuning ist nicht normal')
        DNSServer = @('DNS-Server ist gesetzt', 'DNS-Server von Windows')
        NetworkThrottling = @('Netzwerkdrosselung ist aus (0xFFFFFFFF)', 'Netzwerkdrosselung auf Windows-Standard (10)')
        SystemResponsiveness = @('Systemreaktionsfaehigkeit ist 10 (Windows: 20)', 'Systemreaktionsfaehigkeit auf Windows-Standard (20)')
        TransparencyEffects = @('Transparenzeffekte sind AUS', 'Transparenzeffekte sind AN')
        HibernationOff = @('Ruhezustand ist aus', 'Ruhezustand ist an')
        TaskbarEndTask = @('Task beenden ist im Taskleistenmenue', 'Task beenden ist nicht im Taskleistenmenue')
        MmcssGamesTask = @('Games-Aufgabe ist High, Prioritaet 6', 'Games-Aufgabe ist nicht High, Prioritaet 6')
    }
    'fr' = @{
        GameMode = @('Mode jeu ACTIVE', 'Mode jeu DESACTIVE')
        MouseAcceleration = @('Acceleration DESACTIVEE', 'Acceleration ACTIVEE')
        BackgroundApps = @('Applis en arriere-plan DESACTIVEES', 'Applis en arriere-plan autorisees')
        VisualEffects = @('Meilleures performances reglees', 'Pas regle sur meilleures performances')
        DeliveryOptimization = @('Optimisation de la distribution DESACTIVEE', 'Optimisation de la distribution autorisee')
        Telemetry = @('Telemetrie reduite', 'Telemetrie non reduite')
        ActivityHistory = @('Historique des activites DESACTIVE', 'Historique des activites ACTIVE')
        MultiplaneOverlay = @('Multiplane Overlay desactive', 'Multiplane Overlay en mode Windows par defaut')
        Widgets = @('Widgets retires', 'Widgets installes')
        WindowsAI = @('Fonctions IA desactivees', 'Fonctions IA encore actives')
        UltimatePerformance = @('Performances optimales disponible', 'Performances optimales non installe')
        GameDVR = @('Capture en arriere-plan DESACTIVEE', 'Capture en arriere-plan ACTIVEE')
        HAGS = @('Planification materielle ACTIVEE', 'Planification materielle DESACTIVEE')
        WindowedGameOptimizations = @('Optimisations en fenetre ACTIVEES', 'Optimisations en fenetre DESACTIVEES')
        TCPAutoTuning = @('Reglage auto TCP sur normal', 'Reglage auto TCP pas sur normal')
        DNSServer = @('Serveur DNS regle', 'Serveur DNS de Windows')
        NetworkThrottling = @('Limitation reseau desactivee (0xFFFFFFFF)', 'Limitation reseau a la valeur Windows par defaut (10)')
        SystemResponsiveness = @('Reactivite du systeme a 10 (Windows : 20)', 'Reactivite du systeme a la valeur Windows (20)')
        TransparencyEffects = @('Effets de transparence DESACTIVES', 'Effets de transparence ACTIVES')
        HibernationOff = @('Hibernation desactivee', 'Hibernation activee')
        TaskbarEndTask = @('Fin de tache est dans le menu de la barre', 'Fin de tache n''est pas dans le menu de la barre')
        MmcssGamesTask = @('Tache Games en High, priorite 6', 'Tache Games pas en High, priorite 6')
    }
}

function Set-SITweakLanguage {
    <#
    .SYNOPSIS
        Puts the Name and Description of every tweak in the language of
        SIGAME. Ids, registry values and logic never change.
    #>
    param($Tweaks)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    if (-not $script:SITweakText.ContainsKey($lang)) { return }
    $tab = $script:SITweakText[$lang]
    foreach ($t in @($Tweaks)) {
        if (-not $t -or -not $tab.ContainsKey([string]$t.Id)) { continue }
        $pair = $tab[[string]$t.Id]
        $t.Name = [string]$pair[0]
        $t.Description = [string]$pair[1]
        if ($script:SITweakStateText.ContainsKey($lang) -and $script:SITweakStateText[$lang].ContainsKey([string]$t.Id)) {
            $st = $script:SITweakStateText[$lang][[string]$t.Id]
            $t.OnText = [string]$st[0]
            $t.OffText = [string]$st[1]
        }
    }
}

# the table may already be cached by the modules loaded before this one
if ($script:SITweakTableCache) { Set-SITweakLanguage -Tweaks $script:SITweakTableCache }
