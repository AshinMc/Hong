extends Node2D

# Configuration
var player_type = "player2"

# TCP client
var tcp = StreamPeerTCP.new()
var _connected = false
var _buffer = ""

# UI references
onready var character = $Character
onready var status_label = $CanvasLayer/UI/StatusLabel
onready var player1_status = $CanvasLayer/UI/Player1Status

# Character state
var character_position = Vector2(400, 300)
var current_animation = "idle"
var input_cooldown = 0.5  # seconds between action inputs
var can_send_input = true

# Player 1 connection status
var player1_connected = false
var gui_visible = true

func _ready():
	OS.set_window_title("Player 2 - Actions")
	character.position = character_position
	
	# Connect UI signals
	$CanvasLayer/UI/SendButton.connect("pressed", self, "_on_send_pressed")
	$CanvasLayer/UI/BackButton.connect("pressed", self, "_on_back_button_pressed")
	$CanvasLayer/UI/ChatInput.connect("text_entered", self, "_on_text_entered")
	
	# Set initial player1 status
	player1_status.text = "Player 1 has not connected"
	player1_status.add_color_override("font_color", Color(1, 0.5, 0.5))
	
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
		player1_connected = false
		status_label.text = "Disconnected"
		player1_status.text = "Player 1 has not connected"
		player1_status.add_color_override("font_color", Color(1, 0.5, 0.5))
	
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
	
	# Handle action input
	if _connected and can_send_input and player1_connected and not $CanvasLayer/UI/ChatInput.has_focus():
		if Input.is_action_just_pressed("action_punch"):
			send_action("punch")
			_start_input_cooldown()
			status_label.text = "Action: PUNCH"
		elif Input.is_action_just_pressed("action_kick"):
			send_action("kick")
			_start_input_cooldown()
			status_label.text = "Action: KICK"
		elif Input.is_action_just_pressed("action_fireball"):
			send_action("fireball")
			_start_input_cooldown()
			status_label.text = "Action: FIREBALL"
		elif Input.is_action_just_pressed("action_block"):
			send_action("block")
			_start_input_cooldown()
			status_label.text = "Action: BLOCK"

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
		if data.event == "client_connected" and data.client == "player1":
			player1_connected = true
			player1_status.text = "Player 1 is connected!"
			player1_status.add_color_override("font_color", Color(0.5, 1, 0.5))
		elif data.event == "client_disconnected" and data.client == "player1":
			player1_connected = false
			player1_status.text = "Player 1 disconnected"
			player1_status.add_color_override("font_color", Color(1, 0.5, 0.5))
	
	# Handle position data from Player 1
	if data.has("sender") and data.sender == "player1" and data.has("position"):
		# Extract position
		var new_pos_x = data.position.x
		var new_pos_y = data.position.y
		
		# Update our character
		character_position = Vector2(new_pos_x, new_pos_y)
		character.position = character_position
		
		# Status update for debugging
		status_label.text = "Pos: " + str(int(new_pos_x)) + "," + str(int(new_pos_y))
		
		# Update animation based on movement
		if data.has("action") and data.action.begins_with("move_"):
			play_animation("walk")
			
			# Update character flip based on movement direction
			if data.action == "move_left":
				if character.has_node("AnimatedSprite"):
					character.get_node("AnimatedSprite").flip_h = true
			elif data.action == "move_right":
				if character.has_node("AnimatedSprite"):
					character.get_node("AnimatedSprite").flip_h = false
		elif current_animation == "walk":
			play_animation("idle")
	
	# Handle own action animations
	if data.has("action") and data.sender == "player2":
		play_animation(data.action)
		yield(get_tree().create_timer(0.5), "timeout")
		if current_animation == data.action:
			play_animation("idle")
	
	# Handle chat messages
	if data.has("message_type") and data.message_type == "chat":
		var sender = "Player 1" if data.sender == "player1" else "Player 2"
		$CanvasLayer/UI/ChatDisplay.text += "\n" + sender + ": " + data.content
		$CanvasLayer/UI/ChatDisplay.scroll_to_line($CanvasLayer/UI/ChatDisplay.get_line_count())

func _start_input_cooldown():
	can_send_input = false
	yield(get_tree().create_timer(input_cooldown), "timeout")
	can_send_input = true
	status_label.text = "Connected as player2"

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
	$CanvasLayer/UI/ChatDisplay.text += "\n" + "Player 2: " + $CanvasLayer/UI/ChatInput.text
	$CanvasLayer/UI/ChatDisplay.scroll_to_line($CanvasLayer/UI/ChatDisplay.get_line_count())
	
	# Clear input
	$CanvasLayer/UI/ChatInput.text = ""

func send_action(action):
	if not _connected or not player1_connected:
		return
		
	send_message({
		"action": action,
		"timestamp": OS.get_unix_time()
	})
	
	# Also play animation locally
	play_animation(action)
	
	# Return to idle after animation
	yield(get_tree().create_timer(0.5), "timeout")
	if current_animation == action:
		play_animation("idle")

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
