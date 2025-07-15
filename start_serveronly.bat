@echo off
echo Starting Hong Game Environment...

echo.
echo Starting Python WebSocket Server...
start cmd /k python game_server_v3\simplified_game_server.py
echo.
echo Starting Server Monitor...
start game_server_v3\server_monitor.html

echo.
echo Environment Started! Please connect both players.