class_name UserInterface
extends Control

@onready var board: GameBoard = $/root/Tabletop/GameBoard

func _process(_delta: float) -> void:
	queue_redraw()

func set_game_name(name: String) -> void:
	pass

func _draw() -> void:
	if board != null and board.is_selecting:
		draw_rect(board.selection_box, Color.from_hsv(0.6, 1.0, 1.0, 0.5))
		draw_rect(board.selection_box, Color.from_hsv(0.65, 0.6, 1.0, 0.5), false, 2)
