class_name Collection
extends Selectable
## collection.gd
##
## Defines an object that contains pieces within it.

# Shareable properties
## The list of serialized pieces that are inside this collection.
var inside: Array[Dictionary] = []
## Determines whether the pieces inside the collection come out face up or not.
## If [member Selectable.lock_state] is true, the collection's [member face_up] value remains constant.
var face_up: bool = false

## Adds a given [param piece] to the collection.
## Added to the front by default, use [param back] to specify.
func add_piece(piece: Piece, back: bool = false) -> void:
    if back:
        _add_piece_at(piece, 0)
    else:
        _add_piece_at(piece, inside.size())

## Remove a piece from the top of the collection.
## [param position] specifies the position that the player is removing the piece from.
func remove_from_top(_position: Vector2 = Vector2.ZERO) -> Piece:
    if inside.size() == 0:
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

func _serialize_piece(pc: Piece) -> Dictionary:
    return pc._serialize()

func _deserialize_piece(_dict: Dictionary) -> Piece:
    _dict.position = position
    _dict.rotation = rotation
    return board.new_game_object(
        board.GameObjectType.PIECE,
        _dict
    )

func _get_shareable_properties() -> Array:
    return super._get_shareable_properties() + ["inside", "face_up"]

func _ready() -> void:
    super._ready()

@rpc("authority","call_local","reliable")
func _erase_rpc(recursive: bool = false) -> void:
    for obj: Dictionary in inside:
        if not recursive and is_multiplayer_authority():
            _deserialize_piece(obj)
    queue_free()

func _clear_inside() -> void:
    _authority = multiplayer.get_unique_id()
    inside = []
    add_to_property_changes("inside", inside)

func _on_select(_event:InputEvent) -> void:
    if get_inside().is_empty():
        return
    board.board_player.queue_select_object(self)

func _on_deselect(_event:InputEvent) -> void:
    if board.board_player.is_selecting():
        if selected == false:
            board.board_player.stack_selection_to_item(self)

func _process(delta: float) -> void:
    super._process(delta)

func _add_piece_at(piece: Piece, _index: int) -> void:
    if not board.game.can_stack_piece(piece, self):
        return
    _authority = multiplayer.get_unique_id()
    piece._authority = multiplayer.get_unique_id()
    
    var pc_d: Dictionary = _serialize_piece(piece)
    piece._erase_rpc.rpc()
    inside.insert(_index, pc_d)
    add_to_property_changes("inside", inside)

func _remove_piece_at(_index: int) -> Piece:
    if not board.game.can_take_piece_off(self):
        return null
    _authority = multiplayer.get_unique_id()
    var pc_d: Dictionary = inside.pop_at(_index)
    add_to_property_changes("inside", inside)
    var piece: Piece = _deserialize_piece(pc_d)
    piece._authority = multiplayer.get_unique_id()
    piece.position = position
    piece.rotation = rotation
    return piece