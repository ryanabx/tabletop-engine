extends Control

@onready var game_name_label: Label = $GameName
@onready var menu: MenuBar = $Menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_menu()
	options_menu()

func file_menu() -> void:
	var file: PopupMenu = PopupMenu.new()
	file.id_pressed.connect(file_pressed)
	file.name = "File"
	menu.add_child(file)

	file.add_item("Load Config", 0)

	# Reset submenu
	var reset_submenu: PopupMenu = PopupMenu.new()
	reset_submenu.id_pressed.connect(file_pressed)
	reset_submenu.name = "reset"
	file.add_child(reset_submenu)
	file.add_submenu_item("Reset", "reset", 1)
	reset_submenu.add_item("Reset Tabletop", 10)
	reset_submenu.add_item("Reset Camera", 11)

	file.add_item("Exit Open Boardgame Framework", 2)

func options_menu() -> void:
	var options: PopupMenu = PopupMenu.new()
	options.id_pressed.connect(options_pressed)
	options.name = "Options"
	menu.add_child(options)

	options.add_item("Toggle Fullscreen", 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	game_name_label.text = "Current Game: " + Tabletop.game.name

func file_pressed(id: int) -> void:
	match id:
		0: load_config()
		10: Tabletop.reset_tabletop()
		11: Tabletop.camera_controller.reset_camera()
		2: get_tree().quit()

		

func options_pressed(index: int) -> void:
	match index:
		0: toggle_fullscreen()

func load_config() -> void:
	SignalManager.create_load_config_dialog.emit()

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
