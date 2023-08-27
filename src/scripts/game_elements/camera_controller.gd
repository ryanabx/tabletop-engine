class_name CameraController
extends Node2D

@onready var camera: Camera2D = $Camera2D

var input_events: Dictionary = {}

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

func reset_camera() -> void:
	camera.zoom = Vector2.ONE
	camera.rotation_degrees = 0.0
	camera.position = Vector2.ZERO

func _input(event: InputEvent) -> void:
	var ev: InputEvent = make_input_local(event)
	touchscreen_events(ev)

func touchscreen_events(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			input_events[event.index] = event
		else:
			input_events.erase(event.index)
	if event is InputEventScreenDrag:
		input_events[event.index] = event
		if input_events.size() == 2:
			var other_event: InputEvent
			if event.index == 0:
				other_event = input_events[1]
			elif event.index == 1:
				other_event = input_events[0]
			var vec1: Vector2 = other_event.position - event.position
			var vec2: Vector2 = other_event.position - (event.position - event.relative)

			var center1: Vector2 = other_event.position + (vec1 / 2)
			var center2: Vector2 = other_event.position + (vec2 / 2)

			var dist1: float = vec1.length()
			var dist2: float = vec2.length()

			var rotation_delta: float = vec1.angle_to(vec2)
			var position_delta: Vector2 = center2 - center1
			var zoom_delta: float = dist1 / dist2
			camera.rotation += rotation_delta
			camera.position -= position_delta
			camera.zoom *= zoom_delta
		elif input_events.size() == 1 and not board_selecting():
			camera.position -= event.relative



func board_selecting() -> bool:
	return board != null and board.board_player.is_selecting()	

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

func _process(delta: float) -> void:
	if Utils.is_desktop_platform():
		desktop_events(delta)
	camera.zoom = camera.zoom.clamp(Vector2(0.2, 0.2), Vector2(10.0, 10.0))
