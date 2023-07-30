class_name Piece
extends GameObject

const DEFAULT_SIZE = Vector2(64.0, 64.0)

enum STATE {
	IDLE,
	SELECTED,
	LOCKED
}

var grab_offset: Vector2 = Vector2.ZERO

var collection: GameCollection = null


var face_up: bool = true
var image_up: Texture2D = null
var image_down: Texture2D = null
var _state: STATE = STATE.IDLE

@onready var state_label: Label = $StateLabel
@onready var _sprite: Sprite2D = $ObjectSprite

func _ready() -> void:
	add_to_group("piece")

func can_access(player_id: int) -> bool:
	if not has_collection() or (has_collection() and get_collection().can_access(player_id)):
		return true
	else:
		return false

func get_grab_offset() -> Vector2:
	return grab_offset

func set_grab_offset(offset: Vector2) -> void:
	grab_offset = offset

func set_sprite_scale(_sc: Vector2) -> void:
	_sprite.scale = (_sc) / _sprite.texture.get_size()
	scale = Vector2.ONE

func get_rect() -> Rect2:
	return _sprite.get_rect() * _sprite.get_transform()

func get_stack_rect() -> Rect2:
	var stack_transform: Transform2D = _sprite.get_transform()
	stack_transform = stack_transform * 0.25
	return _sprite.get_rect() * stack_transform

func has_collection() -> bool:
	return collection != null

func get_collection() -> GameCollection:
	return collection

func set_collection(coll: GameCollection) -> void:
	collection = coll

func set_state(state: STATE) -> bool:
	_state = state
	return true

func get_state() -> STATE:
	return _state

func unselectable() -> bool:
	return false

func flip() -> void:
	face_up = not face_up
	update_texture()

func update_texture() -> void:
	if not image_up or not image_down:
		return
	if has_collection():
		_sprite.texture = image_up if get_collection().decide_face(self) else image_down
	else:
		_sprite.texture = image_up if face_up else image_down

func set_side(sd: bool) -> void:
	face_up = sd
	update_texture()

func get_side() -> bool:
	return face_up

func select() -> void:
	match get_state():
		STATE.IDLE:
			set_state(STATE.SELECTED)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to selected failed (select).")

func deselect() -> void:
	match get_state():
		STATE.SELECTED:
			set_state(STATE.IDLE)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to idle failed (deselect).")

func put_in_collection(coll: GameCollection) -> void:
	if not has_collection():
		set_collection(coll)
		update_texture()
	else:
		print("Cannot add an object to a collection when a collection already exists")

func remove_from_collection() -> void:
	if has_collection():
		set_collection(null)
		update_texture()
	else:
		print("Cannot remove an object from a null collection")

func _process(_delta: float) -> void:
	state_label.text = state_to_string(get_state())
	z_index = get_index()
	queue_redraw()

func state_to_string(state: STATE) -> String:
	match state:
		STATE.IDLE:
			return "idle"
		STATE.SELECTED:
			return "selected"
		STATE.LOCKED:
			return "locked"
		_:
			return ""

func _draw() -> void:
	super._draw()
	if get_state() == STATE.SELECTED:
		draw_rect(get_rect(), Color.from_hsv(1.0, 1.0, 1.0, 1.0), false, Globals.OUTLINE_THICKNESS * Globals.THICKNESS_RATIO)
