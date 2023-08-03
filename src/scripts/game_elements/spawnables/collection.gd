class_name Collection
extends GameObject

var collection_size: Vector2 = Vector2.ZERO
var base_collection_size: Vector2 = Vector2.ZERO

var permanent: bool = true

var force_state = null

@onready var game_objects: GameObjectList = $GameObjects
@onready var piece_spawner: PieceSpawner = $PieceSpawner

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

func get_game_objects() -> Array:
	return game_objects.get_children()

func get_num_objects() -> int:
	return game_objects.get_child_count(false)

func get_top_object() -> Piece:
	if get_num_objects() == 0: return null
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
		if to_local(obj.position).x < get_game_objects()[a].position.x:
			break
		i = i + 1
	insert_game_object(obj, i)

func get_rect() -> Rect2:
	return Rect2(- collection_size / 2.0, collection_size)

func insert_game_object(obj: Piece, index: int) -> void:
	if obj in get_game_objects(): return
	piece_spawner.spawn(obj.get_name())
	game_objects.move_child(obj, index)

func remove_game_object(obj: Piece) -> void:
	if get_game_objects().has(obj): # May not need this check at some point
		obj.reparent(get_parent())
		Utils.reparenting_requests.append([obj.get_name(), "NONE"])
	if not permanent:
		if get_num_objects() == 1:
			remove_game_object(get_game_objects()[0])
		elif get_num_objects() == 0:
			print("remove stack")
			queue_free()

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
