# GLOBALS SINGLETON - Contains constants related to theming and open boardgame framework details
extends Node

# MULTIPLAYER
const DEFAULT_MAX_PLAYERS: int = 4

const RTC_CONFIG: Dictionary = {
	"iceServers": [
		{
			"urls": [
				"stun.l.google.com:19302",
				"iphone-stun.strato-iphone.de:3478",
				"numb.viagenie.ca:3478",
				"s1.taraba.net:3478",
				"s2.taraba.net:3478",
				"stun.12connect.com:3478",
				"stun.12voip.com:3478",
				"stun.1und1.de:3478",
				"stun.2talk.co.nz:3478",
				"stun.2talk.com:3478",
				"stun.3clogic.com:3478",
				"stun.3cx.com:3478",
				"stun.a-mm.tv:3478",
				"stun.aa.net.uk:3478",
				"stun.acrobits.cz:3478"
				]
		}
	]
}

var current_game: GameConfig2 = null

var safe_margin_l: int = 0
var safe_margin_t: int = 0
var safe_margin_r: int = 0
var safe_margin_b: int = 0

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

# FILE PATHS

const CONFIG_REPO: String = "user://configs"
const CONFIG_EXTENSION: String = ".obgf"

const DEFAULT_CONFIG_PATH: String = "res://configs/default.obgf"

const DOWNLOAD_FILE_PATH: String = "user://downloaded_file.obgf"

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

func set_current_tabletop(tabletop: Board) -> void:
	current_tabletop = tabletop

func set_shared_tabletop_manager(tt: BoardManager) -> void:
	tabletop_manager = tt

func get_current_game():
	if current_tabletop == null:
		return null
	return current_tabletop.game

class Player:
	static var ID: int = 0

class Game:
	enum ObjectType {
		TYPE_PIECE, TYPE_STACK
	}