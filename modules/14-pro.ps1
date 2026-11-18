<#
    SIGAME - PRO tools (18/11)
    PC check (power source, GPU driver + official driver page), support zip,
    export / import of the profile, what's new, game start hints (a SI PRESET
    ready for the game, battery), Steam launch options of a preset, preset
    vote, command line (-Preset / -UndoPreset / -ListPresets).
#>

$script:SIProText = @{
    'en' = @{
        Title        = 'PC check and PRO tools'
        PowerAc      = 'Power: plugged in.'
        PowerBat     = 'Power: on battery ({0}%). Plug in the charger before you play: many laptops limit the CPU and GPU on battery.'
        PowerNone    = 'Power: no battery (desktop).'
        Gpu          = 'GPU: {0}  -  driver {1} ({2})'
        BtnDriver    = 'Driver page of {0}'
        DriverTip    = 'Opens the official driver download page of the maker of your GPU.'
        BtnZip       = 'Support zip'
        ZipTip       = 'Puts the SIGAME report and logs in one zip on your desktop, to attach to a GitHub issue.'
        ZipDone      = "Saved on your desktop:`n{0}`n`nIt holds the SIGAME report and logs, no passwords. The logs can hold folder paths: look at it before you share it."
        ZipFail      = 'The support zip could not be made: {0}'
        BtnExport    = 'Export profile'
        BtnImport    = 'Import profile'
        ProfileTip   = 'Your boost list, your applied SI PRESETS and your anonymous stats choice in one file: keep it, or load it after a new install.'
        ExportDone   = "Profile saved:`n{0}"
        ImportDone   = 'Profile loaded: {0} games in the boost list.'
        ImportBad    = 'This file is not a SIGAME profile.'
        ImportPreset = "The profile has {0} SI PRESETS for games found here and not applied yet. Apply them now? Each one asks first."
        BtnWhatsNew  = "What's new"
        NoNotes      = 'No notes yet: they appear after the next update.'
        HintPreset   = 'SI PRESET for {0}: "{1}" is ready and not applied yet. Open SIGAME > SI PRESETS.'
        HintBattery  = '{0} started on battery. Plug in the charger for full speed.'
        LaunchOpt    = "One more step for {0}: the launch option {1} is copied.`n`nIn Steam: right click the game > Properties > Launch options, then paste it (Ctrl+V)."
        VoteUp       = 'This preset works for me'
        VoteDown     = 'This preset does not work for me'
        VoteThanks   = 'Thanks, your vote for {0} is sent.'
        VoteLocal    = 'Your vote for {0} is saved here. Anonymous stats are off, so it is not sent.'
    }
    'it' = @{
        Title        = 'Controllo PC e strumenti PRO'
        PowerAc      = 'Alimentazione: collegato alla corrente.'
        PowerBat     = 'Alimentazione: a batteria ({0}%). Collega il caricatore prima di giocare: molti portatili limitano CPU e GPU a batteria.'
        PowerNone    = 'Alimentazione: nessuna batteria (desktop).'
        Gpu          = 'GPU: {0}  -  driver {1} ({2})'
        BtnDriver    = 'Pagina driver {0}'
        DriverTip    = 'Apre la pagina ufficiale di download dei driver del produttore della tua GPU.'
        BtnZip       = 'Zip di supporto'
        ZipTip       = 'Mette il report e i log di SIGAME in un solo zip sul desktop, da allegare a una issue su GitHub.'
        ZipDone      = "Salvato sul desktop:`n{0}`n`nContiene il report e i log di SIGAME, nessuna password. I log possono contenere percorsi di cartelle: guardalo prima di condividerlo."
        ZipFail      = 'Impossibile creare lo zip di supporto: {0}'
        BtnExport    = 'Esporta profilo'
        BtnImport    = 'Importa profilo'
        ProfileTip   = 'La tua lista boost, i SI PRESET applicati e la scelta sulle statistiche anonime in un file: tienilo, o caricalo dopo una nuova installazione.'
        ExportDone   = "Profilo salvato:`n{0}"
        ImportDone   = 'Profilo caricato: {0} giochi nella lista boost.'
        ImportBad    = 'Questo file non e un profilo SIGAME.'
        ImportPreset = "Il profilo ha {0} SI PRESET per giochi trovati qui e non ancora applicati. Applicarli ora? Ognuno chiede prima."
        BtnWhatsNew  = 'Novita'
        NoNotes      = 'Ancora nessuna nota: compaiono dopo il prossimo aggiornamento.'
        HintPreset   = 'SI PRESET per {0}: "{1}" e pronto e non ancora applicato. Apri SIGAME > SI PRESETS.'
        HintBattery  = '{0} e partito a batteria. Collega il caricatore per la piena velocita.'
        LaunchOpt    = "Ancora un passo per {0}: l'opzione di avvio {1} e copiata.`n`nIn Steam: tasto destro sul gioco > Proprieta > Opzioni di avvio, poi incolla (Ctrl+V)."
        VoteUp       = 'Questo preset funziona per me'
        VoteDown     = 'Questo preset non funziona per me'
        VoteThanks   = 'Grazie, il tuo voto per {0} e inviato.'
        VoteLocal    = 'Il tuo voto per {0} e salvato qui. Le statistiche anonime sono spente, quindi non viene inviato.'
    }
    'pt-BR' = @{
        Title        = 'Checagem do PC e ferramentas PRO'
        PowerAc      = 'Energia: na tomada.'
        PowerBat     = 'Energia: na bateria ({0}%). Ligue o carregador antes de jogar: muitos notebooks limitam a CPU e a GPU na bateria.'
        PowerNone    = 'Energia: sem bateria (desktop).'
        Gpu          = 'GPU: {0}  -  driver {1} ({2})'
        BtnDriver    = 'Pagina de driver {0}'
        DriverTip    = 'Abre a pagina oficial de download de drivers do fabricante da sua GPU.'
        BtnZip       = 'Zip de suporte'
        ZipTip       = 'Coloca o relatorio e os logs do SIGAME em um zip na area de trabalho, para anexar a uma issue no GitHub.'
        ZipDone      = "Salvo na area de trabalho:`n{0}`n`nTem o relatorio e os logs do SIGAME, nenhuma senha. Os logs podem ter caminhos de pastas: confira antes de compartilhar."
        ZipFail      = 'Nao foi possivel criar o zip de suporte: {0}'
        BtnExport    = 'Exportar perfil'
        BtnImport    = 'Importar perfil'
        ProfileTip   = 'Sua lista de boost, os SI PRESETS aplicados e sua escolha sobre estatisticas anonimas em um arquivo: guarde, ou carregue depois de uma nova instalacao.'
        ExportDone   = "Perfil salvo:`n{0}"
        ImportDone   = 'Perfil carregado: {0} jogos na lista de boost.'
        ImportBad    = 'Este arquivo nao e um perfil do SIGAME.'
        ImportPreset = "O perfil tem {0} SI PRESETS para jogos encontrados aqui e ainda nao aplicados. Aplicar agora? Cada um pergunta antes."
        BtnWhatsNew  = 'Novidades'
        NoNotes      = 'Ainda sem notas: elas aparecem depois da proxima atualizacao.'
        HintPreset   = 'SI PRESET para {0}: "{1}" esta pronto e ainda nao aplicado. Abra SIGAME > SI PRESETS.'
        HintBattery  = '{0} abriu na bateria. Ligue o carregador para a velocidade total.'
        LaunchOpt    = "Mais um passo para {0}: a opcao de inicializacao {1} foi copiada.`n`nNa Steam: clique direito no jogo > Propriedades > Opcoes de inicializacao, depois cole (Ctrl+V)."
        VoteUp       = 'Este preset funciona para mim'
        VoteDown     = 'Este preset nao funciona para mim'
        VoteThanks   = 'Obrigado, seu voto para {0} foi enviado.'
        VoteLocal    = 'Seu voto para {0} ficou salvo aqui. As estatisticas anonimas estao desligadas, entao ele nao e enviado.'
    }
    'es' = @{
        Title        = 'Revision del PC y herramientas PRO'
        PowerAc      = 'Energia: enchufado.'
        PowerBat     = 'Energia: con bateria ({0}%). Conecta el cargador antes de jugar: muchos portatiles limitan la CPU y la GPU con bateria.'
        PowerNone    = 'Energia: sin bateria (escritorio).'
        Gpu          = 'GPU: {0}  -  driver {1} ({2})'
        BtnDriver    = 'Pagina de drivers {0}'
        DriverTip    = 'Abre la pagina oficial de descarga de drivers del fabricante de tu GPU.'
        BtnZip       = 'Zip de soporte'
        ZipTip       = 'Pone el informe y los logs de SIGAME en un zip en tu escritorio, para adjuntarlo a una issue en GitHub.'
        ZipDone      = "Guardado en tu escritorio:`n{0}`n`nTiene el informe y los logs de SIGAME, ninguna contrasena. Los logs pueden tener rutas de carpetas: revisalo antes de compartirlo."
        ZipFail      = 'No se pudo crear el zip de soporte: {0}'
        BtnExport    = 'Exportar perfil'
        BtnImport    = 'Importar perfil'
        ProfileTip   = 'Tu lista de boost, tus SI PRESETS aplicados y tu eleccion sobre estadisticas anonimas en un archivo: guardalo, o cargalo tras una instalacion nueva.'
        ExportDone   = "Perfil guardado:`n{0}"
        ImportDone   = 'Perfil cargado: {0} juegos en la lista de boost.'
        ImportBad    = 'Este archivo no es un perfil de SIGAME.'
        ImportPreset = "El perfil tiene {0} SI PRESETS para juegos encontrados aqui y aun no aplicados. Aplicarlos ahora? Cada uno pregunta antes."
        BtnWhatsNew  = 'Novedades'
        NoNotes      = 'Todavia no hay notas: aparecen despues de la proxima actualizacion.'
        HintPreset   = 'SI PRESET para {0}: "{1}" esta listo y aun no aplicado. Abre SIGAME > SI PRESETS.'
        HintBattery  = '{0} arranco con bateria. Conecta el cargador para la velocidad completa.'
        LaunchOpt    = "Un paso mas para {0}: la opcion de lanzamiento {1} esta copiada.`n`nEn Steam: clic derecho en el juego > Propiedades > Opciones de lanzamiento, y pegala (Ctrl+V)."
        VoteUp       = 'Este preset me funciona'
        VoteDown     = 'Este preset no me funciona'
        VoteThanks   = 'Gracias, tu voto para {0} se envio.'
        VoteLocal    = 'Tu voto para {0} se guardo aqui. Las estadisticas anonimas estan apagadas, asi que no se envia.'
    }
    'de' = @{
        Title        = 'PC-Check und PRO-Werkzeuge'
        PowerAc      = 'Strom: am Netz.'
        PowerBat     = 'Strom: im Akkubetrieb ({0}%). Schliess das Ladegeraet vor dem Spielen an: viele Laptops drosseln CPU und GPU im Akkubetrieb.'
        PowerNone    = 'Strom: kein Akku (Desktop).'
        Gpu          = 'GPU: {0}  -  Treiber {1} ({2})'
        BtnDriver    = 'Treiberseite von {0}'
        DriverTip    = 'Oeffnet die offizielle Treiber-Downloadseite des Herstellers deiner GPU.'
        BtnZip       = 'Support-Zip'
        ZipTip       = 'Legt den SIGAME-Bericht und die Logs in ein Zip auf deinem Desktop, zum Anhaengen an ein GitHub-Issue.'
        ZipDone      = "Auf dem Desktop gespeichert:`n{0}`n`nEs enthaelt den SIGAME-Bericht und die Logs, keine Passwoerter. Die Logs koennen Ordnerpfade enthalten: schau es vor dem Teilen an."
        ZipFail      = 'Das Support-Zip konnte nicht erstellt werden: {0}'
        BtnExport    = 'Profil exportieren'
        BtnImport    = 'Profil importieren'
        ProfileTip   = 'Deine Boost-Liste, deine angewendeten SI PRESETS und deine Wahl zu anonymen Statistiken in einer Datei: behalte sie, oder lade sie nach einer Neuinstallation.'
        ExportDone   = "Profil gespeichert:`n{0}"
        ImportDone   = 'Profil geladen: {0} Spiele in der Boost-Liste.'
        ImportBad    = 'Diese Datei ist kein SIGAME-Profil.'
        ImportPreset = "Das Profil hat {0} SI PRESETS fuer hier gefundene Spiele, die noch nicht angewendet sind. Jetzt anwenden? Jedes fragt vorher."
        BtnWhatsNew  = 'Neuigkeiten'
        NoNotes      = 'Noch keine Notizen: sie erscheinen nach dem naechsten Update.'
        HintPreset   = 'SI PRESET fuer {0}: "{1}" ist bereit und noch nicht angewendet. Oeffne SIGAME > SI PRESETS.'
        HintBattery  = '{0} wurde im Akkubetrieb gestartet. Schliess das Ladegeraet fuer volle Leistung an.'
        LaunchOpt    = "Noch ein Schritt fuer {0}: die Startoption {1} ist kopiert.`n`nIn Steam: Rechtsklick auf das Spiel > Eigenschaften > Startoptionen, dann einfuegen (Strg+V)."
        VoteUp       = 'Dieses Preset funktioniert bei mir'
        VoteDown     = 'Dieses Preset funktioniert bei mir nicht'
        VoteThanks   = 'Danke, deine Stimme fuer {0} ist gesendet.'
        VoteLocal    = 'Deine Stimme fuer {0} ist hier gespeichert. Anonyme Statistiken sind aus, daher wird sie nicht gesendet.'
    }
    'fr' = @{
        Title        = 'Verification du PC et outils PRO'
        PowerAc      = 'Alimentation : sur secteur.'
        PowerBat     = "Alimentation : sur batterie ({0}%). Branche le chargeur avant de jouer : beaucoup de portables limitent le CPU et le GPU sur batterie."
        PowerNone    = 'Alimentation : pas de batterie (PC fixe).'
        Gpu          = 'GPU : {0}  -  pilote {1} ({2})'
        BtnDriver    = 'Page des pilotes {0}'
        DriverTip    = 'Ouvre la page officielle de telechargement des pilotes du fabricant de ton GPU.'
        BtnZip       = 'Zip de support'
        ZipTip       = 'Met le rapport et les logs de SIGAME dans un zip sur ton bureau, a joindre a une issue GitHub.'
        ZipDone      = "Enregistre sur ton bureau :`n{0}`n`nIl contient le rapport et les logs de SIGAME, aucun mot de passe. Les logs peuvent contenir des chemins de dossiers : regarde-le avant de le partager."
        ZipFail      = 'Impossible de creer le zip de support : {0}'
        BtnExport    = 'Exporter le profil'
        BtnImport    = 'Importer le profil'
        ProfileTip   = "Ta liste de boost, tes SI PRESETS appliques et ton choix sur les statistiques anonymes dans un fichier : garde-le, ou charge-le apres une nouvelle installation."
        ExportDone   = "Profil enregistre :`n{0}"
        ImportDone   = 'Profil charge : {0} jeux dans la liste de boost.'
        ImportBad    = "Ce fichier n'est pas un profil SIGAME."
        ImportPreset = "Le profil a {0} SI PRESETS pour des jeux trouves ici et pas encore appliques. Les appliquer maintenant ? Chacun demande avant."
        BtnWhatsNew  = 'Nouveautes'
        NoNotes      = "Pas encore de notes : elles apparaissent apres la prochaine mise a jour."
        HintPreset   = 'SI PRESET pour {0} : "{1}" est pret et pas encore applique. Ouvre SIGAME > SI PRESETS.'
        HintBattery  = '{0} a demarre sur batterie. Branche le chargeur pour la pleine vitesse.'
        LaunchOpt    = "Encore une etape pour {0} : l'option de lancement {1} est copiee.`n`nDans Steam : clic droit sur le jeu > Proprietes > Options de lancement, puis colle-la (Ctrl+V)."
        VoteUp       = 'Ce preset marche pour moi'
        VoteDown     = 'Ce preset ne marche pas pour moi'
        VoteThanks   = 'Merci, ton vote pour {0} est envoye.'
        VoteLocal    = "Ton vote pour {0} est enregistre ici. Les statistiques anonymes sont desactivees, il n'est donc pas envoye."
    }
}

