extends Node

var item_selected: Array = []

var _current_mouse_state: MOUSE_STATE = MOUSE_STATE.BASIC


enum MOUSE_STATE {
	BASIC,
	GRAB
}

func set_mouse_state(state: MOUSE_STATE) -> void:
	_current_mouse_state = state

func get_mouse_state() -> MOUSE_STATE:
	return _current_mouse_state
