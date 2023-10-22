class_name Selectable
extends RefCounted

var obj: GameObject

var _collision_polygon: CollisionPolygon2D
var _area2d: Area2D

var lock_state: bool = false
var grab_offset: Vector2 = Vector2.ZERO

var _on_select: Callable
var _on_deselect: Callable

func _init(_obj: GameObject, __on_select: Callable = _on_select_default, __on_deselect: Callable = _on_deselect_default) -> void:
    obj = _obj
    _on_select = __on_select
    _on_deselect = __on_deselect
    # Collision stuff
    _area2d = Area2D.new()
    _area2d.monitorable = false
    _area2d.monitoring = false
    _area2d.input_pickable = true
    _area2d.collision_layer = 1
    obj.add_child(_area2d)
    _collision_polygon = CollisionPolygon2D.new()
    _collision_polygon.polygon = obj.get_gobject_transform() * obj.shape
    _area2d.add_child(_collision_polygon)

var selected: int = 0:
    set(val):
        selected = val
        if val != 0:
            _area2d.collision_layer = 2
        else:
            _area2d.collision_layer = 1
        obj.add_to_property_changes("selectable.selected", selected)
    get:
        return selected

var queued: int = 0:
    set(val):
        queued = val
        obj.add_to_property_changes("selectable.queued", queued)
    get:
        return queued

func _on_select_default(_event:InputEvent) -> void:
    if selected == 0 and queued == 0:
        obj.board.get_player().queue_select_object(obj)
    else:
        print("Selected: %d, Queued: %d" % [selected, queued])

func _on_deselect_default(_event: InputEvent) -> void:
    obj.board.get_player().stack_selection_to_item(obj)

func get_trait_shareable_properties() -> Array[String]:
    return ["selectable.lock_state", "selectable.selected", "selectable.queued"]