@echo off
echo ========================================
echo Hong Game - Setup Script
echo ========================================
echo.

echo Checking for Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in the PATH.
    echo Please install Python 3.8 or newer from https://www.python.org/downloads/
    echo and make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)

echo Python is installed!
echo.

echo Checking for requirements.txt file...
if not exist requirements.txt (
    echo ERROR: requirements.txt file not found in the current directory.
    echo Make sure this script is in the same directory as requirements.txt.
    echo.
    pause
    exit /b 1
)

echo Installing required packages...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to install some requirements.
    echo Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo ========================================
echo All requirements installed successfully!
echo.
echo You can now run the game server with:
echo python minimal_game_server.py
echo.
echo Start the Godot game and enjoy!
echo ========================================
echo.

pause