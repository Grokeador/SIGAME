<p align="center"><img src="logo.png" width="140" alt="SIGAME logo"></p>

# SIGAME — one-click gaming optimizer for Windows 10 and 11

SIGAME scans your PC, finds your games and applies gaming tweaks with one click.
Every change is saved to a backup **before** it is made, and one button puts everything back.

It is plain PowerShell: no `.exe`, nothing hidden. Read every line before you run it.

Made for the **SI NEWS** YouTube channel ([@SINEWS-q5x](https://www.youtube.com/@SINEWS-q5x)):
SIGAME was rebuilt with AI from our first version into a fully automatic tool:
one click does everything.

## What it does

`SI-GAME-AUTO.bat` opens **SIGAME**: a diagnosis of your PC (hardware profile, applied tweaks, installed games)
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

The default mode of SIGAME is **Max FPS**. In this mode it also applies "hard" tweaks
that trade security or power saving for latency. They are all undone by **Undo all**, but you should know them:

- **CPU Spectre/Meltdown mitigations off** (`FeatureSettingsOverride = 3`) and
  **Virtualization-Based Security off**. Skipped automatically when Riot Vanguard or FACEIT is installed.
- **Game folders added to Microsoft Defender exclusions** (removed again by Undo all).
- Boot settings changed with `bcdedit` (`disabledynamictick`, `tscsyncpolicy`).
- Some unused services set to Manual, Windows Update paused while gaming, Fast Startup off.

If you do not want these, pick one of the other modes (for example **Streaming**) before pressing the button.

SIGAME does not promise a number of FPS: the gain depends on your PC. Measure before and after
with the built-in **live test** (timer, ping/jitter, free RAM).

## SI PRESETS: the extreme configs from our videos

The configs we build in the SI NEWS videos live in the `presets` folder (`presets/catalog.json` lists them).
When SIGAME finds one of those games, its card shows **SI PRESET**: one click backs up the game's config and applies it,
a second click offers **Undo**. **SI PRESETS** lists them all and **Check for new presets** downloads new ones from this repo.

| Preset | Game | What it does |
|---|---|---|
| SI ULTRA | Zelda: Ocarina of Time 3D ([Ocarina ReTuned](https://github.com/OTPR26/Ocarina-ReTuned)) | Saves a user preset with 23 graphics values at the highest the port's own code accepts, plus Link run/roll +20% and camera 150% |
| SI ULTRA | Rayman 3 HD ([Rayman 3 HD Recompiled](https://github.com/MysteriousAeon/rayman3-hd-recompiled)) | Writes two engine keys the port's Settings app does not show, at the highest value its runtime accepts: 16x anisotropic filtering (default 4x) and FXAA Extreme; sets Rendering resolution 2160p |

## Request a game

No SI PRESET for your game yet, or SIGAME does not see it? Press **REQUEST** on its card or **Request a game / Feedback**,
write the game and what you want (more FPS, graphics past the menu limits, ultrawide/144 Hz, faster loading...)
and press SEND. The most requested games get the next SI PRESETS.

## Anonymous stats (you can turn them off)

To choose which games get the next SI PRESETS, SIGAME sends SI NEWS anonymous stats. A line under the games list
says so, with a **Turn off** link (or set `"Telemetry": false` in `SI-GAME-community.json`). What is sent:

- once a week: the **names and stores of the games** SIGAME found, CPU and GPU model, RAM in GB, Windows build,
  SIGAME version and language;
- a game you add by hand (its name, exe file name and folder name), a REQUEST you send, a SI PRESET applied or failed.

Never sent: an id of any kind, file paths, your user name or PC name, files, serial numbers. The data goes to a
SI NEWS server on Cloudflare that stores only the country (from Cloudflare, not your IP address) and is read only
by SI NEWS. A REQUEST you send yourself goes out even with the stats off.

## Files SIGAME writes next to itself

`SI-GAME.log` (what it did), `SI-GAME-backup.json` (original values, used by Undo),
`SI-GAME-measures.json` (before/after measures), `SI-GAME-boost.json` (your games),
`SI-GAME-community.json` (stats on/off, the week of the last report, applied presets).

## Licence

SIGAME is released under the MIT License (see [LICENSE](LICENSE)). It is provided "as is", without warranty:
you run it on your own PC at your own risk, so keep the restore point.
