class_name RightClickMenu
extends PopupMenu

var object_group: Array[Piece] = []
var collection: Collection = null

func _ready() -> void:
	SignalManager.game_menu_create.connect(_on_menu_created)
	SignalManager.game_menu_create_collection.connect(_on_collection_menu_created)
	hide()
	popup_hide.connect(_on_popup_hide)

func reset_menu() -> void:
	set_position(Vector2.ZERO)
	# Disconnect previously connected signals
	if id_pressed.is_connected(_on_clicked_from_object):
		id_pressed.disconnect(_on_clicked_from_object)
	if id_pressed.is_connected(_on_clicked_from_object_group):
		id_pressed.disconnect(_on_clicked_from_object_group)
	if id_pressed.is_connected(_on_clicked_from_collection):
		id_pressed.disconnect(_on_clicked_from_collection)
	clear()
	set_position(get_viewport().get_mouse_position())

func _on_menu_created(objects: Array) -> void:
	reset_menu()
	print("Menu created.")
	object_group = objects.duplicate(false)
	collection = null
	if object_group.size() > 1:
		init_group_menu()
	else:
		init_piece_menu()
	reset_size()
	popup()

func _on_collection_menu_created(coll: Collection) -> void:
	reset_menu()
	print("Collection menu created")
	object_group = []
	collection = coll
	init_collection_menu()
	reset_size()
	popup()

func init_collection_menu() -> void:
	add_item("Convert to stack", 0)
	add_item("Shuffle", 8)
	var orientation_menu = PopupMenu.new()
	orientation_menu.add_item("Face up", 5)
	orientation_menu.add_item("Face down", 6)
	orientation_menu.add_item("Flip selection", 1)
	add_child(orientation_menu)
	orientation_menu.name = "orientation"
	add_submenu_item("Set Orientation", "orientation", 7)
	var ordering_menu = PopupMenu.new()
	ordering_menu.name = "ordering"
	add_child(ordering_menu)
	add_submenu_item("Ordering", "ordering", 2)
	ordering_menu.add_item("Go to front", 3)
	ordering_menu.add_item("Send to back", 4)
	id_pressed.connect(_on_clicked_from_collection)
	ordering_menu.id_pressed.connect(_on_clicked_from_collection)
	orientation_menu.id_pressed.connect(_on_clicked_from_collection)
	add_item("Select group", 9)

func init_piece_menu() -> void:
	add_item("Flip object", 0)
	var ordering_menu = PopupMenu.new()
	ordering_menu.name = "ordering"
	add_child(ordering_menu)
	add_submenu_item("Ordering", "ordering", 1)
	ordering_menu.add_item("Bring to front", 2)
	ordering_menu.add_item("Send to back", 3)
	id_pressed.connect(_on_clicked_from_object)
	ordering_menu.id_pressed.connect(_on_clicked_from_object)

func init_group_menu():
	add_item("Convert to stack", 0)
	add_item("Shuffle", 8)
	var orientation_menu = PopupMenu.new()
	orientation_menu.add_item("Face up", 5)
	orientation_menu.add_item("Face down", 6)
	orientation_menu.add_item("Flip selection", 1)
	add_child(orientation_menu)
	orientation_menu.name = "orientation"
	add_submenu_item("Set Orientation", "orientation", 7)
	var ordering_menu = PopupMenu.new()
	ordering_menu.name = "ordering"
	add_child(ordering_menu)
	add_submenu_item("Ordering", "ordering", 2)
	ordering_menu.add_item("Go to front", 3)
	ordering_menu.add_item("Send to back", 4)
	id_pressed.connect(_on_clicked_from_object_group)
	ordering_menu.id_pressed.connect(_on_clicked_from_object_group)
	orientation_menu.id_pressed.connect(_on_clicked_from_object_group)
	add_item("Select group", 9)

# RIGHT CLICK MENU FUNCIONALITIES

func _on_clicked_from_object(id: int) -> void:
	match id:
		0: _flip_selected_objects()
		2: _move_objects_to_front()
		3: _move_objects_to_back()

func _on_clicked_from_object_group(id: int) -> void:
	match id:
		0: _stack_selected_objects()
		1: _flip_selected_objects()
		3: _move_objects_to_front()
		4: _move_objects_to_back()
		5: _set_objects_orientation(true)
		6: _set_objects_orientation(false)
		8: _shuffle_selection()
		9: _select_objects(true)

func _on_clicked_from_collection(id: int) -> void:
	match id:
		0: print("Not implemented")
		1: collection.flip()
		3: collection.move_self_to_front.rpc()
		4: collection.move_self_to_back.rpc()
		5: collection.set_orientation(true)
		6: collection.set_orientation(false)
		8: collection.shuffle()
		9: collection.board.board_player.select_collections([collection])

func _flip_selected_objects() -> void:
	for obj in object_group:
		obj.flip()

func _set_objects_orientation(side: bool) -> void:
	for obj in object_group:
		obj.set_face(side)

func _move_objects_to_front() -> void:
	for obj in object_group:
		obj.move_self_to_top.rpc()

func _move_objects_to_back() -> void:
	for obj in object_group:
		obj.move_self_to_back.rpc()

func _stack_selected_objects() -> void:
	SignalManager.convert_to_stack.emit(object_group)

func _shuffle_selection() -> void:
	SignalManager.shuffle_selection.emit(object_group)

func _on_popup_hide() -> void:
	SignalManager.game_menu_destroy.emit()

func _select_objects(with_collections: bool) -> void:
	SignalManager.select_objects.emit(object_group, with_collections)
