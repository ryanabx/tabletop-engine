class_name GameObject
extends Sprite2D

enum GAME_OBJECT_STATE {
	OPEN,
	GRABBED,
	RIGHT_CLICKED,
	IN_STACK
}

enum GAME_OBJECT_SIDES {
	FACE_UP,
	FACE_DOWN
}

var _object_side: GAME_OBJECT_SIDES = GAME_OBJECT_SIDES.FACE_UP
var object_state: GAME_OBJECT_STATE = GAME_OBJECT_STATE.OPEN
var mouse_offset_vect: Vector2 = Vector2.ZERO

var parent = null

@onready var collision_area = $CollisionArea
@onready var collision_box = $CollisionArea/CollisionBox

func _ready() -> void:
	if self.get_parent():
		parent = self.get_parent()
	collision_box.shape.size = get_rect().size # Set collision box to match the sprite

func _input(event: InputEvent) -> void:
	if object_state == GAME_OBJECT_STATE.GRABBED and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and event is InputEventMouseMotion:
		_check_for_collections_then_open()

func _check_for_collections_then_open() -> void:
	if collision_area.has_overlapping_areas(): # A collection is overlapping with a game object
		var overlapping_object: GameCollection = collision_area.get_overlapping_areas()[0].get_parent()
		add_to_collection(overlapping_object)
	else: # No collection is overlapping, go back to open state
		object_state = GAME_OBJECT_STATE.OPEN
		GameManager.set_mouse_state(GameManager.MOUSE_STATE.BASIC)

func add_to_collection(coll: GameCollection):
	object_state = GAME_OBJECT_STATE.IN_STACK

func _on_collision_area_mouse_entered() -> void:
	GameManager.grab_selection_lock(self)

func _on_collision_area_mouse_exited() -> void:
	GameManager.release_selection_lock(self)

func _on_collision_area_input_event(_viewport: Viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and GameManager.has_selection_lock(self):
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and object_state == GAME_OBJECT_STATE.OPEN:
				mouse_offset_vect = global_position - get_global_mouse_position()
				_move_self_to_top()
				object_state = GAME_OBJECT_STATE.GRABBED
				GameManager.set_mouse_state(GameManager.MOUSE_STATE.GRAB)
			elif object_state == GAME_OBJECT_STATE.GRABBED or object_state == GAME_OBJECT_STATE.RIGHT_CLICKED:
				_check_for_collections_then_open()

func set_my_state(state: GAME_OBJECT_STATE) -> void:
	object_state = state
	
func get_state() -> GAME_OBJECT_STATE:
	return object_state

func flip_over() -> void:
	print("Flip sides")
	_object_side = GAME_OBJECT_SIDES.FACE_DOWN if _object_side == GAME_OBJECT_SIDES.FACE_UP else GAME_OBJECT_SIDES.FACE_DOWN

func _process(_delta: float) -> void:
	z_index = -get_index()
	if object_state == GAME_OBJECT_STATE.GRABBED and GameManager.has_selection_lock(self) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		global_position = get_global_mouse_position() + mouse_offset_vect
	_set_modulate_from_state() # Set colors based on what state the object is in
	_set_scale_from_overlapping_collections()

func _set_modulate_from_state() -> void:
	match object_state:
		GAME_OBJECT_STATE.OPEN:
			modulate.a = 1.0
			modulate.b = 1.0
			modulate.g = 1.0
		GAME_OBJECT_STATE.GRABBED:
			modulate.a = 1.0
			modulate.b = 0.6
			modulate.g = 1.0
		GAME_OBJECT_STATE.RIGHT_CLICKED:
			modulate.a = 1.0
			modulate.b = 1.0
			modulate.g = 0.6
		GAME_OBJECT_STATE.IN_STACK:
			modulate.a = 0.5
			modulate.b = 1.0
			modulate.g = 1.0
		_:
			pass

func _set_scale_from_overlapping_collections() -> void:
	if collision_area.has_overlapping_areas():
		scale = Vector2(1.03, 1.03)
	else:
		scale = Vector2(1.0, 1.0)

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
