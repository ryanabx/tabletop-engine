extends Node2D

var board: Board

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_player_stuff()
	
func draw_player_stuff() -> void:
	if board.board_player.is_selecting():
		draw_colored_polygon(
			board.board_player.get_selected_object().get_extents(),
			Color.GREEN * Color(1,1,1,0.2)
			)
	if board.board_player.object_queued():
		draw_colored_polygon(
			board.board_player.get_queued_object().get_extents(),
			Color.BLUE * Color(1,1,1,0.2)
			)

