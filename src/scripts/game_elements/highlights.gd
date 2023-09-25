extends Node2D

var board: Board

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    draw_player_stuff()
    
func draw_player_stuff() -> void:
    if board.get_player().is_selecting():
        draw_colored_polygon(
            board.get_player().get_selected_object().get_extents(),
            Color.GREEN * Color(1,1,1,0.2)
            )
    if board.get_player().object_queued():
        if board.get_player().get_queued_object() is Hand:
            draw_rect(
                board.get_player().get_queued_object()._get_selected_range(),
                Color.BLUE * Color(1,1,1,0.2)
                )
        else:
            draw_colored_polygon(
                board.get_player().get_queued_object().get_extents(),
                Color.BLUE * Color(1,1,1,0.2)
                )
    if board.get_player().is_highlighting():
        if board.get_player().get_highlighted_object() is Hand:
            draw_rect(
                board.get_player().get_highlighted_object()._get_selected_range(),
                Color.GRAY * Color(1,1,1,0.2)
                )
        else:
            draw_colored_polygon(
                board.get_player().get_highlighted_object().get_extents(),
                Color.GRAY * Color(1,1,1,0.2)
                )

