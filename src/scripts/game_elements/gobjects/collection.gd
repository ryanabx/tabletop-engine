class_name Collection
extends Selectable

var inside: Array[Dictionary] = []
var permanent: bool = false
var face_up: bool = false

var grab_offset: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D
@onready var count: Label

func serialize_piece(pc: Piece) -> Dictionary:
	return inst_to_dict(pc)

func deserialize_piece(_dict: Dictionary) -> Piece:
	var pc: Piece = dict_to_inst(_dict)
	pc.face_up = face_up
	return pc

func _ready() -> void:
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
	super._ready()

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
	sprite.texture = board.game.include_images[top_pc.image_up] if face_up else board.game.include_images[top_pc.image_down]
	sprite.scale = size / sprite.texture.get_size()

func _draw() -> void:
	draw_polyline(collision_polygon.polygon + PackedVector2Array([collision_polygon.polygon[0]]), Color.WHITE, 2)

func add_piece(piece: Piece, back: bool = false) -> void:
	if not board.game.can_stack_piece(piece, self):
		return
	
	if not lock_state:
		face_up = piece.face_up
	
	var pc_d: Dictionary = serialize_piece(piece)
	piece.auth = multiplayer.get_unique_id()
	piece.erase_self.rpc()
	auth = multiplayer.get_unique_id()
	if back:
		inside.push_front(pc_d)
	else:
		inside.push_back(pc_d)
	call_inside_changed()

func remove_from_top() -> Piece:
	if not board.game.can_take_piece_off(self):
		return null
	auth = multiplayer.get_unique_id()
	var pc_d: Dictionary = inside.pop_back()
	var piece: Piece = deserialize_piece(pc_d)
	board.board_objects.add_child(piece)
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
	face_up = not face_up

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

func _on_select(_event:InputEvent) -> void:
	if get_inside().is_empty():
		return
	board.board_player.queue_select_object(self)

func _on_deselect(_event:InputEvent) -> void:
	if board.board_player.is_selecting():
		if selected == false:
			board.board_player.stack_selection_to_item(self)

func call_inside_changed() -> void:
	auth = multiplayer.get_unique_id()
	inside_changed.rpc(var_to_bytes(inside).compress(3))

@rpc("authority", "call_remote", "reliable")
func inside_changed(new_inside: PackedByteArray) -> void:
	var n_inside: Array[Dictionary] = []
	n_inside.assign(bytes_to_var(new_inside.decompress_dynamic(-1, 3)))
	inside = n_inside
