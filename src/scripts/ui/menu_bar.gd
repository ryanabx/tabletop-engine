extends MenuBar

@onready var menu: MenuBar = self
@onready var player: PopupMenu
@onready var actions: PopupMenu
@onready var tabletop: PopupMenu

var board: Board = null

func _ready() -> void:
	file_menu()
	tabletop_menu()
	if not Utils.is_mobile_platform():
		options_menu()
	if not multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
		multiplayer_menu()
	else:
		server_menu()
	SignalManager.game_load_finished.connect(set_board)

func set_board(_b: Board) -> void:
	board = _b

func server_menu() -> void:
	var sv_menu: PopupMenu = PopupMenu.new()
	if multiplayer.is_server():
		sv_menu.name = "Disband Server"
	else:
		sv_menu.name = "Disconnect from Server"
	sv_menu.about_to_popup.connect(_disconnect_from_server)
	menu.add_child(sv_menu)

func _disconnect_from_server() -> void:
	print("Disconnect from server")
	MultiplayerManager.disband()
	get_tree().reload_current_scene()

func new_game_loaded(max_players: int, action: Array) -> void:
	if player != null:
		player.queue_free()
		await player.tree_exited
	if actions != null:
		actions.queue_free()
		await actions.tree_exited
	player_menu(max_players)
	actions_menu(action)

func actions_menu(action: Array) -> void:
	actions = PopupMenu.new()
	actions.index_pressed.connect(run_action)
	actions.name = "Actions"
	for i in action:
		actions.add_item(i.name)
	tabletop.add_child(actions)
	tabletop.add_submenu_item("Actions", "Actions")


func player_menu(max_players: int) -> void:
	player = PopupMenu.new()
	player.index_pressed.connect(set_player)
	player.name = "Player"
	tabletop.add_child(player)
	tabletop.add_submenu_item("Player", "Player")
	for i in range(max_players):
		player.add_item(str("Player ",i+1))
	

func multiplayer_menu() -> void:
	var _multiplayer: PopupMenu = PopupMenu.new()
	_multiplayer.id_pressed.connect(multiplayer_pressed)
	_multiplayer.name = "Multiplayer"
	menu.add_child(_multiplayer)
	_multiplayer.add_item("Create Server", 0)
	_multiplayer.add_item("Connect to Server", 1)

func tabletop_menu() -> void:
	tabletop = PopupMenu.new()
	tabletop.id_pressed.connect(tabletop_pressed)
	tabletop.name = "Tabletop"
	menu.add_child(tabletop)
	if multiplayer.is_server():
		var conf: PopupMenu = PopupMenu.new()
		conf.name = "Config"
		conf.id_pressed.connect(tabletop_pressed)
		tabletop.add_child(conf)
		tabletop.add_submenu_item("Config", "Config")
		conf.add_item("Load Config", 0)
		conf.add_item("Load Example Config", 5)
		conf.add_item("Create Config", 1)
		conf.add_item("Reload Config", 2)
		conf.add_item("Reset Tabletop", 3)
	
	

func file_menu() -> void:
	var file: PopupMenu = PopupMenu.new()
	file.id_pressed.connect(file_pressed)
	file.name = "File"
	menu.add_child(file)
	file.add_item("Main Menu", 0)
	if not Utils.is_mobile_platform():
		file.add_item("Quit", 1)

func options_menu() -> void:
	var options: PopupMenu = PopupMenu.new()
	options.id_pressed.connect(options_pressed)
	options.name = "Options"
	menu.add_child(options)
	options.add_item("Toggle Fullscreen", 0)

func set_player(index: int) -> void:
	Player.set_id(index)

func run_action(index: int) -> void:
	SignalManager.run_action.emit(index)

func file_pressed(id: int) -> void:
	match id:
		0: get_tree().change_scene_to_file("res://src/scenes/menu/main_menu.tscn")
		1: get_tree().quit()

func multiplayer_pressed(id: int) -> void:
	match id:
		0:
			SignalManager.server_add_peer.emit()
		1:
			SignalManager.client_add_peer.emit()

func tabletop_pressed(id: int) -> void:
	match id:
		0: if multiplayer.is_server(): load_config()
		1: export_config()
		2:
			if board != null:
				board.get_parent().load_game_config(Globals.get_current_game())
				board = null
		3: get_tree().reload_current_scene()
		5: if multiplayer.is_server(): load_sample_config()

func options_pressed(index: int) -> void:
	match index:
		0: toggle_fullscreen()

func load_config() -> void:
	SignalManager.create_load_config_dialog.emit()

func load_sample_config() -> void:
	if FileAccess.file_exists("res://configs/default.obgf"):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://configs/default.obgf")
		var conf: GameConfig2 = GameConfig2.new()
		if conf.fill_bytes(bytes):
			SignalManager.load_game_config.emit(
				conf
			)
	else:
		print("Could not find default config")
		

func export_config() -> void:
	SignalManager.create_export_config_dialog.emit()

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
