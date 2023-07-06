extends Node

@onready var state_label: Label = $UiManager/MouseStateLabel


func _process(delta: float) -> void:
	match GameManager.get_mouse_state():
		GameManager.MOUSE_STATE.BASIC:
			state_label.text = "BASIC"
		GameManager.MOUSE_STATE.GRAB:
			state_label.text = "GRAB"
	state_label.global_position = get_viewport().get_mouse_position() + get_viewport().get_final_transform().get_origin() + Vector2(0.0, -40.0)
