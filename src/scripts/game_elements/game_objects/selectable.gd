class_name Selectable
extends GameObject

@onready var collision_polygon: CollisionPolygon2D
@onready var area2d: Area2D

# Shareable properties
var lock_state: bool = false

func _ready() -> void:
	# Collision stuff
	area2d = Area2D.new()
	area2d.monitorable = false
	area2d.monitoring = false
	area2d.input_pickable = true
	area2d.collision_layer = 1
	add_child(area2d)
	collision_polygon = CollisionPolygon2D.new()
	collision_polygon.polygon = get_gobject_transform() * self.shape
	area2d.add_child(collision_polygon)
	super._ready()

func get_shareable_properties() -> Array:
	return super.get_shareable_properties() + ["lock_state"]

var selected: bool = false:
	set(val):
		authority = multiplayer.get_unique_id()
		if val == true:
			selected = true
			area2d.collision_layer = 2
		else:
			selected = false
			area2d.collision_layer = 1
	get:
		return selected
