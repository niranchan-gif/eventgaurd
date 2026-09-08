@echo off
echo ========================================================
echo   Starting BorderGuard AI Python Backend (CAM-01)
echo ========================================================
cd /d "%~dp0"
if exist "venv\Scripts\python.exe" (
    venv\Scripts\python.exe backend_server.py
) else (
    python backend_server.py
)
pause
