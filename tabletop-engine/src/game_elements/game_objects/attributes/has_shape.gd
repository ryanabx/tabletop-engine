class_name HasShape
extends Attribute

var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
var size: Vector2 = Vector2.ONE

func trait_name() -> String: return "has_shape"

func shareable_properties() -> Array[String]: return ["has_shape.shape", "has_shape.size"]

func get_extents() -> PackedVector2Array:
    return get_main_transform.call() * shape

func get_polyline_extents() -> PackedVector2Array:
    var arr: PackedVector2Array = get_extents()
    return arr + PackedVector2Array([arr[0]])

func get_main_transform() -> Transform2D:
    return Transform2D(obj.rotation, size, 0.0, obj.position)

func get_rect_extents() -> Rect2:
    return Rect2(obj.position - size / 2, size)

func get_rect() -> Rect2:
    return Rect2(-size / 2, size)

func get_gobject_transform() -> Transform2D:
    return Transform2D().scaled(size)

func _init(_obj: GameObject) -> void:
    obj = _obj