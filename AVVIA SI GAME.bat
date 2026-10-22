@echo off
rem  SIGAME - the launcher.
rem
rem  ONE line starts SIGAME: the file SI-GAME.ps1, with PowerShell 5.1, in the
rem  apartment of a single thread (the WPF window of SIGAME needs it).
rem
rem  The console of PowerShell is hidden and this launcher ends at once:
rem  SIGAME runs on its own and the launcher NEVER starts it a second time.
rem
rem  The exit code of PowerShell is NOT read here, on purpose. The launcher
rem  used to read it, and when the code was not 0 it thought that the start
rem  had failed, wrote a message on the screen and started a second SIGAME
rem  (the owner, 21/10). Nothing is written on the screen and nothing is
rem  started twice: the program itself always ends with the code 0.
rem
rem  The name of the program in every text is SIGAME (one word).
cd /d "%~dp0"
start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0SI-GAME.ps1"
exit /b 0
