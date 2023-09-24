extends Control

@onready var ready_button: Button = %ReadyButton
@onready var config_selector: ConfigSelector = %ConfigSelector

func _process(_delta: float) -> void:
    ready_button.disabled = not config_selector.is_selecting_config() or not multiplayer.is_server()

func _on_back_button_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")

func _on_ready_pressed() -> void:
    Global.load_this_game = config_selector.get_selected_config_bytes()
    go_to_scene.rpc("res://src/scenes/game_elements/board_manager.tscn")
    
@rpc("authority","call_local","reliable")
func go_to_scene(scn: String) -> void:
    $FadeRect.scene_transition.emit(scn)
