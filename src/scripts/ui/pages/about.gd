extends Control

@onready var version := %VersionNumber

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    version.text = str("Version ",ProjectSettings.get_setting("application/config/version"))

func _on_back_button_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/main_menu.tscn")
