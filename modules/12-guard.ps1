# ===================== 12. GUARD: OPTIMIZATIONS THAT WENT BACK =====================
# A Windows update, a driver update or another tool can put a setting back without a word. After every
# OPTIMIZE, SIGAME keeps the list of the tweaks that were really active (SI-GAME-guard.json). At the next
# starts it reads the same tweaks again: the ones that are no longer active are named in the status line,
# in the tray and in the log, and one press on the optimize button applies them again.
# Nothing is changed by the guard itself: it only reads. "Undo all" deletes the list.

$script:SIGuardPath    = [System.IO.Path]::Combine($script:SIRoot, 'SI-GAME-guard.json')
$script:SIGuardChecked = $false
$script:SIGuardDrift   = @()

$script:SIGuardText = @{
    'en'    = @{ Title = 'SIGAME GUARD'; Line = 'GUARD: {0} optimizations are no longer active ({1}). Press {2} to apply them again.' }
    'it'    = @{ Title = 'SIGAME GUARD'; Line = 'GUARD: {0} ottimizzazioni non sono piu'' attive ({1}). Premi {2} per riapplicarle.' }
    'pt-BR' = @{ Title = 'SIGAME GUARD'; Line = 'GUARD: {0} otimizacoes nao estao mais ativas ({1}). Pressione {2} para aplicar de novo.' }
    'es'    = @{ Title = 'SIGAME GUARD'; Line = 'GUARD: {0} optimizaciones ya no estan activas ({1}). Pulsa {2} para aplicarlas de nuevo.' }
    'de'    = @{ Title = 'SIGAME GUARD'; Line = 'GUARD: {0} Optimierungen sind nicht mehr aktiv ({1}). {2} druecken, um sie wieder anzuwenden.' }
    'fr'    = @{ Title = 'SIGAME GUARD'; Line = 'GUARD: {0} optimisations ne sont plus actives ({1}). Appuie sur {2} pour les appliquer de nouveau.' }
}

function Get-SIGuardText {
    param([Parameter(Mandatory = $true)][string]$Key)
    $lang = 'en'
    try { $lang = Get-SISILanguage } catch { }
    if ($script:SIGuardText.ContainsKey($lang)) { return $script:SIGuardText[$lang][$Key] }
    return $script:SIGuardText['en'][$Key]
}

function Get-SIGuardTweakLists {
    <#
    .SYNOPSIS
        The tweaks of the hardware plan split in two lists of @{ Id; Name }: Active and Pending.
    #>
    param($Audit)
    $active = @(); $pending = @()
    if ($Audit -and $Audit.Plan) {
        $pendingNames = @($Audit.PendingNames)
        foreach ($item in @($Audit.Plan.Tweaks)) {
            $one = @{ Id = [string]$item.Id; Name = [string]$item.Name }
            if ($pendingNames -contains $item.Name) { $pending += $one } else { $active += $one }
        }
    }
    return @{ Active = $active; Pending = $pending }
}

function Get-SIGuardDrift {
    <#
    .SYNOPSIS
        The names of the tweaks that were active at the last OPTIMIZE and are pending now.
        A tweak that left the plan (other hardware state) is not counted.
    #>
    param([string[]]$SavedIds, $Pending)
    $names = @()
    foreach ($p in @($Pending)) {
        if ($p -and (@($SavedIds) -contains [string]$p.Id)) { $names += [string]$p.Name }
    }
    return @($names)
}

function Save-SIGuardSnapshot {
    <#
    .SYNOPSIS
        Called after OPTIMIZE: keeps the ids of the tweaks that are really active now.
    #>
    param($Audit)
    try {
        $lists = Get-SIGuardTweakLists -Audit $Audit
        $ids = @($lists.Active | ForEach-Object { $_.Id })
        $snap = [pscustomobject]@{ At = [datetime]::Now.ToString('s'); Version = [string]$script:SIGameVersion; Active = $ids }
        [System.IO.File]::WriteAllText($script:SIGuardPath, ($snap | ConvertTo-Json -Depth 4))
        $script:SIGuardDrift = @()
        $script:SIGuardChecked = $true
        Write-SILog -Component 'Guard' -Message "Snapshot saved: $($ids.Count) active tweaks"
    } catch {
        Write-SILog -Level 'WARN' -Component 'Guard' -Message "Snapshot not saved: $($_.Exception.Message)"
    }
}

function Clear-SIGuardSnapshot {
    <#
    .SYNOPSIS
        Called after "Undo all": the player wants the tweaks off, so there is nothing to guard.
    #>
    try { if ([System.IO.File]::Exists($script:SIGuardPath)) { [System.IO.File]::Delete($script:SIGuardPath) } } catch { }
    $script:SIGuardDrift = @()
}

function Invoke-SIGuardCheck {
    <#
    .SYNOPSIS
        Once per start: names the tweaks that went back since the last OPTIMIZE. Reads only.
    .OUTPUTS
        The names (empty when everything is still active or there is no snapshot).
    #>
    param($Audit, [string]$ButtonText = 'OPTIMIZE')
    if ($script:SIGuardChecked) { return @($script:SIGuardDrift) }
    $script:SIGuardChecked = $true
    try {
        $snap = Read-SIJsonFile -Path $script:SIGuardPath
        if (-not $snap -or -not $snap.Active) { return @() }
        $lists = Get-SIGuardTweakLists -Audit $Audit
        $drift = @(Get-SIGuardDrift -SavedIds @($snap.Active | ForEach-Object { [string]$_ }) -Pending $lists.Pending)
        $script:SIGuardDrift = $drift
        if ($drift.Count -eq 0) {
            Write-SILog -Component 'Guard' -Message "All $(@($snap.Active).Count) tweaks of $($snap.At) are still active"
            return @()
        }
        $shown = @($drift | Select-Object -First 4) -join ', '
        if ($drift.Count -gt 4) { $shown += ', ...' }
        $line = (Get-SIGuardText 'Line') -f $drift.Count, $shown, $ButtonText
        Write-SILog -Level 'WARN' -Component 'Guard' -Message ("No longer active since $($snap.At): " + ($drift -join ', '))
        try { Set-SIStatusText -Text $line } catch { }
        try { Show-SITrayBalloon -Title (Get-SIGuardText 'Title') -Text $line } catch { }
        return $drift
    } catch {
        Write-SILog -Level 'WARN' -Component 'Guard' -Message "Check failed: $($_.Exception.Message)"
        return @()
    }
}
