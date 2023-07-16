class_name ObjectStack
extends GameCollection

const DEF_PADDING: Vector2 = Vector2(5.0, 5.0)
const DEF_BORDERSIZE: float = 2.0
const H_PADDING: Vector2 = Vector2(7.0, 7.0)
const H_BORDERSIZE: float = 5.0

var _padding: Vector2 = DEF_PADDING
var _outline_size: float = DEF_BORDERSIZE

var _hue: float = 0.0

func _update_bounds() -> void:
	var larg_x: float = 0.0
	var larg_y: float = 0.0
	
	var _max_index = _get_max_index()
	
	for obj in _game_objects:
		obj.position = position
		get_parent().move_child(obj, _max_index)
		obj.set_obj_stack(self)
		var _sc = obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
	_scale = Vector2(larg_x, larg_y)

func _draw() -> void:
	draw_rect(Rect2(- _scale / 2.0, _scale), Color.from_hsv(0.0, 0.0, 0.0, 0.2), true)
	draw_rect(Rect2(- (_scale + _padding) / 2.0, (_scale + _padding)), Color.from_hsv(clampf(_hue, 0.0, 1.0), 0.5, 1.0), false, _outline_size)

func _process(delta: float) -> void:
	super._process(delta)
	_hue = _hue + 0.1 * delta
	if _hue >= 1.0:
		_hue = _hue - 1.0
	queue_redraw()
