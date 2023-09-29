extends Control

func _ready() -> void:
    if Global.is_mobile_platform():
        %Video.hide()
    else:
        %Fullscreen.button_pressed = Global.get_user_setting("fullscreen")
    %SignalingServer.text = Global.get_user_setting("signaling_server")
    %UIScale.text = str(Global.get_user_setting("ui_scale"))

func _on_back_button_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/main_menu.tscn")

func _on_export_config_pressed() -> void:
    $FadeRect.create_export_config_dialog.emit()

func _on_toggle_fullscreen_toggled(toggled_on:bool) -> void:
    Global.set_user_setting("fullscreen",toggled_on)

func _on_signaling_server_text_changed(new_text:String) -> void:
    Global.set_user_setting("signaling_server", new_text)

func _on_ui_scale_text_changed(new_text:String) -> void:
    Global.set_user_setting("ui_scale", float(new_text))
