class_name ObjectStack
extends Node2D

var _game_objects: Array = []

@onready var _bounds = $Bounds

func _ready() -> void:
	_bounds.modulate.a = 0.5

func add_game_object(obj: GameObject) -> void:
	_game_objects.append(obj)
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
	_bounds.set_scale(Vector2(larg_x, larg_y))

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
