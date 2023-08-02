class_name Hand
extends GameCollection

const V_PADDING = 16.0

func disabled() -> bool:
	return false

func _process(delta: float) -> void:
	super._process(delta)

func _update_objects() -> void:
	if not is_multiplayer_authority():
		return
	super._update_objects()
	var num_objects: int = get_num_objects()
	var _max_index = get_max_index()
	
	var larg_x: float = 0
	var larg_y: float = 0
	var i: int = 0
	for obj in get_game_objects():
		get_parent().move_child(obj, _max_index)
		if force_state is bool:
			obj.set_side(force_state as bool)
		var _lerp_amt: float = (i + 1.0) / (num_objects + 1.0)
		var _pos: Vector2 = to_global(Vector2(get_rect().position.x, get_rect().get_center().y)).lerp(to_global(Vector2(get_rect().end.x, get_rect().get_center().y)), _lerp_amt)
		obj.position = _pos
		obj.rotation = rotation
		var _sc = obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
		i += 1
	if num_objects > 0:
		_scale = Vector2(base_size.x, larg_y)
	else:
		_scale = base_size

func add_game_object_special(obj: Piece) -> void:
	if obj in get_game_objects():
		print("Cannot add object when already added")
		return
	var i: int = 0
	for a in range(get_num_objects()):
		if to_local(obj.position).x < to_local(get_game_objects()[a].position).x:
			break
		i = i + 1
	insert_game_object(obj, i)