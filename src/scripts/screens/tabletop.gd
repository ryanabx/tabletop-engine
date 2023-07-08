class_name Tabletop
extends Node

@onready var state_label: Label = $UiManager/MouseStateLabel


@export var player_id: int = 0

func _process(_delta: float) -> void:
	match GameManager.get_mouse_state():
		GameManager.MOUSE_STATE.BASIC:
			state_label.text = "BASIC"
		GameManager.MOUSE_STATE.GRAB:
			state_label.text = "GRAB"
	state_label.global_position = get_viewport().get_mouse_position() + Vector2(0.0, -40.0)

func get_ui_manager() -> UiManager:
	return $UiManager as UiManager

func get_game_board() -> GameBoard:
	return $GameBoard as GameBoard
