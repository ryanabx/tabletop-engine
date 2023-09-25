class_name Flat
extends Piece
## flat.gd
## 
## Defines a piece that can be flipped (has 2 sides)

# Private variables

@onready var _sprite: Sprite2D

## The image string for the face up side of the flat object.
var image_up: String = ""
## The image string for the face down side of the flat object.
var image_down: String = ""
## Whether the object is face up or not.
var face_up: bool:
    set(val):
        face_up = val
        _refresh_image()
        add_to_property_changes("face_up", val)

func _on_multiplayer_synchronizer_synchronized() -> void:
    _refresh_image()

func _refresh_image() -> void:
    if image_up == "" or image_down == "":
        return
    if board == null or board.game == null or board._get_image(image_up) == null or board._get_image(image_down) == null\
        or not is_instance_valid(_sprite):
            return
    
    _sprite.texture = board._get_image(image_up) if face_up else board._get_image(image_down)
    _sprite.scale = size / _sprite.texture.get_size()

func _serialize() -> Dictionary:
    var _dict: Dictionary = super._serialize()
    _dict.image_up = image_up
    _dict.image_down = image_down
    _dict.face_up = face_up
    return _dict

func _ready() -> void:
    # Sprite stuff
    _sprite = Sprite2D.new()
    add_child(_sprite)
    _refresh_image()
    super._ready()