function Get-SIProText {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    if ($script:SIProText.ContainsKey($lang) -and $script:SIProText[$lang].ContainsKey($Key)) {
        return $script:SIProText[$lang][$Key]
    }
    return $script:SIProText['en'][$Key]
}

# ------------------------------- PC check ----------------------------------

function Get-SIPowerInfo {
    # PowerLineStatus Offline + a battery = on battery
    $r = [pscustomobject]@{ HasBattery = $false; OnBattery = $false; Percent = -1 }
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $p = [System.Windows.Forms.SystemInformation]::PowerStatus
        $noBattery = ([string]$p.BatteryChargeStatus) -match 'NoSystemBattery|Unknown'
        $r.HasBattery = -not $noBattery
        $r.OnBattery = ($r.HasBattery -and ([string]$p.PowerLineStatus -eq 'Offline'))
        if ($r.HasBattery) { $r.Percent = [int]([double]$p.BatteryLifePercent * 100) }
    } catch { }
    return $r
}

function Get-SIPowerText {
    $p = Get-SIPowerInfo
    if (-not $p.HasBattery) { return (Get-SIProText 'PowerNone') }
    if ($p.OnBattery) { return ((Get-SIProText 'PowerBat') -f $p.Percent) }
    return (Get-SIProText 'PowerAc')
}

