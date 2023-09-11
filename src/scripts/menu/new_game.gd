extends Control

@onready var config_list: ItemList = %ConfigList
@onready var ready_button: Button = %ReadyButton
@onready var delete_button: Button = %DeleteSelected
@onready var from_file_button: Button = %LoadConfFile
@onready var create_server_button: Button = %CreateServerButton
@onready var connect_client_button: Button = %ConnectClientButton
@onready var server_list: ItemList = %ServerList

@onready var client_code_entry: LineEdit = %ClientCodeEntry
@onready var server_cancel_button: Button = %ServerCancelButton
@onready var refresh_server_list_button: Button = %RefreshServerListings

var peer_choice: int = 0 # Client

var current_mplay_page: String = "Options1"

var code: String = ""

func _ready() -> void:
	Globals.load_this_game = PackedByteArray([])
	SignalManager.config_added.connect(refresh_list)
	if not Utils.is_desktop_platform():
		from_file_button.hide()
	MultiplayerManager.close_connection()
	SignalManager.mplay_code_created.connect(code_created)
	refresh_list()

func _process(_delta: float) -> void:
	ready_button.disabled = not is_selecting_config() or not multiplayer.is_server()
	delete_button.disabled = not is_selecting_config() or is_selecting_default_config()
	connect_client_button.disabled = not is_selecting_server()
	
	refresh_server_list_button.visible = not (multiplayer.multiplayer_peer is WebRTCMultiplayerPeer)
	server_cancel_button.visible = (multiplayer.multiplayer_peer is WebRTCMultiplayerPeer)



func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func refresh_list() -> void:
	config_list.clear()
	config_list.add_item("Default Config")
	for conf: String in Utils.FileManager.get_available_configs():
		config_list.add_item(conf)
	print("Config list refreshed!")

func refresh_server_list() -> void:
	server_list.clear()
	var servers_list: Array = await MultiplayerManager.get_server_list()
	print(servers_list)
	for x: String in servers_list:
		server_list.add_item(x)


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

func is_selecting_server() -> bool:
	return not server_list.get_selected_items().is_empty()

func get_selected_server() -> String:
	return config_list.get_item_text(server_list.get_selected_items()[0])

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

func code_created(_code: String) -> void:
	OS.alert(str("Code created: ",_code), "Remember this code")


func _on_refresh_server_listings_pressed() -> void:
	refresh_server_list()


func _on_create_server_button_pressed() -> void:
	MultiplayerManager.create_server()
	create_server_button.visible = false
	client_code_entry.visible = true


func _on_connect_client_button_pressed() -> void:
	MultiplayerManager.create_client(get_selected_server())


func _on_server_cancel_button_pressed() -> void:
	MultiplayerManager.close_connection()
	create_server_button.visible = true
	client_code_entry.visible = false
	


func _on_client_code_entry_text_submitted(new_text: String) -> void:
	SignalManager.client_code_received.emit(new_text)

