class_name RightClickMenu
extends VBoxContainer

enum RIGHT_CLICK_MENU_TYPE {
	BLANK,
	GAME_OBJECT
}

var menu_type: RIGHT_CLICK_MENU_TYPE
var associated_object: GameObject = null

func _init(menu_type: RIGHT_CLICK_MENU_TYPE, associated_object: GameObject) -> void:
	self.menu_type = menu_type
	self.associated_object = associated_object

func _ready() -> void:
	_populate_right_click_menu()

func _populate_right_click_menu():
	match menu_type:
		RIGHT_CLICK_MENU_TYPE.GAME_OBJECT:
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