function Get-SIGpuDriverInfo {
    # every display adapter but the basic / remote ones, with the official driver page of its maker
    $list = @()
    try {
        foreach ($v in @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)) {
            $name = [string]$v.Name
            if (-not $name -or $name -match 'Basic Display|Remote Display|Hyper-V|Virtual') { continue }
            $vendor = ''; $url = ''
            if ($name -match 'NVIDIA|GeForce|Quadro|RTX') { $vendor = 'NVIDIA'; $url = 'https://www.nvidia.com/Download/index.aspx' }
            elseif ($name -match 'AMD|Radeon') { $vendor = 'AMD'; $url = 'https://www.amd.com/en/support/download/drivers.html' }
            elseif ($name -match 'Intel') { $vendor = 'Intel'; $url = 'https://www.intel.com/content/www/us/en/support/detect.html' }
            $date = ''
            try { if ($v.DriverDate) { $date = ([datetime]$v.DriverDate).ToString('yyyy-MM-dd') } } catch { }
            $list += [pscustomobject]@{ Name = $name; Driver = [string]$v.DriverVersion; Date = $date; Vendor = $vendor; Url = $url }
        }
    } catch { }
    return $list
}

# ------------------------------- support zip -------------------------------

function Export-SISupportZip {
    <#
    .SYNOPSIS
        The SIGAME report + logs + state files in one zip on the desktop.
        Returns the zip path ('' = failed, the reason is in $script:SIProLastError).
    #>
    $script:SIProLastError = ''
    try {
        $report = ''
        if (Get-Command Export-SIGamingDiagnosticReport -ErrorAction SilentlyContinue) { $report = Export-SIGamingDiagnosticReport }
        $stamp = [datetime]::Now.ToString('yyyyMMdd-HHmm')
        $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "SIGAME-support-$stamp")
        [void][System.IO.Directory]::CreateDirectory($tmp)
        $names = @('SI-GAME-REPORT.txt', 'SI-GAME.log', 'SI-GAME-backup.json', 'SI-GAME-measures.json', 'SI-GAME-boost.json',
                   'SI-GAME-community.json', 'SI-GAME-fps.json', 'SI-GAME-guard.json', 'SI-GAME-srfreq.json', 'version.json')
        foreach ($n in $names) {
            $src = [System.IO.Path]::Combine($script:SIRoot, $n)
            if ([System.IO.File]::Exists($src)) { [System.IO.File]::Copy($src, [System.IO.Path]::Combine($tmp, $n), $true) }
        }
        $info = @("SIGAME $script:SIGameVersion", "Windows $([System.Environment]::OSVersion.Version)", "Created $([datetime]::Now.ToString('s'))")
        [System.IO.File]::WriteAllLines([System.IO.Path]::Combine($tmp, 'SIGAME-version.txt'), $info)
        $desk = [System.Environment]::GetFolderPath('Desktop')
        if (-not $desk) { $desk = $script:SIRoot }
        $zip = [System.IO.Path]::Combine($desk, "SIGAME-support-$stamp.zip")
        Compress-Archive -Path ([System.IO.Path]::Combine($tmp, '*')) -DestinationPath $zip -Force -ErrorAction Stop
        try { [System.IO.Directory]::Delete($tmp, $true) } catch { }
        Write-SILog -Component 'Pro' -Message "Support zip saved: $zip (report: $([bool]$report))"
        return $zip
    } catch {
        $script:SIProLastError = [string]$_.Exception.Message
        Write-SILog -Level 'WARN' -Component 'Pro' -Message "Support zip: $script:SIProLastError"
        return ''
    }
}

