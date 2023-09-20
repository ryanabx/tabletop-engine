class_name Piece
extends Selectable
## piece.gd
## 
## Represents a singular game piece. Typically extended into separate piece types.

# Shareable properties

## A list of tags for categorization of pieces in collections.
var types: Array = []

# Private methods

func _ready() -> void:
    super._ready()

func _get_shareable_properties() -> Array:
    return super._get_shareable_properties() + ["image_up", "image_down", "types", "face_up"]

func _serialize() -> Dictionary:
    var _dict: Dictionary = {}
    _dict.shape = shape
    _dict.size = size
    _dict.types = types
    _dict.object_type = object_type
    return _dict