class_name Selectable
extends Attribute

var _collision_polygon: CollisionPolygon2D
var _area2d: Area2D

var lock_state: bool = false
var grab_offset: Vector2 = Vector2.ZERO

func name() -> String: return "selectable"

func shareable_properties() -> Array[String]: return ["selectable::lock_state", "selectable::selected", "selectable::queued"]

var selected: int = 0:
    set(val):
        selected = val
        if val != 0:
            _area2d.collision_layer = 2
        else:
            _area2d.collision_layer = 1
        obj.add_to_property_changes("selectable::selected", selected)
    get:
        return selected

var queued: int = 0:
    set(val):
        queued = val
        obj.add_to_property_changes("selectable::queued", queued)
    get:
        return queued

func on_select(_event:InputEvent) -> void:
    if selected == 0 and queued == 0:
        obj.board.get_player().queue_select_object(obj)
    else:
        print("Selected: %d, Queued: %d" % [selected, queued])

func on_deselect(_event: InputEvent) -> void:
    obj.board.get_player().stack_selection_to_item(obj)

func _init(_obj: GameObject) -> void:
    obj = _obj
    # Collision stuff
    _area2d = Area2D.new()
    _area2d.monitorable = false
    _area2d.monitoring = false
    _area2d.input_pickable = true
    _area2d.collision_layer = 1
    obj.add_child(_area2d)
    _collision_polygon = CollisionPolygon2D.new()
    if obj.get_attribute("has_shape"):
        _collision_polygon.polygon = (obj.get_attribute("has_shape") as HasShape).get_gobject_transform.call() * (obj.get_attribute("has_shape") as HasShape).shape
    _area2d.add_child(_collision_polygon)