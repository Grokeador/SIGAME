# SIGAME - extra tools (19/11/2026): previous version, game updates after a preset,
# games on an HDD, no Windows Update restarts and no notifications while playing,
# overlays, ping to the Valve servers, light/dark theme and text size.
# Settings in SI-GAME-extra.json. Nothing here claims more FPS.

$script:SIExtraText = @{
    'en' = @{
        Title       = 'MORE TOOLS'
        BtnRollback = 'Go back to the previous version'
        RollNone    = 'There is no previous version saved yet (it is kept at every update).'
        RollAsk     = "Go back from SIGAME {0} to {1}?`nSIGAME restarts. Version {0} is not installed again by itself: the next newer version is."
        RollDone    = 'SIGAME {0} is back. It restarts now.'
        RollFail    = 'The previous version could not be put back: {0}'
        GameUpdated = '{0} was updated since its SI PRESET was applied ({1} -> {2}). A game update can put its settings back: open SI PRESETS and apply it again if needed.'
        BtnDisks    = 'Are my games on an SSD?'
        DiskHdd     = '{0} is on an HDD (drive {1}).'
        DiskAllSsd  = 'Every game of the list is on an SSD.'
        DiskTip     = 'Games on an HDD load slower than on an SSD. Steam and Epic can move a game to another drive.'
        DiskNoSsd   = 'There is no SSD on this computer: nothing to move.'
        DiskNone    = 'No game with a known folder in the list.'
        BtnWu       = 'No Windows Update restarts while playing: {0}'
        WuTip       = 'When a game starts, the Windows active hours are set around now; Windows does not restart for updates inside active hours. They are put back when the game ends. Needs AUTO-BOOST on.'
        BtnDnd      = 'No notifications while playing: {0}'
        DndTip      = 'When a game starts, the Windows notifications are turned off; they come back when the game ends. Needs AUTO-BOOST on.'
        On          = 'ON'
        Off         = 'OFF'
        NeedAdmin   = 'Windows did not allow the change (start SIGAME as administrator).'
        BtnOverlay  = 'Check the overlays'
        OverlayNone = 'No in-game overlay program is running now.'
        OverlayHead = "Running now, with an overlay that draws inside games:`n`n{0}`n`nTo try a game without it, turn the overlay off there."
        BtnPing     = 'Ping the Valve servers (CS2, Dota 2)'
        PingHead    = "Ping to the Valve relays (list from api.steampowered.com):`n`n{0}"
        PingFail    = 'The list of the Valve servers could not be downloaded (no internet?).'
        PingNoReply = 'no reply'
        BtnTheme    = 'Theme: {0}'
        ThemeDark   = 'dark'
        ThemeLight  = 'light'
        ThemeAuto   = 'like Windows'
        ThemeAsk    = 'SIGAME restarts to change the theme. Restart now?'
        BtnText     = 'Text size: {0}'
        TextAuto    = 'like Windows'
    }
    'it' = @{
        Title       = 'ALTRI STRUMENTI'
        BtnRollback = 'Torna alla versione precedente'
        RollNone    = "Non c'e ancora una versione precedente salvata (viene tenuta a ogni aggiornamento)."
        RollAsk     = "Tornare da SIGAME {0} a {1}?`nSIGAME si riavvia. La versione {0} non si reinstalla da sola: si installa la prossima piu nuova."
        RollDone    = 'SIGAME {0} e tornato. Ora si riavvia.'
        RollFail    = 'Non e stato possibile rimettere la versione precedente: {0}'
        GameUpdated = '{0} e stato aggiornato dopo il suo SI PRESET ({1} -> {2}). Un aggiornamento puo rimettere le impostazioni: apri SI PRESETS e riapplicalo se serve.'
        BtnDisks    = 'I miei giochi sono su SSD?'
        DiskHdd     = '{0} e su un HDD (unita {1}).'
        DiskAllSsd  = 'Tutti i giochi della lista sono su SSD.'
        DiskTip     = 'I giochi su HDD caricano piu lentamente che su SSD. Steam ed Epic possono spostare un gioco su un altro disco.'
        DiskNoSsd   = "Su questo computer non c'e un SSD: niente da spostare."
        DiskNone    = 'Nessun gioco con una cartella nota nella lista.'
        BtnWu       = 'Niente riavvii di Windows Update mentre giochi: {0}'
        WuTip       = "Quando parte un gioco, l'orario di attivita di Windows viene messo attorno ad adesso; Windows non si riavvia per gli aggiornamenti in quell'orario. Torna com'era a fine gioco. Serve AUTO-BOOST attivo."
        BtnDnd      = 'Niente notifiche mentre giochi: {0}'
        DndTip      = 'Quando parte un gioco, le notifiche di Windows si spengono; tornano a fine gioco. Serve AUTO-BOOST attivo.'
        On          = 'SI'
        Off         = 'NO'
        NeedAdmin   = 'Windows non ha permesso la modifica (avvia SIGAME come amministratore).'
        BtnOverlay  = 'Controlla gli overlay'
        OverlayNone = 'Nessun programma con overlay nei giochi e aperto adesso.'
        OverlayHead = "Aperti adesso, con un overlay che disegna dentro i giochi:`n`n{0}`n`nPer provare un gioco senza, spegni li l'overlay."
        BtnPing     = 'Ping ai server Valve (CS2, Dota 2)'
        PingHead    = "Ping ai relay Valve (lista da api.steampowered.com):`n`n{0}"
        PingFail    = 'Non e stato possibile scaricare la lista dei server Valve (niente internet?).'
        PingNoReply = 'nessuna risposta'
        BtnTheme    = 'Tema: {0}'
        ThemeDark   = 'scuro'
        ThemeLight  = 'chiaro'
        ThemeAuto   = 'come Windows'
        ThemeAsk    = 'SIGAME si riavvia per cambiare tema. Riavviare ora?'
        BtnText     = 'Dimensione testo: {0}'
        TextAuto    = 'come Windows'
    }
    'pt-BR' = @{
        Title       = 'MAIS FERRAMENTAS'
        BtnRollback = 'Voltar para a versao anterior'
        RollNone    = 'Ainda nao ha uma versao anterior salva (ela e guardada a cada atualizacao).'
        RollAsk     = "Voltar do SIGAME {0} para o {1}?`nO SIGAME reinicia. A versao {0} nao e instalada de novo sozinha: a proxima mais nova e."
        RollDone    = 'O SIGAME {0} voltou. Ele reinicia agora.'
        RollFail    = 'Nao foi possivel voltar a versao anterior: {0}'
        GameUpdated = '{0} foi atualizado depois do SI PRESET ({1} -> {2}). Uma atualizacao pode voltar as configuracoes: abra SI PRESETS e aplique de novo se precisar.'
        BtnDisks    = 'Meus jogos estao em SSD?'
        DiskHdd     = '{0} esta em um HD (unidade {1}).'
        DiskAllSsd  = 'Todos os jogos da lista estao em SSD.'
        DiskTip     = 'Jogos em HD carregam mais devagar que em SSD. A Steam e a Epic podem mover um jogo para outro disco.'
        DiskNoSsd   = 'Nao ha SSD neste computador: nada para mover.'
        DiskNone    = 'Nenhum jogo com pasta conhecida na lista.'
        BtnWu       = 'Sem reinicio do Windows Update enquanto joga: {0}'
        WuTip       = 'Quando um jogo abre, o horario ativo do Windows e colocado em volta de agora; o Windows nao reinicia para atualizacoes no horario ativo. Volta ao normal quando o jogo fecha. Precisa do AUTO-BOOST ligado.'
        BtnDnd      = 'Sem notificacoes enquanto joga: {0}'
        DndTip      = 'Quando um jogo abre, as notificacoes do Windows sao desligadas; elas voltam quando o jogo fecha. Precisa do AUTO-BOOST ligado.'
        On          = 'LIGADO'
        Off         = 'DESLIGADO'
        NeedAdmin   = 'O Windows nao permitiu a mudanca (abra o SIGAME como administrador).'
        BtnOverlay  = 'Verificar os overlays'
        OverlayNone = 'Nenhum programa com overlay nos jogos esta aberto agora.'
        OverlayHead = "Abertos agora, com um overlay que desenha dentro dos jogos:`n`n{0}`n`nPara testar um jogo sem ele, desligue o overlay ali."
        BtnPing     = 'Ping nos servidores da Valve (CS2, Dota 2)'
        PingHead    = "Ping nos relays da Valve (lista de api.steampowered.com):`n`n{0}"
        PingFail    = 'Nao foi possivel baixar a lista dos servidores da Valve (sem internet?).'
        PingNoReply = 'sem resposta'
        BtnTheme    = 'Tema: {0}'
        ThemeDark   = 'escuro'
        ThemeLight  = 'claro'
        ThemeAuto   = 'igual ao Windows'
        ThemeAsk    = 'O SIGAME reinicia para mudar o tema. Reiniciar agora?'
        BtnText     = 'Tamanho do texto: {0}'
        TextAuto    = 'igual ao Windows'
    }
    'es' = @{
        Title       = 'MAS HERRAMIENTAS'
        BtnRollback = 'Volver a la version anterior'
        RollNone    = 'Todavia no hay una version anterior guardada (se guarda en cada actualizacion).'
        RollAsk     = "Volver de SIGAME {0} a {1}?`nSIGAME se reinicia. La version {0} no se instala sola otra vez: se instala la siguiente mas nueva."
        RollDone    = 'SIGAME {0} ha vuelto. Se reinicia ahora.'
        RollFail    = 'No se pudo volver a la version anterior: {0}'
        GameUpdated = '{0} se actualizo despues de su SI PRESET ({1} -> {2}). Una actualizacion puede devolver los ajustes: abre SI PRESETS y aplicalo otra vez si hace falta.'
        BtnDisks    = 'Mis juegos estan en SSD?'
        DiskHdd     = '{0} esta en un HDD (unidad {1}).'
        DiskAllSsd  = 'Todos los juegos de la lista estan en SSD.'
        DiskTip     = 'Los juegos en HDD cargan mas lento que en SSD. Steam y Epic pueden mover un juego a otro disco.'
        DiskNoSsd   = 'No hay SSD en este equipo: nada que mover.'
        DiskNone    = 'Ningun juego con carpeta conocida en la lista.'
        BtnWu       = 'Sin reinicios de Windows Update mientras juegas: {0}'
        WuTip       = 'Cuando arranca un juego, las horas activas de Windows se ponen alrededor de ahora; Windows no se reinicia por actualizaciones dentro de las horas activas. Vuelven al terminar el juego. Necesita AUTO-BOOST activado.'
        BtnDnd      = 'Sin notificaciones mientras juegas: {0}'
        DndTip      = 'Cuando arranca un juego, las notificaciones de Windows se apagan; vuelven al terminar el juego. Necesita AUTO-BOOST activado.'
        On          = 'SI'
        Off         = 'NO'
        NeedAdmin   = 'Windows no permitio el cambio (abre SIGAME como administrador).'
        BtnOverlay  = 'Revisar los overlays'
        OverlayNone = 'Ningun programa con overlay en los juegos esta abierto ahora.'
        OverlayHead = "Abiertos ahora, con un overlay que dibuja dentro de los juegos:`n`n{0}`n`nPara probar un juego sin el, apaga ahi el overlay."
        BtnPing     = 'Ping a los servidores de Valve (CS2, Dota 2)'
        PingHead    = "Ping a los relays de Valve (lista de api.steampowered.com):`n`n{0}"
        PingFail    = 'No se pudo descargar la lista de servidores de Valve (sin internet?).'
        PingNoReply = 'sin respuesta'
        BtnTheme    = 'Tema: {0}'
        ThemeDark   = 'oscuro'
        ThemeLight  = 'claro'
        ThemeAuto   = 'como Windows'
        ThemeAsk    = 'SIGAME se reinicia para cambiar el tema. Reiniciar ahora?'
        BtnText     = 'Tamano del texto: {0}'
        TextAuto    = 'como Windows'
    }
}

