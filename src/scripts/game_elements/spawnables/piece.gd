class_name Piece
extends GameObject

const DEFAULT_SIZE = Vector2(64.0, 64.0)

enum STATE {
	IDLE,
	SELECTED,
	LOCKED
}

var collection: String = ""

var grab_offset: Vector2 = Vector2.ZERO

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $PieceSynchronizer

var face_up: bool = true

var image_up_string: String = ""
var image_down_string: String = ""
var image_up: Texture2D = null
var image_down: Texture2D = null
var state: STATE = STATE.IDLE

var sprite_scale: Vector2 = Vector2.ONE

@onready var state_label: Label = $StateLabel
@onready var _sprite: Sprite2D = $ObjectSprite

func _ready() -> void:
	add_to_group("piece")
	set_piece_texture()

func can_access(player_id: int):
	if not has_collection():
		return true
	else:
		var c: Collection = get_tree().get_first_node_in_group(get_collection())
		if c.can_access(player_id) is bool:
			return c.can_access(player_id)
		return true
	
func can_view(player_id: int):
	if not has_collection():
		if state == STATE.SELECTED:
			return true
		else:
			return face_up
	elif has_collection():
		var c: Collection = get_tree().get_first_node_in_group(get_collection())
		if c.can_view(player_id) is bool:
			return c.can_view(player_id)
		return face_up
	else:
		return false

func get_grab_offset() -> Vector2:
	return grab_offset

func set_grab_offset(offset: Vector2) -> void:
	grab_offset = offset

func set_sprite_scale(sc: Vector2) -> void:
	sprite_scale = sc

func get_rect() -> Rect2:
	return _sprite.get_rect() * _sprite.get_transform()

func get_stack_rect() -> Rect2:
	var stack_transform: Transform2D = _sprite.get_transform()
	stack_transform = stack_transform * 0.25
	return _sprite.get_rect() * stack_transform

## True if a collection exists
func has_collection() -> bool:
	return collection != ""

## Gets the collection this piece is a part of. Returns "" if no collection
func get_collection() -> String:
	return collection

func get_state() -> STATE:
	return state

func unselectable() -> bool:
	return false

func flip() -> void:
	face_up = not face_up

func set_piece_texture() -> void:
	if image_up_string == "" or image_down_string == "" or Globals.get_current_game() == null:
		image_up = null
		image_down = null
	else:
		image_up = Globals.get_current_game().images[image_up_string]
		image_down = Globals.get_current_game().images[image_down_string]

func update_texture() -> void:
	if not image_up or not image_down:
		return
	_sprite.texture = image_up if can_view(Player.get_id()) else image_down
	_sprite.scale = (sprite_scale) / _sprite.texture.get_size()
	scale = Vector2.ONE

func set_side(sd: bool) -> void:
	face_up = sd

func get_side() -> bool:
	return face_up

func select() -> void:
	print("Selecting object!")
	match get_state():
		STATE.IDLE:
			state = STATE.SELECTED
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to selected failed (select).")

func deselect() -> void:
	match get_state():
		STATE.SELECTED:
			state = STATE.IDLE
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to idle failed (deselect).")

func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		z_index = get_index()
		if has_collection():
			update_position_in_collection()
	state_label.text = state_to_string(get_state())
	update_texture()
	queue_redraw()

func get_collection_obj() -> Collection:
	return get_tree().get_first_node_in_group(get_collection())

func update_position_in_collection() -> void:
	var c: Collection = get_collection_obj()
	match c.type:
		Collection.TYPE.STACK:
			position = Vector2.ZERO
			c.collection_size.x = maxf(get_rect().size.x, c.collection_size.x)
			c.collection_size.y = maxf(get_rect().size.y, c.collection_size.y)
		Collection.TYPE.HAND:
			var _lerp_amt: float = (get_index() + 1.0) / (c.get_child_count() + 1.0)
			var _pos: Vector2 = c.to_global(Vector2(c.get_rect().position.x, c.get_rect().get_center().y)).lerp(c.to_global(Vector2(c.get_rect().end.x, c.get_rect().get_center().y)), _lerp_amt)
			global_position = _pos
			c.collection_size.y = maxf(get_rect().size.y, c.collection_size.y)
	rotation = 0.0
	if c.force_state is bool:
		set_side(c.force_state as bool)

func state_to_string(st: STATE) -> String:
	match st:
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
