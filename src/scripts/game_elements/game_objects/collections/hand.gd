class_name Hand
extends Collection
## hand.gd
##
## Defines a [class Collection] which displays its pieces in a row.
## Often useful for player's hands within a game.

## Types of visibility for a hand.[br]
## [member Hand.VisibilitySetting.ALL] Every player can see what's in the hand.
## [member Hand.VisibilitySetting.DESIGNATED] Only players designated in [member Hand.designated_players] can view.
## [member Hand.VisibilitySetting.NOT_DESIGNATED] Opposite of [member Hand.VisibilitySetting.DESIGNATED].
## [member Hand.VisibilitySetting.NONE] No player can view what's in the hand.
enum VisibilitySetting {
    ALL,
    DESIGNATED,
    NOT_DESIGNATED,
    NONE
}

enum SizeOption {
    FIXED_LAYER,
    FIXED_RESIZE,
    GROW_FIXED,
    GROW_UNLIMITED
}

## Determines the overlap between pieces when space is not limited.
## When space is limited (i.e. too many pieces), then this option is ignored.
var layering_factor: float = 0.9

var _spacing_interval: float = 1.0
var _selectable_piece: int = -1
var _droppable_index: int = -1

# Shareable properties
## Determines the visibility of the hand. See [enum Hand.VisibilitySetting]
var visibility: VisibilitySetting = VisibilitySetting.DESIGNATED
## If visibility is set to [member Hand.VisibilitySetting.DESIGNATED] or [member Hand.VisibilitySetting.NOT_DESIGNATED],
## the visibility will be determined by the player numbers defined here.
var designated_players: Array = []
var size_option: SizeOption = SizeOption.FIXED_LAYER

## Determines the fixed size of each [class Piece] displayed in this hand.
var size_pieces: Vector2 = Vector2.ONE

func _get_shareable_properties() -> Array:
    return super._get_shareable_properties() + [
        "visibility", "designated_players",
        "size_option", "size_pieces",
        "layering_factor"]


func _draw() -> void:
    draw_rect(get_rect(), Color.BLACK * Color(1.0, 1.0, 1.0, 0.3))
    if can_view():
        draw_rect(get_rect(), Color.WHITE * Color(1.0, 1.0, 1.0, 0.3), false, Globals.COLLECTION_OUTLINE)
    _draw_pieces()


func _draw_pieces() -> void:
    var i: int = 0
    for pc: Dictionary in inside:
        if i == _selectable_piece:
            i += 1
            continue
        # (size.x - size_pieces.x / 2.0) / (inside.size())
        var card_position: Vector2 = Vector2(
            lerp(get_rect().position.x + size_pieces.x / 2.0, get_rect().end.x - size_pieces.x / 2.0, (i + 0.5) / inside.size()),
            get_rect().get_center().y
        )
        _draw_piece(pc, (i == _selectable_piece), card_position)
        i += 1
    if _selectable_piece != -1 and _selectable_piece < inside.size():
        var card_position: Vector2 = Vector2(
            lerp(get_rect().position.x + size_pieces.x / 2.0, get_rect().end.x - size_pieces.x / 2.0, (_selectable_piece + 0.5) / inside.size()),
            get_rect().get_center().y
        )
        _draw_piece(inside[_selectable_piece], true, card_position)

## Draws a piece from data at a certain position
func _draw_piece(_data: Dictionary, selectable: bool, _position: Vector2, _size: Vector2 = size_pieces) -> void:
    if selectable:
        _size = _size * 1.1
    var _texture: Texture2D = board._get_image(_data.image_up if can_view() else _data.image_down)
    
    draw_texture_rect(_texture, Rect2(_position - _size / 2, _size), false)

func can_view() -> bool:
    match visibility:
        VisibilitySetting.ALL:
            return true
        VisibilitySetting.NONE:
            return false
        VisibilitySetting.DESIGNATED:
            return designated_players.has(board.player_id + 1)
        VisibilitySetting.NOT_DESIGNATED:
            return not designated_players.has(board.player_id + 1)
    return false

func add_piece(piece: Piece, back: bool = false) -> void:
    if _droppable_index == -1:
        super.add_piece(piece, back)
        return
    
    super._add_piece_at(piece, _droppable_index)

func add_collection(coll: Collection, back: bool = false) -> void:
    if _droppable_index == -1:
        super.add_collection(coll, back)
        return
    
    super._add_collection_at(coll, _droppable_index)

func remove_from_top(pos: Vector2 = Vector2.ZERO) -> Piece:
    var _piece: Piece
    _find_selectable_piece(pos, false)
    if _selectable_piece == -1:
        _piece = super.remove_from_top(pos)
    else:
        _piece = super._remove_piece_at(_selectable_piece)
    _piece.position = get_global_mouse_position()
    _piece.rotation = rotation
    _piece.grab_offset = Vector2.ZERO
    _piece.face_up = face_up
    return _piece

func _find_spacing_interval() -> void:
    match size_option:
        SizeOption.GROW_FIXED:
            _spacing_interval = size_pieces.x * layering_factor
            if _spacing_interval * inside.size() > size.x:
                _spacing_interval = (size.x - size_pieces.x / 2.0) / (inside.size())

func _find_selectable_piece(pos: Vector2, check_boundaries: bool = true) -> void:
    if board.input_mode == Board.InputMode.CAMERA or (check_boundaries and (absf(pos.y) > size.y / 2.0 or absf(pos.x) > (size.x / 2.0))):
        _selectable_piece = -1
        _droppable_index = -1
        return

    var check := ((pos.x + (size.x / 2.0) - (size_pieces.x / 2.0)) / (size.x - size_pieces.x)) * inside.size()
    
    _selectable_piece = clampi(floori(check), 0, inside.size() - 1)
    _droppable_index = clampi(roundi(check), 0, inside.size())

    # print("selectable object set to ",_selectable_piece)

func _process(delta: float) -> void:
    queue_redraw()
    _find_spacing_interval()
    _find_selectable_piece(get_local_mouse_position())
    super._process(delta)
