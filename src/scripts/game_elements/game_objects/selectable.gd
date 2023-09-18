class_name Selectable
extends GameObject
## selectable.gd
##
## Defines an object that can be selected and moved by the player.

@onready var collision_polygon: CollisionPolygon2D
@onready var area2d: Area2D

# Shareable properties

## Whether or not state variables are locked, despite being selected or moved.
var lock_state: bool = false

var grab_offset: Vector2 = Vector2.ZERO

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
    return super.get_shareable_properties() + ["lock_state"] # TODO: Add selected to shareable properties

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

func _process(delta: float) -> void:
    super._process(delta)
