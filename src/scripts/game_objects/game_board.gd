class_name GameBoard
extends Node2D

const STACK_LERP: float = 0.8

var is_selecting: bool = false

var game_menu_open: bool = false

var _current_stackable_item: GameObject = null

var selected_objects: Array = []

var selection_box: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0)

var _stack_scene = preload("res://src/scenes/game_elements/stack.tscn")

var group_selection_mode: bool = false
var group_selection_down: bool = false
var previously_stacked: bool = false

var highlighted_piece: Piece = null

var border: Rect2 = Rect2(-640, -360, 1280, 720)

@onready var game_object_manager: Node2D = $GameObjectManager
@onready var board_texture: Sprite2D = $BoardTexture

func reset_board() -> void:
	# Remove all game objects
	for item in game_object_manager.get_children():
		item.queue_free()
	# Reset variables
	group_selection_down = false
	group_selection_mode = false
	previously_stacked = false
	border = Rect2(0, 0, 1280, 720)
	selection_box = Rect2(0.0, 0.0, 0.0, 0.0)
	selected_objects = []
	_current_stackable_item = null
	game_menu_open = false
	is_selecting = false
	board_texture.texture = null

func _ready() -> void:
	Utils.enhanced_inputs.connect(process_input)
	SignalManager.game_menu_create.connect(_on_game_menu_create)
	SignalManager.game_menu_destroy.connect(_on_game_menu_destroy)
	SignalManager.move_items_to_back.connect(_on_items_to_back)
	SignalManager.move_items_to_front.connect(_on_items_to_front)
	SignalManager.convert_to_stack.connect(convert_to_stack)

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

func _on_game_menu_create():
	game_menu_open = true

func _on_game_menu_destroy():
	game_menu_open = false

func set_border(bord: Rect2) -> void:
	border = bord

func get_border() -> Rect2:
	return border

func set_board_texture(txtur: Texture2D) -> void:
	board_texture.set_texture(txtur)
	board_texture.scale = (get_border().size) / board_texture.get_rect().size
	board_texture.position = get_border().get_center()

func process_input(input_actions: Dictionary) -> void:
	if Globals.get_tabletop().camera_controller.in_free_cam():
		return
	# SELECTING OBJECTS
	if Utils.is_action_just_long_held("game_select", input_actions) or Utils.is_action_just_long_held("game_select_stack", input_actions):
		if group_selection_mode:
			if Utils.is_action_just_long_held("game_select", input_actions):
				check_over_group_selection()
		else:
			check_selecting_obj(input_actions)
	# RIGHT CLICKING
	if Utils.is_action_just_short_released("game_menu", input_actions) and not game_menu_open:
		right_click()
	# DESELECTING GROUP SELECTED OBJECTS V2
	if Utils.is_action_just_released("game_select", input_actions) or Utils.is_action_just_released("game_select_stack", input_actions):
		if group_selection_mode and not group_selection_down:
			release_selection_group(input_actions)
		elif not group_selection_mode and Utils.is_action_just_short_released("game_select", input_actions):
			# check_instant_selection()
			pass
	# DESELECTING OBJECTS
	if Utils.is_action_just_long_released("game_select", input_actions) or Utils.is_action_just_long_released("game_select_stack", input_actions):
		release_selection()
	# DESELECTING GROUP SELECTED OBJECTS
	if Utils.is_action_just_released("end_group_select", input_actions):
		if group_selection_mode:
			release_selection_group(input_actions)
	# FLIPPING OBJECTS
	if Utils.is_action_just_released("game_flip", input_actions) and has_selected_items():
		flip_selection()

func right_click() -> void:
	if not game_menu_open and not has_selected_items():
		if highlighted_piece != null:
			if highlighted_piece.has_collection():
				create_right_click_menu_stack(highlighted_piece.get_collection())
			else:
				create_right_click_menu_obj(highlighted_piece)
	elif has_selected_items():
		if get_overlapping_obj_from_selected(get_local_mouse_position()) != null:
			if get_selected_items().size() > 1:
				create_right_click_menu_group(get_selected_items())
			else:
				create_right_click_menu_obj(get_selected_items()[0])

