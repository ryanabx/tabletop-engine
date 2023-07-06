class_name GameObject
extends Sprite2D

enum GAME_OBJECT_STATE {
	OPEN,
	GRABBED,
	IN_STACK
}

var object_state: GAME_OBJECT_STATE = GAME_OBJECT_STATE.OPEN

var grabbable: bool = false
var mouse_offset_vect: Vector2 = Vector2.ZERO

var parent = null

@onready var collision_box = $CollisionArea/CollisionBox

func _ready() -> void:
	if self.get_parent():
		parent = self.get_parent()
	collision_box.shape.size = get_rect().size # Set collision box to match the sprite

func _on_collision_area_mouse_entered() -> void:
	GameManager.grab_selection_lock(self)

func _on_collision_area_mouse_exited() -> void:
	GameManager.release_selection_lock(self)

func _on_collision_area_input_event(viewport: Viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and GameManager.has_selection_lock(self):
		if event.button_index == MOUSE_BUTTON_LEFT:
			grabbable = event.pressed
			if grabbable:
				mouse_offset_vect = global_position - get_global_mouse_position()
				_move_self_to_top()
				GameManager.set_mouse_state(GameManager.MOUSE_STATE.GRAB)
			else:
				GameManager.set_mouse_state(GameManager.MOUSE_STATE.BASIC)

func _process(delta: float) -> void:
	z_index = -get_index()
	if grabbable and GameManager.has_selection_lock(self) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		global_position = get_global_mouse_position() + mouse_offset_vect
		object_state = GAME_OBJECT_STATE.GRABBED
	else:
		object_state = GAME_OBJECT_STATE.OPEN
	
	modulate.b = 0.8 if GameManager.has_selection_lock(self) else 1.0

func _move_self_to_top() -> void:
	if parent:
		parent.move_child(self, 0)

func _move_self_to_back() -> void:
	if parent:
		parent.move_child(self, -1)
