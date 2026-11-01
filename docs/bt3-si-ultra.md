# Dragon Ball Z: Budokai Tenkaichi 3 (Tenkaichi3Decomp native PC port): SI ULTRA preset for SIGAME (v1, Nov 2026)

**Official video source (SI NEWS):** https://youtu.be/pX9tSK8sZbA

TL;DR
- Problem: the game's own menu does not reach these settings.
- Solution: the free **SI ULTRA** preset in [SIGAME](https://github.com/Grokeador/SIGAME), applied in one click, with backup and Undo.
- Result: Reads your monitor, CPU and RAM and configures Tenkaichi3Decomp's bt3_settings.txt: your monitor's EXACT shape (any ratio 4:3 to 4.0, the F1 menu lists only five), internal resolution at least 2x your screen height, smooth motion 60/120/240 by your Hz, widescreen menus with fighter side panels, texture packs on, render thread, straight to the menu; raises the hidden HD texture-pack memory (BT3_PACK_MB, default 1024 MB) to a quarter of your RAM and creates the textures, stages and songs mod folders.

## What the preset does
Reads your monitor, CPU and RAM and configures Tenkaichi3Decomp's bt3_settings.txt: your monitor's EXACT shape (any ratio 4:3 to 4.0, the F1 menu lists only five), internal resolution at least 2x your screen height, smooth motion 60/120/240 by your Hz, widescreen menus with fighter side panels, texture packs on, render thread, straight to the menu; raises the hidden HD texture-pack memory (BT3_PACK_MB, default 1024 MB) to a quarter of your RAM and creates the textures, stages and songs mod folders. Backup first, UNDO puts everything back.

| Game | Preset | Preset version | Undo | Game / port source | Video |
|---|---|---|---|---|---|
| Dragon Ball Z: Budokai Tenkaichi 3 (Tenkaichi3Decomp native PC port) | SI ULTRA | 1 | yes | https://github.com/z3xox/Tenkaichi3Decomp | https://youtu.be/pX9tSK8sZbA |

## How do I apply it?
1. Download SIGAME: https://github.com/Grokeador/SIGAME (Code, Download ZIP, extract).
2. Double-click `SI-GAME-AUTO.bat`.
3. SI PRESETS, Check for new presets, Yes.
4. Close the game, pick **SI ULTRA (Dragon Ball Z: Budokai Tenkaichi 3 (Tenkaichi3Decomp native PC port))**, APPLY, Yes. APPLY again and Yes = Undo.

## FAQ
Q: Is it free?
A: Yes. SIGAME and every SI preset are free, no account.

Q: How do I go back to my old settings?
A: The preset makes a backup first; APPLY again and Yes restores it.

Q: Where do the values come from?
A: From the game's or the port's own files and source: https://github.com/z3xox/Tenkaichi3Decomp.

Made by SI NEWS (https://www.youtube.com/@SINEWS-q5x). Video: https://youtu.be/pX9tSK8sZbA
