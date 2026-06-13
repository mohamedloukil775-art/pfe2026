@echo off
title Padel Championship - Demarrage
echo ============================================
echo   PADEL CHAMPIONSHIP - Demarrage complet
echo ============================================
echo.

:: Arreter les anciens processus sur les ports utilises
echo [1/3] Liberation des ports...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080 "') do taskkill /PID %%a /F >nul 2>&1
taskkill /F /IM "PadelChampionship.Api.exe" >nul 2>&1
timeout /t 2 /nobreak >nul

:: IMPORTANT: lancer le backend depuis PadelChampionship.Api\ pour utiliser padel.db
echo [2/3] Demarrage du backend (port 5001)...
set EXE=%~dp0flutter_application_1\backend\PadelChampionship.Api\bin\Debug\net8.0\PadelChampionship.Api.exe
set DIR=%~dp0flutter_application_1\backend\PadelChampionship.Api
start "Backend Padel" /D "%DIR%" "%EXE%"
timeout /t 4 /nobreak >nul

:: Lancer l'app Flutter en mode web-server (admin + joueur telephone)
echo [3/3] Lancement du serveur web Flutter...
cd /d "%~dp0flutter_application_1"
start "Flutter Web" cmd /k "flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"

echo.
echo ============================================
echo   Application lancee !
echo.
echo   ADMIN  (navigateur PC)  : http://localhost:8080
echo   JOUEUR (telephone WiFi) : http://192.168.1.21:8080
echo.
echo   Admin  : admin@padel.tn  / Admin123!
echo   Joueur : ahmed.ben.ali@padel.tn / Joueur123!
echo ============================================
echo.
pause
