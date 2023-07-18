class_name GameObject
extends GameItem

const DEFAULT_SIZE = Vector2(64.0, 64.0)

enum STATE {
	IDLE,
	SELECTED,
	RIGHT_CLICK,
	LOCKED
}

enum OBJ_TYPE {
	GENERIC,
	CARD,
	STACK
}

enum SIDE {
	UP,
	DOWN
}

var _obj_type: OBJ_TYPE = OBJ_TYPE.GENERIC
var _obj_images: Array = []

var grab_offset: Vector2 = Vector2.ZERO

var collection: GameCollection = null


var _side: SIDE = SIDE.UP
var _state: STATE = STATE.IDLE

@onready var state_label: Label = $StateLabel
@onready var _sprite: Sprite2D = $ObjectSprite

func _ready() -> void:
	add_to_group("game_objects")

func _type_from_string(obj_type: String) -> OBJ_TYPE:
	match obj_type:
		"stack":
			return OBJ_TYPE.STACK
		"card":
			return OBJ_TYPE.CARD
		_:
			return OBJ_TYPE.GENERIC

func get_grab_offset() -> Vector2:
	return grab_offset

func set_grab_offset(offset: Vector2) -> void:
	grab_offset = offset

func _set_scale(_sc: Vector2, preserve_aspect: bool) -> void:
	if not preserve_aspect:
		_sprite.scale = (_sc * DEFAULT_SIZE) / _sprite.get_rect().size
	else:
		_sprite.scale.x = (_sc.x * DEFAULT_SIZE.x) / _sprite.get_rect().size.x
		_sprite.scale.y = (_sc.x * DEFAULT_SIZE.x) / _sprite.get_rect().size.x

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

func get_side() -> SIDE:
	return _side

func flip() -> void:
	_side = SIDE.UP if _side == SIDE.DOWN else SIDE.DOWN
	if _obj_type != OBJ_TYPE.GENERIC:
		_sprite.texture = _obj_images[0] if _side == SIDE.UP else _obj_images[1]

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

func right_click() -> void:
	match get_state():
		STATE.IDLE:
			set_state(STATE.RIGHT_CLICK)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to right click failed (right click).")

func revert_right_click() -> void:
	match get_state():
		STATE.RIGHT_CLICK:
			set_state(STATE.IDLE)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to idle failed (revert right click).")

func put_in_collection(coll: GameCollection) -> void:
	match get_state():
		STATE.SELECTED:
			set_collection(coll)
			set_state(STATE.IDLE)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to idle failed (put in collection).")

func remove_from_collection() -> void:
	if has_collection():
		set_collection(null)
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
		STATE.RIGHT_CLICK:
			return "right click"
		STATE.LOCKED:
			return "locked"
		_:
			return ""

func _draw() -> void:
	super._draw()
	if get_state() == STATE.SELECTED:
		draw_rect(get_rect(), Color.from_hsv(1.0, 1.0, 1.0, 1.0), false, Globals.OUTLINE_THICKNESS * Globals.THICKNESS_RATIO)
