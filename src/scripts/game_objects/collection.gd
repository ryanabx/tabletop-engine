class_name GameCollection
extends Node2D

enum STATE {
	IDLE, HOVERED
}

var _state = STATE.IDLE
var _game_objects: Array = []
var _scale: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("collections")

func _process(_delta: float) -> void:
	_update_objects()

func _update_objects() -> void:
	print("Not Implemented")
	pass

func get_game_objects() -> Array:
	return _game_objects

func _get_max_index() -> int:
	var max_index: int = -1
	for obj in get_game_objects():
		max_index = max(obj.get_index(), max_index)
	return max_index

func add_game_object_to_top(obj: GameObject) -> void:
	get_game_objects().push_back(obj)

func add_game_object_to_bottom(obj: GameObject) -> void:
	get_game_objects().push_front(obj)

func add_game_object_special(_obj: GameObject) -> void:
	print("Not implemented")
	pass

func get_rect() -> Rect2:
	return Rect2(- _scale / 2.0, _scale)

func get_extents() -> Rect2:
	return get_rect() * get_transform().affine_inverse()

func get_top_object() -> GameObject:
	if get_num_objects() == 0:
		return null
	return get_game_objects()[-1]

func remove_game_object(obj: GameObject) -> GameObject:
	var index: int = get_game_objects().find(obj)
	if index == -1:
		return null
	return remove_object_at(index)

func remove_object_at(index: int) -> GameObject:
	var target_object: GameObject = get_game_objects().pop_at(index)
	target_object.make_unstacked()
	if get_num_objects() == 1:
		remove_object_at(0)
	elif get_num_objects() == 0:
		queue_free()
	return target_object

func get_num_objects() -> int:
	return get_game_objects().size()

func get_state() -> STATE:
	return _state

func disabled() -> bool:
	return true

func flip() -> void:
	for obj in get_game_objects():
		obj.flip()

func shuffle() -> void:
	get_game_objects().shuffle()

func make_hovered() -> void:
	match _state:
		STATE.IDLE:
			_state = STATE.HOVERED
		_:
			print("Wtf collection")

func make_unhovered() -> void:
	match _state:
		STATE.HOVERED:
			_state = STATE.IDLE
		_:
			print("Wtf2 collection")