function Get-SIExtraText {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    if ($script:SIExtraText.ContainsKey($lang) -and $script:SIExtraText[$lang].ContainsKey($Key)) { return $script:SIExtraText[$lang][$Key] }
    return $script:SIExtraText['en'][$Key]
}

# ------------------------------- settings ----------------------------------

function Get-SIExtraPath { [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-extra.json') }

function Get-SIExtraState {
    $s = $null
    try { $s = Read-SIJsonFile -Path (Get-SIExtraPath) } catch { }
    if (-not $s) { $s = [pscustomobject]@{} }
    if (-not ($s.PSObject.Properties.Name -contains 'Theme')) { $s | Add-Member 'Theme' 'dark' }
    if (-not ($s.PSObject.Properties.Name -contains 'TextSize')) { $s | Add-Member 'TextSize' 'auto' }
    if (-not ($s.PSObject.Properties.Name -contains 'NoWuRestart')) { $s | Add-Member 'NoWuRestart' $false }
    if (-not ($s.PSObject.Properties.Name -contains 'NoNotify')) { $s | Add-Member 'NoNotify' $false }
    if (-not ($s.PSObject.Properties.Name -contains 'GameVersions')) { $s | Add-Member 'GameVersions' ([pscustomobject]@{}) }
    return $s
}

function Save-SIExtraState {
    param($State)
    try { [System.IO.File]::WriteAllText((Get-SIExtraPath), ($State | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false)) }
    catch { Write-SILog -Level 'WARN' -Component 'Extra' -Message "SI-GAME-extra.json not saved: $($_.Exception.Message)" }
}

# ------------------------------- previous version --------------------------

function Get-SIPreviousVersion {
    <# The newest SI-GAME-update-backup\<version> that is not the running version (Install-SIUpdate fills it). #>
    $dir = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-update-backup')
    if (-not [System.IO.Directory]::Exists($dir)) { return $null }
    $d = Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne [string]$script:SIGameVersion -and (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Filter '*.ps1' -ErrorAction SilentlyContinue) } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $d
}

function Invoke-SIRollback {
    <# Puts the files of the previous version back, holds the current version from the silent update, restarts. #>
    param([switch]$NoRestart)
    $prev = Get-SIPreviousVersion
    if (-not $prev) { Show-SIInfoBox -Text (Get-SIExtraText 'RollNone'); return $false }
    if (-not $NoRestart -and -not (Show-SIMessage -Window $script:SIWindow -Title 'SIGAME' -Text ((Get-SIExtraText 'RollAsk') -f $script:SIGameVersion, $prev.Name))) { return $false }
    try {
        foreach ($f in @(Get-ChildItem -LiteralPath $prev.FullName -Recurse -File)) {
            $rel = $f.FullName.Substring($prev.FullName.Length).TrimStart('\')
            $tok = $null; $errs = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tok, [ref]$errs)
            if ($errs -and $errs.Count -gt 0) { throw "$rel does not parse" }
            $live = [System.IO.Path]::Combine($script:SIRoot, $rel)
            [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($live))
            [System.IO.File]::Copy($f.FullName, $live, $true)
        }
        $state = Get-SICommunityState
        $state | Add-Member 'UpdateHold' ([string]$script:SIGameVersion) -Force
        Save-SICommunityState -State $state
        Write-SILog -Component 'Update' -Message "SIGAME $script:SIGameVersion -> back to $($prev.Name) (rollback)."
        if ($NoRestart) { return $true }
        Show-SIInfoBox -Text ((Get-SIExtraText 'RollDone') -f $prev.Name)
        Restart-SISigame
        return $true
    } catch {
        Show-SIInfoBox -Text ((Get-SIExtraText 'RollFail') -f $_.Exception.Message)
        return $false
    }
}

# ------------------------------- game start / end --------------------------

function Get-SIGameExePath {
    param([string]$Game)
    foreach ($g in @(Get-SIAutoBoostGames)) {
        if ([string]$g.Name -eq $Game -and $g.Exe -and [System.IO.File]::Exists([string]$g.Exe)) { return [string]$g.Exe }
    }
    return ''
}

function Test-SIGameUpdatedSincePreset {
    <# $true + a tray note when the exe version changed since a SI PRESET of this game was applied. #>
    param([string]$Game, [string]$Exe)
    if (-not $Game -or -not $Exe) { return $false }
    $ver = ''
    try { $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Exe); $ver = [string]$vi.FileVersion } catch { }
    if (-not $ver) { $ver = ([System.IO.File]::GetLastWriteTimeUtc($Exe)).ToString('s') }
    $card = $null
    foreach ($g in @($script:SIGameLibrary)) { if ($g -and [string]$g.Name -eq $Game) { $card = $g; break } }
    if (-not $card) { $card = [pscustomobject]@{ Name = $Game; Exe = $Exe; Folder = [System.IO.Path]::GetDirectoryName($Exe) } }
    $e = $null
    try { $e = Find-SIGamePreset -Game $card } catch { }
    if (-not $e) { return $false }
    $applied = @((Get-SICommunityState).Applied.PSObject.Properties.Name)
    if (-not ($applied -contains [string]$e.Id)) { return $false }
    $s = Get-SIExtraState
    $old = ''
    if ($s.GameVersions.PSObject.Properties.Name -contains [string]$e.Id) { $old = [string]$s.GameVersions.([string]$e.Id) }
    $s.GameVersions | Add-Member ([string]$e.Id) $ver -Force
    Save-SIExtraState -State $s
    if ($old -and $old -ne $ver) {
        Show-SITrayNotification -Title 'SI PRESET' -Text ((Get-SIExtraText 'GameUpdated') -f $Game, $old, $ver)
        Write-SILog -Component 'Extra' -Message "$Game updated $old -> $ver after its preset $($e.Id)."
        return $true
    }
    return $false
}

