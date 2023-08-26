class_name CameraController
extends Node2D

@onready var camera: Camera2D = $Camera2D

const MOVEMENT_SPEED: float = 2000.0
const ROTATION_SPEED: float = 2.0

var initial_mouse_pos: Vector2 = Vector2.ZERO
var free_cam: bool = false
var initial_camera_pos: Vector2 = Vector2.ZERO

var board: Board = null

var clamp1: Vector2
var clamp2: Vector2

func _ready() -> void:
	SignalManager.game_load_finished.connect(_game_loaded)
	SignalManager.camera_move_start.connect(free_cam_start)
	SignalManager.camera_move_end.connect(free_cam_finish)

func _game_loaded(_board: Board) -> void:
	board = _board

func reset_camera() -> void:
	camera.zoom = Vector2.ONE
	camera.rotation_degrees = 0.0
	camera.position = Vector2.ZERO

func _input(event: InputEvent) -> void:
	var ev: InputEvent = make_input_local(event)
	multiplatform_events(ev)
	touchscreen_events(ev)

func touchscreen_events(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		camera.zoom *= 1.0 + (1.0 - event.factor) * 0.2
	if event is InputEventPanGesture:
		camera.rotation_degrees += event.delta.normalized().angle()
	

func desktop_events(delta: float) -> void:
	if Input.is_action_pressed("camera_zoom_in"):
		camera.zoom *= 1.0 + (1.5 * delta)
	if Input.is_action_pressed("camera_zoom_out"):
		camera.zoom /= 1.0 + (1.5 * delta)
	
	if Input.is_action_just_pressed("ui_zoom_in"):
		camera.zoom *= 1.1
	if Input.is_action_just_pressed("ui_zoom_out"):
		camera.zoom /= 1.1
	
	camera.position += (Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down") * MOVEMENT_SPEED * delta).rotated(camera.rotation)

	if board == null or not board.board_player.is_selecting():
		camera.rotation += Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise") * ROTATION_SPEED * delta
	else:
		board.board_player.rotate_selection(
			Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise") * ROTATION_SPEED * delta,
			Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise")
		)
	if absf(Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise")) < 0.1 and absf(roundf(camera.rotation_degrees / 45.0) * 45.0 - camera.rotation_degrees) < 7.5:
		camera.rotation_degrees = roundf(camera.rotation_degrees / 45.0) * 45.0

func multiplatform_events(event: InputEvent) -> void:
	if free_cam and event is InputEventScreenDrag:
		camera.position -= (event.relative)

func _process(delta: float) -> void:
	if Utils.is_desktop_platform():
		desktop_events(delta)
	camera.zoom = camera.zoom.clamp(Vector2(0.2, 0.2), Vector2(10.0, 10.0))
	
func free_cam_start() -> void:
	free_cam = true
	initial_mouse_pos = get_local_mouse_position()
	initial_camera_pos = camera.position
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)

func free_cam_finish() -> void:
	initial_mouse_pos = Vector2.ZERO
	free_cam = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func in_free_cam() -> bool:
	return free_cam
