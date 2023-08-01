extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if Globals.get_current_tabletop().board != null:
		if Globals.get_current_tabletop().board.state == Globals.get_current_tabletop().board.STATE.SELECTION_BOX:
			draw_rect(Globals.get_current_tabletop().board.selection_box, Globals.COLOR_SELECTION_BOX)
			draw_rect(Globals.get_current_tabletop().board.selection_box, Globals.COLOR_SELECTION_BOX_BORDER, false, Globals.SELECTION_BOX_OUTLINE)
		if Globals.get_current_tabletop().board.highlighted_piece:
			draw_rect(Globals.get_current_tabletop().board.get_highlighted_piece().get_extents(), Globals.COLOR_HIGHLIGHTED)
	

