extends Control

func _ready() -> void:
    if Global.is_mobile_platform():
        %Video.hide()
    else:
        %Fullscreen.button_pressed = Global.get_user_setting("fullscreen")

func _on_back_button_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/main_menu.tscn")

func _on_export_config_pressed() -> void:
    $FadeRect.create_export_config_dialog.emit()

func _on_toggle_fullscreen_toggled(toggled_on:bool) -> void:
    Global.set_user_setting("fullscreen",toggled_on)
