class_name GameBoard
extends Node2D

const STACK_LERP: float = 0.8

var is_selecting: bool = false

var grab_offset: Vector2 = Vector2.ZERO

var _right_click_menu: RightClickMenu = null

var _current_stackable_object: GameObject = null
var _current_stackable_hand: Hand = null

var selected_objects: Array = []

var selection_box: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0)

var _stack_scene = preload("res://src/scenes/game_objects/stack.tscn")

@onready var game_object_manager: Node2D = $GameObjectManager

func _ready() -> void:
	Utils.enhanced_inputs.connect(process_input)

func process_input(input_actions: Dictionary) -> void:
	# SELECTING OBJECTS
	if Utils.is_action_just_long_held("game_select", input_actions) or Utils.is_action_just_long_held("game_select_stack", input_actions):
		select_object(input_actions)
	# RIGHT CLICKING
	if Utils.is_action_just_short_released("game_menu", input_actions) and get_rclick_menu() == null:
		right_click()
	# ENDING RIGHT CLICK MENU
	elif get_rclick_menu() != null:
		if Utils.is_action_just_released("game_select", input_actions) or Utils.is_action_just_long_held("game_select", input_actions):
			end_right_click()
		if Utils.is_action_just_released("game_select_stack", input_actions) or Utils.is_action_just_long_held("game_select_stack", input_actions):
			end_right_click()
		if Utils.is_action_just_released("game_menu", input_actions) or Utils.is_action_just_long_held("game_menu", input_actions):
			end_right_click()
	# DESELECTING OBJECTS
	if Utils.is_action_just_long_released("game_select", input_actions) or Utils.is_action_just_long_released("game_select_stack", input_actions):
		release_selection()
	# FLIPPING OBJECTS
	if Utils.is_action_just_released("game_flip", input_actions) and has_selected_items():
		flip_selection()

func right_click() -> void:
	if get_rclick_menu() == null and not has_selected_items():
		var highlighted_obj: GameObject = get_overlapping_obj(get_local_mouse_position())
		if highlighted_obj != null:
			if highlighted_obj.get_state() == GameObject.STATE.IDLE:
				create_right_click_menu_obj(get_viewport().get_mouse_position(), highlighted_obj)					
			if highlighted_obj.get_state() == GameObject.STATE.STACKED:
				create_right_click_menu_stack(get_viewport().get_mouse_position(), highlighted_obj)
		else:
			print("Nothing to right click")
	elif has_selected_items():
		pass # Multi select

func end_right_click() -> void:
	if get_rclick_menu() != null:
		if not get_rclick_menu().get_global_rect().has_point(get_rclick_menu().get_global_mouse_position()):
			destroy_rclick_menu()

func flip_selection() -> void:
	for obj in get_selected_items():
		if obj.get_state() == GameObject.STATE.STCK_SLCT:
			obj.get_obj_stack().flip()
		elif obj.get_state() == GameObject.STATE.SELECTED:
			obj.flip()
			
func select_object(input_actions: Dictionary) -> void:
	if not has_selected_items():
		var obj_selection: GameObject = get_overlapping_obj(get_local_mouse_position())
		if obj_selection:
			if obj_selection.get_state() == GameObject.STATE.STACKED and Utils.is_action_just_held("game_select_stack", input_actions):
				select_objects(obj_selection.get_obj_stack().get_game_objects())
			elif obj_selection.get_state() == GameObject.STATE.STACKED:
				obj_selection = obj_selection.get_obj_stack().release_top_of_stack()
				select_one_object(obj_selection)
			else:
				select_one_object(obj_selection)
		else:
			initialize_selection_rect()

func select_one_object(obj: GameObject) -> void:
	if obj.get_state() == GameObject.STATE.IN_HAND:
		var hand: Hand = obj.get_hand()
		hand.remove_game_object(obj)
		obj.take_out_of_hand()
	set_selected_objects([obj])
	move_objects_to_front(selected_objects)
	obj.select()

func select_objects(objects: Array) -> void:
	for obj in objects:
		if obj.get_state() == GameObject.STATE.IN_HAND:
			var hand: Hand = obj.get_hand()
			hand.remove_game_object(obj)
			obj.take_out_of_hand()
		obj.select()
	move_objects_to_front(selected_objects)
	set_selected_objects(objects)

