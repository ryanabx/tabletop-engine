class_name Deck
extends Collection

var permanent: bool = false
var face_up: bool = false

@onready var sprite: Sprite2D
@onready var count: Label

func get_shareable_properties() -> Array:
    return super.get_shareable_properties() + ["permanent", "face_up"]

func _ready() -> void:
    _init_children()
    super._ready()

func _init_children() -> void:
    # Sprite stuff
    sprite = Sprite2D.new()
    add_child(sprite)
    # Count label
    count = Label.new()
    count.z_index = 1
    count.add_theme_constant_override("outline_size", 16)
    count.add_theme_color_override("font_outline_color", Color.BLACK)
    count.scale = Vector2(0.40, 0.40)
    add_child(count)

func _process(_delta: float) -> void:
    count.position = (get_gobject_transform() * self.shape)[0]
    count.text = str("x",inside.size())
    count.reset_size()
    queue_redraw()
    if inside.is_empty():
        sprite.texture = null
        return
    var top_pc: Dictionary = inside[-1]
    if top_pc.size != size:
        size = top_pc.size
        collision_polygon.set_polygon(get_gobject_transform() * self.shape)
    sprite.texture = board.get_image(top_pc.image_up) if face_up else board.get_image(top_pc.image_down)
    sprite.scale = size / sprite.texture.get_size()

func _draw() -> void:
    draw_polyline(collision_polygon.polygon + PackedVector2Array([collision_polygon.polygon[0]]), Color.WHITE, 2)

func add_piece(piece: Piece, back: bool = false) -> void:
    if not board.game.can_stack_piece(piece, self):
        return
    
    if not lock_state and not back:
        face_up = piece.face_up
    
    super.add_piece(piece, back)

func remove_from_top() -> Piece:
    var pc: Piece = super.remove_from_top()
    if inside.is_empty() and not permanent:
        erase_self.rpc()
    return pc

func flip() -> void:
    authority = multiplayer.get_unique_id()
    face_up = not face_up

func clear_inside() -> void:
    super.clear_inside()
    if not permanent:
        erase_self.rpc()

func deserialize_piece(_dict: Dictionary) -> Piece:
    _dict.face_up = face_up
    return super.deserialize_piece(_dict)
