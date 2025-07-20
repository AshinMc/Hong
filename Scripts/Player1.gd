extends Node2D

# Configuration
var player_type = "player1"

# TCP client
var tcp = StreamPeerTCP.new()
var _connected = false
var _buffer = ""

# UI references
onready var character = $Character
onready var status_label = $CanvasLayer/UI/StatusLabel
onready var player2_status = $CanvasLayer/UI/Player2Status

# Character state
var character_position = Vector2(400, 300)
var move_speed = 200
var direction = Vector2.ZERO
var current_animation = "idle"
var input_cooldown = 0.2
var can_send_input = true

# Player 2 connection status
var player2_connected = false
var gui_visible = true

func _ready():
	OS.set_window_title("Player 1 - Movement")
	character.position = character_position
	
	# Connect UI signals
	$CanvasLayer/UI/SendButton.connect("pressed", self, "_on_send_pressed")
	$CanvasLayer/UI/BackButton.connect("pressed", self, "_on_back_button_pressed")
	$CanvasLayer/UI/ChatInput.connect("text_entered", self, "_on_text_entered")
	
	# Set initial player2 status
	player2_status.text = "Player 2 has not connected"
	player2_status.add_color_override("font_color", Color(1, 0.5, 0.5))
	
	# Connect to server
	connect_to_server()
	
	# Start in idle animation
	play_animation("idle")

func connect_to_server():
	status_label.text = "Connecting..."
	var server_host = GameManager.server_host
	var server_port = GameManager.server_port
	
	var err = tcp.connect_to_host(server_host, server_port)
	if err != OK:
		status_label.text = "Connection error"
		return
	
	# Wait for connection to complete
	yield(get_tree().create_timer(0.5), "timeout")
	
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_connected = true
		status_label.text = "Connected to server"
		
		# Send identification message
		send_message({"client_type": player_type})
	else:
		status_label.text = "Connection failed"

func _process(delta):
	# Check connection status
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		if not _connected:
			_connected = true
			status_label.text = "Connected to server"
	elif _connected:
		_connected = false
		player2_connected = false
		status_label.text = "Disconnected"
		player2_status.text = "Player 2 has not connected"
		player2_status.add_color_override("font_color", Color(1, 0.5, 0.5))
	
	# Read incoming data if connected
	if _connected:
		check_for_messages()
	
	# GUI toggle
	if Input.is_action_just_pressed("ui_toggle_gui"):
		gui_visible = !gui_visible
		$CanvasLayer/UI/ControlsInfo.visible = gui_visible
		$CanvasLayer/UI/ChatDisplay.visible = gui_visible
		$CanvasLayer/UI/ChatInput.visible = gui_visible
		$CanvasLayer/UI/SendButton.visible = gui_visible
	
	# Handle movement input
	if _connected and can_send_input and not $CanvasLayer/UI/ChatInput.has_focus():
		direction = Vector2.ZERO
		
		# Check for movement keys
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
			direction.y = -1
			send_movement("move_up")
			_start_input_cooldown()
		elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
			direction.y = 1
			send_movement("move_down")
			_start_input_cooldown()
		elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
			direction.x = -1
			send_movement("move_left")
			_start_input_cooldown()
			if character.has_node("AnimatedSprite"):
				character.get_node("AnimatedSprite").flip_h = true
		elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
			direction.x = 1
			send_movement("move_right")
			_start_input_cooldown()
			if character.has_node("AnimatedSprite"):
				character.get_node("AnimatedSprite").flip_h = false
	
	# Update character position
	if direction != Vector2.ZERO:
		character_position += direction * move_speed * delta
		character.position = character_position
		
		if current_animation != "walk":
			play_animation("walk")
	elif current_animation == "walk":
		play_animation("idle")

