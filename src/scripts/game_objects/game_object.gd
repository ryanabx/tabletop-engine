class_name GameObject
extends Node2D

const DEFAULT_SIZE = Vector2(64.0, 64.0)

enum STATE {
	IDLE,
	SELECTED,
	RIGHT_CLICK,
	IN_COLLECTION,
	LOCKED,
	STACKED
}

enum OBJ_TYPE {
	GENERIC,
	CARD,
	STACK
}

enum SIDE {UP,DOWN}

var _obj_type: OBJ_TYPE = OBJ_TYPE.GENERIC
var _obj_name: String = ""
var _obj_images: Array = []


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

func initialize_object(obj_conf, objref, img_dir):
	_obj_name = obj_conf.name
	_obj_type = _type_from_string(obj_conf.type)
	_obj_images = Utils.load_images_into_array(objref.image, img_dir)
	_side = SIDE.UP if obj_conf.face_up else SIDE.DOWN
	if _side == SIDE.UP:
		_sprite.set_texture(_obj_images[0])
		print("Set texture")
	else:
		_sprite.set_texture(_obj_images[1])
		print("Set texture face down")
	
	if obj_conf.scale is Array:
		_set_scale(Vector2(obj_conf.scale[0], obj_conf.scale[1]), false)
	elif obj_conf.scale is float or obj_conf.scale is int:
		_set_scale(Vector2(obj_conf.scale, obj_conf.scale), true)
	
	position = Vector2(obj_conf.location[0], obj_conf.location[1])

func _set_scale(_sc: Vector2, preserve_aspect: bool) -> void:
	if not preserve_aspect:
		_sprite.scale = (_sc * DEFAULT_SIZE) / _sprite.get_rect().size
	else:
		_sprite.scale.x = (_sc.x * DEFAULT_SIZE.x) / _sprite.get_rect().size.x
		_sprite.scale.y = (_sc.x * DEFAULT_SIZE.x) / _sprite.get_rect().size.x

func get_rect() -> Rect2:
	return _sprite.get_rect() * _sprite.get_transform()

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
		STATE.IN_COLLECTION:
			return "in collection"
		_:
			return ""