$script:SIWuKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
$script:SIToastKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications'

function Set-SIGameQuiet {
    <# -On: active hours around now + toasts off (only the ones turned on); saves the old values. -Off: puts them back. #>
    param([switch]$On)
    $s = Get-SIExtraState
    if ($On) {
        if ($s.NoWuRestart -and -not ($s.PSObject.Properties.Name -contains 'WuSaved')) {
            try {
                $p = Get-ItemProperty -Path $script:SIWuKey -ErrorAction SilentlyContinue
                $old = [pscustomobject]@{ Start = $p.ActiveHoursStart; End = $p.ActiveHoursEnd }
                $h = [datetime]::Now.Hour
                Set-ItemProperty -Path $script:SIWuKey -Name 'ActiveHoursStart' -Value $h -Type DWord -ErrorAction Stop
                Set-ItemProperty -Path $script:SIWuKey -Name 'ActiveHoursEnd' -Value (($h + 12) % 24) -Type DWord -ErrorAction Stop
                $s | Add-Member 'WuSaved' $old -Force
            } catch { Write-SILog -Level 'WARN' -Component 'Extra' -Message "active hours: $($_.Exception.Message)" }
        }
        if ($s.NoNotify -and -not ($s.PSObject.Properties.Name -contains 'DndSaved')) {
            try {
                if (-not (Test-Path $script:SIToastKey)) { [void](New-Item -Path $script:SIToastKey -Force) }
                $p = Get-ItemProperty -Path $script:SIToastKey -ErrorAction SilentlyContinue
                $old = if ($null -ne $p.ToastEnabled) { [int]$p.ToastEnabled } else { -1 }
                Set-ItemProperty -Path $script:SIToastKey -Name 'ToastEnabled' -Value 0 -Type DWord -ErrorAction Stop
                $s | Add-Member 'DndSaved' $old -Force
            } catch { Write-SILog -Level 'WARN' -Component 'Extra' -Message "notifications: $($_.Exception.Message)" }
        }
    } else {
        if ($s.PSObject.Properties.Name -contains 'WuSaved') {
            try {
                foreach ($n in 'Start', 'End') {
                    $v = $s.WuSaved.$n
                    if ($null -ne $v) { Set-ItemProperty -Path $script:SIWuKey -Name "ActiveHours$n" -Value ([int]$v) -Type DWord -ErrorAction Stop }
                    else { Remove-ItemProperty -Path $script:SIWuKey -Name "ActiveHours$n" -ErrorAction SilentlyContinue }
                }
                $s.PSObject.Properties.Remove('WuSaved')
            } catch { Write-SILog -Level 'WARN' -Component 'Extra' -Message "active hours back: $($_.Exception.Message)" }
        }
        if ($s.PSObject.Properties.Name -contains 'DndSaved') {
            try {
                if ([int]$s.DndSaved -lt 0) { Remove-ItemProperty -Path $script:SIToastKey -Name 'ToastEnabled' -ErrorAction SilentlyContinue }
                else { Set-ItemProperty -Path $script:SIToastKey -Name 'ToastEnabled' -Value ([int]$s.DndSaved) -Type DWord -ErrorAction Stop }
                $s.PSObject.Properties.Remove('DndSaved')
            } catch { Write-SILog -Level 'WARN' -Component 'Extra' -Message "notifications back: $($_.Exception.Message)" }
        }
    }
    Save-SIExtraState -State $s
}

