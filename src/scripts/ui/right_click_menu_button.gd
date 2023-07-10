class_name RightClickMenuButton
extends Button

enum MENU_BUTTON_TYPE {
	BLANK
}

enum MENU_BUTTON_FUNCTIONALITY {
	BLANK,
	GO_TO_BACK,
	GO_TO_FRONT,
	FLIP_OBJECT,
	FLIP_STACK,
	SHUFFLE_STACK
}

var _button_type: MENU_BUTTON_TYPE = MENU_BUTTON_TYPE.BLANK
var _button_functionality: MENU_BUTTON_FUNCTIONALITY = MENU_BUTTON_FUNCTIONALITY.BLANK

var _parent: RightClickMenu = null
var _board: GameBoard = null

func _init(parent: RightClickMenu, button_type: MENU_BUTTON_TYPE, button_functionality: MENU_BUTTON_FUNCTIONALITY):
	self._parent = parent
	self._button_type = button_type
	self._button_functionality = button_functionality
	self.pressed.connect(_on_pressed)
	self._board = parent.get_board()


func _on_pressed() -> void:
	match _button_functionality:
		MENU_BUTTON_FUNCTIONALITY.BLANK:
			return
		MENU_BUTTON_FUNCTIONALITY.GO_TO_FRONT:
			_board.move_object_to_front(_parent.get_associated_object())
			_board.destroy_rclick_menu()
		MENU_BUTTON_FUNCTIONALITY.GO_TO_BACK:
			_board.move_object_to_back(_parent.get_associated_object())
			_board.destroy_rclick_menu()
		MENU_BUTTON_FUNCTIONALITY.FLIP_OBJECT:
			_parent.get_associated_object().flip()
			_board.destroy_rclick_menu()
		MENU_BUTTON_FUNCTIONALITY.FLIP_STACK:
			_parent.get_associated_stack().flip()
			_board.destroy_rclick_menu()
		MENU_BUTTON_FUNCTIONALITY.SHUFFLE_STACK:
			_parent.get_associated_stack().shuffle()
			_board.destroy_rclick_menu()
