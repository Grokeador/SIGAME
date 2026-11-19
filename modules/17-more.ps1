# SIGAME - more tools (2026.11.18.11):
# VC++ / DirectX runtimes check, Steam "verify game files", shader cache cleanup
# (and a hint when the GPU driver changes), low disk warning at game start,
# global hotkey Ctrl+Alt+B (GAME BOOST / GAME OVER), local play history,
# backup of the saves before an SI PRESET (1-click restore), notice of a new
# SI PRESET for an installed game, and preset variants (catalog "Variant" +
# "Group": two presets of one Group change the same settings).
# Save folders come from the catalog "Saves" field, taken from the Ludusavi
# manifest (github.com/mtkennerly/ludusavi-manifest, MIT; data from PCGamingWiki).

$script:SIMoreText = @{
    en      = @{
        Title       = 'MORE TOOLS'
        BtnRuntime  = 'RUNTIMES (VC++ / DIRECTX)'
        BtnVerify   = 'VERIFY STEAM GAME'
        BtnShader   = 'SHADER CACHE'
        BtnHistory  = 'PLAY HISTORY'
        BtnSaves    = 'RESTORE SAVES'
        BtnHotkey   = 'HOTKEY CTRL+ALT+B: {0}'
        HotkeyTip   = 'Ctrl+Alt+B turns GAME BOOST on and, pressed again, GAME OVER: it works inside a game too.'
        HotkeyBusy  = 'Another program already uses Ctrl+Alt+B: SIGAME could not take it.'
        RtOk        = '{0}: installed, version {1}'
        RtMiss      = '{0}: MISSING'
        DxOk        = 'DirectX 9.0c extra files (d3dx9_43.dll, older games): present'
        DxMiss      = 'DirectX 9.0c extra files (d3dx9_43.dll, older games): MISSING'
        RtAll       = 'Everything is installed.'
        RtAsk       = 'Something is missing. Open the official Microsoft download page?'
        VerifyNote  = 'Steam checks every file of the game and downloads again only the broken or missing ones.'
        VerifyBtn   = 'VERIFY'
        VerifyNone  = 'No Steam games found on this computer.'
        ShaderNone  = 'The shader caches are already empty.'
        ShaderAsk   = "Shader caches: {0} MB`n{1}`n`nClear them? The first launch of each game builds its shaders again. Close your games first."
        ShaderDone  = 'Shader cache cleared: {0} MB freed ({1} files in use skipped).'
        DriverNew   = 'GPU driver changed: {0}. You can clear the old shader cache in TOOLS > SHADER CACHE.'
        DiskLow     = 'Only {0} GB free on {1}. Game updates, shader caches and saves need space.'
        HistEmpty   = 'No sessions yet. The history fills by itself while AUTO-BOOST is on.'
        HistLast    = 'Last sessions:'
        HistTotal   = 'Last 30 days:'
        HistSess    = '{0} h ({1} sessions)'
        SavesNone   = 'No save backups yet. SIGAME backs up the saves of a game before it applies its SI PRESET.'
        SavesNote   = 'Close the game first. The current saves are backed up before the restore.'
        SavesBtn    = 'RESTORE'
        SavesAsk    = "Restore the saves of {0} from {1}?`nClose the game first. The current saves are backed up before."
        SavesDone   = 'Saves of {0} restored: {1} folders.'
        SavesBacked = 'Saves of {0} backed up ({1} MB): RESTORE SAVES puts them back.'
        SavesBig    = 'Saves of {0} not backed up: {1} MB is over the 2 GB limit.'
        NewPreset   = 'New or updated SI PRESET for a game on this computer: {0}'
        GroupAsk    = "{0} is applied and changes the same settings as {1}.`nUndo {0} first and apply {1}?"
        GroupFail   = 'UNDO of {0} failed: {1}'
    }
    it      = @{
        Title       = 'ALTRI STRUMENTI'
        BtnRuntime  = 'RUNTIME (VC++ / DIRECTX)'
        BtnVerify   = 'VERIFICA GIOCO STEAM'
        BtnShader   = 'CACHE SHADER'
        BtnHistory  = 'STORICO PARTITE'
        BtnSaves    = 'RIPRISTINA SALVATAGGI'
        BtnHotkey   = 'SCORCIATOIA CTRL+ALT+B: {0}'
        HotkeyTip   = 'Ctrl+Alt+B accende GAME BOOST e, premuto di nuovo, GAME OVER: funziona anche dentro un gioco.'
        HotkeyBusy  = 'Un altro programma usa gia Ctrl+Alt+B: SIGAME non ha potuto prenderla.'
        RtOk        = '{0}: installato, versione {1}'
        RtMiss      = '{0}: MANCANTE'
        DxOk        = 'File extra DirectX 9.0c (d3dx9_43.dll, giochi meno recenti): presenti'
        DxMiss      = 'File extra DirectX 9.0c (d3dx9_43.dll, giochi meno recenti): MANCANTI'
        RtAll       = 'E tutto installato.'
        RtAsk       = 'Manca qualcosa. Aprire la pagina ufficiale Microsoft per scaricarlo?'
        VerifyNote  = 'Steam controlla ogni file del gioco e riscarica solo quelli rotti o mancanti.'
        VerifyBtn   = 'VERIFICA'
        VerifyNone  = 'Nessun gioco Steam trovato su questo computer.'
        ShaderNone  = 'Le cache degli shader sono gia vuote.'
        ShaderAsk   = "Cache degli shader: {0} MB`n{1}`n`nSvuotarle? Al primo avvio ogni gioco ricrea i suoi shader. Chiudi prima i giochi."
        ShaderDone  = 'Cache shader svuotata: {0} MB liberati ({1} file in uso saltati).'
        DriverNew   = 'Driver GPU cambiato: {0}. Puoi svuotare la vecchia cache shader in STRUMENTI > CACHE SHADER.'
        DiskLow     = 'Solo {0} GB liberi su {1}. Aggiornamenti dei giochi, cache shader e salvataggi hanno bisogno di spazio.'
        HistEmpty   = 'Nessuna partita ancora. Lo storico si riempie da solo con AUTO-BOOST acceso.'
        HistLast    = 'Ultime partite:'
        HistTotal   = 'Ultimi 30 giorni:'
        HistSess    = '{0} h ({1} partite)'
        SavesNone   = 'Nessun backup dei salvataggi. SIGAME salva i salvataggi di un gioco prima di applicare il suo SI PRESET.'
        SavesNote   = 'Chiudi prima il gioco. I salvataggi attuali vengono copiati prima del ripristino.'
        SavesBtn    = 'RIPRISTINA'
        SavesAsk    = "Ripristinare i salvataggi di {0} del {1}?`nChiudi prima il gioco. I salvataggi attuali vengono copiati prima."
        SavesDone   = 'Salvataggi di {0} ripristinati: {1} cartelle.'
        SavesBacked = 'Salvataggi di {0} copiati ({1} MB): RIPRISTINA SALVATAGGI li rimette.'
        SavesBig    = 'Salvataggi di {0} non copiati: {1} MB superano il limite di 2 GB.'
        NewPreset   = 'SI PRESET nuovo o aggiornato per un gioco di questo computer: {0}'
        GroupAsk    = "{0} e applicato e cambia le stesse impostazioni di {1}.`nAnnullare prima {0} e applicare {1}?"
        GroupFail   = 'UNDO di {0} non riuscito: {1}'
    }
    'pt-BR' = @{
        Title       = 'MAIS FERRAMENTAS'
        BtnRuntime  = 'RUNTIMES (VC++ / DIRECTX)'
        BtnVerify   = 'VERIFICAR JOGO STEAM'
        BtnShader   = 'CACHE DE SHADER'
        BtnHistory  = 'HISTORICO DE JOGO'
        BtnSaves    = 'RESTAURAR SAVES'
        BtnHotkey   = 'ATALHO CTRL+ALT+B: {0}'
        HotkeyTip   = 'Ctrl+Alt+B liga o GAME BOOST e, apertado de novo, GAME OVER: funciona dentro do jogo tambem.'
        HotkeyBusy  = 'Outro programa ja usa Ctrl+Alt+B: o SIGAME nao conseguiu pegar o atalho.'
        RtOk        = '{0}: instalado, versao {1}'
        RtMiss      = '{0}: FALTANDO'
        DxOk        = 'Arquivos extras do DirectX 9.0c (d3dx9_43.dll, jogos antigos): presentes'
        DxMiss      = 'Arquivos extras do DirectX 9.0c (d3dx9_43.dll, jogos antigos): FALTANDO'
        RtAll       = 'Esta tudo instalado.'
        RtAsk       = 'Falta algo. Abrir a pagina oficial da Microsoft para baixar?'
        VerifyNote  = 'A Steam confere cada arquivo do jogo e baixa de novo so os quebrados ou faltando.'
        VerifyBtn   = 'VERIFICAR'
        VerifyNone  = 'Nenhum jogo da Steam encontrado neste computador.'
        ShaderNone  = 'Os caches de shader ja estao vazios.'
        ShaderAsk   = "Caches de shader: {0} MB`n{1}`n`nLimpar? Na primeira abertura cada jogo cria os shaders de novo. Feche os jogos antes."
        ShaderDone  = 'Cache de shader limpo: {0} MB liberados ({1} arquivos em uso pulados).'
        DriverNew   = 'Driver da GPU mudou: {0}. Voce pode limpar o cache de shader antigo em FERRAMENTAS > CACHE DE SHADER.'
        DiskLow     = 'So {0} GB livres em {1}. Atualizacoes, caches de shader e saves precisam de espaco.'
        HistEmpty   = 'Nenhuma sessao ainda. O historico se preenche sozinho com o AUTO-BOOST ligado.'
        HistLast    = 'Ultimas sessoes:'
        HistTotal   = 'Ultimos 30 dias:'
        HistSess    = '{0} h ({1} sessoes)'
        SavesNone   = 'Nenhum backup de saves ainda. O SIGAME copia os saves de um jogo antes de aplicar o SI PRESET dele.'
        SavesNote   = 'Feche o jogo antes. Os saves atuais sao copiados antes da restauracao.'
        SavesBtn    = 'RESTAURAR'
        SavesAsk    = "Restaurar os saves de {0} de {1}?`nFeche o jogo antes. Os saves atuais sao copiados antes."
        SavesDone   = 'Saves de {0} restaurados: {1} pastas.'
        SavesBacked = 'Saves de {0} copiados ({1} MB): RESTAURAR SAVES devolve eles.'
        SavesBig    = 'Saves de {0} nao copiados: {1} MB passam do limite de 2 GB.'
        NewPreset   = 'SI PRESET novo ou atualizado para um jogo deste computador: {0}'
        GroupAsk    = "{0} esta aplicado e muda as mesmas configuracoes de {1}.`nDesfazer {0} antes e aplicar {1}?"
        GroupFail   = 'UNDO de {0} falhou: {1}'
    }
    es      = @{
        Title       = 'MAS HERRAMIENTAS'
        BtnRuntime  = 'RUNTIMES (VC++ / DIRECTX)'
        BtnVerify   = 'VERIFICAR JUEGO STEAM'
        BtnShader   = 'CACHE DE SHADERS'
        BtnHistory  = 'HISTORIAL DE JUEGO'
        BtnSaves    = 'RESTAURAR PARTIDAS'
        BtnHotkey   = 'ATAJO CTRL+ALT+B: {0}'
        HotkeyTip   = 'Ctrl+Alt+B enciende GAME BOOST y, pulsado otra vez, GAME OVER: funciona tambien dentro del juego.'
        HotkeyBusy  = 'Otro programa ya usa Ctrl+Alt+B: SIGAME no pudo tomarlo.'
        RtOk        = '{0}: instalado, version {1}'
        RtMiss      = '{0}: FALTA'
        DxOk        = 'Archivos extra de DirectX 9.0c (d3dx9_43.dll, juegos antiguos): presentes'
        DxMiss      = 'Archivos extra de DirectX 9.0c (d3dx9_43.dll, juegos antiguos): FALTAN'
        RtAll       = 'Todo esta instalado.'
        RtAsk       = 'Falta algo. Abrir la pagina oficial de Microsoft para descargarlo?'
        VerifyNote  = 'Steam revisa cada archivo del juego y vuelve a descargar solo los rotos o que faltan.'
        VerifyBtn   = 'VERIFICAR'
        VerifyNone  = 'No hay juegos de Steam en este equipo.'
        ShaderNone  = 'Las caches de shaders ya estan vacias.'
        ShaderAsk   = "Caches de shaders: {0} MB`n{1}`n`nVaciarlas? En el primer inicio cada juego vuelve a crear sus shaders. Cierra los juegos antes."
        ShaderDone  = 'Cache de shaders vaciada: {0} MB liberados ({1} archivos en uso omitidos).'
        DriverNew   = 'El driver de la GPU cambio: {0}. Puedes vaciar la cache de shaders vieja en HERRAMIENTAS > CACHE DE SHADERS.'
        DiskLow     = 'Solo {0} GB libres en {1}. Las actualizaciones, caches de shaders y partidas necesitan espacio.'
        HistEmpty   = 'Aun no hay sesiones. El historial se llena solo con AUTO-BOOST encendido.'
        HistLast    = 'Ultimas sesiones:'
        HistTotal   = 'Ultimos 30 dias:'
        HistSess    = '{0} h ({1} sesiones)'
        SavesNone   = 'Aun no hay copias de partidas. SIGAME copia las partidas de un juego antes de aplicar su SI PRESET.'
        SavesNote   = 'Cierra el juego antes. Las partidas actuales se copian antes de restaurar.'
        SavesBtn    = 'RESTAURAR'
        SavesAsk    = "Restaurar las partidas de {0} del {1}?`nCierra el juego antes. Las partidas actuales se copian antes."
        SavesDone   = 'Partidas de {0} restauradas: {1} carpetas.'
        SavesBacked = 'Partidas de {0} copiadas ({1} MB): RESTAURAR PARTIDAS las devuelve.'
        SavesBig    = 'Partidas de {0} no copiadas: {1} MB superan el limite de 2 GB.'
        NewPreset   = 'SI PRESET nuevo o actualizado para un juego de este equipo: {0}'
        GroupAsk    = "{0} esta aplicado y cambia los mismos ajustes que {1}.`nDeshacer {0} antes y aplicar {1}?"
        GroupFail   = 'UNDO de {0} fallo: {1}'
    }
}

