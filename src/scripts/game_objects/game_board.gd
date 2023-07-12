class_name GameBoard
extends Node2D

const STACK_LERP: float = 0.8

var _selected_object: GameObject = null

var _grab_offset: Vector2 = Vector2.ZERO

var _right_click_menu: RightClickMenu = null

var _current_stackable_object: GameObject = null
var _current_stackable_hand: Hand = null

@onready var _game_object_manager: Node2D = $GameObjectManager

var _stack_scene = preload("res://src/scenes/game_objects/stack.tscn")

func _input(event: InputEvent) -> void:
	_handle_right_clicks(event)
	_handle_selections(event)

func _handle_right_clicks(event: InputEvent) -> void:
	if Input.is_action_just_pressed("game_menu"):
		if get_rclick_menu() == null:
			if has_selected_object(): # Flip object
				print("Flip!")
				if get_selected_object().get_state() == GameObject.STATE.STCK_SLCT:
					get_selected_object().get_obj_stack().flip()
				elif get_selected_object().get_state() == GameObject.STATE.SELECTED:
					get_selected_object().flip()
			else:
				var _highlighted_object: GameObject = _get_overlapping_object(event.position)
				if _highlighted_object != null:
					if _highlighted_object.get_state() == GameObject.STATE.IDLE:
						create_right_click_menu_obj(get_viewport().get_mouse_position(), _highlighted_object)
					if _highlighted_object.get_state() == GameObject.STATE.STACKED:
						create_right_click_menu_stack(get_viewport().get_mouse_position(), _highlighted_object)
				else:
					print("Nothing to right click")
	elif get_rclick_menu() != null and (Input.is_action_pressed("game_select") or Input.is_action_pressed("game_select_stack")):
		if not get_rclick_menu().get_global_rect().has_point(get_rclick_menu().get_global_mouse_position()):
			destroy_rclick_menu()

func _handle_selections(event: InputEvent) -> void:
	if Input.is_action_just_pressed("game_select") or Input.is_action_just_pressed("game_select_stack") and not get_selected_object():
		var obj_selection: GameObject = _get_overlapping_object(event.position)
		if obj_selection:
			if obj_selection.get_state() == GameObject.STATE.STACKED and Input.is_action_pressed("game_select_stack"):
				_stack_select_object(obj_selection)
			elif obj_selection.get_state() == GameObject.STATE.STACKED:
				obj_selection = obj_selection.get_obj_stack().release_top_of_stack()
				_select_object(obj_selection)
			elif obj_selection.get_state() == GameObject.STATE.IN_HAND:
				print("In hand")
				_select_object_from_hand(obj_selection)
			else:
				_select_object(obj_selection)
	elif (Input.is_action_just_released("game_select") and not Input.is_action_pressed("game_select_stack")) or (Input.is_action_just_released("game_select_stack")  and not Input.is_action_pressed("game_select")):
		if get_selected_object():
			if get_selected_object().get_state() == GameObject.STATE.STCK_SLCT:
				_release_stack_selection()
			elif get_selected_object().get_state() == GameObject.STATE.SELECTED:
				print("Releasing selection")
				_release_selection()

func _get_overlapping_object(point: Vector2) -> GameObject:
	var game_objects = get_tree().get_nodes_in_group("game_object")
	var best: GameObject = null
	for obj in game_objects:
		var g_obj := obj as GameObject
		if (g_obj.get_rect() * g_obj.get_transform().affine_inverse()).has_point(point):
			if best == null or (g_obj.z_index > best.z_index):
				best = g_obj
	return best

func _select_object(obj: GameObject) -> void:
	set_selected_object(obj)
	print("Selecting")
	_grab_offset = obj.position - get_local_mouse_position()
	move_object_to_front(obj)
	obj.select()

func _select_object_from_hand(obj: GameObject) -> void:
	obj.get_hand().remove_game_object(obj)
	obj.take_out_of_hand()
	obj.set_hand(null)
	print("Take obj out of hand")
	_select_object(obj)

func _stack_select_object(obj: GameObject) -> void:
	set_selected_object(obj)
	print("Stack Selecting")
	_grab_offset = obj.position - get_local_mouse_position()
	move_object_to_front(obj)
	move_stack_to_front(obj.get_obj_stack())
	obj.stack_select()

func has_selected_object() -> bool:
	return get_selected_object() != null

func get_selected_object() -> GameObject:
	return _selected_object

func set_selected_object(_slc: GameObject) -> void:
	_selected_object = _slc

func _release_selection() -> void:
	if get_selected_object():
		if _current_stackable_hand:
			print("Stacking card into hand")
			_stack_object_to_hand(get_selected_object(), _current_stackable_hand)
		elif _current_stackable_object:
			if _current_stackable_object.get_obj_stack():
				print("Stacking object into already made stack")
				_stack_object_to_stack(_selected_object, _current_stackable_object.get_obj_stack())
			else:
				print("Stacking 2 objects")
				_stack_objects(_selected_object, _current_stackable_object)
			_selected_object.make_stacked()
			_current_stackable_object.make_stacked()
		_selected_object.deselect()
	_grab_offset = Vector2.ZERO
	set_selected_object(null)

