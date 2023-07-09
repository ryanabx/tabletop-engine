class_name GameBoard
extends Node2D

var _selected_object: GameObject = null

var _grab_offset: Vector2 = Vector2.ZERO

var _right_click_menu: RightClickMenu = null

@onready var _game_object_manager: Node2D = $GameObjectManager

func _input(event: InputEvent) -> void:
	_handle_right_clicks(event)
	_handle_selections(event)

func _handle_right_clicks(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if get_rclick_menu() == null:
			if has_selected_object(): # Flip object
				print("Flip!")
				get_selected_object().flip()
			else:
				var _highlighted_object: GameObject = _get_overlapping_object(event.position)
				if _highlighted_object != null:
					create_right_click_menu_obj(get_viewport().get_mouse_position(), _highlighted_object)
				else:
					print("Nothing to right click")
	elif event is InputEventMouseButton and get_rclick_menu() != null and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not get_rclick_menu().get_global_rect().has_point(get_rclick_menu().get_global_mouse_position()):
			destroy_rclick_menu()

func _handle_selections(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var object_selection: GameObject = _get_overlapping_object(event.position)
			if object_selection != null:
				_select_object(object_selection)
		else:
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
	_selected_object = obj
	print("Selecting")
	_grab_offset = obj.position - get_local_mouse_position()
	move_object_to_front(obj)
	obj.select()

func has_selected_object() -> bool:
	return get_selected_object() != null

func get_selected_object() -> GameObject:
	return _selected_object

func _release_selection() -> void:
	if _selected_object:
		_selected_object.deselect()
	_grab_offset = Vector2.ZERO
	_selected_object = null

func move_object_to_back(obj: GameObject) -> void:
	_game_object_manager.move_child(obj, 0)

func move_object_to_front(obj: GameObject) -> void:
	_game_object_manager.move_child(obj, -1)

func _process(_delta):
	if get_selected_object() != null and get_selected_object().get_state() == GameObject.STATE.SELECTED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_selected_object().position = get_global_mouse_position() + _grab_offset



func create_right_click_menu_obj(pos: Vector2, obj: GameObject):
	print("Generate right click menu")
	_right_click_menu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.GAME_OBJECT, obj, self)
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
