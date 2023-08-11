extends Node2D

var board: Board

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_player_stuff()

func draw_player_stuff() -> void:
	if board.board_player.get_highlighted_item() != null:
		# print("Highlighted item")
		draw_colored_polygon(
			board.board_player.get_highlighted_item().get_extents(),
			Color.from_hsv(0.4, 0.2, 1, 0.3)
			)
	if board.board_player.selection_boxing:
		draw_rect(board.board_player.selection_box, Color.BLUE * Color(1,1,1,0.3))
	for obj in board.board_player.get_selected_pieces():
		draw_colored_polygon(
			obj.get_extents(),
			Color.GREEN * Color(1,1,1,0.2)
			)