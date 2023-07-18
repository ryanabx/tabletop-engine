class_name GameCollection
extends GameItem


var _game_objects: Array = []
var _scale: Vector2 = Vector2.ZERO

var stack_counter_scene: PackedScene = load("res://src/scenes/ui/stack_counter.tscn")
var stack_counter = null

func _ready() -> void:
	add_to_group("collections")
	stack_counter = stack_counter_scene.instantiate()
	stack_counter.z_index = 5
	add_child(stack_counter)
	

func _process(_delta: float) -> void:
	_update_objects()
	stack_counter.set_label(str(get_num_objects()))

func _update_objects() -> void:
	print("_update_objects Not Implemented on: ",get_class()," ",get_name())
	pass

func get_game_objects() -> Array:
	return _game_objects

func _get_max_index() -> int:
	var max_index: int = -1
	for obj in get_game_objects():
		max_index = max(obj.get_index(), max_index)
	return max_index

func add_game_object_to_top(obj: GameObject) -> void:
	get_game_objects().push_back(obj)

func add_game_object_to_bottom(obj: GameObject) -> void:
	get_game_objects().push_front(obj)

func add_game_object_special(_obj: GameObject) -> void:
	print("add_game_object_special not Implemented on: ",get_class())
	pass

func get_rect() -> Rect2:
	return Rect2(- _scale / 2.0, _scale)

func get_top_object() -> GameObject:
	if get_num_objects() == 0:
		return null
	return get_game_objects()[-1]

func remove_game_object(obj: GameObject) -> void:
	var index: int = get_game_objects().find(obj)
	if index == -1:
		return
	remove_object_at(index)

func remove_object_at(index: int) -> void:
	print("Removing object")
	var target_object: GameObject = get_game_objects().pop_at(index)
	target_object.remove_from_collection()
	print(get_num_objects())

func get_num_objects() -> int:
	return get_game_objects().size()

func disabled() -> bool:
	return false

func flip() -> void:
	for obj in get_game_objects():
		obj.flip()

func shuffle() -> void:
	get_game_objects().shuffle()

func _draw() -> void:
	super._draw()
