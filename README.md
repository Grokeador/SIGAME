<p align="center"><img src="logo.png" width="140" alt="SIGAME logo"></p>

# SIGAME AUTO — one-click gaming optimizer for Windows 10 and 11

SIGAME scans your PC, finds your games and applies gaming tweaks with one click.
Every change is saved to a backup **before** it is made, and one button puts everything back.

It is plain PowerShell: no `.exe`, nothing hidden. Read every line before you run it.

Made for the **SI NEWS** YouTube channel ([@SINEWS-q5x](https://www.youtube.com/@SINEWS-q5x)):
the code was written by a **free AI model** (`minimax/minimax-m3.1-flash:free` on OpenRouter)
inside Claude Code, in a race against paid Claude. Based on
[Chris Titus WinUtil](https://github.com/ChrisTitusTech/winutil) (MIT) — credit and licence below.

## What it does

`SI-GAME-AUTO.bat` opens **SIGAME AUTO**: a diagnosis of your PC (hardware profile, applied tweaks, installed games)
and one button, **OTTIMIZZA**, that applies the whole hardware-adapted preset and optimizes every detected game.

Games are detected from Steam, Epic Games, Battle.net, EA app, Ubisoft Connect, Riot Games and GOG Galaxy,
and you can add any game by hand. Each game gets: high-performance GPU, fullscreen optimizations off,
high CPU priority, power throttling off and Auto-Boost.

## How to run it

1. Download the repo (green **Code** button → **Download ZIP**) and extract it.
2. Double-click `SI-GAME-AUTO.bat` and accept the administrator prompt.
3. SIGAME creates a **System Restore point** first, then shows the state of your PC.
4. Press **OTTIMIZZA**. Restart Windows when it asks.
5. Want everything back? Press **Undo all** (it reads `SI-GAME-backup.json`) or use the restore point.

Windows may say the script is from the internet: that is normal for any unsigned script.
Check it yourself on [VirusTotal](https://www.virustotal.com/) and read the code.

## ⚠️ Read this before you press OTTIMIZZA

The default mode of SIGAME AUTO is **Max FPS**. In this mode it also applies "hard" tweaks
that trade security or power saving for latency. They are all undone by **Undo all**, but you should know them:

- **CPU Spectre/Meltdown mitigations off** (`FeatureSettingsOverride = 3`) and
  **Virtualization-Based Security off**. Skipped automatically when Riot Vanguard or FACEIT is installed.
- **Game folders added to Microsoft Defender exclusions** (removed again by Undo all).
- Boot settings changed with `bcdedit` (`disabledynamictick`, `tscsyncpolicy`).
- Some unused services set to Manual, Windows Update paused while gaming, Fast Startup off.

If you do not want these, pick one of the other modes (for example **Streaming**) before pressing the button.

SIGAME does not promise a number of FPS: the gain depends on your PC. Measure before and after
with the built-in **live test** (timer, ping/jitter, free RAM).

## Files SIGAME writes next to itself

`SI-GAME.log` (what it did), `SI-GAME-backup.json` (original values, used by Undo),
`SI-GAME-measures.json` (before/after measures), `SI-GAME-boost.json` (your games).

## Full tweak list

See [docs/TWEAKS.md](docs/TWEAKS.md): every tweak, the registry keys, the source and how the undo works.

## Credits and licence

The tweak set, the registry keys and the apply/undo mechanics come from
**Chris Titus WinUtil** — https://github.com/ChrisTitusTech/winutil — MIT License, Copyright (c) 2023 Chris Titus.

SIGAME is released under the MIT License (see [LICENSE](LICENSE)). It is provided "as is", without warranty:
you run it on your own PC at your own risk, so keep the restore point.
