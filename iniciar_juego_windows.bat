@echo off
title Brilliant Windows Native
echo ===================================================
echo  Iniciando Brilliant (App Nativa de Windows)...
echo ===================================================

:: 1. Iniciar el servidor si no está corriendo
cd /d "%~dp0\servidor_auth"
start "Servidor Auth Brilliant" cmd /k "call C:\src\flutter\bin\dart.bat run bin/server.dart"

:: 2. Esperar 3 segundos
timeout /t 3 /nobreak >nul

:: 3. Lanzar la app nativa de escritorio
cd /d "%~dp0"
start "" "build\windows\x64\runner\Debug\dart_application_1.exe"
