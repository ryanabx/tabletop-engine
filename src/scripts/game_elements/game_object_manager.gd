extends Node2D

var stack_scene = preload("res://src/scenes/game_elements/spawnables/stack.tscn")

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
	elif item is GameCollection:
		move_objects_to_front((item as GameCollection).get_game_objects())

func move_item_to_back(item: GameObject) -> void:
	if item is Piece:
		move_objects_to_back([item])
	elif item is GameCollection:
		move_objects_to_back((item as GameCollection).get_game_objects())

func move_objects_to_back(objects: Array) -> void:
	for object in objects:
		move_child(object, 0)

func move_objects_to_front(objects: Array) -> void:
	for object in objects:
		move_child(object, -1)

# Stacking functions

func stack_objects_to_item(objects: Array, item: GameObject) -> void:
	if item is GameCollection:
		stack_objects_to_collection(objects, item as GameCollection)
	elif item is Piece:
		convert_to_stack([item] + objects)

func convert_to_stack(objects: Array):
	print("Convert to stack")
	if objects.is_empty():
		return
	var stack = stack_scene.instantiate()
	stack.position = objects[0].position
	add_child(stack)
	for object in objects:
		if object.has_collection():
			object.get_collection().remove_game_object(object)
		stack.add_game_object_special(object)
		stack.set_permanence(false)
		object.position = stack.position
	
func stack_objects_to_collection(objects: Array, collection: GameCollection) -> void:
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
