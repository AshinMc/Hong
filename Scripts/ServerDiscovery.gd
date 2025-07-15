extends Node

signal server_found(url)
signal discovery_timeout

var discovery_port = 8766
var discovery_socket = null
var discovery_running = false
var discovery_timer = null

# Try to discover server automatically
func discover_server(timeout_seconds = 10.0):
	print("Starting server auto-discovery...")
	
	# Create UDP socket for listening to broadcasts
	discovery_socket = PacketPeerUDP.new()
	var err = discovery_socket.listen(discovery_port)
	
	if err != OK:
		push_error("Failed to listen on discovery port: " + str(err))
		emit_signal("discovery_timeout")
		return
	
	discovery_running = true
	
	# Create timeout timer
	discovery_timer = Timer.new()
	add_child(discovery_timer)
	discovery_timer.wait_time = timeout_seconds
	discovery_timer.one_shot = true
	discovery_timer.connect("timeout", self, "_on_discovery_timeout")
	discovery_timer.start()
	
	# Send discovery request to broadcast
	var request = JSON.print({
		"type": "hong_discovery_request"
	}).to_utf8()
	discovery_socket.set_broadcast_enabled(true)
	discovery_socket.set_dest_address("255.255.255.255", discovery_port)
	discovery_socket.put_packet(request)
	
	# Start listening
	set_process(true)
	print("Listening for server broadcasts...")
	
	# Also try direct search on common IPs
	_try_direct_discovery()

func _process(delta):
	if not discovery_running:
		return
	
	# Check for incoming discovery packets
	if discovery_socket.get_available_packet_count() > 0:
		var data = discovery_socket.get_packet()
		var sender_ip = discovery_socket.get_packet_ip()
		var text = data.get_string_from_utf8()
		
		print("Received broadcast from " + sender_ip + ": " + text)
		
		# Try to parse as JSON
		var json_result = JSON.parse(text)
		if json_result.error == OK:
			var packet = json_result.result
			
			# Check if it's our server
			if packet.has("type") and packet.type == "hong_server":
				var server_url = "ws://" + packet.ip + ":" + str(packet.port)
				print("Found server at: " + server_url)
				
				# Stop discovery
				_stop_discovery()
				
				# Emit signal with the server URL
				emit_signal("server_found", server_url)

func _try_direct_discovery():
	# This function tries to directly contact potential servers
	# by sending discovery requests to common IP patterns
	
	# Try to guess the network range based on local IP
	var local_ip = IP.get_local_addresses()
	for ip in local_ip:
		# Skip non-IPv4 addresses
		if not ip.is_valid_ip_address() or ip == "127.0.0.1":
			continue
			
		# Try to determine network pattern
		var parts = ip.split(".")
		if parts.size() == 4:
			var base_ip = parts[0] + "." + parts[1] + "." + parts[2] + "."
			
			# Scan some common IPs in this subnet
			for i in range(1, 20):  # Limit to first 20 IPs to avoid flooding
				var target_ip = base_ip + str(i)
				print("Trying direct discovery to: " + target_ip)
				
				# Send discovery request
				var request = JSON.print({
					"type": "hong_discovery_request"
				}).to_utf8()
				discovery_socket.set_dest_address(target_ip, discovery_port)
				discovery_socket.put_packet(request)
				
				# Yield to allow responses to come in
				yield(get_tree().create_timer(0.1), "timeout")
				
				# Check if we've found a server already
				if not discovery_running:
					return

func _on_discovery_timeout():
	print("Server discovery timed out")
	_stop_discovery()
	emit_signal("discovery_timeout")

func _stop_discovery():
	if discovery_running:
		discovery_running = false
		set_process(false)
		
		if discovery_socket:
			discovery_socket.close()
			discovery_socket = null
		
		if discovery_timer:
			discovery_timer.stop()
			discovery_timer.queue_free()
			discovery_timer = null

func _exit_tree():
	_stop_discovery()