function Invoke-SIGameStartExtras {
    param([string]$Game)
    if (-not $Game) { return }
    try {
        $exe = Get-SIGameExePath -Game $Game
        [void](Test-SIGameUpdatedSincePreset -Game $Game -Exe $exe)
        Set-SIGameQuiet -On
    } catch { Write-SILog -Level 'WARN' -Component 'Extra' -Message "game start: $($_.Exception.Message)" }
}

function Invoke-SIGameEndExtras {
    param([string]$Game)
    try { Set-SIGameQuiet } catch { Write-SILog -Level 'WARN' -Component 'Extra' -Message "game end: $($_.Exception.Message)" }
}

# ------------------------------- disks / overlays / ping -------------------

function Get-SIGameDisks {
    <# Rows Name, Drive, Media (SSD / HDD / Unspecified) for the games with a known exe; HasSsd. #>
    $media = @{}
    $hasSsd = $false
    try {
        foreach ($pd in @(Get-PhysicalDisk -ErrorAction Stop)) { if ([string]$pd.MediaType -eq 'SSD') { $hasSsd = $true } }
    } catch { }
    $rows = @()
    $seen = @{}
    foreach ($g in @(Get-SIAutoBoostGames)) {
        $exe = [string]$g.Exe
        if (-not $exe -or $seen.ContainsKey([string]$g.Name)) { continue }
        $seen[[string]$g.Name] = $true
        $drive = ''
        try { $drive = [System.IO.Path]::GetPathRoot($exe).Substring(0, 1).ToUpperInvariant() } catch { continue }
        if (-not $media.ContainsKey($drive)) {
            $m = 'Unspecified'
            try { $m = [string](Get-Partition -DriveLetter $drive -ErrorAction Stop | Get-Disk | Get-PhysicalDisk -ErrorAction Stop | Select-Object -First 1).MediaType } catch { }
            $media[$drive] = $m
        }
        $rows += [pscustomobject]@{ Name = [string]$g.Name; Drive = "${drive}:"; Media = $media[$drive] }
    }
    return [pscustomobject]@{ HasSsd = $hasSsd; Rows = $rows }
}