# ------------------------------- profile -----------------------------------

function Get-SIProfileObject {
    $boost = Read-SIJsonFile -Path $script:SIBoostPath
    $state = Get-SICommunityState
    $ids = @($state.Applied.PSObject.Properties.Name)
    return [ordered]@{
        Kind      = 'SIGAME-profile'
        Version   = $script:SIGameVersion
        Created   = [datetime]::Now.ToString('s')
        Telemetry = [bool]$state.Telemetry
        Presets   = $ids
        Boost     = $boost
    }
}

function Export-SIProfile {
    param([string]$Path = '')
    if (-not $Path) {
        $dlg = [Microsoft.Win32.SaveFileDialog]::new()
        $dlg.FileName = 'SIGAME-profile.json'
        $dlg.Filter = 'SIGAME profile (*.json)|*.json'
        $dlg.InitialDirectory = [System.Environment]::GetFolderPath('Desktop')
        if (-not $dlg.ShowDialog()) { return '' }
        $Path = $dlg.FileName
    }
    [System.IO.File]::WriteAllText($Path, ((Get-SIProfileObject) | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
    Write-SILog -Component 'Pro' -Message "Profile exported: $Path"
    return $Path
}

function Import-SIProfile {
    <#
    .SYNOPSIS
        Loads a profile: boost list + anonymous stats choice. Returns the SI PRESET
        entries of the profile found on this PC and not applied yet ($null = not a profile).
    #>
    param([Parameter(Mandatory = $true)][string]$Path)
    $p = Read-SIJsonFile -Path $Path
    if (-not $p -or [string]$p.Kind -ne 'SIGAME-profile') { return $null }
    if ($p.Boost) {
        # the old list is kept next to it, never deleted
        if ([System.IO.File]::Exists($script:SIBoostPath)) {
            [System.IO.File]::Copy($script:SIBoostPath, $script:SIBoostPath + '.before-import', $true)
        }
        # only the player's choices; what the last boost closed stays local
        $cur = Get-SIBoostState
        foreach ($k in @('Games', 'Ticked', 'AutoBoost', 'Configured')) {
            if ($p.Boost.PSObject.Properties.Name -contains $k) { $cur[$k] = $p.Boost.$k }
        }
        [void](Save-SIBoostState -State $cur)
    }
    $state = Get-SICommunityState
    $state.Telemetry = [bool]$p.Telemetry
    Save-SICommunityState -State $state
    $applied = @($state.Applied.PSObject.Properties.Name)
    $todo = @()
    foreach ($e in (Get-SIPresetCatalog)) {
        if ((@($p.Presets) -contains [string]$e.Id) -and -not ($applied -contains [string]$e.Id)) {
            $found = $true
            if (Get-Command Test-SIPresetFound -ErrorAction SilentlyContinue) { $found = [bool](Test-SIPresetFound -Entry $e) }
            if ($found) { $todo += $e }
        }
    }
    Write-SILog -Component 'Pro' -Message "Profile imported: $Path ($($todo.Count) presets to offer)"
    return , $todo
}

function Get-SIProfileGameCount {
    $b = Read-SIJsonFile -Path $script:SIBoostPath
    if (-not $b) { return 0 }
    foreach ($n in @('Games', 'List', 'BoostList')) {
        if ($b.PSObject.Properties.Name -contains $n) { return @($b.$n).Count }
    }
    return 0
}

# ------------------------------- what's new --------------------------------

function Show-SIWhatsNew {
    $state = Get-SICommunityState
    $t = ''
    if ($state.PSObject.Properties.Name -contains 'LastNotes') { $t = [string]$state.LastNotes }
    if (-not $t) { $t = Get-SIProText 'NoNotes' }
    Show-SIInfoBox -Text $t
}

# ------------------------------- game start hints --------------------------

function Invoke-SIGameStartHints {
    <#
    .SYNOPSIS
        Once per game start (Auto-Boost): a tray note when a SI PRESET is ready for
        the game and not applied yet, and when the PC is on battery.
    #>
    param([string]$Game)
    if (-not $Game) { return }
    try {
        $card = $null
        foreach ($g in @($script:SIGameLibrary)) { if ($g -and [string]$g.Name -eq $Game) { $card = $g; break } }
        if (-not $card) { $card = [pscustomobject]@{ Name = $Game; Exe = ''; Folder = '' } }
        $e = Find-SIGamePreset -Game $card
        if ($e) {
            $state = Get-SICommunityState
            if (-not (@($state.Applied.PSObject.Properties.Name) -contains [string]$e.Id)) {
                Show-SITrayNotification -Title 'SI PRESET' -Text ((Get-SIProText 'HintPreset') -f $Game, [string]$e.Title)
                Write-SILog -Component 'Pro' -Message "Hint: preset $($e.Id) ready for $Game"
                return
            }
        }
        $p = Get-SIPowerInfo
        if ($p.OnBattery) {
            Show-SITrayNotification -Title 'SIGAME' -Text ((Get-SIProText 'HintBattery') -f $Game)
            Write-SILog -Component 'Pro' -Message "Hint: $Game started on battery ($($p.Percent)%)"
        }
    } catch { }
}

# ------------------------------- Steam launch options ----------------------

function Show-SILaunchOptionsHint {
    # a preset that needs a Steam launch option (catalog field LaunchOptions, from the preset's source)
    param($Entry, $Window = $null)
    $opt = ''
    if ($Entry.PSObject.Properties.Name -contains 'LaunchOptions') { $opt = [string]$Entry.LaunchOptions }
    if (-not $opt) { return }
    try { Set-Clipboard -Value $opt } catch { try { [System.Windows.Clipboard]::SetText($opt) } catch { } }
    $text = (Get-SIProText 'LaunchOpt') -f [string]$Entry.Game, $opt
    if (-not $Window) { $Window = $script:SIWindow }
    if ($Window) { [void][System.Windows.MessageBox]::Show($Window, $text, "SI PRESET $($Entry.Title)") }
    else { Show-SIInfoBox -Text $text }
}

# ------------------------------- preset vote -------------------------------

function Send-SIPresetVote {
    param($Entry, [ValidateSet('up', 'down')][string]$Vote)
    $state = Get-SICommunityState
    if (-not ($state.PSObject.Properties.Name -contains 'Votes')) { $state | Add-Member 'Votes' ([pscustomobject]@{}) -Force }
    $state.Votes | Add-Member ([string]$Entry.Id) $Vote -Force
    Save-SICommunityState -State $state
    Send-SITelemetry -Event (New-SITelemetryEvent -Kind 'preset_vote' -Preset ([string]$Entry.Id) -Message $Vote)
    $key = if ($state.Telemetry) { 'VoteThanks' } else { 'VoteLocal' }
    Set-SIStatusText -Text ((Get-SIProText $key) -f [string]$Entry.Title)
}

function Add-SIPresetVoteButtons {
    <#
    .SYNOPSIS
        Thumbs up / down next to APPLY, only on an applied preset (a vote = the player tried it).
    #>
    param($Dock, $Entry, $Window)
    $state = Get-SICommunityState
    $mine = ''
    if (($state.PSObject.Properties.Name -contains 'Votes') -and ($state.Votes.PSObject.Properties.Name -contains [string]$Entry.Id)) {
        $mine = [string]$state.Votes.([string]$Entry.Id)
    }
    foreach ($v in @('down', 'up')) {
        $glyph = if ($v -eq 'up') { [char]::ConvertFromUtf32(0x1F44D) } else { [char]::ConvertFromUtf32(0x1F44E) }
        $style = if ($mine -eq $v) { 'AccentButton' } else { 'GhostButton' }
        $b = New-SIStyleButton -Text $glyph -StyleKey $style -Window $Window -Width 34
        $b.Height = 28
        $b.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
        $b.VerticalAlignment = 'Center'
        $b.ToolTip = if ($v -eq 'up') { Get-SIProText 'VoteUp' } else { Get-SIProText 'VoteDown' }
        [System.Windows.Controls.DockPanel]::SetDock($b, 'Right')
        $cap = $Entry; $cv = $v
        $null = $b.Add_Click({
            Send-SIPresetVote -Entry $cap -Vote $cv
            if ($script:SIPresetsFill) { & $script:SIPresetsFill $script:SIPresetsQuery }
        }.GetNewClosure())
        [void]$Dock.Children.Add($b)
    }
}

# ------------------------------- Advanced section --------------------------

function Add-SIProToolsSection {
    param($Panel, $Window)
    $null = $Panel.Children.Add((New-SIToolTitle -Text (Get-SIProText 'Title')))
    $null = $Panel.Children.Add((New-SIToolText -Text (Get-SIPowerText)))
    $gpus = @(Get-SIGpuDriverInfo)
    foreach ($g in $gpus) {
        $null = $Panel.Children.Add((New-SIToolText -Text ((Get-SIProText 'Gpu') -f $g.Name, $g.Driver, $g.Date)))
    }
    $row = [System.Windows.Controls.WrapPanel]::new()
    $seen = @{}
    foreach ($g in $gpus) {
        if (-not $g.Url -or $seen.ContainsKey($g.Vendor)) { continue }
        $seen[$g.Vendor] = $true
        $b = New-SIStyleButton -Text ((Get-SIProText 'BtnDriver') -f $g.Vendor) -StyleKey 'GhostButton' -Window $Window
        $b.ToolTip = Get-SIProText 'DriverTip'
        $u = $g.Url
        $null = $b.Add_Click({ try { Start-Process $u } catch { } }.GetNewClosure())
        $null = $row.Children.Add($b)
    }
    $zip = New-SIStyleButton -Text (Get-SIProText 'BtnZip') -StyleKey 'GhostButton' -Window $Window
    $zip.ToolTip = Get-SIProText 'ZipTip'
    $null = $zip.Add_Click({
        $z = Export-SISupportZip
        if ($z) { Show-SIInfoBox -Text ((Get-SIProText 'ZipDone') -f $z) }
        else { Show-SIInfoBox -Text ((Get-SIProText 'ZipFail') -f $script:SIProLastError) }
    })
    $null = $row.Children.Add($zip)
    $null = $Panel.Children.Add($row)

    $row2 = [System.Windows.Controls.WrapPanel]::new()
    $ex = New-SIStyleButton -Text (Get-SIProText 'BtnExport') -StyleKey 'GhostButton' -Window $Window
    $ex.ToolTip = Get-SIProText 'ProfileTip'
    $null = $ex.Add_Click({
        try {
            $p = Export-SIProfile
            if ($p) { Show-SIInfoBox -Text ((Get-SIProText 'ExportDone') -f $p) }
        } catch { Show-SIInfoBox -Text $_.Exception.Message }
    })
    $null = $row2.Children.Add($ex)
    $im = New-SIStyleButton -Text (Get-SIProText 'BtnImport') -StyleKey 'GhostButton' -Window $Window
    $im.ToolTip = Get-SIProText 'ProfileTip'
    $null = $im.Add_Click({
        try {
            $dlg = [Microsoft.Win32.OpenFileDialog]::new()
            $dlg.Filter = 'SIGAME profile (*.json)|*.json'
            $dlg.InitialDirectory = [System.Environment]::GetFolderPath('Desktop')
            if (-not $dlg.ShowDialog()) { return }
            $todo = Import-SIProfile -Path $dlg.FileName
            if ($null -eq $todo) { Show-SIInfoBox -Text (Get-SIProText 'ImportBad'); return }
            Show-SIInfoBox -Text ((Get-SIProText 'ImportDone') -f (Get-SIProfileGameCount))
            if (@($todo).Count -gt 0 -and (Show-SIMessage -Window $script:SIWindow -Title 'SI PRESETS' -Text ((Get-SIProText 'ImportPreset') -f @($todo).Count))) {
                foreach ($e in @($todo)) { Invoke-SIGamePreset -Entry $e }
            }
        } catch { Show-SIInfoBox -Text $_.Exception.Message }
    })
    $null = $row2.Children.Add($im)
    $wn = New-SIStyleButton -Text (Get-SIProText 'BtnWhatsNew') -StyleKey 'GhostButton' -Window $Window
    $null = $wn.Add_Click({ Show-SIWhatsNew })
    $null = $row2.Children.Add($wn)
    $null = $Panel.Children.Add($row2)
}

# ------------------------------- command line ------------------------------

function Invoke-SICli {
    <#
    .SYNOPSIS
        SI-GAME-AUTO.ps1 -ListPresets | -Preset <id> | -UndoPreset <id> [-Silent]
        No window: prints the result, writes it in SI-GAME.log, returns the exit code.
    #>
    param([string]$Preset = '', [string]$UndoPreset = '', [switch]$ListPresets)
    $out = [System.Collections.Generic.List[string]]::new()
    $code = 0
    try {
        $catalog = @(Get-SIPresetCatalog)
        $state = Get-SICommunityState
        $applied = @($state.Applied.PSObject.Properties.Name)
        if ($ListPresets) {
            foreach ($e in $catalog) {
                $found = ''
                try { if (Test-SIPresetFound -Entry $e) { $found = 'found' } } catch { }
                $on = if ($applied -contains [string]$e.Id) { 'applied' } else { '' }
                $out.Add(('{0,-24} {1,-8} {2,-6} {3}' -f $e.Id, $on, $found, $e.Game))
            }
        } else {
            $id = if ($UndoPreset) { $UndoPreset } else { $Preset }
            $e = $catalog | Where-Object { [string]$_.Id -eq $id } | Select-Object -First 1
            if (-not $e) {
                $out.Add("Unknown preset: $id (use -ListPresets)"); $code = 2
            } elseif ($UndoPreset -and -not $e.Undo) {
                $out.Add("$id has no UNDO."); $code = 3
            } else {
                $undo = [bool]$UndoPreset
                $r = Invoke-SIPresetScript -Entry $e -Undo:$undo
                foreach ($l in @($r.Lines)) { if ($l) { $out.Add([string]$l) } }
                if ($r.Ok) {
                    if ($undo) { $state.Applied.PSObject.Properties.Remove([string]$e.Id) }
                    else { $state.Applied | Add-Member ([string]$e.Id) ([datetime]::Now.ToString('s')) -Force }
                    Save-SICommunityState -State $state
                    $kind = if ($undo) { 'preset_undo' } else { 'preset_applied' }
                    Send-SITelemetry -Event (New-SITelemetryEvent -Kind $kind -Preset ([string]$e.Id) -Message 'cli')
                    if (-not $undo -and ($e.PSObject.Properties.Name -contains 'LaunchOptions') -and $e.LaunchOptions) {
                        $out.Add("Steam launch option needed: $($e.LaunchOptions)")
                    }
                    $out.Add(($(if ($undo) { 'UNDO' } else { 'APPLIED' }) + ": $id"))
                } else {
                    $out.Add("FAILED: $id"); $code = 1
                }
            }
        }
    } catch {
        $out.Add("SIGAME CLI error: $($_.Exception.Message)"); $code = 1
    }
    foreach ($l in $out) { [System.Console]::WriteLine($l) }
    try { Write-SILog -Component 'CLI' -Message (($out | Select-Object -Last 3) -join ' | ') } catch { }
    return $code
}
