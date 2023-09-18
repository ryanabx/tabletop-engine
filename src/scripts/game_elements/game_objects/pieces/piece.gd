class_name Piece
extends Selectable
## piece.gd
## 
## Represents a singular game piece. Typically extended into separate piece types.

# TODO: Piece split into multiple types

# Shareable properties
var image_up: String = ""
var image_down: String = ""
var types: Array = []

var face_up: bool:
    set(val):
        face_up = val
        add_to_property_changes("face_up", val)
        _refresh_image()

@onready var sprite: Sprite2D

func _ready() -> void:
    # Sprite stuff
    sprite = Sprite2D.new()
    add_child(sprite)
    _refresh_image()
    super._ready()

@rpc("any_peer","call_local","reliable")
func _erase_rpc(_recursive: bool = false) -> void:
    queue_free()

func _get_shareable_properties() -> Array:
    return super._get_shareable_properties() + ["image_up", "image_down", "types", "face_up"]

# Private methods

func _refresh_image() -> void:
    if image_up == "" or image_down == "":
        return
    if board == null or board.game == null or board.get_image(image_up) == null or board.get_image(image_down) == null\
        or not is_instance_valid(sprite):
            return
    
    sprite.texture = board.game.get_images()[image_up] if face_up else board.game.get_images()[image_down]
    sprite.scale = size / sprite.texture.get_size()

func _on_select(_event:InputEvent) -> void:
    board.board_player.queue_select_object(self)

func _on_deselect(_event: InputEvent) -> void:
    board.board_player.stack_selection_to_item(self)

func _on_multiplayer_synchronizer_synchronized() -> void:
    _refresh_image()

func _serialize() -> Dictionary:
    var _dict: Dictionary = {}
    for prop in ["shape", "size", "image_up", "image_down", "types"]:
        _dict[prop] = get(prop)
    return _dict
