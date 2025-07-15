extends Node2D

# Configuration
var server_url = "ws://localhost:8765"  # Will be updated from NetworkConfig
var player_type = "player1"  # Movement controller

# WebSocket client
var _client = WebSocketClient.new()
var _connected = false
var _reconnecting = false

# UI references
onready var character = $Character
onready var status_label = $CanvasLayer/UI/StatusLabel
onready var player2_status = $CanvasLayer/UI/Player2Status
onready var controls_info = $CanvasLayer/UI/ControlsInfo
onready var chat_display = $CanvasLayer/UI/ChatDisplay
onready var chat_input = $CanvasLayer/UI/ChatInput
onready var send_button = $CanvasLayer/UI/SendButton
onready var back_button = $CanvasLayer/UI/BackButton
onready var ui_container = $CanvasLayer/UI

# Character state
var character_position = Vector2(400, 300)
var move_speed = 200
var direction = Vector2.ZERO
var last_movement = ""
var current_animation = "idle"
var input_cooldown = 0.1  # seconds between movement inputs
var can_send_input = true

# Position update and smoothing
var last_sent_position = Vector2.ZERO
var position_update_timer = 0
var position_update_interval = 0.05  # Send 20 position updates per second


# Player 2 connection status
var player2_connected = false
var gui_visible = true

func _ready():
	# Set window title
	OS.set_window_title("Player 1 - Movement Controller")
	if has_node("/root/NetworkConfig"):
		server_url = get_node("/root/NetworkConfig").server_url
		print("Using server URL from NetworkConfig: " + server_url)
	# Initialize character position
	
	
	
	# Connect WebSocket signals
	_client.connect("connection_established", self, "_on_connection_established")
	_client.connect("connection_error", self, "_on_connection_error")
	_client.connect("connection_closed", self, "_on_connection_closed")
	_client.connect("data_received", self, "_on_data_received")
	
	# Connect UI signals
	send_button.connect("pressed", self, "_on_send_pressed")
	chat_input.connect("text_entered", self, "_on_text_entered")
	back_button.connect("pressed", self, "_on_back_button_pressed")
	
	# Connect chat focus signals
	chat_input.connect("focus_entered", self, "_on_chat_focus_entered")
	chat_input.connect("focus_exited", self, "_on_chat_focus_exited")
	
	# Connect reconnect timer
	$ReconnectTimer.connect("timeout", self, "_on_reconnect_timer_timeout")
	
	# Set controls info
	controls_info.text = "CONTROLS:\n" + \
						 "Arrow Keys or WASD - Movement\n" + \
						 "Enter - Send Chat\n" + \
						 "H - Toggle GUI\n" + \
						 "ESC - Back to Menu"
	
	# Set initial player2 status
	player2_status.text = "Player 2 has not connected"
	player2_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	
	# Connect to server
	connect_to_server()
	
	# Start in idle animation
	play_animation("idle")

func connect_to_server():
	status_label.text = "Connecting to server..."
	var err = _client.connect_to_url(server_url)
	if err != OK:
		status_label.text = "Error connecting to server"
		_schedule_reconnect()

func _schedule_reconnect():
	if _reconnecting:
		return
	_reconnecting = true
	$ReconnectTimer.wait_time = 3.0
	$ReconnectTimer.one_shot = true
	$ReconnectTimer.start()

func _on_reconnect_timer_timeout():
	_reconnecting = false
	connect_to_server()

func _process(delta):
	# Keep the WebSocket connection alive
	_client.poll()
	
	# GUI toggle
	if Input.is_action_just_pressed("ui_toggle_gui") and not chat_input.has_focus():
		toggle_gui()
	
	# Focus chat input on enter if not already focused
	if Input.is_action_just_pressed("ui_accept") and not chat_input.has_focus():
		chat_input.grab_focus()
	
	# Escape to go back
	if Input.is_action_just_pressed("ui_cancel") and not chat_input.has_focus():
		_on_back_button_pressed()
	
	# Handle keyboard input for movement - ONLY if chat input is not focused
	if _connected and can_send_input and not chat_input.has_focus():
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
			elif character.has_node("Sprite"):
				character.get_node("Sprite").flip_h = true
		elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
			direction.x = 1
			send_movement("move_right")
			_start_input_cooldown()
			if character.has_node("AnimatedSprite"):
				character.get_node("AnimatedSprite").flip_h = false
			elif character.has_node("Sprite"):
				character.get_node("Sprite").flip_h = false
	
	# Update character position DIRECTLY (no smoothing for now)
	if direction != Vector2.ZERO:
		character_position += direction * move_speed * delta
		character.position = character_position
		
		if current_animation != "walk":
			play_animation("walk")
	elif current_animation == "walk":
		play_animation("idle")
	
	# Send position updates regularly while moving or after stopping
	position_update_timer += delta
	if position_update_timer >= position_update_interval:
		position_update_timer = 0
		
		# Send update if position has changed
		if direction != Vector2.ZERO:
			send_position_update()
			last_sent_position = character_position
	
func _input(event):
	# Allow escape key to exit chat even when focused
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE and chat_input.has_focus():
		chat_input.release_focus()
		# Prevent the event from also triggering menu
		get_tree().set_input_as_handled()

func _on_chat_focus_entered():
	# Visual indication that typing is active
	chat_input.modulate = Color(1.2, 1.2, 0.8) # Slight yellow highlight
	status_label.text = "Typing..."

