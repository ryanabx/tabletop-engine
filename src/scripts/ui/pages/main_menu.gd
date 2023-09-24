extends Control

func _ready() -> void:
    if not Global.has_setup:
        Global.setup()
    Global.load_this_game = PackedByteArray([])

func _on_new_game_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/menu/new_game.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_settings_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/menu/settings.tscn")

func _on_tabletops_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/menu/config_editor.tscn")

func _on_about_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/menu/about.tscn")
