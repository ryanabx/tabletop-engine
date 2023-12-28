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

var _card_to_select: int = -1

# Shareable properties
## Determines the visibility of the hand. See [enum Hand.VisibilitySetting]
var visibility: VisibilitySetting = VisibilitySetting.DESIGNATED
## If visibility is set to [member Hand.VisibilitySetting.DESIGNATED] or [member Hand.VisibilitySetting.NOT_DESIGNATED],
## the visibility will be determined by the player numbers defined here.
var designated_players: Array = []
var size_option: SizeOption = SizeOption.FIXED_LAYER

## Determines the fixed size of each [class Piece] displayed in this hand.
var size_pieces: Vector2 = Vector2.ONE

func _draw() -> void:
    draw_rect(get_attribute("has_shape").get_rect(), Color.BLACK * Color(1.0, 1.0, 1.0, 0.3))
    if can_view():
        draw_rect(get_attribute("has_shape").get_rect(), Color.WHITE * Color(1.0, 1.0, 1.0, 0.3), false, Global.COLLECTION_OUTLINE)
    _draw_pieces()

func _ready() -> void:
    _shareable_properties.append_array([
        "visibility", "designated_players",
        "size_option", "size_pieces",
        "layering_factor"])
    add_attribute(Flippable.new(self))
    super._ready()

func _draw_pieces() -> void:
    var i: int = 0
    for pc: Dictionary in inside:
        if i == _selectable_piece:
            i += 1
            continue
        # (size.x - size_pieces.x / 2.0) / (inside.size())
        var card_position: Vector2 = Vector2(
            lerp(get_attribute("has_shape").get_rect().position.x + size_pieces.x / 2.0, get_attribute("has_shape").get_rect().end.x - size_pieces.x / 2.0, (i + 0.5) / inside.size()) as float,
            get_attribute("has_shape").get_rect().get_center().y
        )
        _draw_piece(pc, (i == _selectable_piece), card_position)
        i += 1
    if _selectable_piece != -1 and _selectable_piece < inside.size():
        var card_position: Vector2 = Vector2(
            lerp(get_attribute("has_shape").get_rect().position.x + size_pieces.x / 2.0, get_attribute("has_shape").get_rect().end.x - size_pieces.x / 2.0, (_selectable_piece + 0.5) / inside.size()) as float,
            get_attribute("has_shape").get_rect().get_center().y
        )
        _draw_piece(inside[_selectable_piece], true, card_position)

## Draws a piece from data at a certain position
func _draw_piece(_data: Dictionary, _selectable: bool, _position: Vector2, _size: Vector2 = size_pieces) -> void:
    if _selectable:
        _size = _size * 1.1
    var img_up: String = _data.image_up
    var img_down: String = _data.image_down
    var _texture: Texture2D = board._get_image(img_up if can_view() else img_down)
    
    draw_texture_rect(_texture, Rect2(_position - _size / 2, _size), false)

func _get_selected_range() -> Rect2:
    if _selectable_piece == -1:
        return Rect2(0, 0, 0, 0)
    var _position: Vector2 = Vector2(
        lerp(get_attribute("has_shape").get_rect().position.x + size_pieces.x / 2.0, get_attribute("has_shape").get_rect().end.x - size_pieces.x / 2.0, (_selectable_piece + 0.5) / inside.size()) as float,
        get_attribute("has_shape").get_rect().get_center().y
    )
    var _size: Vector2 = size_pieces * 1.1
    var rect: Rect2 = Rect2(_position - _size / 2, _size)
    return rect

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
    if _card_to_select == -1:
        _find_selectable_piece(pos, false)
    if _selectable_piece == -1:
        _piece = super.remove_from_top(pos)
    else:
        _piece = super._remove_piece_at(_selectable_piece)
    _piece.position = get_global_mouse_position()
    _piece.rotation = rotation
    _piece.selectable.grab_offset = Vector2.ZERO
    if _piece.get_attribute("flippable"):
        _piece.get_attribute("flippable").set_orientation(not get_attribute("flippable") or get_attribute("flippable").face_up)
    return _piece

func _find_spacing_interval() -> void:
    match size_option:
        SizeOption.GROW_FIXED:
            _spacing_interval = size_pieces.x * layering_factor
            if _spacing_interval * inside.size() > get_attribute("has_shape").size.x:
                _spacing_interval = (get_attribute("has_shape").size.x - size_pieces.x / 2.0) / (inside.size())

func _find_selectable_piece(pos: Vector2, check_boundaries: bool = true) -> void:
    if board.input_mode == Board.InputMode.CAMERA or (check_boundaries and (absf(pos.y) > get_attribute("has_shape").size.y / 2.0 or absf(pos.x) > (get_attribute("has_shape").size.x / 2.0))):
        _reset_selectable_piece()
        return

    var check: float = ((pos.x + (get_attribute("has_shape").size.x / 2.0) - (size_pieces.x / 2.0)) / (get_attribute("has_shape").size.x - size_pieces.x)) * inside.size()
    
    _selectable_piece = clampi(floori(check), 0, inside.size() - 1)
    _droppable_index = clampi(roundi(check), 0, inside.size())

    # print("selesctable object set to ",_selectable_piece)

func deserialize_object(dict: Dictionary) -> GameObject:
    var piece: Piece = super.deserialize_object(dict)
    piece._authority = multiplayer.get_unique_id()
    return piece

func _reset_selectable_piece() -> void:
    _selectable_piece = -1
    _droppable_index = -1

func _process(delta: float) -> void:
    queue_redraw()
    _find_spacing_interval()
    if get_attribute("selectable").queued == 0 and get_attribute("selectable").selected == 0:
        _card_to_select = -1
        if board.touch_type == Board.TouchType.DRAG or (board.touch_type == Board.TouchType.TAP and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
            _find_selectable_piece(get_local_mouse_position())
        else:
            _reset_selectable_piece()
    else:
        _selectable_piece = _card_to_select
    super._process(delta)

class HandSelectable extends Collection.CollectionSelectable:
    func on_select(_event:InputEvent) -> void:
        if obj.inside.is_empty() or selected != 0 or queued != 0:
            return
        obj.board.get_player().queue_select_object(obj)
        obj._find_selectable_piece(obj.get_local_mouse_position())
        obj._card_to_select = obj._selectable_piece
        print("Selectable piece found and locked: ",obj._card_to_select)
