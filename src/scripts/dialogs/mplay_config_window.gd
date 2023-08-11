extends Window

func _ready() -> void:
	SignalManager.open_multiplayer_menu.connect(open_window)

func open_window() -> void:
	print("opening window")
	popup()

func _on_create_server_pressed() -> void:
	var port: String = $Container/VBoxContainer/HBoxContainer2/Port.text
	if MultiplayerManager.create_server(int(port)):
		hide()
		get_tree().reload_current_scene()

func _on_create_client_pressed() -> void:
	var port: String = $Container/VBoxContainer/HBoxContainer/Port.text
	var ip: String = $Container/VBoxContainer/HBoxContainer/IPAddress.text

	if MultiplayerManager.create_client(int(port), ip):
		hide()
		get_tree().reload_current_scene()


func _on_close_requested() -> void:
	hide()
