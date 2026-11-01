# Zelda: Tears of the Kingdom (totk-pc-recomp native PC port): SI ULTRAWIDE preset for SIGAME (v1, Nov 2026)

**Official video source (SI NEWS):** https://youtu.be/3VwD2zssnuo

TL;DR
- Problem: the game's own menu does not reach these settings.
- Solution: the free **SI ULTRAWIDE** preset in [SIGAME](https://github.com/Grokeador/SIGAME), applied in one click, with backup and Undo.
- Result: Reads your monitor and sets the game to its own shape and size, 21:9, 32:9, 16:10 or 16:9, with the camera and the HUD in that shape.

## What the preset does
For port v0.2.1+ (ultrawide). Reads your monitor and sets the game to its own shape and size, 21:9, 32:9, 16:10 or 16:9, with the camera and the HUD in that shape. When your size is not one of the ten shapes in the port's F1 menu (a 57-inch 7680x2160, for example), it builds the HUD layout with the port's own tool from the unpacked TotK-Setup folder. Also: the largest scene the port draws (4096 px) for supersampling, frame limit at your refresh rate with the port's high frame rate keys, shader prewarm on all CPU threads. Close the game first. Backup first, UNDO puts it back.

| Game | Preset | Preset version | Undo | Game / port source | Video |
|---|---|---|---|---|---|
| Zelda: Tears of the Kingdom (totk-pc-recomp native PC port) | SI ULTRAWIDE | 1 | yes | https://github.com/valentderah/totk-pc-recomp | https://youtu.be/3VwD2zssnuo |

## How do I apply it?
1. Download SIGAME: https://github.com/Grokeador/SIGAME (Code, Download ZIP, extract).
2. Double-click `SI-GAME-AUTO.bat`.
3. SI PRESETS, Check for new presets, Yes.
4. Close the game, pick **SI ULTRAWIDE (Zelda: Tears of the Kingdom (totk-pc-recomp native PC port))**, APPLY, Yes. APPLY again and Yes = Undo.

## FAQ
Q: Is it free?
A: Yes. SIGAME and every SI preset are free, no account.

Q: How do I go back to my old settings?
A: The preset makes a backup first; APPLY again and Yes restores it.

Q: Where do the values come from?
A: From the game's or the port's own files and source: https://github.com/valentderah/totk-pc-recomp.

Made by SI NEWS (https://www.youtube.com/@SINEWS-q5x). Video: https://youtu.be/3VwD2zssnuo
