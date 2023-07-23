class_name GameCollection
extends GameItem

var _game_objects: Array = []
var _scale: Vector2 = Vector2.ZERO

var permanent: bool = true

var label: Label = null

const STACK_RECT_SIZE: float = 32.0

const PADDING: float = 8.0

func _ready() -> void:
	add_to_group("collections")
	label = Label.new()
	# label.set_anchors_and_offsets_preset(label.PRESET_CENTER)
	add_child(label)

func _update_objects() -> void:
	pass

func get_permanence() -> bool:
	return permanent

func set_permanence(per: bool) -> void:
	permanent = per

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
	print("add_game_object_special not Implemented on: ",get_class())
	pass

func get_rect() -> Rect2:
	return Rect2(- _scale / 2.0, _scale)

func get_top_object() -> GameObject:
	if get_num_objects() == 0:
		return null
	return get_game_objects()[-1]

func remove_game_object(obj: GameObject) -> void:
	var index: int = get_game_objects().find(obj)
	if index == -1:
		return
	remove_object_at(index)

func remove_object_at(index: int) -> void:
	var target_object: GameObject = get_game_objects().pop_at(index)
	target_object.remove_from_collection()
	if not permanent:
		if get_num_objects() == 1:
			remove_object_at(0)
		elif get_num_objects() == 0:
			print("remove stack")
			queue_free()

func get_num_objects() -> int:
	return get_game_objects().size()

func disabled() -> bool:
	return false

func flip() -> void:
	for obj in get_game_objects():
		obj.flip()

func shuffle() -> void:
	get_game_objects().shuffle()

func _process(_delta: float) -> void:
	_update_objects()
	label.set_text(str(get_num_objects()))
	label.position = get_rect().position
	queue_redraw()

func _draw() -> void:
	super._draw()
	draw_rect(label.get_rect(), Color.from_hsv(1.0, 1.0, 0.0, 0.8), true)
	draw_rect(label.get_rect(), Color.from_hsv(1.0, 1.0, 0.0, 0.8), false, PADDING)
	if permanent:
		draw_rect(get_rect(), Color.from_hsv(0.0, 0.0, 0.0, 0.8))
