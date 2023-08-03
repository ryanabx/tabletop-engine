class_name Collection
extends GameObject

var collection_size: Vector2 = Vector2.ZERO
var base_collection_size: Vector2 = Vector2.ZERO

var permanent: bool = true

var force_state = null

var game_objects: Array[String] = []

var g_objs_changed = false

var prev_list: Array = []

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
	_ready_create_number_label()

@rpc("any_peer", "call_remote", "unreliable")
func refresh_game_objects(g_objs: Array[String]) -> void:
	print("Refreshing game objects")
	game_objects = g_objs

func _ready_create_number_label() -> void:
	label = Label.new()
	label.modulate.a = 0.6
	label.z_index = 1000
	label.z_as_relative = false
	add_child(label)

func can_access(player_id: int):
	if access_perms.is_empty():
		return null
	return access_perms[player_id]

func can_view(player_id: int):
	if view_perms.is_empty():
		return null
	return view_perms[player_id]

func get_game_objects() -> Array[String]:
	return game_objects

func get_num_objects() -> int:
	return game_objects.size()

func get_top_object() -> String:
	if get_num_objects() == 0: return ""
	return get_game_objects()[-1]

func add_game_object_to_top(obj: Piece) -> void:
	insert_game_object(obj, 0)

func add_game_object_special(obj: Piece) -> void:
	match type:
		TYPE.STACK:
			add_game_object_to_top(obj)
		TYPE.HAND:
			add_game_object_special_hand(obj)

func add_game_object_special_hand(obj: Piece) -> void:
	var i: int = 0
	for a in range(get_num_objects()):
		var o: Piece = get_tree().get_first_node_in_group(get_game_objects()[a])
		if to_local(obj.position).x < o.position.x:
			break
		i = i + 1
	insert_game_object(obj, i)

func get_rect() -> Rect2:
	return Rect2(- collection_size / 2.0, collection_size)

## Inserts a game object at the given index
func insert_game_object(obj: Piece, index: int) -> void:
	if get_game_objects().has(obj.get_name()):
		return

	game_objects.insert(index, obj.get_name())
	obj.collection = self.get_name()

## Removes a particular object from the collection
func remove_game_object(obj: Piece) -> void:
	if not get_game_objects().has(obj.get_name()): # May not need this check at some point
		print(get_game_objects(), " : ", obj.get_name())
		return
	print("Removing ",obj.get_name())
	obj.collection = ""
	game_objects.erase(obj.get_name())
	
	if not permanent:
		if get_num_objects() == 1:
			get_tree().get_first_node_in_group(get_game_objects()[0]).collection = ""
			queue_free()
		elif get_num_objects() == 0:
			queue_free()

func flip() -> void:
	for obj in get_game_objects():
		var g: Piece = get_tree().get_first_node_in_group(obj)
		g.flip()

func set_side(side: bool) -> void:
	for obj in get_game_objects():
		var g: Piece = get_tree().get_first_node_in_group(obj)
		g.set_side(side)

func shuffle() -> void:
	get_game_objects().shuffle()	

func _process(_delta: float) -> void:
	label.set_text(str(get_num_objects()))
	label.position = get_rect().position
	if is_multiplayer_authority():
		rpc("refresh_game_objects",game_objects)
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
