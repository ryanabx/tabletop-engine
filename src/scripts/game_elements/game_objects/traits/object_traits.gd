class_name ObjectTraits
extends RefCounted

## Generic object trait definition. Must contain shareable_properties()
class ObjectTrait extends RefCounted:
    func shareable_properties() -> Array[String]: return []

class Flippable extends ObjectTrait:
    var obj: GameObject
    var face_up: bool = false

    func shareable_properties() -> Array[String]: return ["flippable.face_up"]
    
    var flip: Callable = func() -> void:
        face_up = not face_up
        obj.add_to_property_changes("flippable.face_up", face_up)
    
    var set_orientation: Callable = func(orientation: bool) -> void:
        face_up = orientation
        obj.add_to_property_changes("flippable.face_up", face_up)
    
    func _init(_obj: GameObject) -> void:
        obj = _obj

class Selectable extends ObjectTrait:
    var obj: GameObject
    
    var _collision_polygon: CollisionPolygon2D
    var _area2d: Area2D

    var lock_state: bool = false
    var grab_offset: Vector2 = Vector2.ZERO

    func shareable_properties() -> Array[String]: return ["selectable.lock_state", "selectable.selected", "selectable.queued"]

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

    var on_select: Callable = func(_event:InputEvent) -> void:
        if selected == 0 and queued == 0:
            obj.board.get_player().queue_select_object(obj)
        else:
            print("Selected: %d, Queued: %d" % [selected, queued])

    var on_deselect: Callable = func(_event: InputEvent) -> void:
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
        if obj.get_trait("has_shape"):
            _collision_polygon.polygon = (obj.get_trait("has_shape") as HasShape).get_gobject_transform.call() * (obj.get_trait("has_shape") as HasShape).shape
        _area2d.add_child(_collision_polygon)

class HasShape extends ObjectTrait:
    var obj: GameObject
    var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
    var size: Vector2 = Vector2.ONE

    func shareable_properties() -> Array[String]: return ["has_shape.shape", "has_shape.size"]

    var get_extents: Callable = func() -> PackedVector2Array:
        return get_main_transform.call() * shape

    var get_polyline_extents: Callable = func() -> PackedVector2Array:
        var arr: PackedVector2Array = get_extents.call()
        return arr + PackedVector2Array([arr[0]])

    var get_main_transform: Callable = func() -> Transform2D:
        return Transform2D(obj.rotation, size, 0.0, obj.position)

    var get_rect_extents: Callable = func() -> Rect2:
        return Rect2(obj.position - size / 2, size)

    var get_rect: Callable = func() -> Rect2:
        return Rect2(-size / 2, size)

    var get_gobject_transform: Callable = func() -> Transform2D:
        return Transform2D().scaled(size)
    
    func _init(_obj: GameObject) -> void:
        obj = _obj