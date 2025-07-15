extends Node2D

onready var server_status_label = $CanvasLayer/Control/ServerStatusLabel
onready var discovery_button = $CanvasLayer/Control/DiscoverButton

func _ready():
	# Make sure the game looks nice
	OS.set_window_title("Hong")

	# Center the buttons
	$CanvasLayer/Control/TitleLabel.rect_position.x = (get_viewport_rect().size.x - $CanvasLayer/Control/TitleLabel.rect_size.x) / 2
	$CanvasLayer/Control/Player1Button.rect_position.x = (get_viewport_rect().size.x - $CanvasLayer/Control/Player1Button.rect_size.x) / 2
	$CanvasLayer/Control/Player2Button.rect_position.x = (get_viewport_rect().size.x - $CanvasLayer/Control/Player2Button.rect_size.x) / 2
	$CanvasLayer/Control/InstructionsLabel.rect_position.x = (get_viewport_rect().size.x - $CanvasLayer/Control/InstructionsLabel.rect_size.x) / 2
	
	# Connect button signals
	$CanvasLayer/Control/Player1Button.connect("pressed", self, "_on_player1_button_pressed")
	$CanvasLayer/Control/Player2Button.connect("pressed", self, "_on_player2_button_pressed")
	discovery_button.connect("pressed", self, "_on_discover_button_pressed")
	
	# Connect to NetworkConfig signals
	NetworkConfig.connect("server_status_changed", self, "_on_server_status_changed")
	
	# Update server status
	_update_server_status()

func _on_player1_button_pressed():
	# Switch to Player 1 scene
	get_tree().change_scene("res://Scenes/Player1.tscn")

func _on_player2_button_pressed():
	# Switch to Player 2 scene
	get_tree().change_scene("res://Scenes/Player2.tscn")

func _on_discover_button_pressed():
	server_status_label.text = "Discovering server..."
	server_status_label.add_color_override("font_color", Color(1, 0.8, 0))  # Yellow
	discovery_button.disabled = true
	NetworkConfig.discover_server()

func _on_server_status_changed(connected):
	_update_server_status()
	discovery_button.disabled = false

func _update_server_status():
	# Show server URL in the status
	if NetworkConfig.discovery_in_progress:
		server_status_label.text = "Discovering server..."
		server_status_label.add_color_override("font_color", Color(1, 0.8, 0))  # Yellow
	else:
		server_status_label.text = "Server: " + NetworkConfig.server_url
		
		# Try to determine if server is local or remote
		var is_local = NetworkConfig.server_url.find("localhost") >= 0 or NetworkConfig.server_url.find("127.0.0.1") >= 0
		
		if is_local:
			server_status_label.add_color_override("font_color", Color(1, 0.5, 0.5))  # Red - Local only
		else:
			server_status_label.add_color_override("font_color", Color(0.5, 1, 0.5))  # Green - Network
