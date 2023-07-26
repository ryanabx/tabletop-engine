# GLOBALS SINGLETON - Contains constants related to theming and open boardgame framework details
extends Node

# THEMING GLOBALS

const BASE_SCALE: float = 1.0

const OUTLINE_THICKNESS: float = 6.0
const THICKNESS_RATIO: float = 0.8

# OTHER GLOBALS
const GAME_VERSION: String = "0.0.1"
const CURRENT_API_VERSION: int = 1

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_exit_fullscreen") and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func get_tabletop() -> TabletopManager:
    if not has_node("/root/TabletopManager"):
        return null
    return get_node("/root/TabletopManager") as TabletopManager