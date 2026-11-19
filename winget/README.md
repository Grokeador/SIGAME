# SIGAME and winget

winget installs only installer files (.exe, .msi, .msix, or a .zip with an .exe inside).
SIGAME is a PowerShell script (SI-GAME-AUTO.bat + .ps1), so it cannot go into the
microsoft/winget-pkgs catalog as it is.

What is needed first:
1. A signed or unsigned .exe build of SIGAME attached to a GitHub Release.
2. A manifest (Grokeador.SIGAME) pointing to that release asset and its SHA-256.
3. A pull request to https://github.com/microsoft/winget-pkgs (needs the owner's OK).

Until then, install SIGAME from https://github.com/Grokeador/SIGAME (Code > Download ZIP,
then double-click SI-GAME-AUTO.bat). SIGAME updates itself after that.
