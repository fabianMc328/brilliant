@echo off
title Servidor y Juego Brilliant
echo ===================================================
echo  Iniciando Brilliant (Servidor y Juego)...
echo ===================================================
cd /d "%~dp0"
start http://localhost:8080
call "C:\src\flutter\bin\dart.bat" run bin/server.dart
pause
