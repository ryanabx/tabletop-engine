class_name ObjectStack
extends GameCollection

func _update_objects() -> void:
	super._update_objects()
	var larg_x: float = 0
	var larg_y: float = 0
	
	var _max_index = _get_max_index()

	if not get_permanence() and get_num_objects() > 0 and position != get_game_objects()[-1].position:
		position = get_game_objects()[-1].position
	
	for obj in _game_objects:
		if force_state is bool:
			obj.set_side(force_state as bool)
		obj.position = position
		obj.rotation = rotation
		obj.get_parent().move_child(obj, _max_index)
		var _sc = obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
	if get_num_objects() > 0:
		_scale = Vector2(larg_x, larg_y)
	else:
		_scale = base_size

func add_game_object_special(obj: Piece) -> void:
	if obj in get_game_objects():
		print("Cannot add object when already added")
		return
	add_game_object_to_top(obj)

func _draw() -> void:
	super._draw()

func _process(delta: float) -> void:
	super._process(delta)
