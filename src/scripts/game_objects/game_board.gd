class_name GameBoard
extends Node2D

const STACK_LERP: float = 0.8

var is_selecting: bool = false

var grab_offset: Vector2 = Vector2.ZERO

var _right_click_menu: RightClickMenu = null

var _current_stackable_item: GameItem = null

var selected_objects: Array = []

var selection_box: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0)

var _stack_scene = preload("res://src/scenes/game_objects/stack.tscn")

@onready var front_layer: CanvasLayer = $/root/Tabletop/UiLayer

@onready var game_object_manager: Node2D = $GameObjectManager

func _ready() -> void:
	Utils.enhanced_inputs.connect(process_input)

func process_input(input_actions: Dictionary) -> void:
	# SELECTING OBJECTS
	if Utils.is_action_just_long_held("game_select", input_actions) or Utils.is_action_just_long_held("game_select_stack", input_actions):
		select_object(input_actions)
	# RIGHT CLICKING
	if Utils.is_action_just_short_released("game_menu", input_actions) and get_rclick_menu() == null:
		print("Right Click")
		right_click()
	# ENDING RIGHT CLICK MENU
	elif get_rclick_menu() != null:
		if Utils.is_action_just_released("game_select", input_actions) or Utils.is_action_just_long_held("game_select", input_actions):
			print("End Right Click")
			end_right_click()
		if Utils.is_action_just_released("game_select_stack", input_actions) or Utils.is_action_just_long_held("game_select_stack", input_actions):
			print("End Right Click")
			end_right_click()
		if Utils.is_action_just_released("game_menu", input_actions) or Utils.is_action_just_long_held("game_menu", input_actions):
			print("End Right Click")
			end_right_click()
	# DESELECTING OBJECTS
	if Utils.is_action_just_long_released("game_select", input_actions) or Utils.is_action_just_long_released("game_select_stack", input_actions):
		print("Release Selection")
		release_selection()
	# FLIPPING OBJECTS
	if Utils.is_action_just_released("game_flip", input_actions) and has_selected_items():
		print("Flip Selection")
		flip_selection()

func right_click() -> void:
	if get_rclick_menu() == null and not has_selected_items():
		var highlighted_obj: GameObject = get_overlapping_obj(get_local_mouse_position())
		if highlighted_obj != null:
			if highlighted_obj.has_collection():
				create_right_click_menu_stack(get_local_mouse_position(), highlighted_obj.get_collection())
			else:
				create_right_click_menu_obj(get_local_mouse_position(), highlighted_obj)
		else:
			print("Nothing to right click")
	elif has_selected_items():
		pass # Multi select

func end_right_click() -> void:
	if get_rclick_menu() != null:
		if not get_rclick_menu().get_global_rect().has_point(get_rclick_menu().get_global_mouse_position()):
			destroy_rclick_menu()

func flip_selection() -> void:
	for object in get_selected_items():
		if object.has_collection():
			object.get_collection().flip()
		else:
			object.flip()
			
func select_object(input_actions: Dictionary) -> void:
	if not has_selected_items():
		var obj_selection: GameObject = get_overlapping_obj(get_local_mouse_position())
		if obj_selection:
			if obj_selection.has_collection() and Utils.is_action_just_held("game_select_stack", input_actions):
				print("Select Entire Collection")
				select_objects(obj_selection.get_collection().get_game_objects())
			elif obj_selection.has_collection():
				print("Select Object off Collection")
				obj_selection = obj_selection.get_collection().remove_game_object(obj_selection)
				select_objects([obj_selection])
			else:
				print("Select Individual Object")
				select_objects([obj_selection])
		else:
			print("Initialize selection rect")
			initialize_selection_rect()

func select_objects(objects: Array) -> void:
	for object in objects:
		object.select()
	move_objects_to_front(objects)
	set_selected_objects(objects)

func set_selected_objects(objects: Array) -> void:
	selected_objects = objects.duplicate()
	for object in selected_objects:
		object.set_grab_offset(object.position - get_local_mouse_position())

func initialize_selection_rect() -> void:
	selection_box.position = get_local_mouse_position()
	is_selecting = true

func get_overlapping_obj(point: Vector2) -> GameObject:
	var game_objects = get_tree().get_nodes_in_group("game_object")
	var best: GameObject = null
	for object in game_objects:
		var g_obj := object as GameObject
		if (g_obj.get_rect() * g_obj.get_transform().affine_inverse()).has_point(point):
			if best == null or (g_obj.z_index > best.z_index):
				best = g_obj
	return best

func has_selected_items() -> bool:
	return not get_selected_items().is_empty()

func get_selected_items() -> Array:
	return selected_objects

func release_selection() -> void:
	# If over an item, stack objects to that item
	if over_item():
		stack_objects_to_item(get_selected_items(), get_stackable_item())
		set_stackable_item(null)
	else:
		print("Releasing selection not over item")
	# Deselect everything
	for object in get_selected_items():
		object.deselect()
	grab_offset = Vector2.ZERO
	release_selection_box()
	set_selected_objects([])

func stack_objects_to_item(objects: Array, item: GameItem) -> void:
	if item is GameCollection:
		print("Stack objects to collection (stack to collection)")
		stack_objects_to_collection(objects, item as GameCollection)
	elif item is GameObject:
		(item as GameObject).select()
		print("Stack objects to object (convert to stack)")
		convert_to_stack([item] + objects)

func convert_to_stack(objects: Array):
	if objects.is_empty():
		return
	var _new_stack = _stack_scene.instantiate()
	_new_stack.position = objects[0].position
	game_object_manager.add_child(_new_stack)
	for object in objects:
		if object.has_collection():
			object.get_collection().remove_game_object(object)
		object.put_in_collection(_new_stack)
		object.position = _new_stack.position
		_new_stack.add_game_object_special(object)
	
