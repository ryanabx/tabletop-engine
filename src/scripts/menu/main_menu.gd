extends Control

@onready var version := %Version

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    version.text = str("Version: ",ProjectSettings.get_setting("application/config/version"))
    if not Utils.is_desktop_platform():
        %DesktopButtons.hide()
        %MobileButtons.show()

    Globals.load_this_game = PackedByteArray([])

func _on_new_game_pressed() -> void:
    SignalManager.scene_transition.emit("res://src/scenes/menu/new_game.tscn")


func _on_quit_pressed() -> void:
    get_tree().quit()


func _on_settings_pressed() -> void:
    SignalManager.scene_transition.emit("res://src/scenes/menu/settings.tscn")


func _on_configurations_pressed() -> void:
    SignalManager.scene_transition.emit("res://src/scenes/menu/config_editor.tscn")


func _on_about_pressed() -> void:
    pass # Replace with function body.
