class_name RightClickMenuButton
extends Button

enum MENU_BUTTON_TYPE {
	BLANK
}

var _button_type: MENU_BUTTON_TYPE = MENU_BUTTON_TYPE.BLANK

var _parent: RightClickMenu = null

func _init(parent: RightClickMenu, button_type: MENU_BUTTON_TYPE):
	self._parent = parent
	self._button_type = button_type


func _on_pressed():
	match _button_type:
		MENU_BUTTON_TYPE.BLANK:
			return