func set_selected_objects(objects: Array) -> void:
	selected_objects = objects.duplicate()
	for obj in selected_objects:
		obj.set_grab_offset(obj.position - get_local_mouse_position())

func initialize_selection_rect() -> void:
	selection_box.position = get_local_mouse_position()
	is_selecting = true


func get_overlapping_obj(point: Vector2) -> GameObject:
	var game_objects = get_tree().get_nodes_in_group("game_object")
	var best: GameObject = null
	for obj in game_objects:
		var g_obj := obj as GameObject
		if (g_obj.get_rect() * g_obj.get_transform().affine_inverse()).has_point(point):
			if best == null or (g_obj.z_index > best.z_index):
				best = g_obj
	return best

func has_selected_items() -> bool:
	return not get_selected_items().is_empty()

func get_selected_items() -> Array:
	return selected_objects

func release_selection() -> void:
	if over_hand():
		print("stacking objects into hand")
		objects_to_hand(get_selected_items(), get_stackable_hand())
	elif over_object():
		if get_stackable_object().get_state() == GameObject.STATE.STACKED:
			print("stacking objects into stack")
			objects_to_stack(get_selected_items(), get_stackable_object().get_obj_stack())
		else:
			print("converting objects to stack")
			convert_to_stack(get_selected_items() + [get_stackable_object()])
			# Change object state back to idle or stacked
	for obj in get_selected_items():
		if obj.is_stacked():
			obj.make_unstacked()
		elif obj.is_in_hand():
			obj.take_out_of_hand()
		else:
			obj.deselect()
	grab_offset = Vector2.ZERO
	release_selection_box()
	set_selected_objects([])
	

func over_hand():
	return _current_stackable_hand != null

func over_object():
	return _current_stackable_object != null

func get_stackable_object() -> GameObject:
	return _current_stackable_object

func get_stackable_hand() -> Hand:
	return _current_stackable_hand

func objects_to_hand(objects: Array, hand: Hand) -> void:
	for obj in objects:
		obj.put_in_hand()
		obj.set_hand(hand)
		hand.add_game_object(obj)
		hand.make_unhovered()

func stack_to_hand(stck: ObjectStack, hand: Hand) -> void:
	for obj in stck.get_game_objects():
		print("Object state: ", obj.state_to_string(obj.get_state()))
		obj.set_obj_stack(null)
		obj.put_in_hand()
		obj.set_hand(hand)
		hand.add_game_object(obj)
	stck.queue_free()
	hand.make_unhovered()

func stack_to_stack(stck: ObjectStack, stck2: ObjectStack) -> void:
	for obj in stck.get_game_objects():
		obj.set_obj_stack(stck2)
		stck2.add_game_object(obj)
	stck2.make_unhovered()
	stck.queue_free()

func objects_to_stack(objects: Array, stck: ObjectStack) -> void:
	for obj in objects:
		obj.set_obj_stack(stck)
		stck.add_game_object(obj)
		stck.make_unhovered()

func stack_to_objects(stck: ObjectStack, obj2: GameObject) -> void:
	obj2.set_obj_stack(stck)
	stck.add_game_object_to_bottom(obj2)
	stck.make_unhovered()

func stack_objects(obj1: GameObject, obj2: GameObject) -> void:
	var _new_stack = _stack_scene.instantiate()
	_new_stack.position = obj2.position
	game_object_manager.add_child(_new_stack)
	_new_stack.add_game_object(obj2)
	_new_stack.add_game_object(obj1)

func convert_to_stack(objects: Array):
	if objects.is_empty():
		return
	var _new_stack = _stack_scene.instantiate()
	_new_stack.position = objects[0].position
	game_object_manager.add_child(_new_stack)
	for obj in objects:
		_new_stack.add_game_object(obj)
	

func move_objects_to_back(objects: Array) -> void:
	for obj in objects:
		game_object_manager.move_child(obj, 0)

func move_objects_to_front(objects: Array) -> void:
	for obj in objects:
		game_object_manager.move_child(obj, -1)

func _process(_delta):
	if has_selected_items():
		move_selected_items()
	if is_selecting:
		update_selection_rect()
		queue_redraw()

func update_selection_rect():
	selection_box.end = get_local_mouse_position()

