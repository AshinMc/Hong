extends Node

var server_url = "ws://localhost:8765"  # Default fallback
var server_discovery = null
var discovery_in_progress = false

signal server_status_changed(connected)

func _ready():
	# Create the server discovery object
	server_discovery = preload("res://Scripts/ServerDiscovery.gd").new()
	add_child(server_discovery)
	server_discovery.connect("server_found", self, "_on_server_found")
	server_discovery.connect("discovery_timeout", self, "_on_discovery_timeout")
	
	# Start with trying to discover server
	discover_server()

func discover_server():
	if discovery_in_progress:
		return
		
	discovery_in_progress = true
	print("Starting server discovery...")
	
	# Try to discover server
	server_discovery.discover_server(5.0)  # 5-second timeout

func _on_server_found(url):
	discovery_in_progress = false
	server_url = url
	print("Auto-discovered server at: " + server_url)
	emit_signal("server_status_changed", true)

func _on_discovery_timeout():
	discovery_in_progress = false
	print("Server auto-discovery failed, falling back to config file")
	
	# Try to load from config file as fallback
	_load_from_config()
	
	# Signal that we might not have a valid server
	emit_signal("server_status_changed", false)

func _load_from_config():
	# Try to load server URL from config file
	var config_file = File.new()
	var found_config = false
	
	# First check external config (near executable)
	if OS.has_feature("standalone"):
		var external_path = OS.get_executable_path().get_base_dir() + "/server_config.txt"
		if config_file.file_exists(external_path):
			config_file.open(external_path, File.READ)
			var content = config_file.get_as_text().strip_edges()
			config_file.close()
			
			if content.begins_with("ws://"):
				server_url = content
				print("Loaded server URL from external config: " + server_url)
				found_config = true
	
	# Then check internal config
	if !found_config and config_file.file_exists("res://server_config.txt"):
		config_file.open("res://server_config.txt", File.READ)
		var content = config_file.get_as_text().strip_edges()
		config_file.close()
		
		if content.begins_with("ws://"):
			server_url = content
			print("Loaded server URL from internal config: " + server_url)
			found_config = true
	
	if !found_config:
		print("No config file found, using default: " + server_url)
