class_name RightClickMenu
extends VBoxContainer

enum TYPE {NONE,GAME_OBJECT,OBJECT_GROUP,COLLECTION}

var type: TYPE = TYPE.NONE
var item: GameItem = null
var object_group: Array = []
var board: GameBoard = null

static func from_collection(collection: GameCollection, brd: GameBoard) -> RightClickMenu:
	var rclick_menu = RightClickMenu.new()
	rclick_menu.type = TYPE.COLLECTION
	rclick_menu.item = collection
	rclick_menu.board = brd
	return rclick_menu

static func from_game_object(object: GameObject, brd: GameBoard) -> RightClickMenu:
	var rclick_menu = RightClickMenu.new()
	rclick_menu.type = TYPE.GAME_OBJECT
	rclick_menu.item = object
	rclick_menu.board = brd
	return rclick_menu

static func from_object_group(objects: Array, brd: GameBoard) -> RightClickMenu:
	var rclick_menu = RightClickMenu.new()
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
	add_child(RightClickMenuButton.new("Flip object", self._flip_item))
	add_child(RightClickMenuButton.new("Go to front", self._move_item_to_front))
	add_child(RightClickMenuButton.new("Send to back", self._move_item_to_back))

func init_collection_menu():
	add_child(RightClickMenuButton.new("Flip collection", self._flip_item))
	add_child(RightClickMenuButton.new("Shuffle collection", self._shuffle_collection))
	add_child(RightClickMenuButton.new("Go to front", self._move_item_to_front))
	add_child(RightClickMenuButton.new("Send to back", self._move_item_to_back))

func init_object_group_menu():
	add_child(RightClickMenuButton.new("Flip selection", self._flip_selected_objects))
	add_child(RightClickMenuButton.new("Go to front", self._move_objects_to_front))
	add_child(RightClickMenuButton.new("Send to back", self._move_objects_to_back))

# RIGHT CLICK MENU FUNCIONALITIES

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