class_name GameObjectManager
extends Node2D

var stack_scene = preload("res://src/scenes/game_elements/spawnables/collection.tscn")

func _ready() -> void:
	add_to_group("game_object_manager")
	SignalManager.move_items_to_back.connect(_on_items_to_back)
	SignalManager.move_items_to_front.connect(_on_items_to_front)
	SignalManager.convert_to_stack.connect(convert_to_stack)

# Ordering functions

func _on_items_to_back(objects: Array) -> void:
	if objects.size() == 1:
		move_item_to_back(objects[0])
	else:
		move_objects_to_back(objects)

func _on_items_to_front(objects: Array) -> void:
	if objects.size() == 1:
		move_item_to_front(objects[0])
	else:
		move_objects_to_front(objects)

func move_item_to_front(item: GameObject) -> void:
	if item is Piece:
		move_objects_to_front([item])
	elif item is Collection:
		move_objects_to_front((item as Collection).get_game_objects())

func move_item_to_back(item: GameObject) -> void:
	if item is Piece:
		move_objects_to_back([item])
	elif item is Collection:
		move_objects_to_back((item as Collection).get_game_objects())

func move_objects_to_back(objects: Array) -> void:
	for object in objects:
		object.get_parent().move_child(object, 0)

func move_objects_to_front(objects: Array) -> void:
	for object in objects:
		object.get_parent().move_child(object, -1)

func flip_objects(objects: Array) -> void:
	for object in objects:
		if object.has_collection():
			object.get_collection().flip()
		else:
			object.flip()

func objects_to_string(arr: Array) -> Array[String]:
	var res: Array[String] = []

	for a in arr:
		res.append(a.get_name())
	return res

func string_to_objects(arr: Array[String]) -> Array:
	var res: Array = []

	for a in arr:
		res.append(get_node(a))
	return res

@rpc("any_peer", "call_local", "reliable")
func gain_control_over_objects(id: int, objects: Array) -> void:
	for obj in objects:
		get_node(obj).set_multiplayer_authority(id)

# Stacking functions
func stack_objects_to_item(objects: Array[GameObject], item: GameObject) -> void:
	rpc("gain_control_over_objects", multiplayer.get_unique_id(), objects_to_string([item] + objects))
	print("Stacking object to item")
	if item is Collection:
		stack_objects_to_collection(objects, item)
	elif item is Piece:
		convert_to_stack([item] + objects)

func convert_to_stack(objects: Array):
	print("Convert to stack")
	if objects.is_empty():
		return
	var stack: Collection = get_node("../GameObjectSpawner").spawn(GameObjectSpawner.make_stack_config(objects[0].position))
	stack.permanent = false
	for object in objects:
		if object.has_collection():
			object.get_collection_obj().remove_game_object(object)
		stack.add_game_object_to_top(object)
		object.position = stack.position
	
func stack_objects_to_collection(objects: Array, collection: Collection) -> void:
	print("Stack objects to collection")
	for object in objects:
		if object.has_collection():
			object.get_collection_obj().remove_game_object(object)
		collection.add_game_object_special(object)
		object.position = collection.position
	collection.dehighlight()
