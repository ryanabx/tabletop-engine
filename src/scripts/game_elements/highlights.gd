extends Node2D

var board: Board

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    draw_player_stuff()
    
func draw_player_stuff() -> void:
    if board.get_player().is_highlighting():
        if board.get_player().get_highlighted_object() is Hand:
            if board.get_player().is_selecting() or\
                (board.get_player().get_highlighted_object() is Collection and board.get_player().get_highlighted_object().inside.is_empty()):
                draw_set_transform(board.get_player().get_highlighted_object().position, board.get_player().get_highlighted_object().rotation)
                draw_rect(
                    board.get_player().get_highlighted_object()._get_selected_range(),
                    Color.BLACK * Color(1,1,1,0.3)
                )
                draw_set_transform(position, rotation)
            else:
                draw_set_transform(board.get_player().get_highlighted_object().position, board.get_player().get_highlighted_object().rotation)
                draw_rect(
                    board.get_player().get_highlighted_object()._get_selected_range(),
                    Color.BLACK * Color(1,1,1,0.2)
                )
                draw_rect(
                    board.get_player().get_highlighted_object()._get_selected_range(),
                    Color.WHITE * Color(1,1,1,1.0),
                    false, 4
                )
                draw_set_transform(position, rotation)
        else:
            if board.get_player().is_selecting() or\
                (board.get_player().get_highlighted_object() is Collection and board.get_player().get_highlighted_object().inside.is_empty()):
                draw_colored_polygon(
                    board.get_player().get_highlighted_object().get_extents(),
                    Color.BLACK * Color(1,1,1,0.3)
                )
            else:
                draw_colored_polygon(
                    board.get_player().get_highlighted_object().get_extents(),
                    Color.BLACK * Color(1,1,1,0.2)
                )
                draw_polyline(
                    board.get_player().get_highlighted_object().get_polyline_extents(),
                    Color.WHITE * Color(1,1,1,1.0),
                    4
                )
    if board.get_player().object_queued():
        if board.get_player().get_queued_object() is Hand:
            draw_set_transform(board.get_player().get_highlighted_object().position, board.get_player().get_highlighted_object().rotation)
            draw_rect(
                board.get_player().get_queued_object()._get_selected_range(),
                Color.BLUE * Color(1,1,1,0.2)
            )
            draw_set_transform(position, rotation)
        else:
            draw_colored_polygon(
                board.get_player().get_queued_object().get_extents(),
                Color.BLUE * Color(1,1,1,0.2)
            )
    if board.get_player().is_selecting():
        draw_colored_polygon(
            board.get_player().get_selected_object().get_extents(),
            Color.GREEN * Color(1,1,1,0.1)
        )
        draw_polyline(
            board.get_player().get_selected_object().get_polyline_extents(),
            Color.GREEN * Color(1,1,1,0.8),
            3
        )

