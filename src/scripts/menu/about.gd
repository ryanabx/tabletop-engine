extends Control

@onready var version := %VersionNumber

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    version.text = str("Version ",ProjectSettings.get_setting("application/config/version"))

func _on_back_button_pressed() -> void:
    SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")
