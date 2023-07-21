class_name RightClickMenu
extends PopupMenu

enum TYPE {NONE,GAME_OBJECT,OBJECT_GROUP,COLLECTION}

var item: GameItem = null
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
	match type:
		TYPE.GAME_OBJECT:
			item = objects[0]
			object_group = []
			init_game_object_menu()
		TYPE.COLLECTION:
			item = objects[0]
			object_group = []
			init_collection_menu()
		TYPE.OBJECT_GROUP:
			item = null
			object_group = objects
			init_object_group_menu()
		_:
			print("None")
	reset_size()
	popup()

func init_game_object_menu() -> void:
	add_item("Flip object")
	add_item("Go to front")
	add_item("Send to back")
	index_pressed.connect(_on_clicked_from_object)
	

func init_collection_menu():
	add_item("Shuffle collection")
	add_item("Flip collection")
	add_item("Go to front")
	add_item("Send to back")
	index_pressed.connect(_on_clicked_from_collection)

func init_object_group_menu():
	add_item("Convert to stack")
	add_item("Flip selection")
	add_item("Go to front")
	add_item("Send to back")
	index_pressed.connect(_on_clicked_from_object_group)

# RIGHT CLICK MENU FUNCIONALITIES

func _on_clicked_from_collection(index: int) -> void:
	match index:
		0: _shuffle_collection()
		1: _flip_item()
		2: _move_item_to_front()
		3: _move_item_to_back()

func _on_clicked_from_object(index: int) -> void:
	match index:
		0: _flip_item()
		1: _move_item_to_front()
		2: _move_item_to_back()

func _on_clicked_from_object_group(index: int) -> void:
	match index:
		0: _stack_selected_objects()
		1: _flip_item()
		2: _move_objects_to_front()
		3: _move_objects_to_back()

func _shuffle_collection() -> void:
	(item as GameCollection).shuffle()

func _flip_item() -> void:
	SignalManager.flip_items.emit([item])

func _move_item_to_front() -> void:
	SignalManager.move_items_to_front.emit([item])

func _move_item_to_back() -> void:
	SignalManager.move_items_to_back.emit([item])

func _flip_selected_objects() -> void:
	SignalManager.flip_items.emit(object_group)

func _move_objects_to_front() -> void:
	SignalManager.move_items_to_front.emit(object_group)

func _move_objects_to_back() -> void:
	SignalManager.move_items_to_back.emit(object_group)

func _stack_selected_objects() -> void:
	SignalManager.convert_to_stack.emit(object_group)

func _on_popup_hide() -> void:
	SignalManager.game_menu_destroy.emit()
