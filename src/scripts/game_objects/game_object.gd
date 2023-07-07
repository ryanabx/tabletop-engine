class_name GameObject
extends Sprite2D

enum GAME_OBJECT_STATE {
	OPEN,
	GRABBED,
	GRABBED_OVER_COLLECTION,
	RIGHT_CLICKED,
	IN_STACK
}

enum GAME_OBJECT_SIDES {
	FACE_UP,
	FACE_DOWN
}

var _object_side: GAME_OBJECT_SIDES = GAME_OBJECT_SIDES.FACE_UP
var _object_state: GAME_OBJECT_STATE = GAME_OBJECT_STATE.OPEN
var mouse_offset_vect: Vector2 = Vector2.ZERO

var parent = null
var default_scale: Vector2 = Vector2.ONE

@onready var collision_area = $CollisionArea
@onready var collision_box = $CollisionArea/CollisionBox

func _ready() -> void:
	if self.get_parent():
		parent = self.get_parent()
	collision_box.shape.size = get_rect().size # Set collision box to match the sprite
	default_scale = scale
	_connect_signals()

func _connect_signals() -> void:
	collision_area.input_event.connect(_on_collision_area_input_event)
	collision_area.mouse_entered.connect(_on_collision_area_mouse_entered)
	collision_area.mouse_exited.connect(_on_collision_area_mouse_exited)
	collision_area.area_entered.connect(_on_collision_area_area_entered)
	collision_area.area_exited.connect(_on_collision_area_area_exited)

func _input(event: InputEvent) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and event is InputEventMouseMotion:
		_check_for_collections_then_stack()

func _check_for_collections_then_stack() -> void:
	if get_state() == GAME_OBJECT_STATE.GRABBED:
		set_my_state(GAME_OBJECT_STATE.OPEN)
		GameManager.set_mouse_state(GameManager.MOUSE_STATE.BASIC)
	elif get_state() == GAME_OBJECT_STATE.GRABBED_OVER_COLLECTION and collision_area.has_overlapping_areas():
		var overlapping_object: GameCollection = collision_area.get_overlapping_areas()[0].get_parent()
		add_to_collection(overlapping_object)
	

func add_to_collection(coll: GameCollection):
	set_my_state(GAME_OBJECT_STATE.IN_STACK)

func _on_collision_area_mouse_entered() -> void:
	GameManager.grab_selection_lock(self)

func _on_collision_area_mouse_exited() -> void:
	GameManager.release_selection_lock(self)

func _on_collision_area_input_event(_viewport: Viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and GameManager.has_selection_lock(self):
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and get_state() == GAME_OBJECT_STATE.OPEN:
				mouse_offset_vect = global_position - get_global_mouse_position()
				_move_self_to_top()
				set_my_state(GAME_OBJECT_STATE.GRABBED)
				GameManager.set_mouse_state(GameManager.MOUSE_STATE.GRAB)
			elif get_state() == GAME_OBJECT_STATE.GRABBED or get_state() == GAME_OBJECT_STATE.RIGHT_CLICKED:
				_check_for_collections_then_stack()

func _on_collision_area_area_entered(area: Area2D) -> void:
	if get_state() == GAME_OBJECT_STATE.GRABBED:
		set_my_state(GAME_OBJECT_STATE.GRABBED_OVER_COLLECTION)

func _on_collision_area_area_exited(area: Area2D) -> void:
	if get_state() == GAME_OBJECT_STATE.GRABBED_OVER_COLLECTION:
		set_my_state(GAME_OBJECT_STATE.GRABBED)

func set_my_state(state: GAME_OBJECT_STATE) -> bool:
	_object_state = state
	return true
	
func get_state() -> GAME_OBJECT_STATE:
	return _object_state

func flip_over() -> void:
	print("Flip sides")
	_object_side = GAME_OBJECT_SIDES.FACE_DOWN if _object_side == GAME_OBJECT_SIDES.FACE_UP else GAME_OBJECT_SIDES.FACE_DOWN

func _process(_delta: float) -> void:
	z_index = -get_index()
	if (get_state() == GAME_OBJECT_STATE.GRABBED or get_state() == GAME_OBJECT_STATE.GRABBED_OVER_COLLECTION) and GameManager.has_selection_lock(self) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		global_position = get_global_mouse_position() + mouse_offset_vect
	_set_modulate_from_state() # Set colors based on what state the object is in

func _set_modulate_from_state() -> void:
	match get_state():
		GAME_OBJECT_STATE.OPEN:
			modulate.a = 1.0
			modulate.b = 1.0
			modulate.g = 1.0
			scale = default_scale
		GAME_OBJECT_STATE.GRABBED:
			modulate.a = 1.0
			modulate.b = 0.6
			modulate.g = 1.0
			scale = default_scale
		GAME_OBJECT_STATE.RIGHT_CLICKED:
			modulate.a = 1.0
			modulate.b = 1.0
			modulate.g = 0.6
			scale = default_scale
		GAME_OBJECT_STATE.IN_STACK:
			modulate.a = 0.5
			modulate.b = 1.0
			modulate.g = 1.0
			scale = default_scale
		GAME_OBJECT_STATE.GRABBED_OVER_COLLECTION:
			modulate.a = 0.9
			modulate.b = 1.0
			modulate.g = 1.0
			scale = default_scale * 1.05
		_:
			pass

func _move_self_to_top() -> void:
	if parent:
		parent.move_child(self, 0)
		GameManager.refresh_selection(self)

func _move_self_to_back() -> void:
	if parent:
		parent.move_child(self, -1)
		GameManager.refresh_selection(self)


class GameObjectData:
	var image_front: Image
	var image_back: Image
