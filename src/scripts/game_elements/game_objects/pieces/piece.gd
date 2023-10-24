class_name Piece
extends GameObject
## piece.gd
## 
## Represents a singular game piece. Typically extended into separate piece types.

# Private methods

func _ready() -> void:
    _shareable_properties.append_array(["image_up", "image_down", "types", "face_up"])
    # Traits
    object_traits["has_shape"] = ObjectTraits.HasShape.new(self)
    object_traits["selectable"] = ObjectTraits.Selectable.new(self)
    super._ready()

func _serialize() -> Dictionary:
    var _dict: Dictionary = {}
    _dict.shape = (get_trait("has_shape") as ObjectTraits.HasShape).shape
    _dict.size = (get_trait("has_shape") as ObjectTraits.HasShape).size
    _dict.object_type = object_type
    return _dict