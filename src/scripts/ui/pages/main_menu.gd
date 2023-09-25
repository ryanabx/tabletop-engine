extends Control

func _ready() -> void:
    if not Global.has_setup:
        Global.setup()
    if not Global.is_desktop_platform():
        %Quit.hide()
    if Global.is_mobile_platform():
        %Tabletops.hide()
        %Settings.hide()
    Global.load_this_game = PackedByteArray([])
    randomize()
    %Splash.text = Global.SPLASHES[randi_range(0, len(Global.SPLASHES) - 1)]

func _on_new_game_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/new_game.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_settings_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/settings.tscn")

func _on_tabletops_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/config_editor.tscn")

func _on_about_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/about.tscn")
