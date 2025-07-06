extends Node2D

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

func _on_player1_button_pressed():
	# Switch to Player 1 scene
	get_tree().change_scene("res://Scenes/Player1.tscn")

func _on_player2_button_pressed():
	# Switch to Player 2 scene
	get_tree().change_scene("res://Scenes/Player2.tscn")
