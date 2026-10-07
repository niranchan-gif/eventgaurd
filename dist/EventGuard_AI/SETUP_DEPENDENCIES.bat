@echo off
title EventGuard AI - Environment Setup
color 0A
echo ================================================================
echo           EVENTGUARD AI - ONE-TIME ENVIRONMENT SETUP
echo ================================================================
echo.
echo Checking for Python installation...

where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python was not detected on your system.
    echo Please install Python 3.10, 3.11, or 3.12 from https://www.python.org/downloads/
    echo IMPORTANT: Make sure to check "Add Python to PATH" during installation!
    echo.
    pause
    exit /b 1
)

python --version
echo.
echo [1/3] Creating dedicated local virtual environment (venv)...
cd /d "%~dp0"
if not exist "venv" (
    python -m venv venv
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    echo [OK] Virtual environment created.
) else (
    echo [INFO] Virtual environment already exists.
)

echo.
echo [2/3] Upgrading pip and wheel...
venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel >nul 2>&1

echo.
echo [3/3] Installing AI Computer Vision & Deep Learning dependencies...
echo (This downloads PyTorch, YOLOv11, OpenCV, and Flask - please wait a few moments)
echo.
venv\Scripts\pip.exe install -r requirements.txt
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Some dependencies had warnings. Attempting direct core install...
    venv\Scripts\pip.exe install flask flask-cors ultralytics opencv-python numpy pillow psutil pygrabber
)

echo.
echo ================================================================
echo   SETUP COMPLETED SUCCESSFULLY!
echo ================================================================
echo You are all set! You can now start EventGuard AI by double-clicking:
echo   START_EVENTGUARD_AI.bat
echo ================================================================
echo.
pause
