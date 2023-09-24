extends Control

@onready var view_menu: VBoxContainer = $SafeMargins/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/View

func _ready() -> void:
	if Global.is_mobile_platform():
		view_menu.hide()

func _on_back_button_pressed() -> void:
	$FadeRect.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func _on_toggle_fullscreen_pressed() -> void:
	Global.set_user_setting("fullscreen",not Global.get_user_setting("fullscreen"))


func _on_export_config_pressed() -> void:
	$FadeRect.create_export_config_dialog.emit()
