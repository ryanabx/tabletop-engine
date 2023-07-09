class_name GameObject
extends Sprite2D

enum STATE {
	IDLE,
	SELECTED,
	RIGHT_CLICK,
	IN_COLLECTION
}

enum SIDE {UP,DOWN}

var _side: SIDE = SIDE.UP
var _state: STATE = STATE.IDLE

@onready var state_label: Label = $StateLabel

func set_state(state: STATE) -> bool:
	_state = state
	return true

func get_state() -> STATE:
	return _state

func get_side() -> SIDE:
	return _side

func flip() -> void:
	_side = SIDE.UP if _side == SIDE.DOWN else SIDE.DOWN

func select() -> void:
	match get_state():
		STATE.IDLE:
			set_state(STATE.SELECTED)
		_:
			print("WTF")

func deselect() -> void:
	match get_state():
		STATE.SELECTED:
			set_state(STATE.IDLE)
		_:
			print("Wtf")

func right_click() -> void:
	match get_state():
		STATE.IDLE:
			set_state(STATE.RIGHT_CLICK)
		_:
			print("Wtf2")

func revert_right_click() -> void:
	match get_state():
		STATE.RIGHT_CLICK:
			set_state(STATE.IDLE)
		_:
			print("Wtf3")

func _process(delta: float) -> void:
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
		STATE.IN_COLLECTION:
			return "in collection"
		_:
			return ""
