@echo off
title SIGAME AUTO
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0SI-GAME-AUTO.ps1"
