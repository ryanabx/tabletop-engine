class_name ObjectStack
extends Node2D

const DEF_PADDING: Vector2 = Vector2(5.0, 5.0)
const DEF_BORDERSIZE: float = 2.0
const H_PADDING: Vector2 = Vector2(7.0, 7.0)
const H_BORDERSIZE: float = 5.0

var _game_objects: Array = []

var _padding: Vector2 = DEF_PADDING
var _outline_size: float = DEF_BORDERSIZE

var _scale: Vector2 = Vector2(1.0, 1.0)

var _hue: float = 0.0


enum STCKSTATE {IDLE, HOVERED}

var _state: STCKSTATE = STCKSTATE.IDLE

func add_game_object(obj: GameObject) -> void:
	_game_objects.push_back(obj)
	_update_bounds()

func add_game_object_to_bottom(obj: GameObject) -> void:
	_game_objects.push_front(obj)
	_update_bounds()

func shuffle() -> void:
	_game_objects.shuffle()
	_update_bounds()

func flip() -> void:
	for obj in _game_objects:
		obj.flip()

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
	_set_scale(Vector2(larg_x, larg_y))

func _get_max_index() -> int:
	var max_index: int = -1
	for obj in _game_objects:
		max_index = max(obj.get_index(), max_index)
	return max_index

func stack_moved() -> void:
	_update_bounds()

func get_top_of_stack() -> GameObject:
	if _game_objects.size() > 0:
		return _game_objects[-1]
	else:
		return null

func get_game_objects() -> Array:
	return _game_objects

func release_top_of_stack() -> GameObject:
	var _top_of_stack: GameObject = _game_objects.pop_back()
	_top_of_stack.make_unstacked()
	_top_of_stack.set_obj_stack(null)
	if _game_objects.size() == 1:
		release_top_of_stack()
	elif _game_objects.size() == 0:
		queue_free()
	_update_bounds()
	return _top_of_stack

func _set_scale(_vec: Vector2) -> void:
	_scale = _vec

func _draw() -> void:
	draw_rect(Rect2(- _scale / 2.0, _scale), Color.BLACK, true)
	draw_rect(Rect2(- (_scale + _padding) / 2.0, (_scale + _padding)), Color.from_hsv(clampf(_hue, 0.0, 1.0), 0.5, 1.0), false, _outline_size)

func make_hovered() -> void:
	match _state:
		STCKSTATE.IDLE:
			_padding = H_PADDING
			_outline_size = H_BORDERSIZE
			_state = STCKSTATE.HOVERED
		_:
			print("Wtf")

func make_unhovered() -> void:
	match _state:
		STCKSTATE.HOVERED:
			_padding = DEF_PADDING
			_outline_size = DEF_BORDERSIZE
			_state = STCKSTATE.IDLE
		_:
			print("Wtf2")

func _process(delta: float) -> void:
	_hue = _hue + 0.1 * delta
	if _hue >= 1.0:
		_hue = _hue - 1.0
	queue_redraw()
