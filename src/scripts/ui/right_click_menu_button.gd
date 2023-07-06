extends Button

enum MENU_BUTTON_TYPE {
	BLANK
}

var button_type: MENU_BUTTON_TYPE = MENU_BUTTON_TYPE.BLANK

var parent = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent():
		parent = get_parent()


func _on_pressed():
	match button_type:
		MENU_BUTTON_TYPE.BLANK:
			return
