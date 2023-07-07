class_name RightClickMenuButton
extends Button

enum MENU_BUTTON_TYPE {
	BLANK
}

enum MENU_BUTTON_FUNCTIONALITY {
	BLANK,
	GO_TO_BACK,
	GO_TO_FRONT,
	FLIP_OBJECT
}

var _button_type: MENU_BUTTON_TYPE = MENU_BUTTON_TYPE.BLANK
var _button_functionality: MENU_BUTTON_FUNCTIONALITY = MENU_BUTTON_FUNCTIONALITY.BLANK

var _parent: RightClickMenu = null

func _init(parent: RightClickMenu, button_type: MENU_BUTTON_TYPE, button_functionality: MENU_BUTTON_FUNCTIONALITY):
	self._parent = parent
	self._button_type = button_type
	self._button_functionality = button_functionality
	self.pressed.connect(_on_pressed)
	


func _on_pressed() -> void:
	match _button_functionality:
		MENU_BUTTON_FUNCTIONALITY.BLANK:
			return
		MENU_BUTTON_FUNCTIONALITY.GO_TO_FRONT:
			_parent.get_associated_object()._move_self_to_top()
			_parent.destroy_menu()
		MENU_BUTTON_FUNCTIONALITY.GO_TO_BACK:
			_parent.get_associated_object()._move_self_to_back()
			_parent.destroy_menu()
		MENU_BUTTON_FUNCTIONALITY.FLIP_OBJECT:
			_parent.get_associated_object().flip_over()
			_parent.destroy_menu()
