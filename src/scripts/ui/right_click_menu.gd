extends VBoxContainer

enum RIGHT_CLICK_MENU_TYPE {
	BLANK,
	GAME_OBJECT
}

var menu_type: RIGHT_CLICK_MENU_TYPE


# Called when the node enters the scene tree for the first time.
func _ready():
	menu_type = _determine_right_click_type()

func _determine_right_click_type():
	if GameManager.highlighted_over_item():
		return RIGHT_CLICK_MENU_TYPE.GAME_OBJECT
	return RIGHT_CLICK_MENU_TYPE.BLANK

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
