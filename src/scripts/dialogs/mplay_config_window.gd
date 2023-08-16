extends Window


func _ready() -> void:
	SignalManager.open_multiplayer_menu.connect(popup)
	$MarginContainer/VBoxContainer/Step1.show()
	$MarginContainer/VBoxContainer/Step2.hide()
	%CreateServer.pressed.connect(_create_server_button)
	%CreateClient.pressed.connect(_create_client_button)

func _create_server_button():
	MultiplayerManager.create_server()
	$MarginContainer/VBoxContainer/Step1.hide()
	$MarginContainer/VBoxContainer/Step2.show()
	$MarginContainer/VBoxContainer/Step2/Server.show()
	$MarginContainer/VBoxContainer/Step2/Client.hide()

func _create_client_button():
	var p_id: int = int(%ClientId.text)
	if p_id != 0:
		MultiplayerManager.create_client(p_id)
		$MarginContainer/VBoxContainer/Step1.hide()
		$MarginContainer/VBoxContainer/Step2.show()
		$MarginContainer/VBoxContainer/Step2/Client.show()
		$MarginContainer/VBoxContainer/Step2/Server.hide()
		$MarginContainer/VBoxContainer/Step2/Client/C_ID.text = str(p_id)
	

func _on_add_peer_button_pressed() -> void:
	get_node("../ServerAddPeer").popup()


func _on_connect_server_button_pressed() -> void:
	get_node("../ClientConnect").popup()
