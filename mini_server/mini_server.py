import asyncio
import json
import websockets

# Store connected clients
players = {"player1": None, "player2": None}
print("=== HONG GAME SERVER ===")
print("Running on ws://localhost:8765")

async def handle_client(websocket):
    """Handle a client connection with minimal code"""
    client_type = None
    
    try:
        # First message is identification
        message = await websocket.recv()
        data = json.loads(message)
        
        if "client_type" in data:
            client_type = data["client_type"]
            players[client_type] = websocket
            print(f"+ {client_type} connected")
            
            # Send confirmation
            await websocket.send(json.dumps({
                "status": "connected",
                "client_type": client_type
            }))
            
            # Notify other player
            other = "player2" if client_type == "player1" else "player1"
            if players[other]:
                await players[other].send(json.dumps({
                    "event": "client_connected",
                    "client": client_type
                }))
        
        # Main message handling
        async for message in websocket:
            data = json.loads(message)
            other = "player2" if client_type == "player1" else "player1"
            
            # Only log chat messages and actions, not position updates
            if "action" in data and not "position_update" in data:
                print(f"{client_type} → {data['action']}")
            elif "message_type" in data and data["message_type"] == "chat":
                print(f"{client_type} says: \"{data['content']}\"")
            
            # Add sender info
            data["sender"] = client_type
            
            # Forward to other player
            if players[other]:
                await players[other].send(json.dumps(data))
    
    except websockets.exceptions.ConnectionClosed:
        print(f"- {client_type} disconnected")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Clean up
        if client_type in players:
            players[client_type] = None
            
            # Notify other player
            other = "player2" if client_type == "player1" else "player1"
            if players[other]:
                try:
                    await players[other].send(json.dumps({
                        "event": "client_disconnected",
                        "client": client_type
                    }))
                except:
                    pass

async def main():
    async with websockets.serve(handle_client, "localhost", 8765):
        print("Server ready! Press Ctrl+C to stop")
        await asyncio.Future()  # Run forever

try:
    asyncio.run(main())
except KeyboardInterrupt:
    print("Server stopped")
except OSError as e:
    if e.errno == 10048:
        print("ERROR: Port 8765 already in use")
    else:
        print(f"ERROR: {e}")