function Get-SIDiskReport {
    $d = Get-SIGameDisks
    if (@($d.Rows).Count -eq 0) { return (Get-SIExtraText 'DiskNone') }
    $hdd = @($d.Rows | Where-Object { $_.Media -eq 'HDD' })
    if ($hdd.Count -eq 0) { return (Get-SIExtraText 'DiskAllSsd') }
    $lines = @($hdd | ForEach-Object { (Get-SIExtraText 'DiskHdd') -f $_.Name, $_.Drive })
    $lines += ''
    $lines += $(if ($d.HasSsd) { Get-SIExtraText 'DiskTip' } else { Get-SIExtraText 'DiskNoSsd' })
    return ($lines -join "`n")
}

$script:SIOverlays = @(
    @{ P = 'RTSS'; N = 'RivaTuner Statistics Server'; W = 'RTSS: Show On-Screen Display = Off' }
    @{ P = 'MSIAfterburner'; N = 'MSI Afterburner'; W = 'Afterburner: Settings > Monitoring > Show in On-Screen Display' }
    @{ P = 'Discord'; N = 'Discord'; W = 'Discord: User Settings > Game Overlay' }
    @{ P = 'NVIDIA Overlay'; N = 'NVIDIA app overlay'; W = 'NVIDIA app: Settings > Features > NVIDIA Overlay' }
    @{ P = 'NVIDIA Share'; N = 'GeForce Experience overlay'; W = 'GeForce Experience: Settings > General > In-game overlay' }
    @{ P = 'GameBar'; N = 'Xbox Game Bar'; W = 'Windows Settings > Gaming > Xbox Game Bar' }
    @{ P = 'steam'; N = 'Steam overlay'; W = 'Steam: Settings > In Game > Enable the Steam Overlay while in-game' }
    @{ P = 'Overwolf'; N = 'Overwolf'; W = 'Overwolf: Settings > Overlay & Hotkeys' }
)

