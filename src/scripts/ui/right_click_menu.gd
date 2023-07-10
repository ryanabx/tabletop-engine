class_name RightClickMenu
extends VBoxContainer

enum RIGHT_CLICK_MENU_TYPE {
	BLANK,
	GAME_OBJECT,
	STACK
}

var _menu_type: RIGHT_CLICK_MENU_TYPE
var _associated_object: GameObject = null
var _board: GameBoard
var _associated_stack: ObjectStack

func _init(menu_type: RIGHT_CLICK_MENU_TYPE, associated_object: GameObject, associated_stack: ObjectStack, board: GameBoard) -> void:
	self._menu_type = menu_type
	self._associated_object = associated_object
	self._associated_stack = associated_stack
	self._board = board

func _ready() -> void:
	_populate_right_click_menu()

func destroy_menu():
	get_board().destroy_rclick_menu()

func _populate_right_click_menu():
	match _menu_type:
		RIGHT_CLICK_MENU_TYPE.GAME_OBJECT:
			var flip_object = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.FLIP_OBJECT)
			flip_object.text = "Flip object"
			add_child(flip_object)
			var go_to_front = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.GO_TO_FRONT)
			go_to_front.text = "Bring to front"
			add_child(go_to_front)
			var go_to_back = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.GO_TO_BACK)
			go_to_back.text = "Send to back"
			add_child(go_to_back)
		RIGHT_CLICK_MENU_TYPE.STACK:
			var flip_stack = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.FLIP_STACK)
			flip_stack.text = "Flip stack"
			add_child(flip_stack)
			var shuffle_stack = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.SHUFFLE_STACK)
			shuffle_stack.text = "Shuffle"
			add_child(shuffle_stack)
		_:
			return

func get_associated_object() -> GameObject:
	return _associated_object

func get_associated_stack() -> ObjectStack:
	return _associated_stack

func get_board() -> GameBoard:
	return _board
