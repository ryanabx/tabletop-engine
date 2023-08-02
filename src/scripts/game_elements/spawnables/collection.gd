class_name Collection
extends GameObject

var game_objects: Array = []
var _scale: Vector2 = Vector2.ZERO

var base_size: Vector2 = Vector2.ZERO

var permanent: bool = true

var force_state = null

enum TYPE {
	STACK, HAND
}

var type: TYPE = TYPE.STACK

var view_perms: Array = []
var access_perms: Array = []

var label: Label = null

const STACK_RECT_SIZE: float = 32.0

const PADDING: float = 8.0
const N_PADDING: float = 4.0

const LABEL_OPACITY = 0.6

func _ready() -> void:
	add_to_group("collections")
	label = Label.new()
	label.modulate.a = 0.6
	label.z_index = 1000
	label.z_as_relative = false
	# label.set_anchors_and_offsets_preset(label.PRESET_CENTER)
	add_child(label)

func _update_objects() -> void:
	if not is_multiplayer_authority():
		return
	
	if type == TYPE.HAND:
		_update_objects_hand()
		return
	
	var larg_x: float = 0
	var larg_y: float = 0
	
	var max_index = get_max_index()

	if not get_permanence() and get_num_objects() > 0 and position != get_game_objects()[-1].position:
		position = get_game_objects()[-1].position
	
	for obj in get_game_objects():
		obj.get_parent().move_child(obj, max_index)
		if force_state is bool:
			obj.set_side(force_state as bool)
		obj.position = position
		obj.rotation = rotation
		var _sc = obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
	if get_num_objects() > 0:
		_scale = Vector2(larg_x, larg_y)
	else:
		_scale = base_size

func _update_objects_hand() -> void:
	if not is_multiplayer_authority():
		return
	var num_objects: int = get_num_objects()
	var _max_index = get_max_index()
	
	var larg_x: float = 0
	var larg_y: float = 0
	var i: int = 0
	for obj in get_game_objects():
		get_parent().move_child(obj, _max_index)
		if force_state is bool:
			obj.set_side(force_state as bool)
		var _lerp_amt: float = (i + 1.0) / (num_objects + 1.0)
		var _pos: Vector2 = to_global(Vector2(get_rect().position.x, get_rect().get_center().y)).lerp(to_global(Vector2(get_rect().end.x, get_rect().get_center().y)), _lerp_amt)
		obj.position = _pos
		obj.rotation = rotation
		var _sc = obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
		i += 1
	if num_objects > 0:
		_scale = Vector2(base_size.x, larg_y)
	else:
		_scale = base_size

func can_access(player_id: int):
	if access_perms.is_empty():
		return null
	return access_perms[player_id]

func can_view(player_id: int):
	if view_perms.is_empty():
		return null
	return view_perms[player_id]

func get_permanence() -> bool:
	return permanent

func set_permanence(per: bool) -> void:
	permanent = per

func get_game_objects() -> Array:
	return (Utils.get_game_objects(game_objects) as Array[Piece])

func get_max_index() -> int:
	var max_index: int = -1
	for obj in get_game_objects():
		max_index = max(obj.get_index(), max_index)
	return max_index

func add_game_object_to_top(obj: Piece) -> void:
	if obj in get_game_objects():
		print("Cannot add object when already added")
		return
	if obj.put_in_collection(self):
		game_objects.push_back(obj.get_name())

func add_game_object_to_bottom(obj: Piece) -> void:
	if obj in get_game_objects():
		print("Cannot add object when already added")
		return
	if obj.put_in_collection(self):
		game_objects.push_front(obj.get_name())

func add_game_object_special(obj: Piece) -> void:
	match type:
		TYPE.STACK:
			add_game_object_to_top(obj)
		TYPE.HAND:
			add_game_object_special_hand(obj)

func add_game_object_special_hand(obj: Piece) -> void:
	if obj in get_game_objects():
		print("Cannot add object when already added")
		return
	var i: int = 0
	for a in range(get_num_objects()):
		if to_local(obj.position).x < to_local(get_game_objects()[a].position).x:
			break
		i = i + 1
	insert_game_object(obj, i)

func get_rect() -> Rect2:
	return Rect2(- _scale / 2.0, _scale)

func get_top_object() -> Piece:
	if get_num_objects() == 0:
		return null
	return get_game_objects()[-1]

func remove_game_object(obj: Piece) -> void:
	var index: int = game_objects.find(obj.get_name())
	if index == -1:
		return
	remove_object_at(index)

func remove_object_at(index: int) -> void:
	var target_object: Piece = Utils.get_game_object(game_objects.pop_at(index))
	if target_object == null: return
	target_object.remove_from_collection()
	if not permanent:
		if get_num_objects() == 1:
			remove_object_at(0)
		elif get_num_objects() == 0:
			print("remove stack")
			queue_free()

func insert_game_object(obj: Piece, index: int) -> void:
	if obj in get_game_objects():
		print("Cannot add object when already added")
		return
	if obj.put_in_collection(self):
		game_objects.insert(index, obj.get_name())

func get_num_objects() -> int:
	var size: int = get_game_objects().size()
	return size

func disabled() -> bool:
	return false

func flip() -> void:
	for obj in get_game_objects():
		obj.flip()

func set_side(side: bool) -> void:
	for obj in get_game_objects():
		obj.set_side(side)

func shuffle() -> void:
	get_game_objects().shuffle()	

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		_update_objects()
	label.set_text(str(get_num_objects()))
	label.position = get_rect().position
	queue_redraw()

func _draw() -> void:
	if permanent:
		if can_access(Player.get_id()) == false:
			draw_rect(get_rect(), Color.from_hsv(0.0, 0.0, 0.0, 0.5), false,N_PADDING)
			draw_rect(get_rect(), Color.RED * Color(1.0, 1.0, 1.0, 0.1))
		else:
			draw_rect(get_rect(), Color.from_hsv(0.0, 0.0, 0.0, 0.8), false,PADDING)
			draw_rect(get_rect(), Color.BLACK * Color(1.0, 1.0, 1.0, 0.3))
	super._draw()