func _release_stack_selection() -> void:
	if get_selected_object():
		if _current_stackable_hand:
			print("Stacking stack into hand")
			_stack_stack_to_hand(get_selected_object().get_obj_stack(), _current_stackable_hand)
		elif _current_stackable_object:
			if _current_stackable_object.get_obj_stack():
				print("Stacking stack into already made stack")
				_stack_stacks(get_selected_object().get_obj_stack(), _current_stackable_object.get_obj_stack())
			else:
				print("Stacking stack onto object")
				_stack_stack_to_object(get_selected_object().get_obj_stack(), _current_stackable_object)
			get_selected_object().make_stacked()
			_current_stackable_object.make_stacked()
		get_selected_object().stack_deselect()
	_grab_offset = Vector2.ZERO
	set_selected_object(null)

func _stack_object_to_hand(obj: GameObject, hand: Hand) -> void:
	obj.put_in_hand()
	obj.set_hand(hand)
	hand.add_game_object(obj)
	hand.make_unhovered()

func _stack_stack_to_hand(stck: ObjectStack, hand: Hand) -> void:
	for _obj in stck.get_game_objects():
		print("Object state: ", _obj.state_to_string(_obj.get_state()))
		_obj.set_obj_stack(null)
		_obj.put_in_hand()
		_obj.set_hand(hand)
		hand.add_game_object(_obj)
	stck.queue_free()
	hand.make_unhovered()

func _stack_stacks(stck: ObjectStack, stck2: ObjectStack) -> void:
	for obj in stck.get_game_objects():
		obj.set_obj_stack(stck2)
		stck2.add_game_object(obj)
	stck2.make_unhovered()
	stck.queue_free()

func _stack_object_to_stack(obj: GameObject, stck: ObjectStack) -> void:
	obj.set_obj_stack(stck)
	stck.add_game_object(obj)
	stck.make_unhovered()

func _stack_stack_to_object(stck: ObjectStack, obj2: GameObject) -> void:
	obj2.set_obj_stack(stck)
	stck.add_game_object_to_bottom(obj2)
	stck.make_unhovered()

func _stack_objects(obj1: GameObject, obj2: GameObject) -> void:
	var _new_stack = _stack_scene.instantiate()
	_new_stack.position = obj2.position
	_game_object_manager.add_child(_new_stack)
	_new_stack.add_game_object(obj2)
	_new_stack.add_game_object(obj1)

func move_object_to_back(obj: GameObject) -> void:
	_game_object_manager.move_child(obj, 0)

func move_object_to_front(obj: GameObject) -> void:
	_game_object_manager.move_child(obj, -1)

func move_stack_to_front(stck: ObjectStack) -> void:
	for obj in stck.get_game_objects():
		_game_object_manager.move_child(obj, -1)
	
func move_stack_to_back(stck: ObjectStack) -> void:
	var game_objects_reverse = stck.get_game_objects().duplicate(false)
	game_objects_reverse.reverse()
	for obj in game_objects_reverse:
		_game_object_manager.move_child(obj, 0)

func _process(_delta):
	_check_move_selected_object()
	_check_move_stack()
	
func _check_move_selected_object() -> void:
	if get_selected_object() != null and get_selected_object().get_state() == GameObject.STATE.SELECTED and (Input.is_action_pressed("game_select") or Input.is_action_pressed("game_select_stack")):
		
		get_selected_object().position = get_global_mouse_position() + _grab_offset
		get_selected_object().position = get_selected_object().position.clamp(get_viewport().get_visible_rect().position, get_viewport().get_visible_rect().position + get_viewport().get_visible_rect().size)
		_check_stacking(false)
		_check_over_hand(false)

func _check_move_stack() -> void:
	if get_selected_object() != null and Input.is_action_pressed("game_select_stack"):
		if get_selected_object().get_state() == GameObject.STATE.STCK_SLCT:
			get_selected_object().get_obj_stack().position = get_global_mouse_position() + _grab_offset
			get_selected_object().get_obj_stack().position = get_selected_object().get_obj_stack().position.clamp(get_viewport().get_visible_rect().position, get_viewport().get_visible_rect().position + get_viewport().get_visible_rect().size)
			get_selected_object().get_obj_stack().stack_moved()
			_check_stacking(true)
			_check_over_hand(true)

func _check_over_hand(holding_stack: bool) -> void:
	var stackable_hand: Hand = _get_overlapping_hand_of_same_player(get_selected_object())
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
	var stackable_object: GameObject = _get_overlapping_area_of_same_type(get_selected_object(), true) # Test, return to true if holding_stack doesn't work
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

func _get_overlapping_hand_of_same_player(obj: GameObject) -> Hand:
	var _hands = get_tree().get_nodes_in_group("hands")
	var best_hand: Hand = null
	var best_dist: float = 0.0
	for _hand in _hands:
		if _hand.get_player_id() != Globals.get_player_id():
			continue
		if _hand_obj_areas_overlap(obj, _hand) and (best_hand == null or obj.position.distance_to(best_hand.position) < best_dist):
			best_hand = _hand
			best_dist = obj.position.distance_to(best_hand.position)
	return best_hand

func _get_overlapping_area_of_same_type(obj: GameObject, check_stack: bool) -> GameObject:
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

func get_game_object_manager() -> Node2D:
	return _game_object_manager

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
