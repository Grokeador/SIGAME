# SIGAME and winget

winget installs only installer files (.exe, .msi, .msix, or a .zip with an .exe inside).
Since 2026.11.18.11 every GitHub Release of SIGAME has `SIGAME-<version>.zip`: the app files plus
`SIGAME.exe`, a small launcher built from [launcher/SIGAME.cs](../launcher/SIGAME.cs) with
[launcher/build.ps1](../launcher/build.ps1). It starts `SI-GAME-AUTO.ps1` from its own folder.

The manifests for that zip are in [manifests/g/Grokeador/SIGAME](manifests/g/Grokeador/SIGAME)
(zip + portable SIGAME.exe, command `sigame`, SHA-256 of the release asset).

Still to do (needs the owner's OK): a pull request with that folder to
https://github.com/microsoft/winget-pkgs. Check it first with
`winget validate --manifest winget\manifests\g\Grokeador\SIGAME\<version>` and
`winget install --manifest winget\manifests\g\Grokeador\SIGAME\<version>`.

Until it is accepted, install SIGAME from https://github.com/Grokeador/SIGAME/releases (extract the zip, then
double-click SIGAME.exe) or Code > Download ZIP and SI-GAME-AUTO.bat. SIGAME updates its scripts itself after that.
