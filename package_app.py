import os
import shutil
import zipfile
import glob
import sys

def package():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    dist_dir = os.path.join(base_dir, "dist", "EventGuard_AI")
    zip_output_path = os.path.join(base_dir, "EventGuard_AI_v1.0_Windows_x64.zip")
    
    print(f"[1/5] Preparing clean dist folder: {dist_dir}")
    if os.path.exists(dist_dir):
        shutil.rmtree(dist_dir)
    os.makedirs(dist_dir, exist_ok=True)
    
    # 1. Copy Flutter Release files
    release_dir = os.path.join(base_dir, "build", "windows", "x64", "runner", "Release")
    if not os.path.exists(release_dir):
        raise RuntimeError(f"Release directory not found: {release_dir}. Build flutter first.")
    
    print("[2/5] Copying Flutter Release binaries and assets...")
    for item in os.listdir(release_dir):
        s = os.path.join(release_dir, item)
        d = os.path.join(dist_dir, item)
        if os.path.isdir(s):
            shutil.copytree(s, d)
        else:
            shutil.copy2(s, d)
            
    # 2. Copy Python AI Backend & Model Assets
    print("[3/5] Copying Python backend scripts, models, and cascades...")
    ai_files = ["backend_server.py", "yolo11n.pt", "anpr.py", "detc.py", "face.py", "vir.py"]
    for f in ai_files:
        src = os.path.join(base_dir, f)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(dist_dir, f))
            print(f"  + Copied {f}")
            
    # Copy all haarcascade xmls
    cascades = glob.glob(os.path.join(base_dir, "haarcascade_*.xml"))
    for c in cascades:
        shutil.copy2(c, os.path.join(dist_dir, os.path.basename(c)))
    print(f"  + Copied {len(cascades)} Haar cascade XML files")
    
    # 3. Create requirements.txt
    print("[4/5] Creating requirements.txt, launch scripts, and documentation...")
    reqs_content = """# EventGuard AI Backend Dependencies
flask>=3.0.0
flask-cors>=4.0.0
ultralytics>=8.0.0
opencv-python>=4.8.0
numpy>=1.24.0
torch>=2.0.0
torchvision>=0.15.0
pillow>=10.0.0
psutil>=5.9.0
pygrabber>=0.2
"""
    with open(os.path.join(dist_dir, "requirements.txt"), "w", encoding="utf-8") as f:
        f.write(reqs_content)
        
    # Create SETUP_DEPENDENCIES.bat
    setup_bat = r"""@echo off
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
echo   START_BORDERGUARD_AI.bat
echo ================================================================
echo.
pause
"""
    with open(os.path.join(dist_dir, "SETUP_DEPENDENCIES.bat"), "w", encoding="utf-8") as f:
        f.write(setup_bat)

    # Create START_BORDERGUARD_AI.bat
    launcher_bat = r"""@echo off
title EventGuard AI - Tactical Surveillance System
color 0B
echo ================================================================
echo                EVENTGUARD AI TACTICAL SUITE
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
"""
    with open(os.path.join(dist_dir, "START_BORDERGUARD_AI.bat"), "w", encoding="utf-8") as f:
        f.write(launcher_bat)

    # Create start_backend_debug.bat
    debug_bat = r"""@echo off
title EventGuard AI - Python Backend Debug Console
cd /d "%~dp0"
echo ========================================================
echo   EventGuard AI Multi-Node Tactical Video Backend
echo   (Debug Console Mode)
echo ========================================================
if exist "venv\Scripts\python.exe" (
    venv\Scripts\python.exe backend_server.py %*
) else (
    python backend_server.py %*
)
pause
"""
    with open(os.path.join(dist_dir, "start_backend_debug.bat"), "w", encoding="utf-8") as f:
        f.write(debug_bat)

    # Create README_HOW_TO_RUN.txt
    readme_txt = """================================================================
          EVENTGUARD AI - TACTICAL MULTI-NODE SURVEILLANCE
================================================================

EventGuard AI is an intelligent defense and border monitoring
workstation powered by Flutter and YOLOv11 Deep Learning.

FEATURES:
- Dual-node multi-camera tactical live streaming
- Real-time intruder, personnel, and vehicle tracking
- Virtual tripwire intrusion perimeter detection
- Automated License Plate Recognition (ANPR)
- Facial Biometric scanning and detection
- Low-latency DirectShow camera acceleration

----------------------------------------------------------------
SYSTEM REQUIREMENTS:
----------------------------------------------------------------
1. Windows 10 or Windows 11 (64-bit)
2. Python 3.10, 3.11, or 3.12 (with "Add Python to PATH" enabled)
   Download from: https://www.python.org/downloads/
3. Built-in Laptop Webcam (CAM-001) and/or Phone/External Camera (CAM-002)

----------------------------------------------------------------
QUICK START GUIDE (2 SIMPLE STEPS):
----------------------------------------------------------------
STEP 1 (First Time Only):
   Double-click:  SETUP_DEPENDENCIES.bat
   This will automatically create a local virtual environment and
   install PyTorch, YOLOv11, OpenCV, Flask, etc.

STEP 2:
   Double-click:  START_BORDERGUARD_AI.bat
   (or double-click eventguard_ai.exe directly)
   The application will start immediately and automatically manage
   the AI backend!

----------------------------------------------------------------
ADVANCED / DEBUGGING:
----------------------------------------------------------------
If you want to view live backend AI logs in a visible terminal window:
   Double-click:  start_backend_debug.bat
Then launch eventguard_ai.exe.

Enjoy using EventGuard AI!
================================================================
"""
    with open(os.path.join(dist_dir, "README_HOW_TO_RUN.txt"), "w", encoding="utf-8") as f:
        f.write(readme_txt)

    # 4. Create ZIP Archive
    print(f"[5/5] Compressing into ZIP archive: {zip_output_path}...")
    if os.path.exists(zip_output_path):
        os.remove(zip_output_path)
        
    file_count = 0
    with zipfile.ZipFile(zip_output_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for root, dirs, files in os.walk(dist_dir):
            for file in files:
                abs_path = os.path.join(root, file)
                # Compute relative path inside zip under EventGuard_AI/ folder
                rel_path = os.path.join("EventGuard_AI", os.path.relpath(abs_path, dist_dir))
                zf.write(abs_path, rel_path)
                file_count += 1
                
    zip_size_mb = os.path.getsize(zip_output_path) / (1024 * 1024)
    print(f"\n[SUCCESS] Packaged {file_count} files successfully!")
    print(f"Zip Location: {zip_output_path}")
    print(f"Zip Size: {zip_size_mb:.2f} MB")

if __name__ == "__main__":
    package()