func check_over_group_selection() -> void:
	if get_overlapping_obj_from_selected(get_local_mouse_position()) != null:
		group_selection_down = true

func flip_selection() -> void:
	for object in get_selected_items():
		if object.has_collection():
			object.get_collection().flip()
		else:
			object.flip()

func check_instant_selection() -> void:
	if not has_selected_items():
		var obj_selection: Piece = get_overlapping_obj(get_local_mouse_position())
		if obj_selection:
			group_selection_mode = true
			selecting_piece(obj_selection)
			
func check_selecting_obj(input_actions: Dictionary) -> void:
	if not has_selected_items():
		var obj_selection: Piece = get_overlapping_obj(get_local_mouse_position())
		if obj_selection:
			if obj_selection.has_collection() and Utils.is_action_just_held("game_select_stack", input_actions): # Select collection
				selecting_collection(obj_selection, false)
			else: # Select piece
				selecting_piece(obj_selection)
		elif not Utils.is_action_just_long_held("game_select_stack", input_actions): # Selection box
			initialize_selection_rect()

func selecting_piece(obj_selection: Piece) -> void:
	if obj_selection.has_collection() and not group_selection_mode:
		obj_selection.get_collection().remove_game_object(obj_selection)
	select_objects([obj_selection])

func selecting_collection(obj_selection: Piece, instant_selection: bool) -> void:
	if obj_selection.get_collection().get_permanence():
		if not instant_selection:
			return
		select_objects(obj_selection.get_collection().get_game_objects())
	else:
		select_objects(obj_selection.get_collection().get_game_objects())

func select_objects(objects: Array) -> void:
	for object in objects:
		object.select()
		object.rotation = Globals.get_tabletop().camera_controller.camera.rotation
	move_objects_to_front(objects)
	set_selected_objects(objects)

func set_selected_objects(objects: Array) -> void:
	selected_objects = objects.duplicate()
	set_object_grab_offsets()

func initialize_selection_rect() -> void:
	selection_box.position = get_local_mouse_position()
	is_selecting = true

func get_overlapping_obj_from_selected(point: Vector2) -> Piece:
	var game_objects = get_selected_items()
	var best: Piece = null
	for object in game_objects:
		var g_obj := object as Piece
		if (g_obj.get_rect() * g_obj.get_transform().affine_inverse()).has_point(point):
			if best == null or (g_obj.z_index > best.z_index):
				best = g_obj
	return best

func get_overlapping_obj(point: Vector2) -> Piece:
	var game_objects = get_tree().get_nodes_in_group("piece")
	var best: Piece = null
	for object in game_objects:
		var g_obj := object as Piece
		if g_obj.has_collection() and not g_obj.can_access(Player.get_id()):
			continue
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
		group_selection_mode = false
		previously_stacked = false
	if not group_selection_mode:
		# Deselect everything
		for object in get_selected_items():
			object.deselect()
		set_selected_objects([])
	group_selection_down = false
	if selection_box:
		release_selection_box()

func release_selection_group(input_actions: Dictionary) -> void:
	# Deselect everything
	if not Utils.is_action_just_short_released("game_menu", input_actions):
		for object in get_selected_items():
			object.deselect()
		if previously_stacked and objects_not_in_collection(get_selected_items()):
			convert_to_stack(get_selected_items())
		group_selection_mode = false
		previously_stacked = false
		set_selected_objects([])

func objects_not_in_collection(objects: Array) -> bool:
	for obj in objects:
		if obj.has_collection():
			return false
	return true

func stack_objects_to_item(objects: Array, item: GameObject) -> void:
	if item is GameCollection:
		stack_objects_to_collection(objects, item as GameCollection)
	elif item is Piece:
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
		_new_stack.add_game_object_special(object)
		_new_stack.set_permanence(false)
		object.position = _new_stack.position
	
func stack_objects_to_collection(objects: Array, collection: GameCollection) -> void:
	for object in objects:
		if object.has_collection():
			object.get_collection().remove_game_object(object)
		collection.add_game_object_special(object)
		object.position = collection.position
	collection.dehighlight()

func over_item():
	return _current_stackable_item != null

func get_stackable_item() -> GameObject:
	return _current_stackable_item

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
		game_object_manager.move_child(object, 0)

