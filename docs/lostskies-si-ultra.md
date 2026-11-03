# Lost Skies (PC): SI ULTRA preset for SIGAME (v1, Nov 2026)

**Official video source (SI NEWS):** https://youtu.be/obudSasMbmI

TL;DR
- Problem: the game's own menu does not reach these settings.
- Solution: the free **SI ULTRA** preset in [SIGAME](https://github.com/Grokeador/SIGAME), applied in one click, with backup and Undo.
- Result: Lost Skies runs on Unity: this edits the game's boot.config (graphics jobs, garbage collector time per frame) and Unity's own registry keys (full screen window, your monitor's resolution), and tells Windows to use the high performance GPU.

## What the preset does
Lost Skies runs on Unity: this edits the game's boot.config (graphics jobs, garbage collector time per frame) and Unity's own registry keys (full screen window, your monitor's resolution), and tells Windows to use the high performance GPU. Keys from Unity's docs and a public guide. Steam update or Verify? APPLY, No, Yes. UNDO restores the exact old values.

| Game | Preset | Preset version | Undo | Game / port source | Video |
|---|---|---|---|---|---|
| Lost Skies (PC) | SI ULTRA | 1 | yes | https://docs.unity.com/en-us/engine/6000.7/manual/platform-specific/windows/playersettings | https://youtu.be/obudSasMbmI |

## How do I apply it?
1. Download SIGAME: https://github.com/Grokeador/SIGAME (Code, Download ZIP, extract).
2. Double-click `SI-GAME-AUTO.bat`.
3. SI PRESETS, Check for new presets, Yes.
4. Close the game, pick **SI ULTRA (Lost Skies (PC))**, APPLY, Yes. APPLY again and Yes = Undo.

## FAQ
Q: Is it free?
A: Yes. SIGAME and every SI preset are free, no account.

Q: How do I go back to my old settings?
A: The preset makes a backup first; APPLY again and Yes restores it.

Q: Where do the values come from?
A: From the game's or the port's own files and source: https://docs.unity.com/en-us/engine/6000.7/manual/platform-specific/windows/playersettings.

Made by SI NEWS (https://www.youtube.com/@SINEWS-q5x). Video: https://youtu.be/obudSasMbmI
