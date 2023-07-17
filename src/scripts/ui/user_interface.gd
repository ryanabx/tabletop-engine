class_name UserInterface
extends Control

@onready var _game_label = $PanelContainer/MarginContainer/HBoxContainer/GameLabel

@onready var board: GameBoard = $/root/Tabletop/GameBoard


func set_game_name(_game: String):
	_game_label.text = "Game: " + _game

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if board.is_selecting:
		draw_rect(board.selection_box, Color.from_hsv(0.6, 1.0, 1.0, 0.5))
