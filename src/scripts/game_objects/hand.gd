class_name Hand
extends GameCollection

const V_PADDING = 16.0

var _player: int
var _hue: float = 0.0

func _init(_pl: int, _pos: Vector2, _siz: Vector2):
	_player = _pl
	position = _pos
	_scale = _siz
	add_to_group("hands")

func disabled() -> bool:
	return Globals.get_player_id() != get_player_id()

func _process(delta: float) -> void:
	super._process(delta)
	_hue = _hue + 0.1 * delta
	if _hue >= 1.0:
		_hue = _hue - 1.0
	queue_redraw()

func get_horizontal_extents() -> Array:
	var _extents: Rect2 = get_extents()
	var _ext1: Vector2 = Vector2(_extents.position.x, _extents.get_center().y)
	var _ext2: Vector2 = Vector2(_extents.position.x + _extents.size.x, _extents.get_center().y)
	return [_ext1, _ext2]

func _update_objects() -> void:
	var num_objects: int = get_num_objects()
	var _extents: Array = get_horizontal_extents()
	var _max_index = _get_max_index()
	z_index = _max_index + 1
	
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

func add_game_object_special(obj: GameObject) -> void:
	var i: int = 0
	for a in range(get_num_objects()):
		if obj.position.x < get_game_objects()[a].position.x:
			break
		i = i + 1
	get_game_objects().insert(i, obj)

func get_player_id() -> int:
	return _player

func _draw():
	super._draw()
	draw_rect(get_rect(), Color.from_hsv(0.0, 0.0, 1.0, 1.0), false, Globals.OUTLINE_THICKNESS * Globals.THICKNESS_RATIO)