function Get-SIRunningOverlays {
    param([string[]]$ProcessNames)
    if (-not $ProcessNames) { $ProcessNames = @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.ProcessName }) }
    $set = @{}
    foreach ($n in $ProcessNames) { if ($n) { $set[$n.ToLowerInvariant()] = $true } }
    return @($script:SIOverlays | Where-Object { $set.ContainsKey($_.P.ToLowerInvariant()) })
}

function Get-SIOverlayReport {
    $o = @(Get-SIRunningOverlays)
    if ($o.Count -eq 0) { return (Get-SIExtraText 'OverlayNone') }
    return ((Get-SIExtraText 'OverlayHead') -f (($o | ForEach-Object { "- $($_.N)`n   $($_.W)" }) -join "`n"))
}

function Get-SIValvePing {
    <# Official relay list (api.steampowered.com GetSDRConfig), one ICMP ping per main region in parallel. #>
    param([int]$Top = 6)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    $cfg = Invoke-RestMethod -Uri 'https://api.steampowered.com/ISteamApps/GetSDRConfig/v1/?appid=730' -TimeoutSec 15 -UseBasicParsing
    $jobs = @()
    foreach ($p in $cfg.pops.PSObject.Properties) {
        $v = $p.Value
        if (-not $v.relays -or -not $v.desc -or $p.Name -notmatch '^[a-z]{3}$') { continue }
        $ip = [string]@($v.relays)[0].ipv4
        if (-not $ip) { continue }
        $jobs += [pscustomobject]@{ Desc = [string]$v.desc; Ip = $ip; Task = ([System.Net.NetworkInformation.Ping]::new()).SendPingAsync($ip, 1500) }
    }
    try { [void][System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]@($jobs | ForEach-Object { $_.Task }), 4000) } catch { }
    $rows = foreach ($j in $jobs) {
        $ms = -1
        try { if ($j.Task.IsCompleted -and $j.Task.Result.Status -eq 'Success') { $ms = [int]$j.Task.Result.RoundtripTime } } catch { }
        [pscustomobject]@{ Desc = $j.Desc; Ms = $ms }
    }
    $ok = @($rows | Where-Object { $_.Ms -ge 0 } | Sort-Object Ms | Select-Object -First $Top)
    return [pscustomobject]@{ Best = $ok; NoReply = @($rows | Where-Object { $_.Ms -lt 0 }).Count; Total = @($rows).Count }
}

