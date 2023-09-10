class_name CameraController
extends Camera2D

var camera_transform: Transform2D = transform

var initial_points: Dictionary = {}
var current_points: Dictionary = {}

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
	event = make_input_local(event)
	if event is InputEventScreenTouch:
		if event.pressed:
			current_points[event.index] = event
		else:
			current_points.erase(event.index)
	elif event is InputEventScreenDrag:
		current_points[event.index] = event
		if current_points.size() == 1: # Pan only
			global_position -= event.relative.rotated(rotation) / zoom
		if current_points.size() == 2: # Zoom, Rotate
			var other: int
			var my: int = event.index
			if current_points.keys().find(event.index) == 0:
				other = current_points.keys()[1]
			else:
				other = current_points.keys()[0]
			# Initial constants
			var a1: Vector2 = current_points[my].position
			var b1: Vector2 = current_points[other].position
			var a2: Vector2 = initial_points[my].position
			var b2: Vector2 = initial_points[other].position

			var v1: Vector2 = b1 - a1
			var v2: Vector2 = b2 - a2

			var c1: Vector2 = a1 + (v1/2.0)
			var c2: Vector2 = a2 + (v2/2.0)

			var p1: Vector2 = global_position

			var delta_angle: float = v1.angle_to(v2)

			var delta_scale: Vector2 = Vector2.ONE * (v2.length() / v1.length())

			var new_global_position: Vector2 = (p1-c1).rotated(delta_angle) * delta_scale + c2

			global_position = new_global_position
			rotation += delta_angle
			zoom *= delta_scale


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
	
	global_position += (Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down") * MOVEMENT_SPEED * delta).rotated(rotation)

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
