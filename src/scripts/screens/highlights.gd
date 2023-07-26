extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if Globals.get_tabletop().board != null and Globals.get_tabletop().board.is_selecting:
		draw_rect(Globals.get_tabletop().board.selection_box, Color.from_hsv(0.6, 1.0, 1.0, 0.5))
		draw_rect(Globals.get_tabletop().board.selection_box, Color.from_hsv(0.65, 0.6, 1.0, 0.5), false, 2)
