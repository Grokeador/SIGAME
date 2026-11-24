# SI UNLOCKER — Teenage Mutant Ninja Turtles (2003) PS2 (PCSX2)

Solves the classic **TMNT 2003 PS2 character-disappearance bug** when swapping one of the 5 Versus-only fighters (*Shredder, Oroku Saki, Hun, Foot Ninja, Hamato Yoshi*) into Story Mode, and configures PCSX2 for crisp 4K 60 FPS widescreen automatically.

## Why Characters Vanish in Story Mode
On PlayStation 2 (32 MB main RAM), each Story Mode stage only loads the 6 Story fighters plus the enemies present in that specific stage. Overwriting only the character ID in RAM on a stage that did not load the Versus fighter's 3D model points the engine to a `NULL` model — making the player disappear.

## What This Preset Does
1. Auto-detects your PCSX2 directory (or reads `$env:SIGAME_PCSX2_ROOT`), backs up `inis\PCSX2.ini` to `PCSX2.ini.sigame.bak`, and enables `EnableCheats`, `EnableWideScreenPatches`, `16:9`, `16x` anisotropic filtering, `LoadTextureReplacements`, and supersampled internal resolution matching your monitor.
2. Generates ready-to-use `.pnach` patch templates in `cheats\` for NTSC-U (`SLUS-20728`) and PAL (`SLES-51908`).
3. Writes the complete stage-safe swap & legal ISO model-slot remapping checklist to `cheats\SIGAME_TMNT_2003\STAGE_ASSET_REMAP_GUIDE.txt`.

## Usage
```powershell
# Apply (default fighter: Shredder)
powershell -ExecutionPolicy Bypass -File presets\tmnt-ps2-si-unlocker.ps1

# Choose another Versus fighter (Shredder | OrokuSaki | Hun | FootNinja | Yoshi)
powershell -ExecutionPolicy Bypass -File presets\tmnt-ps2-si-unlocker.ps1 -Character Hun

# Undo everything cleanly
powershell -ExecutionPolicy Bypass -File presets\tmnt-ps2-si-unlocker.ps1 -Undo
```
