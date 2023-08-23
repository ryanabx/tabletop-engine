extends MenuBar

@onready var menu: MenuBar = self
@onready var player: PopupMenu
@onready var actions: PopupMenu

func _ready() -> void:
	file_menu()
	if multiplayer.is_server():
		tabletop_menu()
	view_menu()
	options_menu()
	if not multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
		multiplayer_menu()

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
	menu.add_child(actions)


func player_menu(max_players: int) -> void:
	player = PopupMenu.new()
	player.index_pressed.connect(set_player)
	player.name = str("Player ",Player.get_number())
	for i in range(max_players):
		player.add_item(str("Player ",i+1))
	menu.add_child(player)


func multiplayer_menu() -> void:
	var multiplayer: PopupMenu = PopupMenu.new()
	multiplayer.id_pressed.connect(multiplayer_pressed)
	multiplayer.name = "Multiplayer"
	menu.add_child(multiplayer)
	multiplayer.add_item("Create Server", 0)
	multiplayer.add_item("Connect to Client", 1)

func tabletop_menu() -> void:
	var tabletop: PopupMenu = PopupMenu.new()
	tabletop.id_pressed.connect(tabletop_pressed)
	tabletop.name = "Tabletop"
	menu.add_child(tabletop)
	tabletop.add_item("Load Config", 0)
	tabletop.add_item("Create Config", 1)
	tabletop.add_item("Reload Config", 2)
	tabletop.add_item("Reset Tabletop", 3)
	

func file_menu() -> void:
	var file: PopupMenu = PopupMenu.new()
	file.id_pressed.connect(file_pressed)
	file.name = "File"
	menu.add_child(file)
	file.add_item("Main Menu", 0)
	file.add_item("Quit", 1)

func view_menu() -> void:
	var view: PopupMenu = PopupMenu.new()
	view.id_pressed.connect(view_pressed)
	view.name = "View"
	menu.add_child(view)
	view.add_item("Reset Camera", 0)
	var rotation_submenu: PopupMenu = PopupMenu.new()
	rotation_submenu.id_pressed.connect(view_pressed)
	rotation_submenu.name = "rotation"
	view.add_child(rotation_submenu)
	view.add_submenu_item("Camera Rotation", "rotation", 1)
	rotation_submenu.add_item("0 Degrees", 2)
	rotation_submenu.add_item("90 Degrees", 3)
	rotation_submenu.add_item("180 Degrees", 4)
	rotation_submenu.add_item("270 Degrees", 5)
	rotation_submenu.add_item("Snap To Nearest 90 Degree Angle", 6)

func options_menu() -> void:
	var options: PopupMenu = PopupMenu.new()
	options.id_pressed.connect(options_pressed)
	options.name = "Options"
	menu.add_child(options)
	options.add_item("Toggle Fullscreen", 0)

func set_player(index: int) -> void:
	Player.set_id(index)
	player.name = str("Player ",Player.get_number())

func run_action(index: int) -> void:
	SignalManager.run_action.emit(index)

func file_pressed(id: int) -> void:
	match id:
		0: get_tree().change_scene_to_file("res://src/scenes/menu/main_menu.tscn")
		1: get_tree().quit()

func multiplayer_pressed(id: int) -> void:
	match id:
		0:
			MultiplayerManager.create_server()
			SignalManager.server_add_peer.emit()
		1:
			SignalManager.client_add_peer.emit()

func tabletop_pressed(id: int) -> void:
	match id:
		0: if multiplayer.is_server(): load_config()
		1: export_config()
		2: Globals.get_shared_tabletop_manager().load_game_config(Globals.get_current_game())
		3: print("Not implemented yet")

func view_pressed(id: int) -> void:
	match id:
		0: Globals.get_shared_tabletop_manager().camera_controller.reset_camera()
		2: Globals.get_shared_tabletop_manager().camera_controller.set_camera_orientation(0)
		3: Globals.get_shared_tabletop_manager().camera_controller.set_camera_orientation(90)
		4: Globals.get_shared_tabletop_manager().camera_controller.set_camera_orientation(180)
		5: Globals.get_shared_tabletop_manager().camera_controller.set_camera_orientation(270)
		6: Globals.get_shared_tabletop_manager().camera_controller.snap_to_nearest_orientation()

func options_pressed(index: int) -> void:
	match index:
		0: toggle_fullscreen()

func load_config() -> void:
	SignalManager.create_load_config_dialog.emit()

func export_config() -> void:
	SignalManager.create_export_config_dialog.emit()

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
