extends Control


func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GameManager.highlighted_over_item():
			var new_menu: RightClickMenu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.GAME_OBJECT, GameManager.get_highlighted_item())
			new_menu.global_position = get_global_mouse_position()
			print("Created right click menu!")
			add_child(new_menu)
