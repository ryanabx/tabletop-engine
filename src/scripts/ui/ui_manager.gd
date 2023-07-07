class_name UiManager
extends CanvasLayer

var rclick_menu: RightClickMenu = null


func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if rclick_menu == null and GameManager.highlighted_over_item():
			if GameManager.get_highlighted_item().get_state() == GameObject.GAME_OBJECT_STATE.GRABBED or GameManager.get_highlighted_item().get_state() == GameObject.GAME_OBJECT_STATE.GRABBED_OVER_COLLECTION:
				GameManager.get_highlighted_item().flip_over()
			else:
				rclick_menu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.GAME_OBJECT, GameManager.get_highlighted_item(), self)
				rclick_menu.global_position = get_viewport().get_mouse_position()
				print("Created right click menu!")
				add_child(rclick_menu)
	elif event is InputEventMouseButton and rclick_menu != null and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not rclick_menu.get_global_rect().has_point(rclick_menu.get_global_mouse_position()):
			destroy_rclick_menu()

func destroy_rclick_menu():
	rclick_menu._set_object_highlight(false)
	rclick_menu.queue_free()
	print("Right click menu destroyed")
	rclick_menu = null
	
