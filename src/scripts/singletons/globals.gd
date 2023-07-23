extends Node

var _player_id: int = 0

const VERSION_NUMBER: String = "0.0.1"

const OUTLINE_THICKNESS: float = 6.0
const THICKNESS_RATIO: float = 0.8

var default_font: Font = null

var game_name = ""

@onready var tabletop = $/root/Tabletop
@onready var camera_controller = $/root/Tabletop/CameraController
@onready var board = $/root/Tabletop/GameBoard

func _ready() -> void:
	var l = Label.new()
	default_font = l.get_theme_default_font()
	l.free()

func set_player_id(id: int) -> void:
	_player_id = id

func get_player_id() -> int:
	return _player_id

func get_tabletop() -> Tabletop:
	return tabletop

func get_camera_controller() -> Node2D:
	return camera_controller

func get_camera_zoom() -> Vector2:
	return camera_controller.camera.zoom

func get_board() -> GameBoard:
	return board

func get_bounds() -> Rect2:
	return board.get_border()
