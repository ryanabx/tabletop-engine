extends Control

@onready var config_list: ItemList = %ConfigList
@onready var ready_button: Button = %ReadyButton
@onready var delete_button: Button = %DeleteSelected
@onready var from_file_button: Button = %LoadConfFile

var peer_choice: int = 0 # Client

var current_mplay_page: String = "Options1"

var code: String = ""

func _ready() -> void:
	Globals.load_this_game = PackedByteArray([])
	SignalManager.config_added.connect(refresh_list)
	if not Utils.is_desktop_platform():
		from_file_button.hide()
	MultiplayerManager.close_connection()
	refresh_list()

func _process(_delta: float) -> void:
	ready_button.disabled = not is_selecting_config() or not multiplayer.is_server()
	delete_button.disabled = not is_selecting_config() or is_selecting_default_config()

func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func refresh_list() -> void:
	if MultiplayerManager.wip_connection != null:
		print("Connecting state multiplayer peer: ",multiplayer.multiplayer_peer.get_connection_status(),
		", ConnectionState: ", MultiplayerManager.wip_connection.get_connection_state(),
		", GatheringState: ", MultiplayerManager.wip_connection.get_gathering_state(),
		", SignalingState: ", MultiplayerManager.wip_connection.get_signaling_state()
		)
	config_list.clear()
	config_list.add_item("Default Config")
	for conf: String in Utils.FileManager.get_available_configs():
		config_list.add_item(conf)
	print("Config list refreshed!")

func _on_ready_pressed() -> void:
	if is_selecting_config():
		if is_selecting_default_config():
			Globals.load_this_game = Utils.FileManager.get_file_bytes(Globals.DEFAULT_CONFIG_PATH)
		else:
			Globals.load_this_game = Utils.FileManager.get_file_bytes(get_config_file_path(get_currently_selected_config()))
		SignalManager.scene_transition.emit("res://src/scenes/game_elements/board_manager.tscn")

func _on_load_conf_file_pressed() -> void:
	SignalManager.create_load_config_dialog.emit()

func _on_refresh_conf_list_pressed() -> void:
	refresh_list()

func get_currently_selected_config() -> String:
	return config_list.get_item_text(config_list.get_selected_items()[0])

func is_selecting_config() -> bool:
	return not config_list.get_selected_items().is_empty()

func is_selecting_default_config() -> bool:
	return is_selecting_config() and config_list.get_selected_items()[0] == 0

func get_config_file_path(conf_name: String) -> String:
	return str(Globals.CONFIG_REPO,"/",conf_name,Globals.CONFIG_EXTENSION)

func _on_delete_selected_pressed() -> void:
	if is_selecting_config() and not is_selecting_default_config():
		var currently_selected: String = get_currently_selected_config()
		Utils.FileManager.delete_file(get_config_file_path(currently_selected))
		print("File deleted")
		refresh_list()

func _on_load_conf_url_pressed() -> void:
	SignalManager.download_config_popup.emit()

# MULTIPLAYER


