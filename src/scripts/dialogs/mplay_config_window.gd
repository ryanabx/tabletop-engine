extends Window

func _on_close_requested() -> void:
	hide()

func _ready() -> void:
	SignalManager.open_multiplayer_menu.connect(popup)
	%CreateServer.pressed.connect(_create_server_button)
	%CreateClient.pressed.connect(_create_client_button)

func _create_server_button():
	MultiplayerManager.create_server()
	hide()
	get_node("../ServerAddPeer").popup()

func _create_client_button():
	var p_id: int = int(%ClientId.text)
	if p_id != 0:
		MultiplayerManager.create_client(p_id)
		hide()
		get_node("../ClientConnect").popup()