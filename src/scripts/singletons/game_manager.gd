extends Node

var _item_selected: Array = []

var _current_mouse_state: MOUSE_STATE = MOUSE_STATE.BASIC


enum MOUSE_STATE {
	BASIC,
	GRAB
}

func set_mouse_state(state: MOUSE_STATE) -> void:
	_current_mouse_state = state

func get_mouse_state() -> MOUSE_STATE:
	return _current_mouse_state

func highlighted_over_item() -> bool:
	return _item_selected.size() > 0

func has_selection_lock(obj: GameObject) -> bool:
	return _item_selected.size() > 0 and _item_selected[0] == obj

func grab_selection_lock(obj: GameObject) -> void:
	var index = 0
	while _item_selected.size() > index and _item_selected[index].get_index() < obj.get_index():
		index+=1
	_item_selected.insert(index, obj)

func release_selection_lock(obj: GameObject) -> void:
	_item_selected.erase(obj)
