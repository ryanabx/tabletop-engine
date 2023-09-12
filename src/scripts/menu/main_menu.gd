extends Control

@onready var version := $SafeMargins/MarginContainer/VBoxContainer/HBoxContainer/Version
@onready var quit_button := $SafeMargins/MarginContainer/VBoxContainer/VBoxContainer/Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	version.text = str("Version: ",ProjectSettings.get_setting("application/config/version"))
	if Utils.is_mobile_platform():
		quit_button.hide()
	for i: Node in get_tree().get_nodes_in_group("hi"):
		pass
	Globals.load_this_game = PackedByteArray([])

func _on_new_game_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/new_game.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/settings.tscn")
