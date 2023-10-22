class_name Piece
extends GameObject
## piece.gd
## 
## Represents a singular game piece. Typically extended into separate piece types.

# Shareable properties

## A list of tags for categorization of pieces in collections.
var types: Array = []

# Private methods

func _ready() -> void:
    _shareable_properties.append_array(["image_up", "image_down", "types", "face_up"])
    super._ready()

func _serialize() -> Dictionary:
    var _dict: Dictionary = {}
    _dict.shape = shape
    _dict.size = size
    _dict.types = types
    _dict.object_type = object_type
    return _dict