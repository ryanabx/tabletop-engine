extends Sprite2D

var grabbable: bool = false
var mouse_offset_vect: Vector2 = Vector2.ZERO

@onready var sprite = $Sprite

func _input(event):
	if event is InputEventMouseButton:
		if get_rect().has_point(to_local(event.position) - get_viewport_transform().origin):
			grabbable = event.pressed
			mouse_offset_vect = global_position - get_global_mouse_position()
	if event is InputEventMouseMotion:
		if get_rect().has_point(to_local(event.global_position) - get_viewport_transform().origin):
			modulate.a = 0.7
		else:
			modulate.a = 1.0

func _process(delta):
	if grabbable and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		position = get_global_mouse_position() + mouse_offset_vect
