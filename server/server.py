import socket
import json
import select
import time

class KongGame:
    def __init__(self):
        self.player1 = None
        self.player2 = None
        self.running = True
        self.client_types = {}  # Maps socket to player type

    def start_server(self, host="localhost", port=8765):
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((host, port))
        server.listen(2)  # Listen for 2 players
        print(f"Server running on {host}:{port}")
        
        # List of sockets to monitor
        sockets_list = [server]
        
        while self.running:
            # Use select to wait for any socket to be ready
            readable, _, _ = select.select(sockets_list, [], [], 0.1)
            
            for sock in readable:
                # New connection
                if sock == server:
                    client, addr = server.accept()
                    print(f"New connection from {addr}")
                    time.sleep(0.1) # delay for idk
                    sockets_list.append(client)
                # Existing connection has data
                else:
                    self.process_client_message(sock, sockets_list)
        
        server.close()

    def process_client_message(self, client, sockets_list):
        try:
            # Receive data
            data = client.recv(4096)
            
            # If no data, client disconnected
            if not data:
                self.handle_disconnect(client, sockets_list)
                return
            
            # Process the message
            message = json.loads(data.decode('utf-8'))
            
            # First message - client identification
            if "client_type" in message and client not in self.client_types:
                client_type = message["client_type"]
                
                # Store client connection based on type
                if client_type == "player1" and not self.player1:
                    self.player1 = client
                    self.client_types[client] = "player1"
                    print("Player 1 connected")
                    # Send confirmation
                    response = {"status": "connected", "client_type": "player1"}
                    client.send((json.dumps(response) + "\n").encode('utf-8'))
                    
                    # Notify player2 if connected
                    if self.player2:
                        notify = {"event": "client_connected", "client": "player1"}
                        self.player2.send((json.dumps(response) + "\n").encode('utf-8'))
                        
                elif client_type == "player2" and not self.player2:
                    self.player2 = client
                    self.client_types[client] = "player2"
                    print("Player 2 connected")
                    # Send confirmation
                    response = {"status": "connected", "client_type": "player2"}
                    client.send((json.dumps(response) + "\n").encode('utf-8'))
                    
                    # Notify player1 if connected
                    if self.player1:
                        notify = {"event": "client_connected", "client": "player2"}
                        self.player1.send((json.dumps(response) + "\n").encode('utf-8'))
                        
                else:
                    # Player slot already taken
                    error_msg = {"error": "Player slot already taken"}
                    client.send((json.dumps(response) + "\n").encode('utf-8'))
                    client.close()
                    sockets_list.remove(client)
                    return
            
            # Forward message to other player
            elif client in self.client_types:
                client_type = self.client_types[client]
                message["sender"] = client_type
                
                 # Debug position messages
                if "position" in message:
                    print(f"Forwarding position from {client_type}: {message['position']}")
           
                # In process_client_message, modify how you send messages:
                if client_type == "player1" and self.player2:
                    # Add a newline as message delimiter
                    json_str = json.dumps(message) + "\n"
                    self.player2.send(json_str.encode('utf-8'))
                elif client_type == "player2" and self.player1:
                    # Add a newline as message delimiter
                    json_str = json.dumps(message) + "\n"
                    self.player1.send(json_str.encode('utf-8'))
                    
        except Exception as e:
            print(f"Error: {e}")
            self.handle_disconnect(client, sockets_list)

    def handle_disconnect(self, client, sockets_list):
        # Remove from socket list
        if client in sockets_list:
            sockets_list.remove(client)
        
        # Get client type before removing from dictionary
        client_type = self.client_types.get(client)
        
        # Handle disconnection
        if client == self.player1:
            self.player1 = None
            print("Player 1 disconnected")
            if self.player2:
                notify = {"event": "client_disconnected", "client": "player1"}
                try:
                    self.player2.send(json.dumps(notify).encode('utf-8'))
                except:
                    pass
        elif client == self.player2:
            self.player2 = None
            print("Player 2 disconnected")
            if self.player1:
                notify = {"event": "client_disconnected", "client": "player2"}
                try:
                    self.player1.send(json.dumps(notify).encode('utf-8'))
                except:
                    pass
        
        # Remove from client types dictionary
        if client in self.client_types:
            del self.client_types[client]
            
        try:
            client.close()
        except:
            pass

# Start the server
game = KongGame()
game.start_server()