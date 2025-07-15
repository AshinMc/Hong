@echo off
echo Starting Hong Game Environment...

echo.
echo Starting Python WebSocket Server...
start cmd /k python game_server_v3\simplified_game_server.py
echo.
echo Starting Server Monitor...
start game_server_v3\server_monitor.html

echo.
echo Starting Godot Instances...
rem Replace with your actual Godot executable path
start "Player 1" "godot\Godot.exe" --path . --position 100,100
timeout /t 2
start "Player 2" "godot\Godot.exe" --path . --position 800,100

echo.
echo Environment Started! Please connect both players.