extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer/VersionNumber.text = str("Version: ",ProjectSettings.get_setting("application/config/version"))


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/game_elements/board_manager.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
