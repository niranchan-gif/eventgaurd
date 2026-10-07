@echo off
title EventGuard AI - Python Backend Debug Console
cd /d "%~dp0"
echo ========================================================
echo   EventGuard AI Multi-Node Event Video Backend
echo   (Debug Console Mode)
echo ========================================================
if exist "venv\Scripts\python.exe" (
    venv\Scripts\python.exe backend_server.py %*
) else (
    python backend_server.py %*
)
pause
