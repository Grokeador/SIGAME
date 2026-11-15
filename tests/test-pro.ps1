# Tests of the FPS statistics, the before/after verdict and the GUARD. No admin, no window, nothing is changed on the PC.
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-pro.ps1
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$work = Join-Path ([System.IO.Path]::GetTempPath()) ('sigame-test-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $work)
$script:SIRoot = $work
$script:SIGameVersion = 'test'
$script:Status = ''; $script:Balloon = ''
function Write-SILog { param($Level, $Component, $Message) }
function Get-SISILanguage { 'en' }
function Read-SIJsonFile { param([string]$Path) if (-not (Test-Path -LiteralPath $Path)) { return $null }; Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
function Set-SIStatusText { param($Text) $script:Status = $Text }
function Show-SITrayBalloon { param($Title, $Text) $script:Balloon = $Text }
. (Join-Path $repo 'modules\11-fps.ps1')
. (Join-Path $repo 'modules\12-guard.ps1')

$fail = 0
function Check { param([string]$Name, $Got, $Want)
    if ([string]$Got -ceq [string]$Want) { "ok    $Name = $Got" } else { $script:fail++; "FAIL  $Name = $Got (want $Want)" } }

# --- FPS: 6000 frames = 5940 x 10 ms, 54 x 25 ms, 6 x 50 ms (plus a smaller second swap chain to ignore)
$csv = Join-Path $work 'fps.csv'
$rows = New-Object System.Collections.Generic.List[string]
$rows.Add('Application,SwapChainAddress,MsBetweenPresents')
for ($i = 0; $i -lt 6000; $i++) {
    $ms = if ($i % 1000 -eq 0) { '50.0' } elseif ($i % 111 -eq 1 -and $rows.Count -ge 0 -and ($script:n25 -lt 54)) { $script:n25++; '25.0' } else { '10.0' }
    $rows.Add("game.exe,0xA,$ms")
}
for ($i = 0; $i -lt 100; $i++) { $rows.Add('game.exe,0xB,100.0') }
[System.IO.File]::WriteAllLines($csv, $rows)
$st = Get-SIFpsStats -CsvPath $csv
Check 'frames'   $st.Frames 6000
Check 'avg'      $st.Avg 98.3
Check 'low1'     $st.Low1 36.4
Check 'low01'    $st.Low01 20
Check 'worst ms' $st.WorstMs 50
Check 'stutters' $st.Stutters 60

# under 1000 frames: no 0.1% low
$small = Join-Path $work 'small.csv'
[System.IO.File]::WriteAllLines($small, @('SwapChainAddress,MsBetweenPresents') + (1..500 | ForEach-Object { '0xA,10.0' }))
Check 'low01 under 1000 frames' (Get-SIFpsStats -CsvPath $small).Low01 0
Check 'stutters flat run'       (Get-SIFpsStats -CsvPath $small).Stutters 0
Check 'no GPU column = 0'       (Get-SIFpsStats -CsvPath $small).GpuShare 0

# --- bottleneck and input latency (PresentMon MsGPUBusy, MsAllInputToPhotonLatency)
$gcsv = Join-Path $work 'gpu.csv'
$g = @('SwapChainAddress,MsBetweenPresents,MsGPUBusy,MsAllInputToPhotonLatency')
for ($i = 0; $i -lt 200; $i++) { $g += ('0xA,10.0,9.5,{0}' -f $(if ($i % 20 -eq 0) { '30.0' } else { 'NA' })) }
[System.IO.File]::WriteAllLines($gcsv, $g)
$gs = Get-SIFpsStats -CsvPath $gcsv
Check 'gpu share'          $gs.GpuShare 0.95
Check 'input ms median'    $gs.InputMs 30
Check 'bound 0.95'         (Get-SIFpsBound -Share 0.95) 'GPU'
Check 'bound 0.5'          (Get-SIFpsBound -Share 0.5) 'CPU'
Check 'bound 0.8'          (Get-SIFpsBound -Share 0.8) 'Balanced'
Check 'bound unknown'      (Get-SIFpsBound -Share 0) ''

# --- auto mode: the Undo offer waits until the game is closed
$script:Undo = ''; $script:Running = $true
function Get-SIGameProcess { param($Game) if ($script:Running) { 1 } }
function Invoke-SIFpsAutoUndo { param($Name, $Now, $Before) $script:Undo = "$Name|$($Now -join ',')|$Before" }
$script:SIFpsWatchTimer = [pscustomobject]@{} | Add-Member -MemberType ScriptMethod -Name Stop -Value { } -PassThru
$script:SIFpsWatch = @{ Game = 'g'; UndoAfterExit = $true; Name = 'Game'; Now = @('a', 'b'); Before = 'a' }
Step-SIFpsAutoWatch
Check 'no undo while the game runs' $script:Undo ''
$script:Running = $false
Step-SIFpsAutoWatch
Check 'undo offer after exit' $script:Undo 'Game|a,b|a'
Check 'watch cleared' ($null -eq $script:SIFpsWatch) 'True'

# --- verdict
Check 'verdict +1 / -2'  (Get-SIFpsVerdict -DeltaAvg 1 -DeltaLow -2) 'Noise'
Check 'verdict +5 / +1'  (Get-SIFpsVerdict -DeltaAvg 5 -DeltaLow 1) 'Better'
Check 'verdict 0 / +3'   (Get-SIFpsVerdict -DeltaAvg 0 -DeltaLow 3) 'Better'
Check 'verdict -4 / 0'   (Get-SIFpsVerdict -DeltaAvg -4 -DeltaLow 0) 'Worse'
Check 'verdict +6 / -6'  (Get-SIFpsVerdict -DeltaAvg 6 -DeltaLow -6) 'Mixed'
Check 'unsteady +24/+74' (Get-SIFpsVerdict -DeltaAvg 24 -DeltaLow 74 -NoiseAvg 30 -NoiseLow 80) 'Noise'
Check 'unsteady +40/+10' (Get-SIFpsVerdict -DeltaAvg 40 -DeltaLow 10 -NoiseAvg 30 -NoiseLow 80) 'Better'
Check 'steady spread <1' ($st.SpreadAvg -lt 1) 'True'
foreach ($lang in $script:SIFpsText.Keys) {
    Check "texts $lang same keys as en" (@($script:SIFpsText[$lang].Keys | Sort-Object) -join ',') (@($script:SIFpsText['en'].Keys | Sort-Object) -join ',')
}

# --- GUARD
function New-Audit { param([string[]]$Pending)
    $tw = 'A', 'B', 'C', 'D' | ForEach-Object { [pscustomobject]@{ Id = "id$_"; Name = "Tweak $_" } }
    [pscustomobject]@{ Plan = [pscustomobject]@{ Tweaks = $tw }; PendingNames = $Pending } }

Check 'no snapshot = no drift' (@(Invoke-SIGuardCheck -Audit (New-Audit @())).Count) 0
Save-SIGuardSnapshot -Audit (New-Audit @('Tweak D'))            # A B C active, D never applied
Check 'snapshot ids' ((Read-SIJsonFile $script:SIGuardPath).Active -join ',') 'idA,idB,idC'

$script:SIGuardChecked = $false
Check 'all still active' (@(Invoke-SIGuardCheck -Audit (New-Audit @('Tweak D'))).Count) 0
Check 'no status line'   $script:Status ''

$script:SIGuardChecked = $false
$d = @(Invoke-SIGuardCheck -Audit (New-Audit @('Tweak B', 'Tweak D')) -ButtonText 'GO')
Check 'drift = only B (D was never active)' ($d -join ',') 'Tweak B'
Check 'status line' $script:Status 'GUARD: 1 optimizations are no longer active (Tweak B). Press GO to apply them again.'
Check 'tray text = status' $script:Balloon $script:Status
Check 'once per start' (@(Invoke-SIGuardCheck -Audit (New-Audit @())) -join ',') 'Tweak B'

Clear-SIGuardSnapshot
Check 'undo all deletes the snapshot' (Test-Path -LiteralPath $script:SIGuardPath) $false
foreach ($lang in $script:SIGuardText.Keys) {
    Check "guard text $lang has 3 places" ([regex]::Matches($script:SIGuardText[$lang].Line, '\{\d\}').Count) 3
}

Remove-Item -LiteralPath $work -Recurse -Force
if ($fail) { "`n$fail FAILED"; exit 1 } else { "`nALL OK"; exit 0 }
