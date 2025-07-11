import asyncio
import json
import websockets

# Store connected clients
connected = {"player1": None, "player2": None, "monitors": []}
print("\n===== HONG GAME SERVER =====")
print("Server starting on ws://localhost:8765")

async def handle_client(websocket):
    """Handle a client connection"""
    client_type = None
    
    try:
        # First message should be identification
        message = await websocket.recv()
        data = json.loads(message)
        
        if "client_type" in data:
            client_type = data["client_type"]
            
            # Special handling for monitor connections
            if client_type == "monitor":
                connected["monitors"].append(websocket)
                print(f"\n🖥️ Monitor connected (Total: {len(connected['monitors'])})")
                # Send connection confirmation
                await websocket.send(json.dumps({
                    "status": "connected",
                    "client_type": "monitor",
                    "player1_connected": connected["player1"] is not None,
                    "player2_connected": connected["player2"] is not None
                }))
            else:
                # Normal player connection
                connected[client_type] = websocket
                print(f"\n➡️ {client_type} connected")
                
                # Send confirmation to client
                await websocket.send(json.dumps({
                    "status": "connected",
                    "client_type": client_type
                }))
                
                # Notify other client if connected
                other = "player2" if client_type == "player1" else "player1"
                if connected[other]:
                    print(f"Notifying {other} about {client_type} connection")
                    await connected[other].send(json.dumps({
                        "event": "client_connected",
                        "client": client_type
                    }))
                
                # Notify all monitors
                event = {
                    "monitor_event": "player_connected",
                    "player": client_type
                }
                await broadcast_to_monitors(event)
        
        # If this is a monitor, just keep the connection open
        if client_type == "monitor":
            # Keep connection alive until closed
            await websocket.wait_closed()
            return
        
        # Process messages for players
        async for message in websocket:
            data = json.loads(message)
            other = "player2" if client_type == "player1" else "player1"
            
            # Log the message type for clarity
            if "action" in data:
                msg_type = "action"
                print(f"\n🎮 {client_type} → {other}: {data['action']}")
            elif "message_type" in data and data["message_type"] == "chat":
                msg_type = "chat"
                print(f"\n💬 {client_type} → {other}: \"{data['content']}\"")
            elif "position_update" in data:
                msg_type = "position"
                # Don't log position updates to keep console clean
                pass
            else:
                msg_type = "other"
                print(f"\n📦 {client_type} → {other}: {data}")
            
            # Add sender information
            data["sender"] = client_type
            
            # Forward to other client
            if connected[other]:
                await connected[other].send(json.dumps(data))
            
            # Also send to all monitors (except position updates)
            if msg_type != "position":
                monitor_event = {
                    "monitor_event": "message",
                    "message_type": msg_type,
                    "from": client_type,
                    "to": other,
                    "data": data
                }
                await broadcast_to_monitors(monitor_event)
    
    except websockets.exceptions.ConnectionClosed:
        print(f"\n❌ {'Monitor' if client_type == 'monitor' else client_type} disconnected")
    except Exception as e:
        print(f"\n❌ Error: {e}")
    finally:
        # Clean up
        if client_type == "monitor":
            if websocket in connected["monitors"]:
                connected["monitors"].remove(websocket)
                print(f"Removed monitor (Remaining: {len(connected['monitors'])})")
        elif client_type:
            connected[client_type] = None
            print(f"Removed {client_type} from connected clients")
            
            # Notify other client
            other = "player2" if client_type == "player1" else "player1"
            if connected[other]:
                try:
                    await connected[other].send(json.dumps({
                        "event": "client_disconnected",
                        "client": client_type
                    }))
                    print(f"Notified {other} about {client_type} disconnection")
                except:
                    pass
            
            # Notify all monitors
            event = {
                "monitor_event": "player_disconnected",
                "player": client_type
            }
            await broadcast_to_monitors(event)

async def broadcast_to_monitors(event):
    """Send event to all connected monitors"""
    if not connected["monitors"]:
        return
        
    for monitor in connected["monitors"][:]:  # Copy the list to avoid modification during iteration
        try:
            await monitor.send(json.dumps(event))
        except:
            # If sending fails, the monitor will be removed in the next exception handler
            pass

async def status_reporter():
    """Print status periodically"""
    while True:
        await asyncio.sleep(15)  # Check every 15 seconds
        p1 = "✅" if connected["player1"] else "❌"
        p2 = "✅" if connected["player2"] else "❌"
        m = len(connected["monitors"])
        print(f"\n📊 STATUS: Player 1: {p1}  Player 2: {p2}  Monitors: {m}")

async def main():
    async with websockets.serve(handle_client, "localhost", 8765):
        # Start status reporter
        asyncio.create_task(status_reporter())
        print("Server is running! Waiting for players...\n")
        print("Press Ctrl+C to stop the server")
        # Keep the server running
        await asyncio.Future()

try:
    asyncio.run(main())
except KeyboardInterrupt:
    print("\n\n🛑 Server stopped by user")
except OSError as e:
    if e.errno == 10048:  # Port already in use
        print("\n❌ ERROR: Port 8765 is already in use!")
        print("Please close any existing server instances or use a different port.")
    else:
        print(f"\n❌ ERROR: {e}")