func move_objects_to_front(objects: Array) -> void:
	for object in objects:
		game_object_manager.move_child(object, -1)

func _process(_delta):
	highlighted_piece = get_overlapping_obj(get_local_mouse_position())
	if (Input.is_action_just_pressed("game_select") or Input.is_action_just_pressed("game_select_stack")):
		set_object_grab_offsets()
	if has_selected_items():
		if (Input.is_action_pressed("game_select") or Input.is_action_pressed("game_select_stack")):
			if not group_selection_mode:
				move_selected_items()
			elif group_selection_mode and group_selection_down:
				move_selected_items()
	if is_selecting:
		update_selection_rect()
	queue_redraw()

func set_object_grab_offsets() -> void:
	for object in get_selected_items():
		object.set_grab_offset(object.position - get_local_mouse_position())

func update_selection_rect() -> void:
	selection_box.end = get_local_mouse_position()
	selection_box.position = selection_box.position.clamp(border.position, border.end)
	selection_box.end = selection_box.end.clamp(border.position, border.end)

func move_selected_items() -> void:
	for object in get_selected_items():
		if object.has_collection() and object.get_collection().get_permanence():
			object.get_collection().remove_game_object(object)
		object.position = get_local_mouse_position() + object.get_grab_offset()
		object.position = object.position.clamp(border.position, border.end)
	# CHECK STACKING
	var stackable_collection: GameCollection = find_stackable_collection(get_selected_items())
	if stackable_collection == null:
		var stackable_object: Piece = find_stackable_object(get_selected_items())
		if stackable_object == null:
			set_stackable_item(null)
		else:
			set_stackable_item(stackable_object)
	else:
		set_stackable_item(stackable_collection)
	
func set_stackable_item(item: GameObject) -> void:
	if get_stackable_item() != null and get_stackable_item() != item:
		get_stackable_item().dehighlight()
	# If stack is permitted
	if item and not item.can_access(Player.get_id()):
		pass
	else:
		_current_stackable_item = item
	if _current_stackable_item != null:
		_current_stackable_item.highlight()

func find_stackable_object(objects: Array) -> Piece:
	var game_objs: Array = get_tree().get_nodes_in_group("piece")
	var best_object: Piece = null
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
			continue
		elif collection_overlaps_point(collection, ref_position):
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

func object_overlaps_point(object: Piece, point: Vector2):
	return object.get_extents().has_point(point)

func _rect_obj_areas_overlap(obj1: Piece, _rect: Rect2):
	return (obj1.get_rect() * obj1.get_transform().affine_inverse()).intersects(_rect.abs())

func create_right_click_menu_obj(object: Piece):
	SignalManager.game_menu_create.emit(RightClickMenu.TYPE.GAME_OBJECT, [object])

func create_right_click_menu_stack(collection: GameCollection):
	SignalManager.game_menu_create.emit(RightClickMenu.TYPE.COLLECTION, [collection])

func create_right_click_menu_group(selection: Array):
	SignalManager.game_menu_create.emit(RightClickMenu.TYPE.OBJECT_GROUP, selection)

func release_selection_box() -> void:
	if is_selecting:
		var objects: Array = select_in_range()
		if not objects.is_empty():
			select_objects(objects)
			group_selection_mode = true
		previously_stacked = objects_part_of_same_collection(objects)
		selection_box = Rect2(0.0, 0.0, 0.0, 0.0)
		is_selecting = false

func objects_part_of_same_collection(objects: Array) -> bool:
	if objects.is_empty():
		return false
	
	var coll: GameCollection = objects[0].get_collection()
	if coll == null:
		return false
	
	for obj in objects:
		if obj.get_collection() != coll:
			return false
	return true

func select_in_range() -> Array:
	var items: Array = []
	for object in get_tree().get_nodes_in_group("piece"):
		if not object.can_access(Player.get_id()):
			continue
		if _rect_obj_areas_overlap(object, selection_box):
			items.append(object)
	return items

func _draw() -> void:
	draw_rect(border, Color.from_hsv(0.0, 0.0, 1.0, 1.0), false, Globals.OUTLINE_THICKNESS * 3.0)