function Get-SIMoreText {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    if ($script:SIMoreText.ContainsKey($lang) -and $script:SIMoreText[$lang].ContainsKey($Key)) { return $script:SIMoreText[$lang][$Key] }
    return $script:SIMoreText['en'][$Key]
}

function Get-SIMoreOnOff {
    param([bool]$On)
    try { if ($On) { return (Get-SIExtraText 'On') } else { return (Get-SIExtraText 'Off') } } catch { }
    if ($On) { 'ON' } else { 'OFF' }
}

# ------------------------------- runtimes ----------------------------------
# Official pages: Microsoft Learn (latest supported VC++ redistributable) and
# the Microsoft Download Center (DirectX End-User Runtime Web Installer).
$script:SIVcUrl = 'https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist'
$script:SIDxUrl = 'https://www.microsoft.com/en-us/download/details.aspx?id=35'

function Get-SIRuntimeState {
    $out = @()
    foreach ($r in @(
            @{ N = 'Visual C++ 2015-2022 x64'; K = 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' },
            @{ N = 'Visual C++ 2015-2022 x86'; K = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86' })) {
        $v = $null
        try { $v = Get-ItemProperty -LiteralPath $r.K -ErrorAction Stop } catch { }
        $ok = ($v -and [int]$v.Installed -eq 1)
        $out += [pscustomobject]@{ Name = $r.N; Ok = $ok; Version = $(if ($ok) { [string]$v.Version } else { '' }); Url = $script:SIVcUrl }
    }
    $dx = Test-Path -LiteralPath (Join-Path $env:WINDIR 'System32\d3dx9_43.dll')
    $out += [pscustomobject]@{ Name = 'DirectX 9.0c'; Ok = $dx; Version = ''; Url = $script:SIDxUrl }
    return $out
}

function Get-SIRuntimeReport {
    $lines = foreach ($r in @(Get-SIRuntimeState)) {
        if ($r.Name -eq 'DirectX 9.0c') { if ($r.Ok) { Get-SIMoreText 'DxOk' } else { Get-SIMoreText 'DxMiss' } }
        elseif ($r.Ok) { (Get-SIMoreText 'RtOk') -f $r.Name, ($r.Version -replace '^v', '') }
        else { (Get-SIMoreText 'RtMiss') -f $r.Name }
    }
    return ($lines -join "`n")
}

function Invoke-SIRuntimeCheck {
    $state = @(Get-SIRuntimeState)
    $text = Get-SIRuntimeReport
    $miss = @($state | Where-Object { -not $_.Ok })
    if ($miss.Count -eq 0) { Show-SIInfoBox -Text ($text + "`n`n" + (Get-SIMoreText 'RtAll')); return }
    if (Show-SIMessage -Window $script:SIWindow -Title 'SIGAME' -Text ($text + "`n`n" + (Get-SIMoreText 'RtAsk'))) {
        foreach ($u in @($miss | ForEach-Object { $_.Url } | Select-Object -Unique)) { Start-Process $u }
    }
}

# ------------------------------- Steam verify ------------------------------

function Get-SISteamVerifyGames {
    $games = @($script:SIGameLibrary | Where-Object { $_ -and [string]$_.Id -match '^steam-\d+$' })
    if ($games.Count -eq 0 -and (Get-Command Get-SISteamGames -ErrorAction SilentlyContinue)) {
        try { $games = @(Get-SISteamGames | Where-Object { [string]$_.Id -match '^steam-\d+$' }) } catch { }
    }
    return @($games | Sort-Object -Property Name)
}

function Show-SISteamVerify {
    $games = @(Get-SISteamVerifyGames)
    if ($games.Count -eq 0) { Show-SIInfoBox -Text (Get-SIMoreText 'VerifyNone'); return }
    $rows = foreach ($g in $games) {
        $appId = ([string]$g.Id) -replace '^steam-', ''
        [pscustomobject]@{
            Text   = [string]$g.Name
            Button = Get-SIMoreText 'VerifyBtn'
            Action = { Start-Process ('steam://validate/' + $appId) }.GetNewClosure()
        }
    }
    Show-SIPickWindow -Title (Get-SIMoreText 'BtnVerify') -Note (Get-SIMoreText 'VerifyNote') -Rows $rows
}

# ------------------------------- shader cache ------------------------------

function Get-SIShaderDirs {
    $low = Join-Path $env:USERPROFILE 'AppData\LocalLow'
    @(
        @{ V = 'Windows (DirectX)'; P = (Join-Path $env:LOCALAPPDATA 'D3DSCache') },
        @{ V = 'NVIDIA DX'; P = (Join-Path $env:LOCALAPPDATA 'NVIDIA\DXCache') },
        @{ V = 'NVIDIA GL'; P = (Join-Path $env:LOCALAPPDATA 'NVIDIA\GLCache') },
        @{ V = 'NVIDIA'; P = (Join-Path $low 'NVIDIA\PerDriverVersion\DXCache') },
        @{ V = 'AMD DX'; P = (Join-Path $env:LOCALAPPDATA 'AMD\DxCache') },
        @{ V = 'AMD DXC'; P = (Join-Path $env:LOCALAPPDATA 'AMD\DxcCache') },
        @{ V = 'AMD Vulkan'; P = (Join-Path $env:LOCALAPPDATA 'AMD\VkCache') },
        @{ V = 'AMD GL'; P = (Join-Path $env:LOCALAPPDATA 'AMD\GLCache') },
        @{ V = 'Intel'; P = (Join-Path $low 'Intel\ShaderCache') }
    ) | Where-Object { Test-Path -LiteralPath $_.P }
}

function Get-SIFolderBytes {
    param([string]$Path)
    $sum = 0L
    try { foreach ($f in @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue)) { $sum += $f.Length } } catch { }
    return $sum
}

function Invoke-SIShaderCacheClean {
    param([switch]$NoAsk)
    $dirs = @(Get-SIShaderDirs | ForEach-Object { [pscustomobject]@{ V = $_.V; P = $_.P; B = (Get-SIFolderBytes -Path $_.P) } } | Where-Object { $_.B -gt 0 })
    $total = ($dirs | Measure-Object -Property B -Sum).Sum
    if (-not $total) { if (-not $NoAsk) { Show-SIInfoBox -Text (Get-SIMoreText 'ShaderNone') }; return 0 }
    $list = ($dirs | ForEach-Object { '{0}: {1} MB' -f $_.V, [math]::Round($_.B / 1MB, 1) }) -join "`n"
    if (-not $NoAsk -and -not (Show-SIMessage -Window $script:SIWindow -Title 'SIGAME' -Text ((Get-SIMoreText 'ShaderAsk') -f [math]::Round($total / 1MB, 1), $list))) { return 0 }
    $freed = 0L; $skip = 0
    foreach ($d in $dirs) {
        foreach ($f in @(Get-ChildItem -LiteralPath $d.P -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            $len = $f.Length
            try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $freed += $len } catch { $skip++ }
        }
    }
    $mb = [math]::Round($freed / 1MB, 1)
    Write-SILog -Component 'More' -Message "Shader cache cleared: $mb MB, $skip in use"
    if (-not $NoAsk) { Show-SIInfoBox -Text ((Get-SIMoreText 'ShaderDone') -f $mb, $skip) }
    return $mb
}

function Test-SIGpuDriverChanged {
    $now = ''
    try { $now = (@(Get-SIGpuDriverInfo) | ForEach-Object { "$($_.Name) $($_.Driver)" }) -join '; ' } catch { return }
    if (-not $now) { return }
    $x = Get-SIExtraState
    $old = ''
    if ($x.PSObject.Properties.Name -contains 'LastDriver') { $old = [string]$x.LastDriver }
    if ($old -eq $now) { return }
    $x | Add-Member 'LastDriver' $now -Force
    Save-SIExtraState -State $x
    if ($old) {
        Write-SILog -Component 'More' -Message "GPU driver changed: $old -> $now"
        Show-SITrayNotification -Title 'SIGAME' -Text ((Get-SIMoreText 'DriverNew') -f $now)
    }
}

# ------------------------------- low disk ----------------------------------

function Get-SILowDisks {
    param([string]$Exe, [double]$MinGB = 10)
    $roots = @([System.IO.Path]::GetPathRoot($env:WINDIR))
    if ($Exe) { try { $roots += [System.IO.Path]::GetPathRoot($Exe) } catch { } }
    $out = @()
    foreach ($r in @($roots | Where-Object { $_ } | Select-Object -Unique)) {
        try {
            $d = [System.IO.DriveInfo]::new($r)
            if ($d.IsReady) {
                $gb = [math]::Round($d.AvailableFreeSpace / 1GB, 1)
                if ($gb -lt $MinGB) { $out += [pscustomobject]@{ Drive = $r.TrimEnd('\'); GB = $gb } }
            }
        } catch { }
    }
    return $out
}

# ------------------------------- play history ------------------------------

function Get-SIHistoryPath { [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-history.jsonl') }

function Get-SIActivePresetTitle {
    param([string]$Game)
    try {
        $e = Find-SIGamePreset -Game $Game
        if (-not $e) { return '' }
        $applied = @((Get-SICommunityState).Applied.PSObject.Properties.Name)
        if ($applied -contains [string]$e.Id) { return [string]$e.Title }
    } catch { }
    return ''
}

function Add-SIPlaySession {
    param([string]$Game, [datetime]$Start, [datetime]$End)
    $min = [int][math]::Round(($End - $Start).TotalMinutes)
    if ($min -lt 1) { return }
    $line = [pscustomobject]@{ Game = $Game; Start = $Start.ToString('s'); Minutes = $min; Preset = (Get-SIActivePresetTitle -Game $Game) } | ConvertTo-Json -Compress
    $p = Get-SIHistoryPath
    try {
        [System.IO.File]::AppendAllText($p, $line + "`n", [System.Text.UTF8Encoding]::new($false))
        $all = [System.IO.File]::ReadAllLines($p)
        if ($all.Count -gt 2000) { [System.IO.File]::WriteAllLines($p, [string[]]($all | Select-Object -Last 1000)) }
    } catch { Write-SILog -Level 'WARN' -Component 'More' -Message "history: $($_.Exception.Message)" }
}

function Get-SIPlayHistory {
    $p = Get-SIHistoryPath
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    $out = @()
    foreach ($l in @([System.IO.File]::ReadAllLines($p) | Select-Object -Last 1000)) {
        if (-not $l) { continue }
        try { $out += ($l | ConvertFrom-Json) } catch { }
    }
    return $out
}

function Get-SIHistoryReport {
    $h = @(Get-SIPlayHistory)
    if ($h.Count -eq 0) { return (Get-SIMoreText 'HistEmpty') }
    $lines = @(Get-SIMoreText 'HistLast')
    foreach ($s in @($h | Sort-Object { [datetime]$_.Start } -Descending | Select-Object -First 15)) {
        $d = [datetime]$s.Start
        $pre = if ($s.Preset) { "  [$($s.Preset)]" } else { '' }
        $lines += '{0}  {1}  {2} min{3}' -f $d.ToString('dd/MM HH:mm'), $s.Game, $s.Minutes, $pre
    }
    $since = [datetime]::Now.AddDays(-30)
    $lines += ''; $lines += (Get-SIMoreText 'HistTotal')
    foreach ($g in @($h | Where-Object { [datetime]$_.Start -ge $since } | Group-Object -Property Game | Sort-Object { ($_.Group | Measure-Object -Property Minutes -Sum).Sum } -Descending)) {
        $m = ($g.Group | Measure-Object -Property Minutes -Sum).Sum
        $lines += '{0}: {1}' -f $g.Name, ((Get-SIMoreText 'HistSess') -f [math]::Round($m / 60, 1), $g.Count)
    }
    return ($lines -join "`n")
}

# ------------------------------- game start / end --------------------------

function Invoke-SIMoreGameStart {
    param([string]$Game, [string]$Exe)
    if (-not $Game) { return }
    $script:SIMorePlay = @{ Game = $Game; Start = [datetime]::Now }
    foreach ($d in @(Get-SILowDisks -Exe $Exe)) {
        Show-SITrayNotification -Title 'SIGAME' -Text ((Get-SIMoreText 'DiskLow') -f $d.GB, $d.Drive)
        Write-SILog -Level 'WARN' -Component 'More' -Message "Low disk $($d.Drive): $($d.GB) GB"
    }
}

function Invoke-SIMoreGameEnd {
    param([string]$Game)
    $p = $script:SIMorePlay
    $script:SIMorePlay = $null
    if (-not $p) { return }
    Add-SIPlaySession -Game ([string]$p.Game) -Start ([datetime]$p.Start) -End ([datetime]::Now)
}

# ------------------------------- saves backup ------------------------------

function Get-SISteamRoot {
    try { $p = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath; if ($p) { return ($p -replace '/', '\') } } catch { }
    return ''
}

function Get-SIGameBaseFolder {
    param($Entry)
    if (-not $Entry.Match) { return '' }
    foreach ($g in @($script:SIGameLibrary)) {
        $hay = @([string]$g.Name, [System.IO.Path]::GetFileName([string]$g.Exe), [System.IO.Path]::GetFileName([string]$g.Folder)) -join ' | '
        if ($hay -match [string]$Entry.Match) {
            if ($g.Folder) { return [string]$g.Folder }
            if ($g.Exe) { return (Split-Path -Parent ([string]$g.Exe)) }
        }
    }
    return ''
}

function Resolve-SISavePath {
    # one Ludusavi path -> the items found on this computer
    param([string]$Pattern, $Entry)
    $p = $Pattern.Replace('<home>', $env:USERPROFILE).Replace('<winDocuments>', [Environment]::GetFolderPath('MyDocuments'))
    $p = $p.Replace('<winLocalAppData>', $env:LOCALAPPDATA).Replace('<winAppData>', $env:APPDATA).Replace('<storeUserId>', '*')
    if ($p.Contains('<root>')) { $r = Get-SISteamRoot; if (-not $r) { return @() }; $p = $p.Replace('<root>', $r) }
    if ($p.Contains('<base>')) { $b = Get-SIGameBaseFolder -Entry $Entry; if (-not $b) { return @() }; $p = $p.Replace('<base>', $b) }
    if ($p.Contains('<')) { return @() }
    $p = $p -replace '/', '\'
    if ($p.Contains('*')) { return @(Get-Item -Path $p -Force -ErrorAction SilentlyContinue) }
    return @(Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue)
}

function Get-SISaveSet {
    # folders as they are, single files grouped by their folder
    param($Entry)
    $set = @()
    $files = @{}
    foreach ($pat in @($Entry.Saves)) {
        foreach ($it in @(Resolve-SISavePath -Pattern ([string]$pat) -Entry $Entry)) {
            if ($it.PSIsContainer) {
                if (-not ($set | Where-Object { $_.Path -eq $it.FullName })) { $set += [pscustomobject]@{ Path = $it.FullName; Dir = $true; Files = @() } }
            } else {
                if (-not $files.ContainsKey($it.DirectoryName)) { $files[$it.DirectoryName] = @() }
                $files[$it.DirectoryName] += $it.Name
            }
        }
    }
    foreach ($k in $files.Keys) { $set += [pscustomobject]@{ Path = $k; Dir = $false; Files = @($files[$k] | Select-Object -Unique) } }
    return $set
}

function Get-SISaveSetBytes {
    param($Set)
    $sum = 0L
    foreach ($s in @($Set)) {
        if ($s.Dir) { $sum += Get-SIFolderBytes -Path $s.Path }
        else { foreach ($n in $s.Files) { try { $sum += ([System.IO.FileInfo]::new((Join-Path $s.Path $n))).Length } catch { } } }
    }
    return $sum
}

function Copy-SISaveSet {
    param($Set, [string]$Dest, [string]$Game, [string]$Id)
    [void](New-Item -ItemType Directory -Path $Dest -Force)
    $i = 0
    $map = @()
    foreach ($s in @($Set)) {
        $to = Join-Path $Dest ([string]$i)
        if ($s.Dir) {
            if (Test-Path -LiteralPath $s.Path) { Copy-Item -LiteralPath $s.Path -Destination $to -Recurse -Force -ErrorAction SilentlyContinue }
        } else {
            [void](New-Item -ItemType Directory -Path $to -Force)
            foreach ($n in $s.Files) { Copy-Item -LiteralPath (Join-Path $s.Path $n) -Destination $to -Force -ErrorAction SilentlyContinue }
        }
        $map += [pscustomobject]@{ N = $i; Path = $s.Path; Dir = [bool]$s.Dir; Files = @($s.Files) }
        $i++
    }
    $mb = [math]::Max(0.01, [math]::Round((Get-SIFolderBytes -Path $Dest) / 1MB, 2))
    $info = [pscustomobject]@{ Id = $Id; Game = $Game; Date = [datetime]::Now.ToString('s'); MB = $mb; Items = $map }
    [System.IO.File]::WriteAllText((Join-Path $Dest 'map.json'), ($info | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
    return $info
}

function Get-SISavesRoot { [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-saves') }

function Backup-SIGameSaves {
    param($Entry)
    if (-not ($Entry.PSObject.Properties.Name -contains 'Saves') -or -not $Entry.Saves) { return $null }
    $set = @(Get-SISaveSet -Entry $Entry)
    if ($set.Count -eq 0) { return $null }
    $bytes = Get-SISaveSetBytes -Set $set
    if ($bytes -le 0) { return $null }
    if ($bytes -gt 2GB) {
        $t = (Get-SIMoreText 'SavesBig') -f $Entry.Game, [math]::Round($bytes / 1MB)
        Write-SILog -Level 'WARN' -Component 'More' -Message $t
        return [pscustomobject]@{ Ok = $false; Text = $t }
    }
    $dir = Join-Path (Join-Path (Get-SISavesRoot) ([string]$Entry.Id)) ([datetime]::Now.ToString('yyyyMMdd-HHmmss'))
    $info = Copy-SISaveSet -Set $set -Dest $dir -Game ([string]$Entry.Game) -Id ([string]$Entry.Id)
    # keep the 3 newest backups of each preset (only SIGAME's own copies are removed)
    try {
        $old = @(Get-ChildItem -LiteralPath (Split-Path -Parent $dir) -Directory | Sort-Object -Property Name -Descending | Select-Object -Skip 3)
        foreach ($o in $old) { Remove-Item -LiteralPath $o.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    } catch { }
    $t = (Get-SIMoreText 'SavesBacked') -f $Entry.Game, $info.MB
    Write-SILog -Component 'More' -Message "Saves backup $($Entry.Id): $($info.MB) MB -> $dir"
    return [pscustomobject]@{ Ok = $true; Text = $t; Path = $dir }
}

function Get-SISaveBackups {
    $root = Get-SISavesRoot
    if (-not (Test-Path -LiteralPath $root)) { return @() }
    $out = @()
    foreach ($m in @(Get-ChildItem -LiteralPath $root -Recurse -Filter 'map.json' -File -ErrorAction SilentlyContinue)) {
        try {
            $j = Get-Content -LiteralPath $m.FullName -Raw | ConvertFrom-Json
            $out += [pscustomobject]@{ Folder = $m.DirectoryName; Game = [string]$j.Game; Id = [string]$j.Id; Date = [datetime]$j.Date; MB = $j.MB; Items = @($j.Items) }
        } catch { }
    }
    return @($out | Sort-Object -Property Date -Descending)
}

function Restore-SIGameSaves {
    param($Backup, [switch]$NoAsk)
    if (-not $NoAsk -and -not (Show-SIMessage -Window $script:SIWindow -Title 'SIGAME' -Text ((Get-SIMoreText 'SavesAsk') -f $Backup.Game, $Backup.Date.ToString('dd/MM/yyyy HH:mm')))) { return $false }
    # the saves of now first, so a restore can be undone too
    $now = @($Backup.Items | Where-Object { Test-Path -LiteralPath $_.Path } | ForEach-Object { [pscustomobject]@{ Path = $_.Path; Dir = [bool]$_.Dir; Files = @($_.Files) } })
    if ($now.Count) {
        $pre = Join-Path (Split-Path -Parent $Backup.Folder) ([datetime]::Now.ToString('yyyyMMdd-HHmmss') + '-before-restore')
        [void](Copy-SISaveSet -Set $now -Dest $pre -Game $Backup.Game -Id $Backup.Id)
    }
    $n = 0
    foreach ($it in @($Backup.Items)) {
        $src = Join-Path $Backup.Folder ([string]$it.N)
        if (-not (Test-Path -LiteralPath $src)) { continue }
        [void](New-Item -ItemType Directory -Path $it.Path -Force)
        Get-ChildItem -LiteralPath $src -Force | Copy-Item -Destination $it.Path -Recurse -Force -ErrorAction SilentlyContinue
        $n++
    }
    Write-SILog -Component 'More' -Message "Saves restored $($Backup.Id) from $($Backup.Folder)"
    if (-not $NoAsk) { Show-SIInfoBox -Text ((Get-SIMoreText 'SavesDone') -f $Backup.Game, $n) }
    return $true
}

function Show-SISaveRestore {
    $list = @(Get-SISaveBackups)
    if ($list.Count -eq 0) { Show-SIInfoBox -Text (Get-SIMoreText 'SavesNone'); return }
    $rows = foreach ($b in $list) {
        $cap = $b
        [pscustomobject]@{
            Text   = '{0}  -  {1}  -  {2} MB' -f $b.Game, $b.Date.ToString('dd/MM/yyyy HH:mm'), $b.MB
            Button = Get-SIMoreText 'SavesBtn'
            Action = { [void](Restore-SIGameSaves -Backup $cap) }.GetNewClosure()
        }
    }
    Show-SIPickWindow -Title (Get-SIMoreText 'BtnSaves') -Note (Get-SIMoreText 'SavesNote') -Rows $rows
}

# ------------------------------- new presets / variants --------------------

function Send-SINewPresetNotice {
    param($Entries)
    $found = @($Entries | Where-Object { $_ -and $(try { Test-SIPresetFound -Entry $_ } catch { $false }) })
    if ($found.Count -eq 0) { return }
    $names = ($found | ForEach-Object { "$($_.Title) - $($_.Game)" }) -join ', '
    Show-SITrayNotification -Title 'SI PRESETS' -Text ((Get-SIMoreText 'NewPreset') -f $names)
}

function Get-SIPresetLabel {
    param($Entry)
    if ($Entry.PSObject.Properties.Name -contains 'Variant' -and $Entry.Variant) { return "$($Entry.Title) ($($Entry.Variant))" }
    return [string]$Entry.Title
}

function Test-SIPresetGroup {
    # two presets of one Group change the same settings: undo the applied one first
    param($Entry, $Window)
    if (-not ($Entry.PSObject.Properties.Name -contains 'Group') -or -not $Entry.Group) { return $true }
    $state = Get-SICommunityState
    $applied = @($state.Applied.PSObject.Properties.Name)
    $others = @(Get-SIPresetCatalog | Where-Object { $_.Id -ne $Entry.Id -and ($_.PSObject.Properties.Name -contains 'Group') -and $_.Group -eq $Entry.Group -and $applied -contains [string]$_.Id })
    foreach ($o in $others) {
        $a = Get-SIPresetLabel -Entry $o; $b = Get-SIPresetLabel -Entry $Entry
        if (-not (Show-SIMessage -Window $Window -Title 'SI PRESET' -Text ((Get-SIMoreText 'GroupAsk') -f $a, $b))) { return $false }
        if ($o.Undo) {
            $r = Invoke-SIPresetScript -Entry $o -Undo
            if (-not $r.Ok) { Show-SIInfoBox -Text ((Get-SIMoreText 'GroupFail') -f $a, (@($r.Lines | Where-Object { $_ }) | Select-Object -Last 1)); return $false }
        }
        $state.Applied.PSObject.Properties.Remove([string]$o.Id)
        Save-SICommunityState -State $state
    }
    return $true
}

# ------------------------------- hotkey ------------------------------------

$script:SIHotkeyCode = @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Interop;
public static class SIHotkey {
    [DllImport("user32.dll", SetLastError = true)] static extern bool RegisterHotKey(IntPtr hWnd, int id, uint mods, uint vk);
    [DllImport("user32.dll")] static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    public static Action<int> Callback;
    static bool hooked;
    public static bool Register(int id, uint mods, uint vk) {
        if (!hooked) { ComponentDispatcher.ThreadFilterMessage += OnMessage; hooked = true; }
        return RegisterHotKey(IntPtr.Zero, id, mods | 0x4000, vk);
    }
    public static void Unregister(int id) { UnregisterHotKey(IntPtr.Zero, id); }
    static void OnMessage(ref MSG msg, ref bool handled) {
        if (msg.message != 0x0312 || Callback == null) return;
        try { Callback(msg.wParam.ToInt32()); } catch { }
        handled = true;
    }
}
'@
$script:SIHotkeyId = 0x5347

function Invoke-SIHotkeyToggle {
    try {
        if ($script:SIBoostIsActive) { Invoke-SIGameOver } else { Invoke-SIBoost }
    } catch { Write-SILog -Level 'WARN' -Component 'More' -Message "hotkey: $($_.Exception.Message)" }
}

function Register-SIBoostHotkey {
    # Ctrl+Alt+B on the thread of the window (no window handle needed)
    if (-not ('SIHotkey' -as [type])) {
        $wb = [System.Windows.Interop.ComponentDispatcher].Assembly.Location
        Add-Type -ReferencedAssemblies $wb -TypeDefinition $script:SIHotkeyCode -ErrorAction Stop
    }
    $t = 'SIHotkey' -as [type]
    $t::Callback = [Action[int]] { param($id) Invoke-SIHotkeyToggle }
    $ok = $t::Register($script:SIHotkeyId, 0x0003, 0x42)
    $script:SIHotkeyOn = [bool]$ok
    if (-not $ok) { Write-SILog -Level 'WARN' -Component 'More' -Message 'Ctrl+Alt+B is used by another program' }
    return [bool]$ok
}

function Unregister-SIBoostHotkey {
    $t = 'SIHotkey' -as [type]
    if ($t) { $t::Unregister($script:SIHotkeyId) }
    $script:SIHotkeyOn = $false
}

# ------------------------------- window ------------------------------------

function Show-SIPickWindow {
    param([string]$Title, [string]$Note, $Rows)
    $c = $script:SIColors
    $w = [System.Windows.Window]::new()
    $w.Title = $Title
    $w.Width = 580; $w.Height = 500
    $w.WindowStartupLocation = 'CenterOwner'
    if ($script:SIWindow) { try { $w.Owner = $script:SIWindow } catch { } }
    $w.Background = Get-SIBrush $c.Background
    $sv = [System.Windows.Controls.ScrollViewer]::new()
    $sv.VerticalScrollBarVisibility = 'Auto'
    $sp = [System.Windows.Controls.StackPanel]::new()
    $sp.Margin = [System.Windows.Thickness]::new(14)
    if ($Note) {
        $n = [System.Windows.Controls.TextBlock]::new()
        $n.Text = $Note; $n.TextWrapping = 'Wrap'; $n.Foreground = Get-SIBrush $c.Muted
        $n.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
        [void]$sp.Children.Add($n)
    }
    foreach ($r in @($Rows)) {
        $b = [System.Windows.Controls.Border]::new()
        $b.Background = Get-SIBrush $c.PanelAlt
        $b.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $b.Padding = [System.Windows.Thickness]::new(10, 8, 10, 8)
        $b.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
        $d = [System.Windows.Controls.DockPanel]::new()
        $btn = New-SIStyleButton -Text $r.Button -StyleKey 'AccentButton' -Window $w -Width 110
        $btn.Height = 28
        [System.Windows.Controls.DockPanel]::SetDock($btn, 'Right')
        $a = $r.Action
        $null = $btn.Add_Click({ & $a }.GetNewClosure())
        [void]$d.Children.Add($btn)
        $t = [System.Windows.Controls.TextBlock]::new()
        $t.Text = $r.Text; $t.TextWrapping = 'Wrap'; $t.VerticalAlignment = 'Center'
        $t.Foreground = Get-SIBrush $c.Text
        [void]$d.Children.Add($t)
        $b.Child = $d
        [void]$sp.Children.Add($b)
    }
    $sv.Content = $sp
    $w.Content = $sv
    [void]$w.ShowDialog()
}

function Add-SIMoreSection {
    param($Panel, $Window)
    $null = $Panel.Children.Add((New-SIToolTitle -Text (Get-SIMoreText 'Title')))
    $row = [System.Windows.Controls.WrapPanel]::new()
    foreach ($b in @(
            @{ T = 'BtnRuntime'; F = { Invoke-SIRuntimeCheck } },
            @{ T = 'BtnVerify'; F = { Show-SISteamVerify } },
            @{ T = 'BtnShader'; F = { [void](Invoke-SIShaderCacheClean) } })) {
        $btn = New-SIStyleButton -Text (Get-SIMoreText $b.T) -StyleKey 'GhostButton' -Window $Window
        $f = $b.F
        $null = $btn.Add_Click({
            try { [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait; & $f }
            catch { Show-SIInfoBox -Text $_.Exception.Message }
            finally { [System.Windows.Input.Mouse]::OverrideCursor = $null }
        }.GetNewClosure())
        $null = $row.Children.Add($btn)
    }
    $null = $Panel.Children.Add($row)

    $row2 = [System.Windows.Controls.WrapPanel]::new()
    $hb = New-SIStyleButton -Text (Get-SIMoreText 'BtnHistory') -StyleKey 'GhostButton' -Window $Window
    $null = $hb.Add_Click({ Show-SIInfoBox -Text (Get-SIHistoryReport) })
    $null = $row2.Children.Add($hb)
    $sb = New-SIStyleButton -Text (Get-SIMoreText 'BtnSaves') -StyleKey 'GhostButton' -Window $Window
    $null = $sb.Add_Click({ Show-SISaveRestore })
    $null = $row2.Children.Add($sb)
    $on = ((Get-SIExtraState).PSObject.Properties.Name -notcontains 'Hotkey') -or [bool](Get-SIExtraState).Hotkey
    $kb = New-SIStyleButton -Text ((Get-SIMoreText 'BtnHotkey') -f (Get-SIMoreOnOff $on)) -StyleKey 'GhostButton' -Window $Window
    $kb.ToolTip = Get-SIMoreText 'HotkeyTip'
    $null = $kb.Add_Click({
        $x = Get-SIExtraState
        $now = -not (($x.PSObject.Properties.Name -notcontains 'Hotkey') -or [bool]$x.Hotkey)
        if ($now) {
            $ok = $false
            try { $ok = Register-SIBoostHotkey } catch { }
            if (-not $ok) { Show-SIInfoBox -Text (Get-SIMoreText 'HotkeyBusy'); return }
        } else { Unregister-SIBoostHotkey }
        $x | Add-Member 'Hotkey' $now -Force
        Save-SIExtraState -State $x
        $this.Content = (Get-SIMoreText 'BtnHotkey') -f (Get-SIMoreOnOff $now)
    })
    $null = $row2.Children.Add($kb)
    $null = $Panel.Children.Add($row2)
}

# ------------------------------- at load -----------------------------------
# a few seconds after the window opens: the hotkey and the GPU driver check
# (the C# build and the WMI query stay out of the start time)
try {
    $script:SIMoreTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $script:SIMoreTimer.Interval = [TimeSpan]::FromSeconds(8)
    $null = $script:SIMoreTimer.Add_Tick({
        $script:SIMoreTimer.Stop()
        try {
            $x = Get-SIExtraState
            if (($x.PSObject.Properties.Name -notcontains 'Hotkey') -or [bool]$x.Hotkey) { [void](Register-SIBoostHotkey) }
        } catch { Write-SILog -Level 'WARN' -Component 'More' -Message "hotkey: $($_.Exception.Message)" }
        try { Test-SIGpuDriverChanged } catch { }
    })
    $script:SIMoreTimer.Start()
} catch { }
