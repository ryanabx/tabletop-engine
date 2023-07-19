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
	

func _populate_popup_menus() -> void:
	print("HIII")
	file.add_check_item("Hi", 1)
	actions.add_submenu_item("Run Action", "run_action", 2)
	options.add_check_item("Fullscreen", 1)
	help.add_item("About Open Boardgame Framework")
	help.add_item("Check for Updates")
	pass # TODO: Implement this


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func file_button_pressed(id: int) -> void:
	pass

func options_button_pressed(index: int) -> void:
	match index:
		0:
			options.set_item_checked(0, not options.is_item_checked(0))
			if options.is_item_checked(0):
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)