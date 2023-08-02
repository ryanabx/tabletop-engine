extends Node2D

var stack_scene = preload("res://src/scenes/game_elements/spawnables/collection.tscn")

func _ready() -> void:
	SignalManager.convert_to_stack.connect(convert_to_stack)
	SignalManager.move_items_to_back.connect(_on_items_to_back)
	SignalManager.move_items_to_front.connect(_on_items_to_front)

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
		move_child(object, 0)

func move_objects_to_front(objects: Array) -> void:
	for object in objects:
		move_child(object, -1)

# Stacking functions
func stack_objects_to_item(objects: Array, item: String) -> void:
	var g_item: GameObject = Utils.get_game_object(item)
	if g_item == null: return
	var g_objects: Array[GameObject] = Utils.get_game_objects(objects)
	Utils.rpc("gain_control_over_objects", multiplayer.get_unique_id(), objects + [item])
	print("Stacking object to item")
	if g_item is Collection:
		stack_objects_to_collection(g_objects, g_item as Collection)
	elif g_item is Piece:
		convert_to_stack([g_item] + g_objects)

func convert_to_stack(objects: Array):
	print("Convert to stack")
	if objects.is_empty():
		return
	var stack: Collection = get_parent().get_node("GameObjectSpawner").spawn(GameObjectSpawner.make_stack_config(objects[0].position))
	stack.set_permanence(false)
	for object in objects:
		if object.has_collection():
			object.get_collection().remove_game_object(object)
		stack.add_game_object_to_top(object)
		object.position = stack.position
	
func stack_objects_to_collection(objects: Array, collection: Collection) -> void:
	print("Stack objects to collection")
	for object in objects:
		if object.has_collection():
			object.get_collection().remove_game_object(object)
		collection.add_game_object_special(object)
		object.position = collection.position
	collection.dehighlight()

func flip_objects(objects: Array) -> void:
	for object in objects:
		if object.has_collection():
			object.get_collection().flip()
		else:
			object.flip()