func move_selected_items() -> void:
	for obj in get_selected_items():
		obj.position = get_local_mouse_position() + obj.get_grab_offset()
		
		obj.position = obj.position.clamp(get_viewport().get_visible_rect().position, get_viewport().get_visible_rect().position + get_viewport().get_visible_rect().size)
	# CHECK STACKING COLLECTIONS
	var stackable_collection: GameCollection = find_stackable_collection()
	# CHECK STACKING OBJECT
	var stackable_object: GameObject = find_stackable_object()

func _check_move_selected_object() -> void:
	if get_selected_object() != null and get_selected_object().get_state() == GameObject.STATE.SELECTED and (Input.is_action_pressed("game_select") or Input.is_action_pressed("game_select_stack")):
		get_selected_object().position = get_global_mouse_position() + grab_offset
		get_selected_object().position = get_selected_object().position.clamp(get_viewport().get_visible_rect().position, get_viewport().get_visible_rect().position + get_viewport().get_visible_rect().size)
		_check_stacking(false)
		_check_over_hand(false)

func _check_move_stack() -> void:
	if get_selected_object() != null and Input.is_action_pressed("game_select_stack"):
		if get_selected_object().get_state() == GameObject.STATE.STCK_SLCT:
			get_selected_object().get_obj_stack().position = get_global_mouse_position() + grab_offset
			get_selected_object().get_obj_stack().position = get_selected_object().get_obj_stack().position.clamp(get_viewport().get_visible_rect().position, get_viewport().get_visible_rect().position + get_viewport().get_visible_rect().size)
			get_selected_object().get_obj_stack().stack_moved()
			_check_stacking(true)
			_check_over_hand(true)

func _check_over_hand(holding_stack: bool) -> void:
	var stackable_hand: Hand = find_overlapping_hands(get_selected_object())
	if stackable_hand != null:
		if _current_stackable_hand and _current_stackable_hand != stackable_hand:
			_current_stackable_hand.make_unhovered()
		_current_stackable_hand = stackable_hand
		if _current_stackable_hand.get_state() != Hand.HNDSTATE.HOVERED:
			_current_stackable_hand.make_hovered()
		if holding_stack:
			var lerp_thing: Vector2 = Vector2(get_selected_object().get_obj_stack().position.x, _current_stackable_hand.position.y)
			get_selected_object().get_obj_stack().position = get_selected_object().get_obj_stack().position.lerp(lerp_thing, STACK_LERP)
			get_selected_object().get_obj_stack().stack_moved()
		else:
			var lerp_thing: Vector2 = Vector2(get_selected_object().position.x, _current_stackable_hand.position.y)
			get_selected_object().position = get_selected_object().position.lerp(lerp_thing, STACK_LERP)
	elif _current_stackable_hand != null:
		_current_stackable_hand.make_unhovered()
		_current_stackable_hand = null

func _check_stacking(holding_stack: bool) -> void:
	var stackable_object: GameObject = find_overlapping_areas(get_selected_object(), true) # Test, return to true if holding_stack doesn't work
	if stackable_object != null:
		if _current_stackable_object and _current_stackable_object != stackable_object:
			_current_stackable_object.get_unready_for_stacking()
		_current_stackable_object = stackable_object
		if _current_stackable_object.get_state() != GameObject.STATE.READY_FOR_STACKING:
			_current_stackable_object.get_ready_for_stacking()
			if _current_stackable_object.get_obj_stack():
				_current_stackable_object.get_obj_stack().make_hovered()
		if holding_stack:
			get_selected_object().get_obj_stack().position = get_selected_object().get_obj_stack().position.lerp(_current_stackable_object.position, STACK_LERP)
			get_selected_object().get_obj_stack().stack_moved()
		else:
			get_selected_object().position = get_selected_object().position.lerp(_current_stackable_object.position, STACK_LERP)
	elif _current_stackable_object != null:
		_current_stackable_object.get_unready_for_stacking()
		if _current_stackable_object.get_obj_stack():
			_current_stackable_object.get_obj_stack().make_unhovered()
		_current_stackable_object = null

func find_stackable_object() -> GameObject:
	var objects: Array = get_tree().get_nodes_in_group("game_objects")
	var best_object: GameObject = null
	var best_dist: float = 0.0
	var ref_position = get_local_mouse_position()
	for object in objects:
		if object.unselectable():
			continue
		elif object_overlaps_point(object, ref_position):
			if best_object != null or ref_position.distance_to(collection.position) < best_dist:
				best_dist = ref_position.distance_to(collection.position)
				best_object = collection
	return best_object


