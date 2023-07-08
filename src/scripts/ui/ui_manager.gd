class_name UiManager
extends CanvasLayer

var rclick_menu: RightClickMenu = null

var _selected_object: GameObject = null

var parent: Tabletop = null

func _ready() -> void:
	if get_parent() != null:
		parent = get_parent()

func _input(event: InputEvent) -> void:
	_handle_right_clicks(event)
	_handle_selections(event)

func _handle_right_clicks(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if rclick_menu == null and GameManager.highlighted_over_item():
			if get_selected_object() != null:
				get_selected_object().flip_over()
			else:
				rclick_menu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.GAME_OBJECT, get_selected_object(), self)
				rclick_menu.global_position = get_viewport().get_mouse_position()
				add_child(rclick_menu)
	elif event is InputEventMouseButton and rclick_menu != null and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not rclick_menu.get_global_rect().has_point(rclick_menu.get_global_mouse_position()):
			destroy_rclick_menu()

func _handle_selections(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var object_selection: GameObject = _get_overlapping_object()
			if object_selection != null:
				_select_object(object_selection)
		else:
			_release_selection()
	

func _select_object(obj: GameObject) -> void:
	_selected_object = obj

func get_selected_object() -> GameObject:
	return _selected_object

func _release_selection() -> void:
	_selected_object = null

func _get_overlapping_object(point: Vector2) -> GameObject:
	game_objects = get_tree().get_nodes_in_group("game_objects")
	var best: GameObject = null
	for obj in game_objects:
		var g_obj := obj as GameObject
		if best == null or (g_obj.z_index > best.z_index and g_obj.get_rect().has_point(point)):
			best = obj
	return best as GameObject

func destroy_rclick_menu() -> void:
	rclick_menu._set_object_highlight(false)
	rclick_menu.queue_free()
	rclick_menu = null


