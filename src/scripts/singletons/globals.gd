# GLOBALS SINGLETON - Contains constants related to theming and open boardgame framework details
extends Node

# MULTIPLAYER
const DEFAULT_MAX_PLAYERS: int = 4

var current_game: GameConfig2 = null

# GAME MODE

enum GAME_MODE {SINGLEPLAYER, MULTIPLAYER}

const TRANSITION_TIME_IN: float = 0.2
const TRANSITION_TIME_OUT: float = 0.1

var game_mode: GAME_MODE = GAME_MODE.SINGLEPLAYER

var piece_id: int = 0
var collection_id: int = 0

# THEMING GLOBALS

const BASE_SCALE: float = 1.0

const SCREEN_SIZE = Vector2(1280.0, 720.0)

const OUTLINE_THICKNESS: float = 6.0
const THICKNESS_RATIO: float = 0.8

const SELECTION_BOX_OUTLINE: float = 2.0

# UserInterface.gd
const GAME_NAME_PADDING: float = 2.0

# GameObject.gd
const OBJECT_HIGHLIGHT_BORDER: float = 2.0
const OBJECT_HIGHLIGHT_PADDING: float = 6.0
const OBJECT_HIGHLIGHT_COLOR: Color = Color.WHITE

# OTHER GLOBALS
const GAME_VERSION: String = "0.0.1"
const CURRENT_API_VERSION: int = 1

var current_tabletop: Board = null

var tabletop_manager: BoardManager = null

# COLORS

const COLOR_TRANSPARENT_HIGHLIGHT = Color(1.0, 1.0, 1.0, 0.2)
const COLOR_SELECTED: Color = Color.AZURE
const COLOR_HIGHLIGHTED: Color = Color.ALICE_BLUE * COLOR_TRANSPARENT_HIGHLIGHT
const COLOR_PERMANENT: Color = Color.BLACK
const COLOR_SELECTION_BOX_BORDER: Color = Color.BLUE
const COLOR_SELECTION_BOX: Color = COLOR_SELECTION_BOX_BORDER * COLOR_TRANSPARENT_HIGHLIGHT

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_exit_fullscreen") and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
# func _process(_delta: float) -> void:
# 	if get_window().get_size().width > get_window().get_size().height:
# 		get_viewport().set_size_override(true, Vector2(width, height)) # Custom size for 2D.
# 		get_viewport().set_size_override_stretch(true) # Enable stretch for custom size.

func set_current_tabletop(tabletop: Board) -> void:
	current_tabletop = tabletop

func set_shared_tabletop_manager(tt: BoardManager) -> void:
	tabletop_manager = tt

func get_current_game():
	if current_tabletop == null:
		return null
	return current_tabletop.game
