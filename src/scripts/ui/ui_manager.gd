class_name UiManager
extends Control

var rclick_menu: RightClickMenu = null


func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and rclick_menu == null:
		if GameManager.highlighted_over_item():
			rclick_menu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.GAME_OBJECT, GameManager.get_highlighted_item(), self)
			rclick_menu.global_position = get_global_mouse_position()
			print("Created right click menu!")
			add_child(rclick_menu)

func destroy_rclick_menu():
	rclick_menu.queue_free()
	print("Right click menu destroyed")
	rclick_menu = null
	
