extends Node2D

# Configuration
export var server_url = "ws://localhost:8765"
var player_type = "player2"  # Action controller

# WebSocket client
var _client = WebSocketClient.new()
var _connected = false
var _reconnecting = false

# UI references
onready var character = $Character
onready var status_label = $CanvasLayer/UI/StatusLabel
onready var player1_status = $CanvasLayer/UI/Player1Status
onready var controls_info = $CanvasLayer/UI/ControlsInfo
onready var chat_display = $CanvasLayer/UI/ChatDisplay
onready var chat_input = $CanvasLayer/UI/ChatInput
onready var send_button = $CanvasLayer/UI/SendButton
onready var back_button = $CanvasLayer/UI/BackButton
onready var ui_container = $CanvasLayer/UI

# Character state
var character_position = Vector2(400, 300)
var current_animation = "idle"
var input_cooldown = 0.5  # seconds between action inputs
var can_send_input = true
var last_key_pressed = ""

# Position update and movement
var target_position = Vector2(400, 300)
var position_update_timer = 0
var last_received_position = Vector2.ZERO

# Player 1 connection status
var player1_connected = false
var gui_visible = true

func _ready():
	# Set window title
	OS.set_window_title("Player 2 - Action Controller")
	
	# Initialize character position
	character.position = character_position
	target_position = character_position
	
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
						 "SPACE - Punch\n" + \
						 "K - Kick\n" + \
						 "F - Fireball\n" + \
						 "B - Block\n" + \
						 "Enter - Send Chat\n" + \
						 "H - Toggle GUI\n" + \
						 "ESC - Back to Menu"
	
	# Set initial player1 status
	player1_status.text = "Player 1 has not connected"
	player1_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	
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
	
	# GUI toggle - only if not typing
	if Input.is_action_just_pressed("ui_toggle_gui") and not chat_input.has_focus():
		toggle_gui()
	
	# Focus chat input on enter if not already focused
	if Input.is_action_just_pressed("ui_accept") and not chat_input.has_focus():
		chat_input.grab_focus()
	
	# Escape to go back - only if not typing
	if Input.is_action_just_pressed("ui_cancel") and not chat_input.has_focus():
		_on_back_button_pressed()
	
	# Handle keyboard input for actions - ONLY if not typing
	if _connected and can_send_input and player1_connected and not chat_input.has_focus():
		# Check for action keys
		if Input.is_action_just_pressed("action_punch"):
			send_action("punch")
			_start_input_cooldown()
			_show_key_press_feedback("PUNCH")
		elif Input.is_action_just_pressed("action_kick"):
			send_action("kick")
			_start_input_cooldown()
			_show_key_press_feedback("KICK")
		elif Input.is_action_just_pressed("action_fireball"):
			send_action("fireball")
			_start_input_cooldown()
			_show_key_press_feedback("FIREBALL")
		elif Input.is_action_just_pressed("action_block"):
			send_action("block")
			_start_input_cooldown()
			_show_key_press_feedback("BLOCK")
	
	# Update character position directly to match received position
	character.position = character_position

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
	player1_status.visible = true

func _show_key_press_feedback(action_name):
	# Update status to show what key was pressed (optional)
	last_key_pressed = action_name
	status_label.text = "Connected as player2 - Action sent: " + action_name
	
	# Reset the status after a brief delay
	yield(get_tree().create_timer(1.5), "timeout")
	if last_key_pressed == action_name:  # Only reset if no new key was pressed
		status_label.text = "Connected as player2"

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
	player1_connected = false
	status_label.text = "Connection error, retrying..."
	player1_status.text = "Player 1 has not connected"
	player1_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	_schedule_reconnect()

func _on_connection_closed(_was_clean = false):
	_connected = false
	player1_connected = false
	status_label.text = "Disconnected from server"
	player1_status.text = "Player 1 has not connected"
	player1_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	_schedule_reconnect()

