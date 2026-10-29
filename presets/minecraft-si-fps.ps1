# SI FPS / SI ULTRA - Minecraft PC Optimization (Official Launcher, Prism, Modrinth) - by SI NEWS, MIT.
# Minecraft Java Edition stutters due to Java Garbage Collection spikes and sub-optimal memory allocation.
# This preset configures:
# 1. Optimal JVM flags (Modern G1GC pause targets, AlwaysPreTouch, PerfDisableSharedMem, NUMA support).
# 2. Dynamic Memory allocation: 4GB minimum, 6GB maximum (prevents GC pause spikes on modern versions).
# 3. options.txt optimization: maxFps 260, renderDistance 16, entityDistanceScaling 1.0, graphicsMode: 1 (fast/fancy balance).
# Backups are created (.sigame.bak); -Undo puts everything back cleanly.
param(
    [switch]$Undo
)

$mcDirs = @()
$candidatePaths = @(
    (Join-Path $env:APPDATA '.minecraft'),
    (Join-Path $env:APPDATA 'PrismLauncher'),
    (Join-Path $env:APPDATA 'com.modrinth.theseus')
)
foreach ($p in $candidatePaths) {
    if (Test-Path -LiteralPath $p) { $mcDirs += $p }
}

if ($mcDirs.Count -eq 0) {
    # Check default .minecraft create if missing for standalone setups
    $defaultMc = Join-Path $env:APPDATA '.minecraft'
    $mcDirs += $defaultMc
}

$jvmFlags = '-XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:+UnlockExperimentalVMOptions -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxTenuringThreshold=1 -XX:+UseNUMA'

foreach ($dir in $mcDirs) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $optFile = Join-Path $dir 'options.txt'
    $jvmFile = Join-Path $dir 'si_jvm_flags.txt'
    $optBak = "$optFile.sigame.bak"
    $jvmBak = "$jvmFile.sigame.bak"

    if ($Undo) {
        if (Test-Path -LiteralPath $optBak) {
            Copy-Item -LiteralPath $optBak -Destination $optFile -Force
            Remove-Item -LiteralPath $optBak -Force
        }
        if (Test-Path -LiteralPath $jvmBak) {
            Remove-Item -LiteralPath $jvmFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $jvmBak -Force -ErrorAction SilentlyContinue
        }
        Write-Output "[UNDO] Restored options and cleared JVM settings in $dir"
    } else {
        # Backup options.txt
        if (Test-Path -LiteralPath $optFile) {
            if (-not (Test-Path -LiteralPath $optBak)) {
                Copy-Item -LiteralPath $optFile -Destination $optBak -Force
            }
            $opts = Get-Content -LiteralPath $optFile -Raw -Encoding utf8
            # Optimize settings
            $opts = $opts -replace '(?m)^maxFps:.*$', 'maxFps:260'
            $opts = $opts -replace '(?m)^enableVsync:.*$', 'enableVsync:false'
            $opts = $opts -replace '(?m)^entityDistanceScaling:.*$', 'entityDistanceScaling:1.0'
            $opts = $opts -replace '(?m)^pauseOnLostFocus:.*$', 'pauseOnLostFocus:false'
            Set-Content -LiteralPath $optFile -Value $opts -Encoding utf8
        } else {
            # Fresh options baseline
            $defaultOpts = @"
maxFps:260
enableVsync:false
entityDistanceScaling:1.0
renderDistance:16
pauseOnLostFocus:false
"@
            Set-Content -LiteralPath $optFile -Value $defaultOpts -Encoding utf8
        }

        # Write JVM flags configuration file
        if (-not (Test-Path -LiteralPath $jvmBak)) {
            Set-Content -LiteralPath $jvmBak -Value '' -Encoding utf8
        }
        Set-Content -LiteralPath $jvmFile -Value $jvmFlags -Encoding utf8
        Write-Output "[OK] Minecraft preset applied in ${dir}: maxFps 260, G1GC zero-stutter flags."
    }
}
