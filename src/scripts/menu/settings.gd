extends Control

@onready var fullscreen_toggle: CheckButton = $MainMargin/PanelMargins/Content/ContentList/ViewMenu/Fullscreen
@onready var view_menu: VBoxContainer = $MainMargin/PanelMargins/Content/ContentList/ViewMenu
@onready var config_tools: VBoxContainer = $MainMargin/PanelMargins/Content/ContentList/ConfigTools

func _ready() -> void:
	if Utils.is_mobile_platform():
		view_menu.hide()
	if Utils.is_web_platform():
		config_tools.hide()

func _process(_delta: float) -> void:
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func _on_fullscreen_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_export_new_config_pressed() -> void:
	SignalManager.create_export_config_dialog.emit()
