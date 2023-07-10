class_name GameBoard
extends Node2D

var _selected_object: GameObject = null

var _grab_offset: Vector2 = Vector2.ZERO

var _right_click_menu: RightClickMenu = null

var _current_stackable_object: GameObject = null

@onready var _game_object_manager: Node2D = $GameObjectManager

var _stack_scene = preload("res://src/scenes/game_objects/stack.tscn")

func _input(event: InputEvent) -> void:
	_handle_right_clicks(event)
	_handle_selections(event)

func _handle_right_clicks(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		if get_rclick_menu() == null:
			if has_selected_object(): # Flip object
				print("Flip!")
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
	elif event is InputEventMouseButton and get_rclick_menu() != null and event.button_index == MOUSE_BUTTON_LEFT:
		if not get_rclick_menu().get_global_rect().has_point(get_rclick_menu().get_global_mouse_position()):
			destroy_rclick_menu()

func _handle_selections(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var object_selection: GameObject = _get_overlapping_object(event.position)
			if object_selection != null:
				if object_selection.get_obj_stack():
					object_selection = object_selection.get_obj_stack().release_top_of_stack()
				_select_object(object_selection)
		else:
			_release_selection()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			var object_selection: GameObject = _get_overlapping_object(event.position)
			if object_selection != null and object_selection.get_state() == GameObject.STATE.STACKED:
				_stack_select_object(object_selection)
		else:
			_release_stack_selection()

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
	_selected_object = obj
	print("Selecting")
	_grab_offset = obj.position - get_local_mouse_position()
	move_object_to_front(obj)
	obj.select()

func _stack_select_object(obj: GameObject) -> void:
	_selected_object = obj
	print("Stack Selecting")
	_grab_offset = obj.position - get_local_mouse_position()
	move_object_to_front(obj)
	move_stack_to_front(obj.get_obj_stack())
	obj.stack_select()

func has_selected_object() -> bool:
	return get_selected_object() != null

func get_selected_object() -> GameObject:
	return _selected_object

func _release_selection() -> void:
	if _selected_object:
		if _current_stackable_object:
			if _current_stackable_object.get_obj_stack():
				print("Stacking object into already made stack")
				_stack_object(_selected_object, _current_stackable_object.get_obj_stack())
			else:
				print("Stacking 2 objects")
				_stack_objects(_selected_object, _current_stackable_object)
			_selected_object.make_stacked()
			_current_stackable_object.make_stacked()
		_selected_object.deselect()
	_grab_offset = Vector2.ZERO
	_selected_object = null

func _release_stack_selection() -> void:
	if _selected_object:
		_selected_object.stack_deselect()
	_grab_offset = Vector2.ZERO
	_selected_object = null

func _stack_object(obj: GameObject, stck: ObjectStack) -> void:
	obj.set_obj_stack(stck)
	stck.add_game_object(obj)

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
	if get_selected_object() != null and get_selected_object().get_state() == GameObject.STATE.SELECTED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_selected_object().position = get_global_mouse_position() + _grab_offset
		var stackable_object: GameObject = _get_overlapping_area_of_same_type(get_selected_object(), true)
		if stackable_object != null:
			_current_stackable_object = stackable_object
			if _current_stackable_object.get_state() != GameObject.STATE.READY_FOR_STACKING:
				_current_stackable_object.get_ready_for_stacking()
			get_selected_object().position = get_selected_object().position.lerp(_current_stackable_object.position, 0.3)
		elif _current_stackable_object != null:
			_current_stackable_object.get_unready_for_stacking()
			_current_stackable_object = null

func _check_move_stack() -> void:
	if get_selected_object() != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		if get_selected_object().get_state() == GameObject.STATE.STCK_SLCT:
			get_selected_object().get_obj_stack().position = get_global_mouse_position() + _grab_offset
			get_selected_object().get_obj_stack().stack_moved()
# TODO: FIX BUG WHERE TWO OR MORE OBJECTS CAN BECOME "READY TO STACK" AND GET STUCK IN THAT POSITION

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
