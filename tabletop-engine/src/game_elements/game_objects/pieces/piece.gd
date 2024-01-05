class_name Piece
extends GameObject
## piece.gd
## 
## Represents a singular game piece. Typically extended into separate piece types.

# Private methods

func _ready() -> void:
    # Traits
    add_attribute(HasShape.new(self))
    add_attribute(Selectable.new(self))
    super._ready()