func check_for_messages():
	# Check if data is available
	if tcp.get_available_bytes() > 0:
		# Read available data
		var data = tcp.get_data(tcp.get_available_bytes())
		if data[0] == OK:
			_buffer += data[1].get_string_from_utf8()
			
			# IMPROVED JSON PARSING - find complete JSON objects by counting braces
			var start_pos = 0
			var brace_count = 0
			var in_string = false
			var escape_next = false
			
			for i in range(_buffer.length()):
				var c = _buffer[i]
				
				# Handle string literals and escaping
				if c == '"' and not escape_next:
					in_string = not in_string
				
				# Only count braces outside of strings
				if not in_string:
					if c == '{':
						if brace_count == 0:
							start_pos = i
						brace_count += 1
					elif c == '}':
						brace_count -= 1
						
						# Complete JSON object found
						if brace_count == 0:
							var json_str = _buffer.substr(start_pos, i - start_pos + 1)
							
							# Try to parse the JSON
							var parse_result = JSON.parse(json_str)
							if parse_result.error == OK:
								process_message(parse_result.result)
							else:
								print("JSON Parse Error: ", parse_result.error)
							
							# Remove processed part from buffer
							if i + 1 < _buffer.length():
								_buffer = _buffer.substr(i + 1)
								i = -1  # Reset loop (will become 0 on next iteration)
							else:
								_buffer = ""
								break
				
				# Handle escape sequences
				if c == '\\' and not escape_next:
					escape_next = true
				else:
					escape_next = false

func process_message(data):
	# Handle connection status
	if data.has("status") and data.status == "connected":
		status_label.text = "Connected as " + data.client_type
	
	# Handle connection events
	if data.has("event"):
		if data.event == "client_connected" and data.client == "player2":
			player2_connected = true
			player2_status.text = "Player 2 is connected!"
			player2_status.add_color_override("font_color", Color(0.5, 1, 0.5))
			
			# Send position to sync up
			send_message({
				"sync": true,
				"position": {"x": character_position.x, "y": character_position.y},
				"animation": current_animation,
				"timestamp": OS.get_unix_time()
			})
		elif data.event == "client_disconnected" and data.client == "player2":
			player2_connected = false
			player2_status.text = "Player 2 disconnected"
			player2_status.add_color_override("font_color", Color(1, 0.5, 0.5))
	
	# Handle chat messages
	if data.has("message_type") and data.message_type == "chat":
		var sender = "Player 1" if data.sender == "player1" else "Player 2"
		$CanvasLayer/UI/ChatDisplay.text += "\n" + sender + ": " + data.content
		# Scroll to bottom
		$CanvasLayer/UI/ChatDisplay.scroll_to_line($CanvasLayer/UI/ChatDisplay.get_line_count())
	
	# Handle action messages from Player 2
	if data.has("action") and data.sender == "player2":
		play_animation(data.action)
		yield(get_tree().create_timer(0.5), "timeout")
		if current_animation == data.action:
			play_animation("idle")

func _start_input_cooldown():
	can_send_input = false
	yield(get_tree().create_timer(input_cooldown), "timeout")
	can_send_input = true

func play_animation(anim_name):
	current_animation = anim_name
	
	if character.has_node("AnimatedSprite"):
		var sprite = character.get_node("AnimatedSprite")
		if sprite.frames.has_animation(anim_name):
			sprite.play(anim_name)
	elif character.has_node("AnimationPlayer"):
		var anim = character.get_node("AnimationPlayer")
		if anim.has_animation(anim_name):
			anim.play(anim_name)

func _on_text_entered(text):
	if text.strip_edges() != "":
		_send_chat_message()
		$CanvasLayer/UI/ChatInput.release_focus()

func _on_send_pressed():
	_send_chat_message()
	$CanvasLayer/UI/ChatInput.release_focus()

func _send_chat_message():
	if not _connected or $CanvasLayer/UI/ChatInput.text.strip_edges() == "":
		return
	
	send_message({
		"message_type": "chat",
		"content": $CanvasLayer/UI/ChatInput.text,
		"timestamp": OS.get_unix_time()
	})
	
	# Add message to our own chat
	$CanvasLayer/UI/ChatDisplay.text += "\n" + "Player 1: " + $CanvasLayer/UI/ChatInput.text
	$CanvasLayer/UI/ChatDisplay.scroll_to_line($CanvasLayer/UI/ChatDisplay.get_line_count())
	
	# Clear input
	$CanvasLayer/UI/ChatInput.text = ""

func send_movement(action):
	if not _connected:
		return
	
	# Add a special flag to ensure this is treated as a position update
	send_message({
		"action": action,
		"position": {"x": character_position.x, "y": character_position.y},
		"timestamp": OS.get_unix_time()
	})

func send_message(msg):
	if not _connected:
		return
	
	# Send the message as JSON
	var json_string = JSON.print(msg)
	tcp.put_data(json_string.to_utf8())

func _on_back_button_pressed():
	if _connected:
		tcp.disconnect_from_host()
	get_tree().change_scene("res://Scenes/MainMenu.tscn")

func _exit_tree():
	# Make sure we disconnect when the scene is unloaded
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		tcp.disconnect_from_host()
