extends Control

func _ready() -> void:
    if GlobalBridge.global.IsMobilePlatform():
        %Video.hide()
    else:
        %Fullscreen.button_pressed = GlobalBridge.global.GetUserSetting("fullscreen")
    %SignalingServer.text = GlobalBridge.global.GetUserSetting("signaling_server")
    %UIScale.text = str(GlobalBridge.global.GetUserSetting("ui_scale"))

func _on_back_button_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/main_menu.tscn")

func _on_export_config_pressed() -> void:
    $FadeRect.create_export_config_dialog.emit()

func _on_toggle_fullscreen_toggled(toggled_on:bool) -> void:
    GlobalBridge.global.SetUserSetting("fullscreen",toggled_on)

func _on_signaling_server_text_changed(new_text:String) -> void:
    GlobalBridge.global.SetUserSetting("signaling_server", new_text)

func _on_ui_scale_text_changed(new_text:String) -> void:
    GlobalBridge.global.SetUserSetting("ui_scale", float(new_text))