function Get-SIPingReport {
    try { $r = Get-SIValvePing } catch { return (Get-SIExtraText 'PingFail') }
    $lines = @($r.Best | ForEach-Object { '{0,5} ms  {1}' -f $_.Ms, $_.Desc })
    if ($r.NoReply -gt 0) { $lines += ('{0}/{1}: {2}' -f $r.NoReply, $r.Total, (Get-SIExtraText 'PingNoReply')) }
    return ((Get-SIExtraText 'PingHead') -f ($lines -join "`n"))
}

# ------------------------------- theme / text size -------------------------

function Get-SIWindowsLightTheme {
    try { return ([int](Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -ErrorAction Stop).AppsUseLightTheme -eq 1) } catch { return $false }
}

function Set-SIThemeColors {
    param([string]$Theme)
    $light = ($Theme -eq 'light') -or ($Theme -eq 'auto' -and (Get-SIWindowsLightTheme))
    if (-not $light -or -not $script:SIColors) { return $false }
    $script:SIColors.Background = '#f3f4f8'
    $script:SIColors.Panel = '#ffffff'
    $script:SIColors.PanelAlt = '#e6e9f0'
    $script:SIColors.BorderGold = '#d9c189'
    $script:SIColors.GlowGold = '#b07800'
    $script:SIColors.Accent = '#9a6a00'
    $script:SIColors.Text = '#151824'
    $script:SIColors.Muted = '#535b6e'
    $script:SIColors.Ok = '#1e8a4c'
    $script:SIColors.Off = '#7a8090'
    $script:SIColors.Warn = '#b35c00'
    $script:SIColors.Danger = '#c62828'
    return $true
}

