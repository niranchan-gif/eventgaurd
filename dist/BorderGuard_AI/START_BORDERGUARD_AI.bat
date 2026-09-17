@echo off
title BorderGuard AI - Tactical Surveillance System
color 0B
echo ================================================================
echo                BORDERGUARD AI TACTICAL SUITE
echo ================================================================
echo.
cd /d "%~dp0"

:: Check if local virtualenv exists
if not exist "venv\Scripts\python.exe" (
    echo [FIRST RUN DETECTED]
    echo Local Python AI environment is not set up yet.
    echo Running automated setup now...
    echo.
    call SETUP_DEPENDENCIES.bat
    if not exist "venv\Scripts\python.exe" (
        echo [ERROR] Setup did not finish. Exiting.
        pause
        exit /b 1
    )
)

echo [LAUNCHING] Starting BorderGuard AI Application...
start "" "%~dp0borderguard_ai.exe"
exit
