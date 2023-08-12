class_name Gobject
extends Node2D

var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
var erased: bool = false

var gobject_scale: Vector2 = Vector2.ONE
var board: Board

## Moves this object to the top of the draw order
func move_self_to_top() -> void:
    get_parent().move_child(self, -1)

## Moves this object to the back of the draw order
func move_self_to_back() -> void:
    get_parent().move_child(self, 0)

func move_to_index(index: int) -> void:
    get_parent().move_child(self, index)

func overlaps_point(point: Vector2) -> bool:
    var full_shape: PackedVector2Array = get_extents()
    return Geometry2D.is_point_in_polygon(point, full_shape)

func get_extents() -> PackedVector2Array:
    return get_main_transform() * shape

func get_main_transform() -> Transform2D:
    return Transform2D(rotation, gobject_scale, 0.0, position)

func get_rect_extents() -> Rect2:
    return Rect2(position - scale / 2, scale)

func get_rect() -> Rect2:
    return Rect2(-scale / 2, scale)

func get_gobject_transform() -> Transform2D:
    return Transform2D().scaled(gobject_scale)

func overlaps_polygon(polygon: PackedVector2Array) -> bool:
    var full_shape: PackedVector2Array = get_extents()
    return not Geometry2D.intersect_polygons(full_shape, polygon).is_empty()