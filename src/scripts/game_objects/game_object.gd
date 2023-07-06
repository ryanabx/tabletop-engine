class_name GameObject
extends Sprite2D

var grabbable: bool = false
var mouse_offset_vect: Vector2 = Vector2.ZERO

var parent = null

@onready var sprite = $Sprite
@onready var collision_box = $CollisionArea/CollisionBox

func _ready():
	if self.get_parent():
		parent = self.get_parent()
	collision_box.shape.size = get_rect().size # Set collision box to match the sprite

func _on_collision_area_mouse_entered():
	_grab_selection_lock()

func _on_collision_area_mouse_exited():
	_release_selection_lock()

func _on_collision_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and _has_selection_lock():
		if event.button_index == MOUSE_BUTTON_LEFT:
			grabbable = event.pressed
			if grabbable:
				mouse_offset_vect = global_position - event.global_position + get_viewport_transform().origin
				_move_self_to_top()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_reset_selection_lock()

func _process(delta):
	z_index = -get_index()
	if grabbable and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		global_position = get_global_mouse_position() + mouse_offset_vect
	
	modulate.b = 0.8 if _has_selection_lock() else 1.0

func _has_selection_lock() -> bool:
	return GameManager.item_selected.size() > 0 and GameManager.item_selected[0] == self

func _grab_selection_lock() -> void:
	var index = 0
	while GameManager.item_selected.size() > index and GameManager.item_selected[index].get_index() < get_index():
		index+=1
	GameManager.item_selected.insert(index, self)
	print("Item inserted at ",index, self.get_name())

func _release_selection_lock() -> void:
	GameManager.item_selected.erase(self)

func _reset_selection_lock() -> void:
	_move_self_to_back()
	_release_selection_lock()
	_grab_selection_lock()

func _move_self_to_top() -> void:
	if parent:
		parent.move_child(self, 0)

func _move_self_to_back() -> void:
	if parent:
		parent.move_child(self, -1)
