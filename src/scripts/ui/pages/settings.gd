extends Control

func _ready() -> void:
    if Global.is_mobile_platform():
        (%Video as Control).hide()
    else:
        (%Fullscreen as Button).button_pressed = Global.get_user_setting("fullscreen")
    (%SignalingServer as LineEdit).text = Global.get_user_setting("signaling_server")
    (%UIScale as LineEdit).text = str(Global.get_user_setting("ui_scale"))

func _on_back_button_pressed() -> void:
    ($FadeRect as FadeRect).scene_transition.emit("res://src/scenes/ui/pages/main_menu.tscn")

func _on_toggle_fullscreen_toggled(toggled_on:bool) -> void:
    Global.set_user_setting("fullscreen",toggled_on)

func _on_signaling_server_text_changed(new_text:String) -> void:
    Global.set_user_setting("signaling_server", new_text)

func _on_ui_scale_text_changed(new_text:String) -> void:
    Global.set_user_setting("ui_scale", float(new_text))
