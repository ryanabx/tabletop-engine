class_name UiManager
extends CanvasLayer

var rclick_menu: RightClickMenu = null

var parent: Tabletop = null

func _ready() -> void:
	if get_parent() != null:
		parent = get_parent()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if rclick_menu == null and GameManager.highlighted_over_item():
			if GameManager.get_highlighted_item().get_state() == GameObject.GAME_OBJECT_STATE.GRABBED or GameManager.get_highlighted_item().get_state() == GameObject.GAME_OBJECT_STATE.GRABBED_OVER_COLLECTION:
				GameManager.get_highlighted_item().flip_over()
			else:
				rclick_menu = RightClickMenu.new(RightClickMenu.RIGHT_CLICK_MENU_TYPE.GAME_OBJECT, GameManager.get_highlighted_item(), self)
				rclick_menu.global_position = get_viewport().get_mouse_position()
				add_child(rclick_menu)
	elif event is InputEventMouseButton and rclick_menu != null and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not rclick_menu.get_global_rect().has_point(rclick_menu.get_global_mouse_position()):
			destroy_rclick_menu()

func destroy_rclick_menu():
	rclick_menu._set_object_highlight(false)
	rclick_menu.queue_free()
	rclick_menu = null
	
