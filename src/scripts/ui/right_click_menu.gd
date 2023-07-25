class_name RightClickMenu
extends PopupMenu

enum TYPE {NONE,GAME_OBJECT,OBJECT_GROUP,COLLECTION}

var object_group: Array = []

func _ready() -> void:
	SignalManager.game_menu_create.connect(_on_menu_created)
	hide()
	popup_hide.connect(_on_popup_hide)

func _reset_popup_menu() -> void:
	set_position(Vector2.ZERO)
	# Disconnect previously connected signals
	if index_pressed.is_connected(_on_clicked_from_object):
		index_pressed.disconnect(_on_clicked_from_object)
	if index_pressed.is_connected(_on_clicked_from_collection):
		index_pressed.disconnect(_on_clicked_from_collection)
	if index_pressed.is_connected(_on_clicked_from_object_group):
		index_pressed.disconnect(_on_clicked_from_object_group)
	clear()
	set_position(get_viewport().get_mouse_position())

func _on_menu_created(type: RightClickMenu.TYPE, objects: Array):
	_reset_popup_menu()
	print("Menu created. Position: ",position)
	object_group = objects
	match type:
		TYPE.GAME_OBJECT:
			init_game_object_menu()
		TYPE.COLLECTION:
			init_collection_menu()
		TYPE.OBJECT_GROUP:
			init_object_group_menu()
		_:
			print("None")
	reset_size()
	popup()

func init_game_object_menu() -> void:
	add_item("Flip object", 0)
	var ordering_menu = PopupMenu.new()
	ordering_menu.name = "ordering"
	add_child(ordering_menu)
	add_submenu_item("Ordering", "ordering", 1)
	ordering_menu.add_item("Bring to front", 2)
	ordering_menu.add_item("Send to back", 3)
	id_pressed.connect(_on_clicked_from_object)
	ordering_menu.id_pressed.connect(_on_clicked_from_object)
	
# TODO: FIX RIGHT CLICK MENU
func init_collection_menu():
	add_item("Shuffle collection", 0)
	add_item("Flip collection", 1)
	var ordering_menu = PopupMenu.new()
	ordering_menu.name = "ordering"
	add_child(ordering_menu)
	add_submenu_item("Ordering", "ordering", 2)
	ordering_menu.add_item("Go to front", 3)
	ordering_menu.add_item("Send to back", 4)
	var orientation_menu = PopupMenu.new()
	orientation_menu.name = "orientation"
	id_pressed.connect(_on_clicked_from_collection)
	ordering_menu.id_pressed.connect(_on_clicked_from_collection)
	orientation_menu.id_pressed.connect(_on_clicked_from_collection)

func init_object_group_menu():
	add_item("Stack selection", 0)
	add_item("Flip selection", 1)
	var ordering_menu = PopupMenu.new()
	ordering_menu.name = "ordering"
	add_child(ordering_menu)
	add_submenu_item("Ordering", "ordering", 2)
	ordering_menu.add_item("Go to front", 3)
	ordering_menu.add_item("Send to back", 4)
	id_pressed.connect(_on_clicked_from_object_group)
	ordering_menu.id_pressed.connect(_on_clicked_from_object_group)

# RIGHT CLICK MENU FUNCIONALITIES

func _on_clicked_from_object(id: int) -> void:
	match id:
		0: _flip_selected_objects()
		2: _move_objects_to_front()
		3: _move_objects_to_back()

func _on_clicked_from_collection(id: int) -> void:
	match id:
		0: _shuffle_collection()
		1: _flip_selected_objects()
		3: _move_objects_to_front()
		4: _move_objects_to_back()

func _on_clicked_from_object_group(id: int) -> void:
	match id:
		0: _stack_selected_objects()
		1: _flip_selected_objects()
		3: _move_objects_to_front()
		4: _move_objects_to_back()

func _shuffle_collection() -> void:
	for object in object_group:
		if object is GameCollection:
			(object as GameCollection).shuffle()

func _flip_selected_objects() -> void:
	print("Flip objects")
	for object in object_group:
		object.flip()

func _set_objects_orientation(flipped: bool) -> void:
	for object in object_group:
		object.set_side(flipped)

func _move_objects_to_front() -> void:
	SignalManager.move_items_to_front.emit(object_group)

func _move_objects_to_back() -> void:
	SignalManager.move_items_to_back.emit(object_group)

func _stack_selected_objects() -> void:
	SignalManager.convert_to_stack.emit(object_group)

func _on_popup_hide() -> void:
	SignalManager.game_menu_destroy.emit()
