class_name Collection
extends GameObject
## collection.gd
##
## Defines an object that contains pieces within it.

var types: Array = [] # Currently just for compatibility. TODO: Remove

# Shareable properties
## The list of serialized pieces that are inside this collection.
var inside: Array[Dictionary] = []

## Adds a given [param piece] to the collection.
## Added to the front by default, use [param back] to specify.
func add_piece(piece: Piece, back: bool = false) -> void:
    if back:
        _add_piece_at(piece, 0)
    else:
        _add_piece_at(piece, inside.size())

## Adds a given [param coll] to the collection.
## Added to the front by default, use [param back] to specify.
func add_collection(coll: Collection, back: bool = false) -> void:
    if back:
        _add_collection_at(coll, 0)
    else:
        _add_collection_at(coll, inside.size())

## Remove a piece from the top of the collection.
## [param position] specifies the position that the player is removing the piece from.
func remove_from_top(_position: Vector2 = Vector2.ZERO) -> Piece:
    if inside.size() == 0:
        print("Inside size is 0")
        return null
    return _remove_piece_at(inside.size() - 1)

## Returns the serialized list of [class Piece] in the collection.
func get_inside() -> Array[Dictionary]:
    return inside

## Shuffles the pieces inside of the collection.
func shuffle() -> void:
    _authority = multiplayer.get_unique_id()
    inside.shuffle()
    add_to_property_changes("inside", inside)

# Private methods

func _ready() -> void:
    _shareable_properties.append_array(["inside"])
    add_attribute(CollectionSelectable.new(self))
    super._ready()

@rpc("authority","call_local","reliable")
func _erase_rpc(recursive: bool = false) -> void:
    for obj: Dictionary in inside:
        if not recursive and is_multiplayer_authority():
            deserialize_object(obj)
    queue_free()

func deserialize_object(dict: Dictionary) -> GameObject:
    dict.position = position
    dict.rotation = rotation
    var piece: Piece = super.deserialize_object(dict)
    piece._authority = multiplayer.get_unique_id()
    return piece

func _clear_inside() -> void:
    _authority = multiplayer.get_unique_id()
    inside = []
    add_to_property_changes("inside", inside)

class CollectionSelectable extends Selectable:
    func on_select(_event:InputEvent) -> void:
        if obj.inside.is_empty():
            return
        super.on_select(_event)

func _process(delta: float) -> void:
    super._process(delta)

func _add_piece_at(piece: Piece, _index: int) -> void:
    if not board.game.can_stack(piece, self):
        return
    _authority = multiplayer.get_unique_id()
    piece._authority = multiplayer.get_unique_id()
    
    var pc_d: Dictionary = piece.serialize_object()
    piece._erase_rpc.rpc(false)
    inside.insert(_index, pc_d)
    add_to_property_changes("inside", inside)

func _add_collection_at(coll: Collection, _index: int) -> void:
    if not board.game.can_stack(coll, self):
        return
    if coll.get_attribute("flippable") and get_attribute("flippable") and coll.get_attribute("flippable").face_up != get_attribute("flippable").face_up:
        coll.get_attribute("flippable").flip()
    if _index == inside.size():
        inside.append_array(coll.inside)
    else:
        inside = inside.slice(0, _index) + coll.inside + inside.slice(_index, inside.size())
    add_to_property_changes("inside",inside)
    coll._clear_inside()

func _remove_piece_at(_index: int) -> Piece:
    if not board.game.can_take_piece_off(self):
        return null
    _authority = multiplayer.get_unique_id()
    var pc_d: Dictionary = inside.pop_at(_index)
    add_to_property_changes("inside", inside)
    var piece: Piece = deserialize_object(pc_d)
    return piece
