extends Sprite2D

var grabbable: bool = false
var mouse_offset_vect: Vector2 = Vector2.ZERO

@onready var sprite = $Sprite

func _input(event):
	if event is InputEventMouseButton:
		if get_rect().has_point(to_local(event.position)):
			grabbable = event.pressed
			mouse_offset_vect = position - get_global_mouse_position()

func _process(delta):
	if grabbable and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		position = get_global_mouse_position() + mouse_offset_vect
