@echo off
title Brilliant - Iniciador
echo ===================================================
echo  Iniciando Servidor de Autenticacion y Brilliant...
echo ===================================================

:: 1. Iniciar el servidor en su propia ventana dedicada
cd /d "%~dp0\servidor_auth"
start "Servidor Auth Brilliant" cmd /k "call C:\src\flutter\bin\dart.bat run bin/server.dart"

:: 2. Esperar 3 segundos a que el servidor este listo y escuchando en el puerto 8080
echo Esperando a que el servidor este listo en puerto 8080...
timeout /t 3 /nobreak >nul

:: 3. Abrir la aplicacion en el navegador
echo Abriendo Brilliant en el navegador...
start http://localhost:8080

echo ===================================================
echo  Servidor corriendo en su ventana.
echo  Pestaña abierta en http://localhost:8080
echo ===================================================
