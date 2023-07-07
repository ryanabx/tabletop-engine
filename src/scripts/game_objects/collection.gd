class_name GameCollection
extends Sprite2D

@onready var collision_area = $CollisionArea
@onready var collision_box = $CollisionArea/CollisionBox

func _ready() -> void:
	collision_box.shape.size = get_rect().size # Set collision box to match the sprite
