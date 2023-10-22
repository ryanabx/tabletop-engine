class_name Flippable
extends RefCounted

var obj: GameObject
var flip: Callable
var set_orientation: Callable

var face_up: bool = false


func _init(_obj: GameObject, _flip: Callable = flip_default, _set_orientation: Callable = set_orientation_default) -> void:
    obj = _obj
    flip = _flip
    set_orientation = _set_orientation

func flip_default() -> void:
    face_up = not face_up
    obj.add_to_property_changes("flippable.face_up", face_up)

func set_orientation_default(orientation: bool) -> void:
    face_up = orientation
    obj.add_to_property_changes("flippable.face_up", face_up)

func get_trait_shareable_properties() -> Array[String]:
    return ["flippable.face_up"]