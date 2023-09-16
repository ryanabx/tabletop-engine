class_name Collection
extends Selectable

# Shareable properties
var inside: Array[Dictionary] = []

func serialize_piece(pc: Piece) -> Dictionary:
    return pc.serialize()

func deserialize_piece(_dict: Dictionary) -> Piece:
    _dict.position = position
    _dict.rotation = rotation
    return board.new_game_object(
        board.GameObjectType.PIECE,
        _dict
    )

func get_shareable_properties() -> Array:
    return super.get_shareable_properties() + ["inside"]

func _ready() -> void:
    super._ready()

func add_piece(piece: Piece, back: bool = false) -> void:
    if back:
        _add_piece_at(piece, 0)
    else:
        _add_piece_at(piece, inside.size())

func _add_piece_at(piece: Piece, _index: int) -> void:
    if not board.game.can_stack_piece(piece, self):
        return
    authority = multiplayer.get_unique_id()
    piece.authority = multiplayer.get_unique_id()
    
    var pc_d: Dictionary = serialize_piece(piece)
    piece.erase_self.rpc()
    inside.insert(_index, pc_d)
    add_to_property_changes("inside", inside)

func remove_from_top(_position: Vector2) -> Piece:
    if inside.size() == 0:
        return null
    return _remove_piece_at(inside.size() - 1)

func _remove_piece_at(_index: int) -> Piece:
    if not board.game.can_take_piece_off(self):
        return null
    authority = multiplayer.get_unique_id()
    var pc_d: Dictionary = inside.pop_at(_index)
    add_to_property_changes("inside", inside)
    var piece: Piece = deserialize_piece(pc_d)
    piece.authority = multiplayer.get_unique_id()
    piece.position = position
    piece.rotation = rotation
    return piece

func get_inside() -> Array[Dictionary]:
    return inside

func shuffle() -> void:
    authority = multiplayer.get_unique_id()
    inside.shuffle()
    add_to_property_changes("inside", inside)

@rpc("authority","call_local","reliable")
func erase_self() -> void:
    for obj: Dictionary in inside:
        if is_multiplayer_authority():
            deserialize_piece(obj)
    queue_free()

func clear_inside() -> void:
    authority = multiplayer.get_unique_id()
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