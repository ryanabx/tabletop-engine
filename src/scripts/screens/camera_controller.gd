extends Node2D

@onready var camera = $Camera2D
@onready var game_bg = $BoardBG

const MOVEMENT_SPEED: float = 1000.0
const ROTATION_SPEED: float = 1.0

var initial_mouse_pos: Vector2 = Vector2.ZERO
var free_cam: bool = false
var initial_camera_pos: Vector2 = Vector2.ZERO

var start_pos: Vector2

func _ready() -> void:
	SignalManager.reset_tabletop.connect(_reset_camera)
	start_pos = camera.offset

func _reset_camera() -> void:
	camera.zoom = Vector2.ONE
	camera.offset = start_pos
	game_bg.set_texture(null)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_zoom_in"):
		camera.zoom *= 1.1
	if Input.is_action_just_pressed("ui_zoom_out"):
		camera.zoom *= 0.9
	camera.offset += Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down") * MOVEMENT_SPEED * _delta
	update_bg_scale()
	check_free_cam()

func set_bg(texture: Texture2D) -> void:
	game_bg.set_texture(texture)

func update_bg_scale() -> void:
	var texture = game_bg.get_texture()
	if texture == null:
		return
	var _sc: Vector2 = Vector2(get_viewport().get_size().x / texture.get_size().x, get_viewport().get_size().y / texture.get_size().y)
	game_bg.scale = _sc / camera.zoom
	game_bg.position = camera.position + camera.offset

func check_free_cam() -> void:
	if Input.is_action_just_pressed("free_cam"):
		free_cam = true
		initial_mouse_pos = get_viewport().get_mouse_position()
		initial_camera_pos = camera.offset
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	elif Input.is_action_just_released("free_cam"):
		initial_mouse_pos = Vector2.ZERO
		free_cam = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	if free_cam:
		camera.offset = initial_camera_pos - (get_viewport().get_mouse_position() - initial_mouse_pos) / camera.zoom
		game_bg.position = camera.position
	
	camera.offset = camera.offset.clamp(Globals.get_bounds().position, Globals.get_bounds().end)

func in_free_cam() -> bool:
	return free_cam
