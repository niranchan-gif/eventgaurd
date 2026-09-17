@echo off
title BorderGuard AI - Python Backend Debug Console
cd /d "%~dp0"
echo ========================================================
echo   BorderGuard AI Multi-Node Tactical Video Backend
echo   (Debug Console Mode)
echo ========================================================
if exist "venv\Scripts\python.exe" (
    venv\Scripts\python.exe backend_server.py %*
) else (
    python backend_server.py %*
)
pause
