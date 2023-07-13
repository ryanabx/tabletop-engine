extends Control

@onready var v_label = $HBoxContainer/TitleMargins/TitleList/Version
@onready var quit_button = $HBoxContainer/ButtonMargins/MenuButtons/Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_label.text = "v." + Globals.VERSION_NUMBER
	_connect_buttons()

func _connect_buttons() -> void:
	quit_button.pressed.connect(_on_quit_pressed)

func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
