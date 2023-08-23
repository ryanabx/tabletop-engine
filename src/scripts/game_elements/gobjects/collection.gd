class_name Collection
extends Gobject

var base_size: Vector2 = Vector2.ONE
var inside: Array[Dictionary] = []
var view_perms: Array = []
var access_perms: Array = []
var permanent: bool = false
var force_state = null
var type: Type = Type.STACK

var grab_offset: Vector2 = Vector2.ZERO

var selected: bool = false
@onready var collision_polygon = $Area2D/CollisionPolygon2D
@onready var area2d: Area2D = $Area2D

enum Type {STACK, HAND}

@onready var count: Label = $Count

func serialize_piece(pc: Piece) -> Dictionary:
    var _dict: Dictionary = {
        "name": pc.name,
        "image_up": pc.image_up,
        "image_down": pc.image_down,
        "face_up": pc.face_up,
        "shape": pc.shape,
        "gobject_scale": pc.gobject_scale
    }
    return _dict

func deserialize_piece(_dict: Dictionary) -> Piece:
    var piece: Piece = board.create_piece(
    var_to_bytes(_dict)
    )
    return piece


func _ready() -> void:
    collision_polygon.polygon = get_gobject_transform() * self.shape
    count.z_index = 1000

## Moves this object to the top of the draw order
@rpc("any_peer","call_local", "reliable")
func move_self_to_top() -> void:
    get_parent().move_child(self, -1)

## Moves this object to the back of the draw order
@rpc("any_peer","call_local", "reliable")
func move_self_to_back() -> void:
    get_parent().move_child(self, 0)

@rpc("any_peer","call_local", "reliable")
func move_to_index(index: int) -> void:
    get_parent().move_child(self, index)

@rpc("any_peer","call_remote","reliable")
func set_authority(id: int) -> void:
    auth = id

func update_position() -> void:
    if selected and not permanent:
        auth = multiplayer.get_unique_id()
        position = (board.get_local_mouse_position() - grab_offset).clamp(board.border.position, board.border.end)

func _process(_delta: float) -> void:
    update_position()
    count.position = (get_gobject_transform() * self.shape)[0]
    count.text = str(name,"[",inside.size(),"]")
    queue_redraw()

func _draw() -> void:
    if inside.is_empty():
        draw_colored_polygon(get_gobject_transform() * self.shape, Color.BLACK * Color(1,1,1,0.3))
        return
    var top_pc: Dictionary = inside[-1]
    _update_scale(Vector2(maxf(base_size.x, top_pc.gobject_scale.x), maxf(base_size.y, top_pc.gobject_scale.y)))
    draw_colored_polygon(get_gobject_transform() * self.shape, Color.BLACK * Color(1,1,1,0.3))
    var texture: Texture2D = board.game.images[top_pc.image_up] if top_pc.face_up else board.game.images[top_pc.image_down]
    draw_texture_rect(texture, Rect2(Vector2.ZERO - gobject_scale / 2, gobject_scale), false)

func _update_scale(_sc: Vector2) -> void:
    if gobject_scale != _sc:
        gobject_scale = _sc
        collision_polygon.polygon = get_gobject_transform() * self.shape


func add_piece(piece: Piece) -> void:
    var pc_d: Dictionary = serialize_piece(piece)
    piece.auth = multiplayer.get_unique_id()
    piece.erase_self.rpc()
    auth = multiplayer.get_unique_id()
    inside.append(pc_d)
    call_inside_changed()

func remove_from_top() -> Piece:
    auth = multiplayer.get_unique_id()
    var pc_d: Dictionary = inside.pop_back()
    var piece: Piece = deserialize_piece(pc_d)
    piece.auth = multiplayer.get_unique_id()
    if inside.is_empty() and not permanent:
        if is_multiplayer_authority():
            erase_self.rpc()
    else:
        call_inside_changed()
    return piece

func get_inside() -> Array[Dictionary]:
    return inside

func set_inside(_inside: Array) -> void:
    if _inside != inside:
        auth = multiplayer.get_unique_id()
        self.inside = _inside
        call_inside_changed()
    

func flip() -> void:
    auth = multiplayer.get_unique_id()
    for obj in inside:
        obj.face_up = not obj.face_up

func set_orientation(orientation: bool) -> void:
    auth = multiplayer.get_unique_id()
    for obj in inside:
        obj.face_up = orientation

func shuffle() -> void:
    auth = multiplayer.get_unique_id()
    inside.shuffle()
    call_inside_changed()

@rpc("authority","call_local","reliable")
func erase_self() -> void:
    for obj in inside:
        if is_multiplayer_authority():
            deserialize_piece(obj)
    queue_free()

func clear_inside() -> void:
    auth = multiplayer.get_unique_id()
    inside = []
    if not permanent:
        erase_self.rpc()
    else:
        call_inside_changed()

static var collection_scene = preload("res://src/scenes/game_elements/gobjects/collection.tscn")
## Constructor
static func construct(brd: Board, config: Dictionary) -> Collection:
    var collection: Collection = collection_scene.instantiate()
    collection.board = brd
    for prop in config.keys():
        if prop == "inside":
            continue
        collection.set(prop, config[prop])
    brd.board_objects.add_child(collection)
    if "inside" in config:
        for key in config.inside:
            var piece: Piece = brd.get_piece(key)
            if piece != null:
                piece.add_to_collection(collection)
    return collection

func can_access() -> bool:
    if access_perms.size() <= Player.get_id():
        return true # Default to true if there's no access perms
    elif access_perms[Player.get_id()] == false:
        return false
    return true

func set_selected(sl: bool) -> void:
    auth = multiplayer.get_unique_id()
    if sl == true:
        selected = true
        area2d.collision_layer = 2
    else:
        selected = false
        area2d.collision_layer = 1

func _on_select(_event:InputEvent) -> void:
    if get_inside().is_empty():
        return
    board.board_player.select_collection(self)

func _on_deselect(_event:InputEvent) -> void:
    if board.board_player.is_selecting():
        if selected == false and can_access():
            print("RELEASED AND STACKABLE OBJECT FOUND")
            board.board_player.stack_stackables_to_collection(self)


func _on_multiplayer_synchronizer_2_synchronized() -> void:
    collision_polygon.polygon = get_gobject_transform() * self.shape

func call_inside_changed() -> void:
    auth = multiplayer.get_unique_id()
    inside_changed.rpc(var_to_bytes(inside).compress(3))

@rpc("authority", "call_remote", "reliable")
func inside_changed(new_inside: PackedByteArray) -> void:
    var n_inside: Array[Dictionary] = []
    n_inside.assign(bytes_to_var(new_inside.decompress_dynamic(-1, 3)))
    inside = n_inside
