extends Control

# TODO: Replace regular window menu with menubar

@onready var file: PopupMenu = $Menu/File
@onready var actions: PopupMenu = $Menu/Actions
@onready var options: PopupMenu = $Menu/Options
@onready var help: PopupMenu = $Menu/Help

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_popup_menus()
	options.index_pressed.connect(options_button_pressed)
	file.index_pressed.connect(file_button_pressed)
	

func _populate_popup_menus() -> void:
	print("HIII")
	file.add_item("Load Config")
	actions.add_submenu_item("Run Action", "run_action")
	options.add_check_item("Fullscreen")
	help.add_item("About Open Boardgame Framework")
	help.add_item("Check for Updates")
	pass # TODO: Implement this


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func file_button_pressed(index: int) -> void:
	match index:
		0: load_config()

		

func options_button_pressed(index: int) -> void:
	match index:
		0: toggle_fullscreen()

func load_config() -> void:
	print("Loading config dialog")
	var fd = FileDialog.new()
	add_child(fd)
	fd.popup_window = true
	fd.popup()
	fd.grab_focus()

func toggle_fullscreen() -> void:
	options.set_item_checked(0, not options.is_item_checked(0))
	if options.is_item_checked(0):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)