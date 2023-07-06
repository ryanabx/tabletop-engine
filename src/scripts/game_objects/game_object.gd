class_name GameObject
extends Sprite2D

var grabbable: bool = false
var mouse_offset_vect: Vector2 = Vector2.ZERO

@onready var sprite = $Sprite
@onready var collision_box = $CollisionArea/CollisionBox

func _ready():
	collision_box.shape.size = get_rect().size

func _on_collision_area_mouse_entered():
	print("Mouse here")
	modulate.a = 0.8

func _on_collision_area_mouse_exited():
	print("Mouse out")
	modulate.a = 1.0
