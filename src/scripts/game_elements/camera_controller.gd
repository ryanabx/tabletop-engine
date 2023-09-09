class_name CameraController
extends Camera2D

var camera_transform: Transform2D = transform

var initial_points: Dictionary = {}
var current_points: Dictionary = {}

var init_pos: Vector2 = Vector2.ZERO
var init_rot: float = 0.0
var init_zoom: Vector2 = Vector2.ONE

const MOVEMENT_SPEED: float = 2000.0
const ROTATION_SPEED: float = 2.0

var initial_mouse_pos: Vector2 = Vector2.ZERO
var initial_camera_pos: Vector2 = Vector2.ZERO

var board: Board = null

var clamp1: Vector2
var clamp2: Vector2

func _ready() -> void:
	SignalManager.game_load_finished.connect(_game_loaded)

func _game_loaded(_board: Board) -> void:
	board = _board

func _input(event: InputEvent) -> void:
	if board_selecting():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			initial_points[event.index] = event.position
			current_points[event.index] = event.position
		else:
			initial_points.erase(event.index)
			current_points.erase(event.index)
		init_pos = offset
		init_rot = rotation
		init_zoom = zoom
	if event is InputEventScreenDrag:
		current_points[event.index] = event.position
		var curr: Array = current_points.values()
		var start: Array = initial_points.values()
		if current_points.size() == 1: # Pan only
			var delta_t: Vector2 = start[0] - curr[0]
			offset = init_pos + delta_t.rotated(init_rot) / init_zoom
		if current_points.size() == 2: # Zoom, Rotate
			var curr_vec: Vector2 = curr[1] - curr[0]
			var start_vec: Vector2 = start[1] - start[0]

			var r: float = curr_vec.angle_to(start_vec)
			var s: Vector2 = Vector2.ONE * (curr_vec.length() / start_vec.length())

			rotation = init_rot + r
			zoom = init_zoom * s

func board_selecting() -> bool:
	return board != null and (board.board_player.is_selecting() or board.board_player.object_queued())

func desktop_events(delta: float) -> void:
	if Input.is_action_pressed("camera_zoom_in"):
		zoom *= 1.0 + (1.5 * delta)
	if Input.is_action_pressed("camera_zoom_out"):
		zoom /= 1.0 + (1.5 * delta)
	
	if Input.is_action_just_pressed("ui_zoom_in"):
		zoom *= 1.1
	if Input.is_action_just_pressed("ui_zoom_out"):
		zoom /= 1.1
	
	offset += (Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down") * MOVEMENT_SPEED * delta).rotated(rotation)

	if board == null or not board.board_player.is_selecting():
		rotation += Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise") * ROTATION_SPEED * delta
	else:
		board.board_player.rotate_selection(
			Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise") * ROTATION_SPEED * delta,
			Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise")
		)
	if absf(Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise")) < 0.1 and absf(roundf(rotation_degrees / 45.0) * 45.0 - rotation_degrees) < 7.5:
		rotation_degrees = roundf(rotation_degrees / 45.0) * 45.0

func _process(delta: float) -> void:
	if Utils.is_desktop_platform():
		desktop_events(delta)
	zoom = zoom.clamp(Vector2(0.2, 0.2), Vector2(10.0, 10.0))
