class_name GameObject
extends Node2D

const DEFAULT_SIZE = Vector2(64.0, 64.0)

enum STATE {IDLE,SELECTED,RIGHT_CLICK,LOCKED,STACKED,STCK_SLCT,READY_FOR_STACKING,STACKED_READY}

enum OBJ_TYPE {
	GENERIC,
	CARD,
	STACK
}

enum SIDE {UP,DOWN}

var _obj_type: OBJ_TYPE = OBJ_TYPE.GENERIC
var _obj_name: String = ""
var _obj_images: Array = []

var _next_in_stack: GameObject = null
var _prev_in_stack: GameObject = null

var _obj_stack: ObjectStack = null


var _side: SIDE = SIDE.UP
var _state: STATE = STATE.IDLE

@onready var state_label: Label = $StateLabel
@onready var _sprite: Sprite2D = $ObjectSprite

func _type_from_string(obj_type: String) -> OBJ_TYPE:
	match obj_type:
		"stack":
			return OBJ_TYPE.STACK
		"card":
			return OBJ_TYPE.CARD
		_:
			return OBJ_TYPE.GENERIC

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

func get_obj_stack() -> ObjectStack:
	return _obj_stack

func set_obj_stack(_stck: ObjectStack) -> void:
	_obj_stack = _stck

func set_state(state: STATE) -> bool:
	_state = state
	return true

func get_state() -> STATE:
	return _state

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

func stack_select() -> void:
	match get_state():
		STATE.STACKED:
			set_state(STATE.STCK_SLCT)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to stack selected failed (stack select).")

func stack_deselect() -> void:
	match get_state():
		STATE.STCK_SLCT:
			set_state(STATE.STACKED)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to stacked failed (stack deselect).")

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

func get_ready_for_stacking() -> void:
	match get_state():
		STATE.IDLE:
			set_state(STATE.READY_FOR_STACKING)
		STATE.STACKED:
			set_state(STATE.STACKED_READY)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to ready for stacking failed (get ready for stacking).")

func get_unready_for_stacking() -> void:
	match get_state():
		STATE.READY_FOR_STACKING:
			set_state(STATE.IDLE)
		STATE.STACKED_READY:
			set_state(STATE.STACKED)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to idle failed (get unready for stacking).")

func make_stacked() -> void:
	match get_state():
		STATE.READY_FOR_STACKING:
			set_state(STATE.STACKED)
		STATE.SELECTED:
			set_state(STATE.STACKED)
		STATE.STACKED_READY:
			set_state(STATE.STACKED)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to stacked failed (make stacked).")

func make_unstacked() -> void:
	match get_state():
		STATE.STACKED:
			set_state(STATE.IDLE)
		_:
			print("Attempted transition from ", state_to_string(get_state()), " to idle failed (make unstacked).")

func _process(_delta: float) -> void:
	state_label.text = state_to_string(get_state())
	z_index = get_index()

func state_to_string(state: STATE) -> String:
	match state:
		STATE.IDLE:
			return "idle"
		STATE.SELECTED:
			return "selected"
		STATE.RIGHT_CLICK:
			return "right click"
		STATE.STACKED:
			return "stacked"
		STATE.STCK_SLCT:
			return "stack selected"
		STATE.READY_FOR_STACKING:
			return "ready for stacking"
		STATE.STACKED_READY:
			return "stacked and ready for stacking"
		_:
			return ""
