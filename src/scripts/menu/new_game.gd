extends Control

@onready var config_list: ItemList = $SafeMargins/MarginContainer/VBoxContainer/ConfigList
@onready var ready_button: Button = $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer/Ready
@onready var delete_button: Button = $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer2/DeleteSelected
@onready var from_file_button: Button = $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer2/LoadConfFile

var peer_choice: int = 0 # Client

var current_mplay_page: String = "Options1"

var code: String = ""

func _ready() -> void:
	Globals.load_this_game = PackedByteArray([])
	SignalManager.config_added.connect(refresh_list)
	SignalManager.mplay_code_created.connect(code_created)
	SignalManager.mplay_offer_percentage.connect(code_percentage)
	SignalManager.mplay_connection_result.connect(connection_result)
	SignalManager.mplay_establishing_connection.connect(establishing_connection)
	if not Utils.is_desktop_platform():
		from_file_button.hide()
	Utils.MultiplayerManager.close_connection()
	refresh_list()

func _process(_delta: float) -> void:
	ready_button.disabled = not is_selecting_config() or not multiplayer.is_server()
	delete_button.disabled = not is_selecting_config() or is_selecting_default_config()

	if peer_choice == 1 and multiplayer.is_server():
		%ServerStatsLabel.text = str("[Server] # of peers: ",multiplayer.get_peers().size())

func mplay_next_page(next_mplay_page: String) -> void:
	get_node(str("%",current_mplay_page)).hide()
	get_node(str("%",next_mplay_page)).show()
	current_mplay_page = next_mplay_page

func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func refresh_list() -> void:
	if Utils.MultiplayerManager.wip_connection != null:
		print("Connecting state multiplayer peer: ",multiplayer.multiplayer_peer.get_connection_status(),
		", ConnectionState: ", Utils.MultiplayerManager.wip_connection.get_connection_state(),
		", GatheringState: ", Utils.MultiplayerManager.wip_connection.get_gathering_state(),
		", SignalingState: ", Utils.MultiplayerManager.wip_connection.get_signaling_state()
		)
	config_list.clear()
	config_list.add_item("Default Config")
	for conf in Utils.FileManager.get_available_configs():
		config_list.add_item(conf)
	print("Config list refreshed!")

func _on_ready_pressed():
	if is_selecting_config():
		if is_selecting_default_config():
			Globals.load_this_game = Utils.FileManager.get_file_bytes(Globals.DEFAULT_CONFIG_PATH)
		else:
			Globals.load_this_game = Utils.FileManager.get_file_bytes(get_config_file_path(get_currently_selected_config()))
		SignalManager.scene_transition.emit("res://src/scenes/game_elements/board_manager.tscn")

func _on_load_conf_file_pressed():
	SignalManager.create_load_config_dialog.emit()

func _on_refresh_conf_list_pressed():
	refresh_list()

func get_currently_selected_config() -> String:
	return config_list.get_item_text(config_list.get_selected_items()[0])

func is_selecting_config() -> bool:
	return not config_list.get_selected_items().is_empty()

func is_selecting_default_config() -> bool:
	return is_selecting_config() and config_list.get_selected_items()[0] == 0

func get_config_file_path(conf_name: String) -> String:
	return str(Globals.CONFIG_REPO,"/",conf_name,Globals.CONFIG_EXTENSION)

func _on_delete_selected_pressed():
	if is_selecting_config() and not is_selecting_default_config():
		var currently_selected: String = get_currently_selected_config()
		Utils.FileManager.delete_file(get_config_file_path(currently_selected))
		print("File deleted")
		refresh_list()

func _on_load_conf_url_pressed():
	SignalManager.download_config_popup.emit()

# MULTIPLAYER

func _on_client_pressed() -> void:
	peer_choice = 0 # Client
	Utils.MultiplayerManager.connect_to_server()
	mplay_next_page("CodeFromPeer")

func _on_server_pressed() -> void:
	Utils.MultiplayerManager.initialize_server()
	peer_choice = 1 # Server
	mplay_next_page("ServerMain")

func _on_add_client_pressed() -> void:
	Utils.MultiplayerManager.add_client()
	mplay_next_page("CreatingCode")

func code_created(_code: String) -> void:
	code = _code
	mplay_next_page("CodeCreated")

func code_percentage(pc: float) -> void:
	%CodeProgress.value = pc * 100.0

func _on_copy_code_pressed() -> void:
	DisplayServer.clipboard_set(code)
	mplay_next_page("CodeCopied")

func _on_next_pressed() -> void:
	if peer_choice == 0: # Client
		SignalManager.mplay_go_to_wait.emit()
	elif peer_choice == 1: # Server
		mplay_next_page("CodeFromPeer")

func establishing_connection() -> void:
	mplay_next_page("EstablishingConnection")

func _on_paste_code_pressed() -> void:
	SignalManager.mplay_code_received.emit(DisplayServer.clipboard_get())
	if peer_choice == 0: # Client
		mplay_next_page("CreatingCode")
	elif peer_choice == 1: # Server
		SignalManager.mplay_go_to_wait.emit()

func connection_result(result: bool) -> void:
	if result == true:
		if peer_choice == 0:
			mplay_next_page("ClientFinished")
		elif peer_choice == 1:
			mplay_next_page("ServerMain")
	else:
		OS.alert("Connection with peer failed.")
		mplay_next_page("Options1")

func _on_cancel_pressed() -> void:
	if peer_choice == 0: # Client
		Utils.MultiplayerManager.close_connection()
		mplay_next_page("Options1")
	elif peer_choice == 1: # Server
		Utils.MultiplayerManager.cancel_peer_connection()
		if current_mplay_page == "ServerMain":
			Utils.MultiplayerManager.close_connection()
			mplay_next_page("Options1")
		else:
			mplay_next_page("ServerMain")
