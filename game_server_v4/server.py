import asyncio
import json
import websockets
import socket
import threading
import time
import ipaddress

# Get your local IP address
def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"  # Fallback to localhost

# Store connected clients
players = {"player1": None, "player2": None}
server_ip = get_local_ip()
server_port = 8765
discovery_port = 8766  # Different port for discovery broadcasts

print("=== HONG GAME SERVER ===")
print(f"Running on ws://{server_ip}:{server_port}")
print(f"Players should connect to: ws://{server_ip}:{server_port}")

# Function to broadcast server presence for auto-discovery
def broadcast_presence():
    """Broadcast server IP and port so clients can find it automatically"""
    # Create broadcast socket
    broadcast_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    broadcast_sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    
    # Create direct reply socket
    reply_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    reply_sock.bind((server_ip, discovery_port))
    reply_sock.settimeout(0.1)  # Short timeout for non-blocking checks
    
    # Prepare announcement message
    announcement = json.dumps({
        "type": "hong_server",
        "ip": server_ip,
        "port": server_port,
        "version": "1.0"
    }).encode('utf-8')
    
    print(f"Starting auto-discovery on port {discovery_port}")
    print(f"Server IP: {server_ip}")
    
    try:
        while True:
            # 1. Broadcast to the network
            try:
                broadcast_sock.sendto(announcement, ('<broadcast>', discovery_port))
            except:
                pass
                
            # 2. Check for direct discovery requests
            try:
                data, addr = reply_sock.recvfrom(1024)
                try:
                    request = json.loads(data.decode('utf-8'))
                    if request.get("type") == "hong_discovery_request":
                        print(f"Received direct discovery request from {addr[0]}")
                        # Send direct reply
                        reply_sock.sendto(announcement, addr)
                except:
                    pass
            except socket.timeout:
                pass  # No discovery requests
            
            time.sleep(1)  # Broadcast every second
    except Exception as e:
        print(f"Broadcast error: {e}")
    finally:
        broadcast_sock.close()
        reply_sock.close()


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
    # Start the discovery broadcast thread
    broadcast_thread = threading.Thread(target=broadcast_presence, daemon=True)
    broadcast_thread.start()
    
    # Accept connections from any network interface
    async with websockets.serve(handle_client, "0.0.0.0", server_port):
        print("Server ready! Press Ctrl+C to stop")
        await asyncio.Future()  # Run forever

try:
    asyncio.run(main())
except KeyboardInterrupt:
    print("Server stopped")
except OSError as e:
    if e.errno == 10048:
        print(f"ERROR: Port {server_port} already in use")
    else:
        print(f"ERROR: {e}")