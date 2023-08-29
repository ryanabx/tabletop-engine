extends Control

@onready var config_list: ItemList = $SafeMargins/MarginContainer/VBoxContainer/ConfigList
@onready var ready_button: Button = $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer/Ready
@onready var delete_button: Button = $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer2/DeleteSelected
@onready var from_file_button: Button = $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer2/LoadConfFile

func _ready() -> void:
	Globals.current_game = null
	SignalManager.config_added.connect(refresh_list)
	SignalManager.mplay_code_created.connect(_on_offer_created)
	if not Utils.PlatformManager.is_desktop_platform():
		from_file_button.hide()
	refresh_list()

func _process(_delta: float) -> void:
	ready_button.disabled = not is_selecting_config() or not multiplayer.is_server()
	delete_button.disabled = not is_selecting_config() or is_selecting_default_config()



func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func refresh_list() -> void:
	if Utils.MultiplayerManager.wip_connection != null:
		print(multiplayer.multiplayer_peer.get_connection_status(), ", ",
		Utils.MultiplayerManager.wip_connection.get_connection_state()
		)
	config_list.clear()
	config_list.add_item("Default Config")
	for conf in Utils.FileManager.get_available_configs():
		config_list.add_item(conf)
	print("Config list refreshed!")

func _on_ready_pressed():
	if is_selecting_config():
		if is_selecting_default_config():
			Globals.current_game = Utils.FileManager.get_config(Globals.DEFAULT_CONFIG_PATH)
		else:
			Globals.current_game = Utils.FileManager.get_config(get_config_file_path(get_currently_selected_config()))
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


func _on_client_pressed() -> void:
	Utils.MultiplayerManager.connect_to_server()
	%Options1.hide()
	%OptionsClient.show()

func _on_server_pressed() -> void:
	Utils.MultiplayerManager.initialize_server()
	%Options1.hide()
	%OptionsServer.show()


func _on_add_client_pressed() -> void:
	Utils.MultiplayerManager.add_client()
	%OptionsServer.hide()
	%ServerOfferClient.show()


func _on_submit_offer_pressed() -> void:
	if %ServerOffer.text != "":
		SignalManager.mplay_code_received.emit(%ServerOffer.text)
		%OptionsClient.hide()
		%OfferClient.show()

func _on_offer_created(offer: String) -> void:
	print("Offer created! ", offer, ", ",Utils.MultiplayerManager.connection_type)
	if Utils.MultiplayerManager.connection_type == "Client":
		%CodeForServer.text = offer
	elif Utils.MultiplayerManager.connection_type == "Server":
		%ServerCode.text = offer


func _on_disconnect_mplay_pressed() -> void:
	Utils.MultiplayerManager.close_connection()
	%ConnectedYes.hide()
	%Options1.show()


func _on_paste_offer_from_server_pressed() -> void:
	%ServerOffer.text = DisplayServer.clipboard_get()


func _on_copy_server_code_pressed() -> void:
	DisplayServer.clipboard_set(%CodeForServer.text)


func _on_accept_client_pressed() -> void:
	%OfferClient.hide()
	%ConnectedYes.show()



func _on_copy_code_server_pressed() -> void:
	DisplayServer.clipboard_set(%ServerCode.text)


func _on_next_server_step_pressed() -> void:
	%ServerOfferClient.hide()
	%ServerPasteClientOffer.show()


func _on_paste_client_code_pressed() -> void:
	%ClientCodeOffer.text = DisplayServer.clipboard_get()


func _on_next_server_step2_pressed() -> void:
	if %ClientCodeOffer.text != "":
		SignalManager.mplay_code_received.emit(%ClientCodeOffer.text)
		%ServerPasteClientOffer.hide()
		%OptionsServer.show()
