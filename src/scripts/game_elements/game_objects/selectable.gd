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

func _get_shareable_properties() -> Array:
    return super._get_shareable_properties() + ["lock_state", "selected", "queued"]

var selected: int = 0:
    set(val):
        _authority = multiplayer.get_unique_id()
        selected = val
        if val != 0:
            area2d.collision_layer = 2
        else:
            area2d.collision_layer = 1
        add_to_property_changes("selected", selected)
    get:
        return selected

var queued: int = 0:
    set(val):
        _authority = multiplayer.get_unique_id()
        queued = val
        add_to_property_changes("queued", queued)
    get:
        return queued

func _on_select(_event:InputEvent) -> void:
    if selected == 0 and queued == 0:
        board.board_player.queue_select_object(self)

func _on_deselect(_event: InputEvent) -> void:
    board.board_player.stack_selection_to_item(self)

func _process(delta: float) -> void:
    super._process(delta)
