extends Control

@onready var view_menu: VBoxContainer = $SafeMargins/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/View
@onready var config_tools: VBoxContainer = $SafeMargins/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ConfigTools

func _ready() -> void:
    %SelectingObjects.selected = GameProperties.select_type
    %ConnectionMethod.selected = GameProperties.multiplayer_method
    if Utils.is_mobile_platform():
        view_menu.hide()
    if Utils.is_web_platform():
        config_tools.hide()

func settings_updated() -> void:
    GameProperties.save_settings()

func _on_back_button_pressed() -> void:
    SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")


func _on_toggle_fullscreen_pressed() -> void:
    GameProperties.fullscreen = not GameProperties.fullscreen
    settings_updated()


func _on_export_config_pressed() -> void:
    SignalManager.create_export_config_dialog.emit()

func _on_connection_method_item_selected(index: int) -> void:
    GameProperties.multiplayer_method = (index as GameProperties.MultiplayerMethod)
    settings_updated()


func _on_selecting_objects_item_selected(index: int) -> void:
    GameProperties.select_type = (index as GameProperties.SelectType)
    settings_updated()
