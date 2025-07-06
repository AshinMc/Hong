import asyncio
import json
import logging
import websockets
from datetime import datetime

# Setup logging
logging.basicConfig(
    format="%(asctime)s - %(message)s",
    level=logging.INFO,
    datefmt="%Y-%m-%d %H:%M:%S"
)

# Store connected clients
connected_clients = {}

async def handle_client(websocket):
    """
    Handle a WebSocket connection - Python 3.13 version
    only requires the websocket parameter
    """
    client_type = "unknown"
    client_info = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}" if hasattr(websocket, 'remote_address') else "unknown"
    
    try:
        logging.info(f"New connection from {client_info}")
        
        # Wait for initial identification message
        async for message in websocket:
            try:
                data = json.loads(message)
                
                # Handle client identification
                if "client_type" in data:
                    client_type = data["client_type"]
                    connected_clients[client_type] = websocket
                    logging.info(f"Client identified as {client_type}")
                    
                    # Send confirmation to client
                    await websocket.send(json.dumps({
                        "status": "connected",
                        "client_type": client_type
                    }))
                    
                    # Notify other client if connected
                    other_client = "player2" if client_type == "player1" else "player1"
                    if other_client in connected_clients:
                        await connected_clients[other_client].send(json.dumps({
                            "event": "client_connected",
                            "client": client_type
                        }))
                    break
            except json.JSONDecodeError:
                logging.error(f"Invalid JSON received: {message}")
                continue
        
        # Main message handling loop
        async for message in websocket:
            try:
                data = json.loads(message)
                logging.info(f"Received from {client_type}: {message[:100]}...")  # Log truncated message
                
                # Always add sender information
                data["sender"] = client_type
                
                # Route messages to the other client
                if client_type == "player1":
                    if "player2" in connected_clients:
                        await connected_clients["player2"].send(json.dumps(data))
                elif client_type == "player2":
                    if "player1" in connected_clients:
                        await connected_clients["player1"].send(json.dumps(data))
                
            except json.JSONDecodeError:
                logging.error(f"Invalid JSON received: {message}")
                continue
                
    except websockets.exceptions.ConnectionClosedOK:
        logging.info(f"Connection closed normally for {client_type}")
    except websockets.exceptions.ConnectionClosedError as e:
        logging.info(f"Connection closed with error for {client_type}: {e}")
    except Exception as e:
        logging.error(f"Error handling client: {e}")
    finally:
        # Remove client from connected clients
        if client_type in connected_clients:
            del connected_clients[client_type]
        
        # Notify other client about disconnection
        other_client = "player2" if client_type == "player1" else "player1"
        if other_client in connected_clients:
            try:
                await connected_clients[other_client].send(json.dumps({
                    "event": "client_disconnected",
                    "client": client_type
                }))
            except:
                pass
                
        logging.info(f"Connection from {client_info} ({client_type}) closed")

async def main():
    """Start the websocket server"""
    # Note: For Python 3.13, the API is slightly different
    async with websockets.serve(handle_client, "localhost", 8765):
        logging.info("Server started on ws://localhost:8765")
        # Keep the server running forever
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Server stopped by user")