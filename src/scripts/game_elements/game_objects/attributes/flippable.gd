class_name Flippable
extends Attribute

var face_up: bool = false

func name() -> String: return "flippable"
func shareable_properties() -> Array[String]: return ["flippable::face_up"]

func flip() -> void:
    face_up = not face_up

func set_orientation(orientation: bool) -> void:
    face_up = orientation

func _init(_obj: GameObject) -> void:
    obj = _obj