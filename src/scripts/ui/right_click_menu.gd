class_name RightClickMenu
extends VBoxContainer

enum RIGHT_CLICK_MENU_TYPE {
	BLANK,
	GAME_OBJECT
}

var menu_type: RIGHT_CLICK_MENU_TYPE
var associated_object: GameObject = null
var _ui_manager: UiManager

func _init(menu_type: RIGHT_CLICK_MENU_TYPE, associated_object: GameObject, ui_manager: UiManager) -> void:
	self.menu_type = menu_type
	self.associated_object = associated_object
	self._ui_manager = ui_manager

func _ready() -> void:
	_populate_right_click_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not get_global_rect().has_point(get_global_mouse_position()):
			_ui_manager.destroy_rclick_menu()

func _set_object_highlight(highlight: bool):
	if associated_object != null:
		associated_object.modulate.g = 0.8 if highlight else 1.0

func _populate_right_click_menu():
	match menu_type:
		RIGHT_CLICK_MENU_TYPE.GAME_OBJECT:
			_set_object_highlight(true)
			var go_to_back = RightClickMenuButton.new(self, RightClickMenuButton.MENU_BUTTON_TYPE.BLANK)
			go_to_back.text = "Go to back"
			add_child(go_to_back)
		_:
			return

func _determine_right_click_type():
	if GameManager.highlighted_over_item():
		return RIGHT_CLICK_MENU_TYPE.GAME_OBJECT
	return RIGHT_CLICK_MENU_TYPE.BLANK

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