function Get-SITextScale {
    param([string]$Size)
    if ($Size -match '^\d+$') { $v = [double]$Size / 100 }
    else {
        $v = 1.0
        try { $f = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Accessibility' -ErrorAction Stop).TextScaleFactor; if ($f) { $v = [double]$f / 100 } } catch { }
    }
    return [math]::Min(1.3, [math]::Max(1.0, $v))
}

function Set-SIWindowScale {
    param($Window, [double]$Scale)
    if (-not $Window -or -not $Window.Content) { return }
    $Window.Content.LayoutTransform = [System.Windows.Media.ScaleTransform]::new($Scale, $Scale)
    $wa = [System.Windows.SystemParameters]::WorkArea
    $Window.MinWidth = [math]::Min(900 * $Scale, $wa.Width)
    $Window.MinHeight = [math]::Min(520 * $Scale, $wa.Height)
    if ($Window.Width -lt $Window.MinWidth) { $Window.Width = $Window.MinWidth }
    if ($Window.Height -lt $Window.MinHeight) { $Window.Height = $Window.MinHeight }
}

# ------------------------------- the section -------------------------------

function Add-SIExtraSection {
    param($Panel, $Window)
    $s = Get-SIExtraState
    $null = $Panel.Children.Add((New-SIToolTitle -Text (Get-SIExtraText 'Title')))

    $row = [System.Windows.Controls.WrapPanel]::new()
    $rb = New-SIStyleButton -Text (Get-SIExtraText 'BtnRollback') -StyleKey 'GhostButton' -Window $Window
    $null = $rb.Add_Click({ [void](Invoke-SIRollback) })
    $null = $row.Children.Add($rb)
    foreach ($b in @(
            @{ T = 'BtnDisks'; F = { Get-SIDiskReport } },
            @{ T = 'BtnOverlay'; F = { Get-SIOverlayReport } },
            @{ T = 'BtnPing'; F = { Get-SIPingReport } })) {
        $btn = New-SIStyleButton -Text (Get-SIExtraText $b.T) -StyleKey 'GhostButton' -Window $Window
        if ($b.T -eq 'BtnDisks') { $btn.ToolTip = Get-SIExtraText 'DiskTip' }
        $f = $b.F
        $null = $btn.Add_Click({
            try { [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait; $t = & $f }
            catch { $t = $_.Exception.Message }
            finally { [System.Windows.Input.Mouse]::OverrideCursor = $null }
            Show-SIInfoBox -Text $t
        }.GetNewClosure())
        $null = $row.Children.Add($btn)
    }
    $null = $Panel.Children.Add($row)

    $row2 = [System.Windows.Controls.WrapPanel]::new()
    foreach ($t in @(@{ K = 'NoWuRestart'; B = 'BtnWu'; Tip = 'WuTip' }, @{ K = 'NoNotify'; B = 'BtnDnd'; Tip = 'DndTip' })) {
        $state = if ($s.($t.K)) { Get-SIExtraText 'On' } else { Get-SIExtraText 'Off' }
        $btn = New-SIStyleButton -Text ((Get-SIExtraText $t.B) -f $state) -StyleKey 'GhostButton' -Window $Window
        $btn.ToolTip = Get-SIExtraText $t.Tip
        $k = $t.K; $bk = $t.B
        $null = $btn.Add_Click({
            $x = Get-SIExtraState
            $x.$k = -not [bool]$x.$k
            if ($x.$k -and $k -eq 'NoWuRestart') {
                try { Set-ItemProperty -Path $script:SIWuKey -Name 'ActiveHoursStart' -Value ((Get-ItemProperty -Path $script:SIWuKey -ErrorAction Stop).ActiveHoursStart) -ErrorAction Stop }
                catch { Show-SIInfoBox -Text (Get-SIExtraText 'NeedAdmin'); return }
            }
            Save-SIExtraState -State $x
            $label = if ($x.$k) { Get-SIExtraText 'On' } else { Get-SIExtraText 'Off' }
            $this.Content = (Get-SIExtraText $bk) -f $label
        }.GetNewClosure())
        $null = $row2.Children.Add($btn)
    }
    $null = $Panel.Children.Add($row2)

    $row3 = [System.Windows.Controls.WrapPanel]::new()
    $themeName = @{ dark = (Get-SIExtraText 'ThemeDark'); light = (Get-SIExtraText 'ThemeLight'); auto = (Get-SIExtraText 'ThemeAuto') }
    $th = New-SIStyleButton -Text ((Get-SIExtraText 'BtnTheme') -f $themeName[[string]$s.Theme]) -StyleKey 'GhostButton' -Window $Window
    $null = $th.Add_Click({
        $x = Get-SIExtraState
        $next = @{ dark = 'light'; light = 'auto'; auto = 'dark' }[[string]$x.Theme]
        if (-not $next) { $next = 'dark' }
        $x.Theme = $next
        Save-SIExtraState -State $x
        $this.Content = (Get-SIExtraText 'BtnTheme') -f $themeName[$next]
        if (Show-SIMessage -Window $script:SIWindow -Title 'SIGAME' -Text (Get-SIExtraText 'ThemeAsk')) { Restart-SISigame }
    }.GetNewClosure())
    $null = $row3.Children.Add($th)
    $sizeName = { param($v) if ($v -eq 'auto') { '{0} ({1}%)' -f (Get-SIExtraText 'TextAuto'), [int]((Get-SITextScale 'auto') * 100) } else { "$v%" } }
    $tx = New-SIStyleButton -Text ((Get-SIExtraText 'BtnText') -f (& $sizeName ([string]$s.TextSize))) -StyleKey 'GhostButton' -Window $Window
    $null = $tx.Add_Click({
        $x = Get-SIExtraState
        $next = @{ auto = '100'; '100' = '115'; '115' = '130'; '130' = 'auto' }[[string]$x.TextSize]
        if (-not $next) { $next = 'auto' }
        $x.TextSize = $next
        Save-SIExtraState -State $x
        $this.Content = (Get-SIExtraText 'BtnText') -f (& $sizeName $next)
        Set-SIWindowScale -Window $script:SIWindow -Scale (Get-SITextScale $next)
    }.GetNewClosure())
    $null = $row3.Children.Add($tx)
    $null = $Panel.Children.Add($row3)

    $scale = Get-SITextScale ([string]$s.TextSize)
    if ($scale -gt 1.0) {
        if ($Window.IsLoaded) { Set-SIWindowScale -Window $Window -Scale $scale }
        else { $w = $Window; $null = $Window.Add_Loaded({ Set-SIWindowScale -Window $w -Scale $scale }.GetNewClosure()) }
    }
}

# ------------------------------- at load -----------------------------------

try {
    $script:SIExtraAtLoad = Get-SIExtraState
    [void](Set-SIThemeColors -Theme ([string]$script:SIExtraAtLoad.Theme))
    # SIGAME closed while a game was running: the quiet settings are put back (a running game sets them again).
    if (($script:SIExtraAtLoad.PSObject.Properties.Name -contains 'WuSaved') -or ($script:SIExtraAtLoad.PSObject.Properties.Name -contains 'DndSaved')) { Set-SIGameQuiet }
} catch { }
