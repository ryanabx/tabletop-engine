class_name ObjectStack
extends GameCollection

func _update_objects() -> void:
	super._update_objects()
	var larg_x: float = 0
	var larg_y: float = 0
	
	var max_index = get_max_index()

	if not get_permanence() and get_num_objects() > 0 and position != get_game_objects()[-1].position:
		position = get_game_objects()[-1].position
	
	for obj in get_game_objects():
		if force_state is bool:
			obj.set_side(force_state as bool)
		obj.position = position
		obj.rotation = rotation
		obj.get_parent().move_child(obj, max_index)
		var _sc = obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
	if get_num_objects() > 0:
		_scale = Vector2(larg_x, larg_y)
	else:
		_scale = base_size
