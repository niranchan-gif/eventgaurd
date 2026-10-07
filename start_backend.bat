s@echo off
echo ========================================================
echo   Starting EventGuard AI Multi-Node Event Video Backend
echo   CAM-001 (Laptop Webcam) + CAM-002 (Phone Recon Node)
echo ========================================================
cd /d "%~dp0"
if exist "venv\Scripts\python.exe" (
    venv\Scripts\python.exe backend_server.py %*
) else (
    python backend_server.py %*
)
pause
