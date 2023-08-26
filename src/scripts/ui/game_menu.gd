class_name RightClickMenu
extends PopupMenu

var piece: Piece = null
var collection: Collection = null

func _ready() -> void:
	SignalManager.game_menu_create_piece.connect(_on_menu_created)
	SignalManager.game_menu_create_collection.connect(_on_collection_menu_created)
	hide()
	popup_hide.connect(_on_popup_hide)

func reset_menu() -> void:
	set_position(Vector2.ZERO)
	# Disconnect previously connected signals
	if id_pressed.is_connected(_on_clicked_from_object):
		id_pressed.disconnect(_on_clicked_from_object)
	if id_pressed.is_connected(_on_clicked_from_collection):
		id_pressed.disconnect(_on_clicked_from_collection)
	clear()
	set_position(get_viewport().get_mouse_position())

func _on_menu_created(pc: Piece) -> void:
	reset_menu()
	print("Piece Menu created.")
	piece = pc
	collection = null
	init_piece_menu()
	reset_size()
	popup()

func _on_collection_menu_created(coll: Collection) -> void:
	reset_menu()
	print("Collection menu created")
	piece = null
	collection = coll
	init_collection_menu()
	reset_size()
	popup()

func init_collection_menu() -> void:
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

# RIGHT CLICK MENU FUNCIONALITIES

func _on_clicked_from_object(id: int) -> void:
	match id:
		0: _flip_selected_objects()
		2: _move_objects_to_front()
		3: _move_objects_to_back()

func _on_clicked_from_collection(id: int) -> void:
	match id:
		1: collection.flip()
		3: collection.move_self_to_front.rpc()
		4: collection.move_self_to_back.rpc()
		5: collection.set_orientation(true)
		6: collection.set_orientation(false)
		8: collection.shuffle()
		9: collection.board.board_player._select_collection(collection)

func _flip_selected_objects() -> void:
	piece.face_up = not piece.face_up

func _set_objects_orientation(side: bool) -> void:
	piece.face_up = side

func _move_objects_to_front() -> void:
	piece.move_self_to_top.rpc()

func _move_objects_to_back() -> void:
	piece.move_self_to_back.rpc()

func _on_popup_hide() -> void:
	SignalManager.game_menu_destroy.emit()
