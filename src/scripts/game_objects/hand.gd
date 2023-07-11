class_name Hand
extends Node2D

const V_PADDING = 16.0

var _player: int
var _scale: Vector2

var _hue: float = 0.0

var _game_objects: Array = []

enum HNDSTATE {
	IDLE,
	HOVERED
}

var _state: HNDSTATE = HNDSTATE.IDLE

func _init(_pl: int, _pos: Vector2, _siz: Vector2):
	_player = _pl
	position = _pos
	_scale = _siz
	add_to_group("hands")

func disabled() -> bool:
	return Globals.get_player_id() != _player

func get_state() -> HNDSTATE:
	return _state

func _process(delta: float) -> void:
	_force_object_positions()
	_hue = _hue + 0.1 * delta
	if _hue >= 1.0:
		_hue = _hue - 1.0
	queue_redraw()

func get_rect() -> Rect2:
	return Rect2(- _scale / 2.0, _scale)

func get_extents() -> Rect2:
	return get_rect() * get_transform().affine_inverse()

func get_horizontal_extents() -> Array:
	var _extents: Rect2 = get_extents()
	var _ext1: Vector2 = Vector2(_extents.position.x, _extents.get_center().y)
	var _ext2: Vector2 = Vector2(_extents.position.x + _extents.size.x, _extents.get_center().y)
	
	return [_ext1, _ext2]

func _get_max_index() -> int:
	var max_index: int = -1
	for obj in _game_objects:
		max_index = max(obj.get_index(), max_index)
	return max_index

func _force_object_positions() -> void:
	var num_objects: int = get_num_objects()
	var _extents: Array = get_horizontal_extents()
	var _max_index = _get_max_index()
	
	var larg_x: float = 0.0
	var larg_y: float = 64.0
	
	for i in range(get_num_objects()):
		var _obj: GameObject = get_game_objects()[i]
		get_parent().move_child(_obj, _max_index)
		if _obj.get_side() == GameObject.SIDE.DOWN:
			_obj.flip()
		var _lerp_amt: float = (i + 1.0) / (num_objects + 1.0)
		var _pos: Vector2 = _extents[0].lerp(_extents[1], _lerp_amt)
		_obj.position = _pos
		
		var _sc = _obj.get_rect().size
		if _sc.x > larg_x:
			larg_x = _sc.x
		if _sc.y > larg_y:
			larg_y = _sc.y
	_scale.y = larg_y + V_PADDING

func add_game_object(_obj: GameObject) -> void:
	var i: int = 0
	for a in range(get_num_objects()):
		if _obj.position.x < get_game_objects()[a].position.x:
			break
		i = i + 1
	_game_objects.insert(i, _obj)

func remove_game_object(_obj: GameObject) -> void:
	_game_objects.erase(_obj)

func get_game_objects() -> Array:
	return _game_objects

func get_num_objects() -> int:
	return _game_objects.size()

func get_player_id() -> int:
	return _player

func make_hovered() -> void:
	match _state:
		HNDSTATE.IDLE:
			_state = HNDSTATE.HOVERED
		_:
			print("Wtf hand")

func make_unhovered() -> void:
	match _state:
		HNDSTATE.HOVERED:
			_state = HNDSTATE.IDLE
		_:
			print("Wtf2 hand")

func _draw():
	if not disabled():
		draw_rect(Rect2(- _scale / 2.0, _scale), Color.from_hsv(clampf(_hue, 0.0, 1.0), 1.0, 1.0, 0.3), true)
	# draw_rect(Rect2(- _scale / 2.0, _scale), Color.from_hsv(clampf(_hue, 0.0, 1.0), 0.5, 1.0), false, _outline_size)
