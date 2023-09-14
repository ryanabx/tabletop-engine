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
var _selectable_object: int = -1

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
        _draw_piece(pc, (i == _selectable_object), Vector2(-size.x / 2.0 + i * _spacing_interval, -size.y / 2.0))
        i += 1

## Draws a piece from data at a certain position
func _draw_piece(_data: Dictionary, selectable: bool, _position: Vector2, _size: Vector2 = size_pieces) -> void:
    if selectable:
        _size = _size * 1.1
    var _texture: Texture2D = board.get_image(_data.image_up if can_view() else _data.image_down)
    
    draw_texture_rect(_texture, Rect2(_position, _size), false)

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
    if _selectable_object == -1:
        super.add_piece(piece, back)
        return
    
    _add_piece_at(piece, _selectable_object)

func _find_spacing_interval() -> void:
    match size_option:
        SizeOption.GROW_FIXED:
            _spacing_interval = size_pieces.x * layering_factor
            if _spacing_interval * inside.size() > size.x:
                _spacing_interval = size.x / inside.size()

func _find_selectable_piece(_position: Vector2) -> void:
    if absf(_position.y) > size.y / 2.0 or absf(_position.x) > (size.x + size_pieces.x) / 2.0:
        _selectable_object = -1
        return
    
    _selectable_object = floor(((_position.x + (size.x / 2.0)) / (_spacing_interval * inside.size())) * inside.size())
    if _selectable_object < 0 or _selectable_object >= inside.size():
        _selectable_object = -1
    print("selectable object set to ",_selectable_object)

func _process(delta: float) -> void:
    queue_redraw()
    _find_spacing_interval()
    _find_selectable_piece(get_local_mouse_position())
    super._process(delta)
