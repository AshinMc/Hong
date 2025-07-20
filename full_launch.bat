@echo off
echo Starting Hong ...

echo.
echo Starting Server...
start cmd /k python server\server.py
echo.

echo.
echo Starting Godot Instances...
rem Replace with your actual Godot executable path
start "Player 1" "godot\Godot.exe" --path . --position 100,100
timeout /t 2
start "Player 2" "godot\Godot.exe" --path . --position 800,100

echo.
echo Environment Started! Please connect both players.