extends MenuBar

# TODO: Replace regular window menu with menubar

@onready var file: PopupMenu = $File
@onready var actions: PopupMenu = $Actions
@onready var options: PopupMenu = $Options
@onready var help: PopupMenu = $Help

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_popup_menus()

func _populate_popup_menus() -> void:
	file.add_check_item("Hi", 1)
	actions.add_submenu_item("Run Action", "run_action", 2)
	options.add_check_item("Fullscreen")
	help.add_item("About Open Boardgame Framework")
	help.add_item("Check for Updates")
	pass # TODO: Implement this


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
