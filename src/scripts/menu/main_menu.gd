extends Control

@onready var version: Label = $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer/Version
@onready var quit_button: Button = $SafeMargins/MarginContainer/VBoxContainer/VBoxContainer/Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	version.text = str("Version: ",ProjectSettings.get_setting("application/config/version"))
	if Utils.PlatformManager.is_mobile_platform():
		quit_button.hide()
	Globals.current_game = null

func _on_new_game_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/new_game.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/settings.tscn")
