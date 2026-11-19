@echo off
title Ember Wilds - Discord Bot (24/7 Watchdog)
cd /d "%~dp0"
:loop
echo [%date% %time%] Starting Ember Wilds Discord Bot...
node index.js
echo [%date% %time%] Bot stopped or crashed. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto loop
