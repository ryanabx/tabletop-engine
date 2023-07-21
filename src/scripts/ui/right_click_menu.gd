class_name RightClickMenu
extends Control

enum TYPE {NONE,GAME_OBJECT,OBJECT_GROUP,COLLECTION}

var type: TYPE = TYPE.NONE
var item: GameItem = null
var object_group: Array = []
var board: GameBoard = null

@onready var popupmenu: PopupMenu = $PopupMenu

static var menu_scene = load("res://src/scenes/ui/right_click_menu.tscn")

static func from_collection(collection: GameCollection, brd: GameBoard) -> RightClickMenu:
	var rclick_menu = RightClickMenu.menu_scene.instantiate()
	rclick_menu.type = TYPE.COLLECTION
	rclick_menu.item = collection
	rclick_menu.board = brd
	return rclick_menu

static func from_game_object(object: GameObject, brd: GameBoard) -> RightClickMenu:
	var rclick_menu = RightClickMenu.menu_scene.instantiate()
	rclick_menu.type = TYPE.GAME_OBJECT
	rclick_menu.item = object
	rclick_menu.board = brd
	return rclick_menu

static func from_object_group(objects: Array, brd: GameBoard) -> RightClickMenu:
	var rclick_menu = RightClickMenu.menu_scene.instantiate()
	rclick_menu.type = TYPE.OBJECT_GROUP
	rclick_menu.object_group = objects
	rclick_menu.board = brd
	return rclick_menu

func _ready() -> void:
	match type:
		TYPE.GAME_OBJECT:
			init_game_object_menu()
		TYPE.COLLECTION:
			init_collection_menu()
		TYPE.OBJECT_GROUP:
			init_object_group_menu()
		_:
			print("None")

func init_game_object_menu() -> void:
	popupmenu.add_item("Flip object")
	popupmenu.add_item("Go to front")
	popupmenu.add_item("Send to back")
	popupmenu.position = position
	popupmenu.index_pressed.connect(_on_clicked_from_object)
	popupmenu.popup()

func init_collection_menu():
	popupmenu.add_item("Shuffle collection")
	popupmenu.add_item("Flip collection")
	popupmenu.add_item("Go to front")
	popupmenu.add_item("Send to back")
	popupmenu.position = position
	popupmenu.index_pressed.connect(_on_clicked_from_collection)
	popupmenu.popup()

func init_object_group_menu():
	popupmenu.add_item("Convert to stack")
	popupmenu.add_item("Flip selection")
	popupmenu.add_item("Go to front")
	popupmenu.add_item("Send to back")
	popupmenu.position = position
	popupmenu.index_pressed.connect(_on_clicked_from_object_group)
	popupmenu.popup()

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
	board.destroy_rclick_menu()

func _flip_item() -> void:
	item.flip()
	board.destroy_rclick_menu()

func _move_item_to_front() -> void:
	board.move_item_to_front(item)
	board.destroy_rclick_menu()

func _move_item_to_back() -> void:
	board.move_item_to_back(item)
	board.destroy_rclick_menu()

func _flip_selected_objects() -> void:
	for object in object_group:
		object.flip()
	board.destroy_rclick_menu()

func _move_objects_to_front() -> void:
	for object in object_group:
		board.move_item_to_front(object)
	board.destroy_rclick_menu()

func _move_objects_to_back() -> void:
	for object in object_group:
		board.move_item_to_back(object)
	board.destroy_rclick_menu()

func _stack_selected_objects() -> void:
	board.convert_to_stack(object_group)
	board.destroy_rclick_menu()
