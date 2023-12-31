class_name Deck
extends Collection
## deck.gd
## 
## Defines a generic [class Collection] that acts like a stack of pieces.
## The [class Deck] will dissapear if no pieces are in it, unless [member Deck.permanent] is set to [true]

## If set to [true], this [class Deck] will not disappear when [member Collection.inside] is empty.
var permanent: bool = false

@onready var sprite: Sprite2D
@onready var count: Label

func add_piece(piece: Piece, back: bool = false) -> void:
    if not board.game.can_stack(piece, self):
        return
    super.add_piece(piece, back)

func remove_from_top(pos: Vector2 = Vector2.ZERO) -> Piece:
    var pc: Piece = super.remove_from_top(pos)
    if inside.is_empty() and not permanent:
        _erase_rpc.rpc(false)
    return pc

## Flips the deck
func flip() -> void:
    _authority = multiplayer.get_unique_id()
    flippable.face_up = not flippable.face_up
    inside.reverse()
    add_to_property_changes("inside",inside)

func _ready() -> void:
    _shareable_properties.append_array(["permanent"])
    # Interfaces!!!
    flippable = Flippable.new(self, flip)
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
        selectable._collision_polygon.set_polygon(get_gobject_transform() * self.shape)
    var img_up: String = top_pc.image_up
    var img_down: String = top_pc.image_down
    sprite.texture = board._get_image(img_up) if not flippable or flippable.face_up else board._get_image(img_down)
    sprite.scale = size / sprite.texture.get_size()

func _draw() -> void:
    draw_polyline(selectable._collision_polygon.polygon + PackedVector2Array([selectable._collision_polygon.polygon[0]]), Color.WHITE * Color(1.0, 1.0, 1.0, 0.3), Global.COLLECTION_OUTLINE)

func _clear_inside() -> void:
    super._clear_inside()
    if not permanent:
        _erase_rpc.rpc(false)

func _deserialize_piece(_dict: Dictionary) -> Piece:
    _dict.face_up = flippable.face_up
    return super._deserialize_piece(_dict)
