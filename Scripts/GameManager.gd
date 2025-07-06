extends Node

# Server configuration
var server_url = "ws://localhost:8765"

# Current player type
var current_player = ""

func _ready():
	# Add input map entries
	_setup_input_maps()

# Helper function to go back to main menu
func go_to_main_menu():
	get_tree().change_scene("res://Scenes/MainMenu.tscn")

# Setup additional input maps
func _setup_input_maps():
	# Movement keys (alternative to arrow keys)
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
		var event = InputEventKey.new()
		event.scancode = KEY_W
		InputMap.action_add_event("move_up", event)
	
	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
		var event = InputEventKey.new()
		event.scancode = KEY_S
		InputMap.action_add_event("move_down", event)
	
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		var event = InputEventKey.new()
		event.scancode = KEY_A
		InputMap.action_add_event("move_left", event)
	
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		var event = InputEventKey.new()
		event.scancode = KEY_D
		InputMap.action_add_event("move_right", event)
	
	# Action keys
	if not InputMap.has_action("action_punch"):
		InputMap.add_action("action_punch")
		var event = InputEventKey.new()
		event.scancode = KEY_SPACE
		InputMap.action_add_event("action_punch", event)
	
	if not InputMap.has_action("action_kick"):
		InputMap.add_action("action_kick")
		var event = InputEventKey.new()
		event.scancode = KEY_K
		InputMap.action_add_event("action_kick", event)
	
	if not InputMap.has_action("action_fireball"):
		InputMap.add_action("action_fireball")
		var event = InputEventKey.new()
		event.scancode = KEY_F
		InputMap.action_add_event("action_fireball", event)
	
	if not InputMap.has_action("action_block"):
		InputMap.add_action("action_block")
		var event = InputEventKey.new()
		event.scancode = KEY_B
		InputMap.action_add_event("action_block", event)
	
	# UI toggle with H key
	if not InputMap.has_action("ui_toggle_gui"):
		InputMap.add_action("ui_toggle_gui")
		var event = InputEventKey.new()
		event.scancode = KEY_H
		InputMap.action_add_event("ui_toggle_gui", event)
