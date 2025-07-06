extends Node

# Server configuration
var server_url = "ws://localhost:8765"

# Current player type
var current_player = ""

# Scene reference
var current_scene = null

func _ready():
	# Nothing to do here
	pass

# Helper function to go back to main menu
func go_to_main_menu():
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
