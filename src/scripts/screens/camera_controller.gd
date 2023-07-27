extends Node2D

@onready var camera = $Camera2D

const MOVEMENT_SPEED: float = 1150.0
const ROTATION_SPEED: float = 2.0
const ZOOM_SPEED: float = 2.0

var initial_mouse_pos: Vector2 = Vector2.ZERO
var free_cam: bool = false
var initial_camera_pos: Vector2 = Vector2.ZERO

func reset_camera() -> void:
	if "x" in Globals.get_tabletop().game.board_settings.camera.scale:
		camera.zoom = Vector2(
			get_viewport().get_visible_rect().size.x / (Globals.get_tabletop().game.board_settings.camera.scale.x * Globals.get_tabletop().game.board_settings.scale.x),
			get_viewport().get_visible_rect().size.x / (Globals.get_tabletop().game.board_settings.camera.scale.x * Globals.get_tabletop().game.board_settings.scale.x)
			)
	elif "y" in Globals.get_tabletop().game.board_settings.camera.scale:
		camera.zoom = Vector2(
			get_viewport().get_visible_rect().size.y / (Globals.get_tabletop().game.board_settings.camera.scale.y * Globals.get_tabletop().game.board_settings.scale.y),
			get_viewport().get_visible_rect().size.y / (Globals.get_tabletop().game.board_settings.camera.scale.y * Globals.get_tabletop().game.board_settings.scale.y)
			)
	camera.position = Vector2(Globals.get_tabletop().game.board_settings.camera.position.x * Globals.get_tabletop().game.board_settings.scale.x, Globals.get_tabletop().game.board_settings.camera.position.y * Globals.get_tabletop().game.board_settings.scale.y)
	camera.rotation_degrees = Globals.get_tabletop().game.board_settings.camera.rotation_degrees

func set_camera_orientation(deg: float) -> void:
	camera.rotation_degrees = deg

func snap_to_nearest_orientation() -> void:
	camera.rotation_degrees = roundf(camera.rotation_degrees / 90.0) * 90.0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_zoom_in"):
		camera.zoom *= 1.1
	if Input.is_action_just_pressed("ui_zoom_out"):
		camera.zoom *= 0.9
	camera.position += (Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down") * MOVEMENT_SPEED * _delta).rotated(camera.rotation)
	camera.rotation += Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise") * ROTATION_SPEED * _delta
	if absf(Input.get_axis("camera_rotate_clockwise", "camera_rotate_counterclockwise")) < 0.1 and absf(roundf(camera.rotation_degrees / 45.0) * 45.0 - camera.rotation_degrees) < 7.5:
		camera.rotation_degrees = roundf(camera.rotation_degrees / 45.0) * 45.0
	check_free_cam()

func check_free_cam() -> void:
	if Input.is_action_just_pressed("free_cam"):
		free_cam = true
		initial_mouse_pos = get_local_mouse_position()
		initial_camera_pos = camera.position
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	elif Input.is_action_just_released("free_cam"):
		initial_mouse_pos = Vector2.ZERO
		free_cam = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _input(event: InputEvent) -> void:
	if free_cam and event is InputEventMouseMotion:
		camera.position -= (event.relative / camera.zoom).rotated(camera.rotation)

func in_free_cam() -> bool:
	return free_cam
