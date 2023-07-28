extends Control

@onready var game_name_label: Label = $HBoxContainer/GameName
@onready var menu: MenuBar = $HBoxContainer/Menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_menu()
	view_menu()
	options_menu()

func file_menu() -> void:
	var file: PopupMenu = PopupMenu.new()
	file.id_pressed.connect(file_pressed)
	file.name = "File"
	menu.add_child(file)

	file.add_item("Load Config", 0)
	file.add_item("Export Config", 3)

	# Reset submenu
	var reset_submenu: PopupMenu = PopupMenu.new()
	reset_submenu.id_pressed.connect(file_pressed)
	reset_submenu.name = "reset"
	file.add_child(reset_submenu)
	file.add_submenu_item("Reset", "reset", 1)
	reset_submenu.add_item("Reset Tabletop", 10)
	reset_submenu.add_item("Reset Camera", 11)
	file.add_item("Exit Open Boardgame Framework", 2)

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

	var set_player_submenu: PopupMenu = PopupMenu.new()
	set_player_submenu.index_pressed.connect(set_player)
	set_player_submenu.name = "set_player"
	options.add_child(set_player_submenu)
	if Globals.get_tabletop().game != null:
		if Globals.get_tabletop().game.player != null:
			for i in range(Globals.get_tabletop().game.player.max):
				set_player_submenu.add_item(str("P",i+1))
			options.add_submenu_item("Set Player", "set_player", 2)
		else:
			print("Ugh")
	options.add_item("Toggle Fullscreen", 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Globals.get_tabletop().game != null:
		game_name_label.text = "Current Game: " + Globals.get_tabletop().game.name
	else:
		game_name_label.text = "Current Game: Untitled"

func set_player(index: int) -> void:
	Player.set_id(index)

func file_pressed(id: int) -> void:
	match id:
		0: load_config()
		3: export_config()
		10: Globals.get_tabletop().reset_tabletop()
		11: Globals.get_tabletop().camera_controller.reset_camera()
		2: get_tree().quit()

func view_pressed(id: int) -> void:
	match id:
		0: Globals.get_tabletop().camera_controller.reset_camera()
		2: Globals.get_tabletop().camera_controller.set_camera_orientation(0)
		3: Globals.get_tabletop().camera_controller.set_camera_orientation(90)
		4: Globals.get_tabletop().camera_controller.set_camera_orientation(180)
		5: Globals.get_tabletop().camera_controller.set_camera_orientation(270)
		6: Globals.get_tabletop().camera_controller.snap_to_nearest_orientation()

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
		
