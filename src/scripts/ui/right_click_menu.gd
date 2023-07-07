class_name RightClickMenu
extends VBoxContainer

enum RIGHT_CLICK_MENU_TYPE {
	BLANK,
	GAME_OBJECT
}

var _menu_type: RIGHT_CLICK_MENU_TYPE
var _associated_object: GameObject = null
var _ui_manager: UiManager

func _init(menu_type: RIGHT_CLICK_MENU_TYPE, associated_object: GameObject, ui_manager: UiManager) -> void:
	self._menu_type = menu_type
	self._associated_object = associated_object
	self._ui_manager = ui_manager

func _ready() -> void:
	_populate_right_click_menu()

func destroy_menu():
	_ui_manager.destroy_rclick_menu()

func _set_object_highlight(highlight: bool):
	if _associated_object != null:
		if highlight:
			_associated_object.set_my_state(GameObject.GAME_OBJECT_STATE.RIGHT_CLICKED)
		else:
			_associated_object.set_my_state(GameObject.GAME_OBJECT_STATE.OPEN)			

func _populate_right_click_menu():
	match _menu_type:
		RIGHT_CLICK_MENU_TYPE.GAME_OBJECT:
			_set_object_highlight(true)
			var flip_object = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.FLIP_OBJECT)
			flip_object.text = "Flip object"
			add_child(flip_object)
			var go_to_front = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.GO_TO_FRONT)
			go_to_front.text = "Bring to front"
			add_child(go_to_front)
			var go_to_back = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK, RightClickMenuButton.MENU_BUTTON_FUNCTIONALITY.GO_TO_BACK)
			go_to_back.text = "Send to back"
			add_child(go_to_back)
		_:
			return

func _determine_right_click_type():
	if GameManager.highlighted_over_item():
		return RIGHT_CLICK_MENU_TYPE.GAME_OBJECT
	return RIGHT_CLICK_MENU_TYPE.BLANK

func get_associated_object() -> GameObject:
	return _associated_object
