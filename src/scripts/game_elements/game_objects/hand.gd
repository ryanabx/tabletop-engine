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

# Shareable properties
var visibility: VisibilitySetting = VisibilitySetting.DESIGNATED
var designated_players: Array[int] = []
var size_option: SizeOption = SizeOption.FIXED_LAYER

func get_shareable_properties() -> Array:
    return super.get_shareable_properties() + ["visibility", "designated_players"]

func _draw() -> void:
    match size_option:
        SizeOption.FIXED_LAYER: _draw_fixed()

func _draw_fixed() -> void:
    pass

## Draws a piece from data at a certain position
func _draw_piece(_data: Dictionary, _position: Vector2, _size: Vector2 = Vector2.ZERO) -> void:
    if _size == Vector2.ZERO:
        _size = _data.size
    
    var _texture: Texture2D = board.get_image(_data.face_up if can_view() else _data.face_down)
    
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

func _process(delta: float) -> void:
    queue_redraw()
    super._process(delta)