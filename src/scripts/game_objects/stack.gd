class_name ObjectStack
extends GameCollection

var base_size: Vector2 = Vector2.ZERO

func _update_objects() -> void:
	super._update_objects()
	var larg_x: float = base_size.x
	var larg_y: float = base_size.y
	
	var _max_index = _get_max_index()
	z_index = _max_index + 1

	if not get_permanence() and get_num_objects() > 0 and position != get_game_objects()[-1].position:
		position = get_game_objects()[-1].position
	
	for obj in _game_objects:
		obj.position = position
		get_parent().move_child(obj, _max_index)
		var _sc = obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
	_scale = Vector2(larg_x, larg_y)

func add_game_object_special(obj: GameObject) -> void:
	add_game_object_to_top(obj)

func _draw() -> void:
	super._draw()

func _process(delta: float) -> void:
	super._process(delta)
