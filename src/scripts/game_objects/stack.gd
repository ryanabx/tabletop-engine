class_name ObjectStack
extends GameCollection

var permastack: bool = false


func _update_objects() -> void:
	var larg_x: float = 0.0
	var larg_y: float = 0.0
	
	var _max_index = _get_max_index()
	z_index = _max_index + 1

	if get_num_objects() > 0:
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

func remove_object_at(index: int) -> void:
	super.remove_object_at(index)
	if not permastack:
		if get_num_objects() == 1:
			remove_object_at(0)
		elif get_num_objects() == 0:
			print("remove stack")
			queue_free()

func _draw() -> void:
	super._draw()

func _process(delta: float) -> void:
	super._process(delta)
	queue_redraw()