func _on_chat_focus_exited():
	# Restore normal appearance
	chat_input.modulate = Color(1, 1, 1)
	if _connected:
		status_label.text = "Connected as " + player_type
	else:
		status_label.text = "Connecting to server..."

func toggle_gui():
	gui_visible = !gui_visible
	
	# Toggle visibility for all UI elements except player status indicators
	controls_info.visible = gui_visible
	chat_display.visible = gui_visible
	chat_input.visible = gui_visible
	send_button.visible = gui_visible
	back_button.visible = gui_visible
	
	# Always keep status labels visible for important info
	status_label.visible = true
	player2_status.visible = true

func _start_input_cooldown():
	can_send_input = false
	yield(get_tree().create_timer(input_cooldown), "timeout")
	can_send_input = true

func _on_connection_established(_protocol):
	_connected = true
	status_label.text = "Connected to server"
	
	# Send identification message
	var msg = {
		"client_type": player_type
	}
	_client.get_peer(1).put_packet(JSON.print(msg).to_utf8())

func _on_connection_error():
	_connected = false
	player2_connected = false
	status_label.text = "Connection error, retrying..."
	player2_status.text = "Player 2 has not connected"
	player2_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	_schedule_reconnect()

func _on_connection_closed(_was_clean = false):
	_connected = false
	player2_connected = false
	status_label.text = "Disconnected from server"
	player2_status.text = "Player 2 has not connected"
	player2_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	_schedule_reconnect()

func _on_data_received():
	var data = JSON.parse(_client.get_peer(1).get_packet().get_string_from_utf8()).result
	
	if data.has("status"):
		if data.status == "connected":
			status_label.text = "Connected as " + data.client_type
	
	# Handle connection events
	if data.has("event"):
		if data.event == "client_connected" and data.client == "player2":
			player2_connected = true
			player2_status.text = "Player 2 is connected!"
			player2_status.add_color_override("font_color", Color(0.5, 1, 0.5)) # light green
			# Send initial state to sync player 2
			send_sync_data()
		elif data.event == "client_disconnected" and data.client == "player2":
			player2_connected = false
			player2_status.text = "Player 2 disconnected"
			player2_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	
	# Handle chat messages
	if data.has("message_type") and data.message_type == "chat":
		var sender = "Player 1" if data.sender == "player1" else "Player 2"
		chat_display.text += "\n" + sender + ": " + data.content
		# Scroll to bottom
		chat_display.scroll_to_line(chat_display.get_line_count())
	
	# Handle action messages from Player 2
	if data.has("action") and data.sender == "player2":
		handle_action(data.action)

func handle_action(action):
	# Play the corresponding animation
	play_animation(action)
	
	# After animation finishes, return to idle
	yield(get_tree().create_timer(0.5), "timeout")
	if current_animation == action:  # Only change if no other animation started
		play_animation("idle")

func play_animation(anim_name):
	current_animation = anim_name
	
	# Try AnimatedSprite first (preferred method)
	if character.has_node("AnimatedSprite"):
		var animated_sprite = character.get_node("AnimatedSprite")
		if animated_sprite.frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
		else:
			print("Animation not found in AnimatedSprite: ", anim_name)
	
	# Fall back to AnimationPlayer if no AnimatedSprite
	elif character.has_node("AnimationPlayer"):
		var anim_player = character.get_node("AnimationPlayer")
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		else:
			print("Animation not found in AnimationPlayer: ", anim_name)
	else:
		print("No animation node found")

func _on_text_entered(text):
	if text.strip_edges() != "":
		_send_chat_message()
		chat_input.release_focus()

func _on_send_pressed():
	_send_chat_message()
	chat_input.release_focus()

func _send_chat_message():
	if not _connected or chat_input.text.strip_edges() == "":
		return
		
	var msg = {
		"message_type": "chat",
		"content": chat_input.text,
		"timestamp": OS.get_unix_time()
	}
	
	_client.get_peer(1).put_packet(JSON.print(msg).to_utf8())
	
	# Add message to our own chat
	chat_display.text += "\n" + "Player 1: " + chat_input.text
	# Scroll to bottom
	chat_display.scroll_to_line(chat_display.get_line_count())
	
	# Clear input
	chat_input.text = ""

func send_movement(action):
	if not _connected:
		return
		
	# Only send if it's a new direction or after a pause
	if action != last_movement:
		var msg = {
			"action": action,
			"position": {"x": character_position.x, "y": character_position.y},
			"timestamp": OS.get_unix_time()
		}
		
		_client.get_peer(1).put_packet(JSON.print(msg).to_utf8())
		last_movement = action

# New function to send position updates without requiring movement key
func send_position_update():
	if not _connected:
		return
	
	var msg = {
		"position_update": true,
		"position": {"x": character_position.x, "y": character_position.y},
		"animation": current_animation,
		"timestamp": OS.get_unix_time()
	}
	
	_client.get_peer(1).put_packet(JSON.print(msg).to_utf8())

func send_sync_data():
	# Send current character state to player 2
	if _connected and player2_connected:
		var msg = {
			"sync": true,
			"position": {"x": character_position.x, "y": character_position.y},
			"animation": current_animation,
			"timestamp": OS.get_unix_time()
		}
		
		_client.get_peer(1).put_packet(JSON.print(msg).to_utf8())

func _on_back_button_pressed():
	# Disconnect from server
	if _connected:
		_client.disconnect_from_host()
	
	# Go back to main menu
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