func _on_data_received():
	var data = JSON.parse(_client.get_peer(1).get_packet().get_string_from_utf8()).result
	
	if data.has("status"):
		if data.status == "connected":
			status_label.text = "Connected as " + data.client_type
	
	# Handle connection events
	if data.has("event"):
		if data.event == "client_connected" and data.client == "player1":
			player1_connected = true
			player1_status.text = "Player 1 is connected!"
			player1_status.add_color_override("font_color", Color(0.5, 1, 0.5)) # light green
		elif data.event == "client_disconnected" and data.client == "player1":
			player1_connected = false
			player1_status.text = "Player 1 disconnected"
			player1_status.add_color_override("font_color", Color(1, 0.5, 0.5)) # light red
	
	# Handle sync data from Player 1
	if data.has("sync") and data.sender == "player1":
		character_position.x = data.position.x
		character_position.y = data.position.y
		character.position = character_position
		play_animation(data.animation)
		last_received_position = character_position
	
	# Handle position updates from Player 1
	if data.has("position_update") and data.sender == "player1":
		# Update character position directly
		character_position.x = data.position.x
		character_position.y = data.position.y
		character.position = character_position
		last_received_position = character_position
		
		# Update animation based on received animation
		play_animation(data.animation)
		
		# Update character flip based on movement direction
		if character_position.x < last_received_position.x:
			if character.has_node("AnimatedSprite"):
				character.get_node("AnimatedSprite").flip_h = true
			elif character.has_node("Sprite"):
				character.get_node("Sprite").flip_h = true
		elif character_position.x > last_received_position.x:
			if character.has_node("AnimatedSprite"):
				character.get_node("AnimatedSprite").flip_h = false
			elif character.has_node("Sprite"):
				character.get_node("Sprite").flip_h = false
	
	# Handle movement messages from Player 1
	if data.has("action") and data.has("position") and data.sender == "player1":
		# Update character position
		character_position.x = data.position.x
		character_position.y = data.position.y
		character.position = character_position
		
		# Update animation based on movement
		if data.action.begins_with("move_"):
			play_animation("walk")
			
			# Update character flip based on movement direction
			if data.action == "move_left":
				if character.has_node("AnimatedSprite"):
					character.get_node("AnimatedSprite").flip_h = true
				elif character.has_node("Sprite"):
					character.get_node("Sprite").flip_h = true
			elif data.action == "move_right":
				if character.has_node("AnimatedSprite"):
					character.get_node("AnimatedSprite").flip_h = false
				elif character.has_node("Sprite"):
					character.get_node("Sprite").flip_h = false
		else:
			play_animation("idle")
	
	# Handle own action animations
	if data.has("action") and data.sender == "player2":
		play_animation(data.action)
		
		# Return to idle after animation
		yield(get_tree().create_timer(0.5), "timeout")
		if current_animation == data.action:  # Only if no other animation started
			play_animation("idle")
	
	# Handle chat messages
	if data.has("message_type") and data.message_type == "chat":
		var sender = "Player 1" if data.sender == "player1" else "Player 2"
		chat_display.text += "\n" + sender + ": " + data.content
		# Scroll to bottom
		chat_display.scroll_to_line(chat_display.get_line_count())

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
	chat_display.text += "\n" + "Player 2: " + chat_input.text
	# Scroll to bottom
	chat_display.scroll_to_line(chat_display.get_line_count())
	
	# Clear input
	chat_input.text = ""

func send_action(action):
	if not _connected or not player1_connected:
		return
		
	var msg = {
		"action": action,
		"timestamp": OS.get_unix_time()
	}
	
	_client.get_peer(1).put_packet(JSON.print(msg).to_utf8())
	
	# Also play animation locally
	play_animation(action)
	
	# Return to idle after animation
	yield(get_tree().create_timer(0.5), "timeout")
	if current_animation == action:  # Only if no other animation started
		play_animation("idle")

func _on_back_button_pressed():
	# Disconnect from server
	if _connected:
		_client.disconnect_from_host()
	
	# Go back to main menu
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
