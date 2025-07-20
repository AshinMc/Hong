import socket
import time

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print("Trying to connect to localhost:8765...")
try:
    s.connect(('localhost', 8765))
    print("Connection successful!")
    time.sleep(1)
    s.send(b'{"client_type": "test_client"}')
    print("Sent test message")
    data = s.recv(1024)
    print(f"Received: {data.decode('utf-8')}")
    s.close()
except Exception as e:
    print(f"Connection failed: {e}")