func stack_objects_to_collection(objects: Array, collection: GameCollection) -> void:
	for object in objects:
		if object.has_collection():
			object.get_collection().remove_game_object(object)
		object.position = collection.position
		object.put_in_collection(collection)
		collection.add_game_object_special(object)
	collection.dehighlight()

func over_item():
	return _current_stackable_item != null

func get_stackable_item() -> GameItem:
	return _current_stackable_item

func move_item_to_front(item: GameItem) -> void:
	if item is GameObject:
		move_objects_to_front([item])
	elif item is GameCollection:
		move_objects_to_front((item as GameCollection).get_game_objects())

func move_item_to_back(item: GameItem) -> void:
	if item is GameObject:
		move_objects_to_back([item])
	elif item is GameCollection:
		move_objects_to_back((item as GameCollection).get_game_objects())

func move_objects_to_back(objects: Array) -> void:
	for object in objects:
		game_object_manager.move_child(object, 0)

func move_objects_to_front(objects: Array) -> void:
	for object in objects:
		game_object_manager.move_child(object, -1)

func _process(_delta):
	if has_selected_items():
		move_selected_items()
	if is_selecting:
		update_selection_rect()
	queue_redraw()

func update_selection_rect():
	selection_box.end = get_local_mouse_position()

func move_selected_items() -> void:
	for object in get_selected_items():
		object.position = get_local_mouse_position() + object.get_grab_offset()
		object.position = object.position.clamp(get_viewport().get_visible_rect().position, get_viewport().get_visible_rect().position + get_viewport().get_visible_rect().size)
	# CHECK STACKING
	var stackable_collection: GameCollection = find_stackable_collection(get_selected_items())
	if stackable_collection == null:
		var stackable_object: GameObject = find_stackable_object(get_selected_items())
		if stackable_object == null:
			set_stackable_item(null)
		else:
			set_stackable_item(stackable_object)
	else:
		set_stackable_item(stackable_collection)
	
func set_stackable_item(item: GameItem) -> void:
	if get_stackable_item() != null and get_stackable_item() != item:
		get_stackable_item().dehighlight()
	_current_stackable_item = item
	if item != null:
		item.highlight()

func find_stackable_object(objects: Array) -> GameObject:
	var game_objs: Array = get_tree().get_nodes_in_group("game_objects")
	var best_object: GameObject = null
	var best_dist: float = 0.0
	var ref_position = get_local_mouse_position()
	for object in game_objs:
		if object.unselectable() or object in objects:
			pass
		elif object_overlaps_point(object, ref_position):
			if best_object == null or ref_position.distance_to(object.position) < best_dist or (ref_position.distance_to(object.position) == best_dist and object.z_index > best_object.z_index):
				best_dist = ref_position.distance_to(object.position)
				best_object = object
	return best_object

func find_stackable_collection(objects: Array) -> GameCollection:
	var collections: Array = get_tree().get_nodes_in_group("collections")
	var best_object: GameCollection = null
	var best_dist: float = 0.0
	var ref_position = get_local_mouse_position()
	for collection in collections:
		if collection.disabled() or has_any(collection.get_game_objects(), objects):
			# print(collection.disabled(), " ", has_any(collection.get_game_objects(), objects))
			continue
		elif collection_overlaps_point(collection, ref_position):
			# print(collection)
			if best_object == null or ref_position.distance_to(collection.position) < best_dist:
				best_dist = ref_position.distance_to(collection.position)
				best_object = collection
	return best_object

func has_any(arr1: Array, arr2: Array) -> bool:
	for x in arr1:
		for y in arr2:
			if x == y:
				return true
	return false

func collection_overlaps_point(collection: GameCollection, point: Vector2) -> bool:
	return collection.get_extents().has_point(point)

func object_overlaps_point(object: GameObject, point: Vector2):
	return object.get_extents().has_point(point)

func _rect_obj_areas_overlap(obj1: GameObject, _rect: Rect2):
	return (obj1.get_stack_rect() * obj1.get_transform().affine_inverse()).intersects(_rect.abs())

func get_game_object_manager() -> Node2D:
	return game_object_manager

func create_right_click_menu_obj(pos: Vector2, object: GameObject):
	print("Generate right click menu")
	_right_click_menu = RightClickMenu.from_game_object(object, self)
	_right_click_menu.position = pos
	front_layer.add_child(_right_click_menu)
	object.right_click()

func create_right_click_menu_stack(pos: Vector2, collection: GameCollection):
	print("Generate right click menu")
	_right_click_menu = RightClickMenu.from_collection(collection, self)
	_right_click_menu.position = pos
	front_layer.add_child(_right_click_menu)

func get_rclick_menu() -> RightClickMenu:
	return _right_click_menu

func destroy_rclick_menu() -> void:
	if _right_click_menu.item != null and _right_click_menu.item is GameObject:
		_right_click_menu.item.revert_right_click()
	_right_click_menu.queue_free()
	_right_click_menu = null

func release_selection_box() -> void:
	if is_selecting:
		print("Releasing selection box")
		set_selected_objects(select_in_range())
		selection_box = Rect2(0.0, 0.0, 0.0, 0.0)
		is_selecting = false
		print("Done. Selected ", get_selected_items())

func select_in_range() -> Array:
	var items: Array = []
	for object in get_tree().get_nodes_in_group("game_object"):
		if _rect_obj_areas_overlap(object, selection_box):
			items.append(object)
	return items