func find_stackable_collection() -> GameCollection:
	var collections: Array = get_tree().get_nodes_in_group("collections")
	var best_object: GameCollection = null
	var best_dist: float = 0.0
	var ref_position = get_local_mouse_position()
	for collection in collections:
		if collection.disabled():
			continue
		elif collection_overlaps_point(collection, ref_position):
			if best_object != null or ref_position.distance_to(collection.position) < best_dist:
				best_dist = ref_position.distance_to(collection.position)
				best_object = collection
	return best_object

func collection_overlaps_point(collection: GameCollection, point: Vector2) -> bool:
	return collection.get_extents().has_point(point)

func find_overlapping_areas(obj: GameObject, check_stack: bool) -> GameObject:
	var _groups = obj.get_groups()
	_groups.erase("game_object")
	var best_dist: float = 0.0
	var best_obj: GameObject = null
	var best_z: int = 0
	for group in _groups:
		var _objs_in_group = get_tree().get_nodes_in_group(group)
		for obj2 in _objs_in_group:
			if obj2 == obj:
				continue
			if obj2.get_obj_stack() and obj.get_obj_stack() and obj2.get_obj_stack() == obj.get_obj_stack():
				continue
			if obj2.get_hand():
				continue
			if (not check_stack and _areas_overlap(obj, obj2)) or (check_stack and _stack_areas_overlap(obj, obj2)):
				if best_obj == null or obj.position.distance_to(obj2.position) < best_dist:
					best_obj = obj2
					best_dist = obj.position.distance_to(obj2.position)
					best_z = obj2.z_index
				elif obj.position.distance_to(obj2.position) == best_dist:
					if obj2.z_index > best_z:
						best_obj = obj2
						best_dist = obj.position.distance_to(obj2.position)
						best_z = obj2.z_index
	return best_obj

func _areas_overlap(obj1: GameObject, obj2: GameObject):
	return (obj1.get_rect() * obj1.get_transform().affine_inverse()).intersects((obj2.get_rect() * obj2.get_transform().affine_inverse()))

func _stack_areas_overlap(obj1: GameObject, obj2: GameObject):
	return (obj1.get_stack_rect() * obj1.get_transform().affine_inverse()).intersects((obj2.get_stack_rect() * obj2.get_transform().affine_inverse()))

func _hand_obj_areas_overlap(obj1: GameObject, _hand: Hand):
	return (obj1.get_stack_rect() * obj1.get_transform().affine_inverse()).intersects(_hand.get_rect() * _hand.get_transform().affine_inverse())

func _rect_obj_aread_overlap(obj1: GameObject, _rect: Rect2):
	return (obj1.get_stack_rect() * obj1.get_transform().affine_inverse()).intersects(_rect)

func get_game_object_manager() -> Node2D:
	return game_object_manager

func create_right_click_menu_obj(pos: Vector2, obj: GameObject):
	print("Generate right click menu")
	_right_click_menu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.GAME_OBJECT, obj, null, self)
	_right_click_menu.z_index = 1000
	_right_click_menu.global_position = pos
	add_child(_right_click_menu)
	obj.right_click()

func create_right_click_menu_stack(pos: Vector2, obj: GameObject):
	print("Generate right click menu")
	_right_click_menu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.STACK, obj, obj.get_obj_stack(), self)
	_right_click_menu.z_index = 1000
	_right_click_menu.global_position = pos
	add_child(_right_click_menu)
	obj.right_click()

func get_rclick_menu() -> RightClickMenu:
	return _right_click_menu

func destroy_rclick_menu() -> void:
	if _right_click_menu._associated_object != null:
		_right_click_menu._associated_object.revert_right_click()
	_right_click_menu.queue_free()
	_right_click_menu = null

func release_selection_box() -> void:
	if is_selecting:
		selected_objects = select_in_range()
		selection_box = Rect2(0.0, 0.0, 0.0, 0.0)
		is_selecting = false

func select_in_range() -> Array:
	var items: Array = []
	for obj in get_tree().get_nodes_in_group("game_object"):
		if _rect_obj_aread_overlap(obj, selection_box):
			items.append(obj)
	return items

func _draw() -> void:
	if is_selecting:
		draw_rect(selection_box, Color.from_hsv(0.6, 1.0, 1.0, 0.5))
