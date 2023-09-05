extends Control

@onready var view_menu: VBoxContainer = $SafeMargins/MarginContainer/VBoxContainer/VBoxContainer
@onready var config_tools: VBoxContainer = $SafeMargins/MarginContainer/VBoxContainer/VBoxContainer2

func _ready() -> void:
	if Utils.is_mobile_platform():
		view_menu.hide()
	if Utils.is_web_platform():
		config_tools.hide()

func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func _on_toggle_fullscreen_pressed() -> void:
	Globals.Settings.fullscreen = not Globals.Settings.fullscreen


func _on_export_config_pressed() -> void:
	SignalManager.create_export_config_dialog.emit()
