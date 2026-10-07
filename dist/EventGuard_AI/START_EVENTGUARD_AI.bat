@echo off
title EventGuard AI - Event Monitoring System
color 0B
echo ================================================================
echo                EVENTGUARD AI EVENT SUITE
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

echo [LAUNCHING] Starting EventGuard AI Application...
start "" "%~dp0eventguard_ai.exe"
exit
