class_name Hand
extends Collection

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

var layering_factor: float = 0.9

var _spacing_interval: float = 1.0
var _selectable_piece: int = -1
var _droppable_index: int = -1

# Shareable properties
var visibility: VisibilitySetting = VisibilitySetting.DESIGNATED
var designated_players: Array[int] = []
var size_option: SizeOption = SizeOption.FIXED_LAYER

var size_pieces: Vector2 = Vector2.ONE

func get_shareable_properties() -> Array:
    return super.get_shareable_properties() + [
        "visibility", "designated_players",
        "size_option", "size_pieces",
        "layering_factor"]


func _draw() -> void:
    draw_rect(get_rect(), Color.BLACK * Color(1.0, 1.0, 1.0, 0.3))
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
    var _texture: Texture2D = board.get_image(_data.image_up if can_view() else _data.image_down)
    
    draw_texture_rect(_texture, Rect2(_position - _size / 2, _size), false)

func can_view() -> bool:
    match visibility:
        VisibilitySetting.ALL:
            return true
        VisibilitySetting.NONE:
            return false
        VisibilitySetting.DESIGNATED:
            return Globals.Player.ID in designated_players
        VisibilitySetting.NOT_DESIGNATED:
            return Globals.Player.ID not in designated_players
    return false

func add_piece(piece: Piece, back: bool = false) -> void:
    if _droppable_index == -1:
        super.add_piece(piece, back)
        return
    
    super._add_piece_at(piece, _droppable_index)

func remove_from_top(pos: Vector2) -> Piece:
    var _piece: Piece
    _find_selectable_piece(pos, false)
    if _selectable_piece == -1:
        _piece = super.remove_from_top(pos)
    else:
        _piece = super._remove_piece_at(_selectable_piece)
    _piece.position = get_global_mouse_position()
    _piece.rotation = rotation
    _piece.grab_offset = Vector2.ZERO
    _piece.face_up = true
    return _piece

func _find_spacing_interval() -> void:
    match size_option:
        SizeOption.GROW_FIXED:
            _spacing_interval = size_pieces.x * layering_factor
            if _spacing_interval * inside.size() > size.x:
                _spacing_interval = (size.x - size_pieces.x / 2.0) / (inside.size())

func _find_selectable_piece(pos: Vector2, check_boundaries: bool = true) -> void:
    if check_boundaries and (absf(pos.y) > size.y / 2.0 or absf(pos.x) > (size.x / 2.0)):
        _selectable_piece = -1
        _droppable_index = -1
        return
    
    _selectable_piece = clampi(floori((pos.x + (size.x / 2.0)) / size.x * (inside.size())), 0, inside.size())
    _droppable_index = clampi(roundi(((pos.x + (size.x / 2.0)) / size.x * (inside.size()))), 0, inside.size())
    print(_droppable_index, ":: ", _selectable_piece)

    # print("selectable object set to ",_selectable_piece)

func _process(delta: float) -> void:
    queue_redraw()
    _find_spacing_interval()
    _find_selectable_piece(get_local_mouse_position())
    super._process(delta)
