extends Node2D

@onready var camera = $Camera2D
@onready var game_bg = $BoardBG

const MOVEMENT_SPEED: float = 10.0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_zoom_in"):
		camera.zoom *= 1.1
	if Input.is_action_just_pressed("ui_zoom_out"):
		camera.zoom *= 0.9
	camera.position += Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down") * MOVEMENT_SPEED
	update_bg_scale()

func set_bg(texture: Texture2D) -> void:
	game_bg.set_texture(texture)

func update_bg_scale() -> void:
	var texture = game_bg.get_texture()
	var _sc: Vector2 = Vector2(get_viewport().get_size().x / texture.get_size().x, get_viewport().get_size().y / texture.get_size().y)
	game_bg.scale = _sc / camera.zoom
	game_bg.position = camera.position
