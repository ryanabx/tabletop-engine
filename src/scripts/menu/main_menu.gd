extends Control

@onready var version: Label = $VBoxContainer/HBoxContainer/VersionNumber
@onready var quit_button: Button = $VBoxContainer/MarginContainer/VBoxContainer/Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	version.text = str("Version: ",ProjectSettings.get_setting("application/config/version"))
	if Utils.is_mobile_platform():
		quit_button.hide()

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/game_elements/board_manager.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
