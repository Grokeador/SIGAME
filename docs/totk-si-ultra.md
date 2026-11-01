# Zelda: Tears of the Kingdom (totk-pc-recomp native PC port): SI ULTRA preset for SIGAME (v1, Nov 2026)

**Official video source (SI NEWS):** https://youtu.be/Txgw49K6AcE

TL;DR
- Problem: the game's own menu does not reach these settings.
- Solution: the free **SI ULTRA** preset in [SIGAME](https://github.com/Grokeador/SIGAME), applied in one click, with backup and Undo.
- Result: Reads your monitor and writes the totk.ini keys the port's F1 menu cannot hold: 3D render scale up to the port's 4096-pixel scene for supersampled anti-aliasing (213% on a 1080p monitor; the menu stops at 200%), the largest 16:9 game resolution for your screen (5K and 8K too; the menu stops at 3840x2160), frame limit at your monitor's refresh rate with the port's high frame rate keys, and shader prewarm on all your CPU threads.

## What the preset does
Reads your monitor and writes the totk.ini keys the port's F1 menu cannot hold: 3D render scale up to the port's 4096-pixel scene for supersampled anti-aliasing (213% on a 1080p monitor; the menu stops at 200%), the largest 16:9 game resolution for your screen (5K and 8K too; the menu stops at 3840x2160), frame limit at your monitor's refresh rate with the port's high frame rate keys, and shader prewarm on all your CPU threads. Close the game first. Backup first, UNDO puts it back.

| Game | Preset | Preset version | Undo | Game / port source | Video |
|---|---|---|---|---|---|
| Zelda: Tears of the Kingdom (totk-pc-recomp native PC port) | SI ULTRA | 1 | yes | https://github.com/valentderah/totk-pc-recomp | https://youtu.be/Txgw49K6AcE |

## How do I apply it?
1. Download SIGAME: https://github.com/Grokeador/SIGAME (Code, Download ZIP, extract).
2. Double-click `SI-GAME-AUTO.bat`.
3. SI PRESETS, Check for new presets, Yes.
4. Close the game, pick **SI ULTRA (Zelda: Tears of the Kingdom (totk-pc-recomp native PC port))**, APPLY, Yes. APPLY again and Yes = Undo.

## FAQ
Q: Is it free?
A: Yes. SIGAME and every SI preset are free, no account.

Q: How do I go back to my old settings?
A: The preset makes a backup first; APPLY again and Yes restores it.

Q: Where do the values come from?
A: From the game's or the port's own files and source: https://github.com/valentderah/totk-pc-recomp.

Made by SI NEWS (https://www.youtube.com/@SINEWS-q5x). Video: https://youtu.be/Txgw49K6AcE
