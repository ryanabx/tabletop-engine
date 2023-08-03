class_name BoardPlayer
extends Node2D

var selected_objects: Array[String] = []
var highlighted_piece: String = ""

var selection_box: Rect2 = Rect2(0,0,0,0)

@onready var board: Board = $'..'

######################
### Main Processes ###
######################

func _process(_delta: float) -> void:
	check_for_highlighted_obj()
	queue_redraw()

func check_for_highlighted_obj() -> void:
	var best_obj: String = ""
	for obj in board.pieces.keys():
		if board.obj_overlaps_point(obj, Board.TYPE.PIECE, get_local_mouse_position()):
			if best_obj == "" or board.get_piece(obj).z > board.get_piece(best_obj).z:
				best_obj = obj
	
	highlighted_piece = best_obj

#####################
### Input Parsing ###
#####################

func parse_input(input_actions: Dictionary) -> void:
	pass

#####################
### State changes ###
#####################

func removed_game_menu() -> void:
	pass

##########################
### Drawing Highlights ###
##########################

func _draw() -> void:
	if highlighted_piece != "":
		draw_colored_polygon(
			board.get_obj_extents(board.get_piece(highlighted_piece)),
			Color.from_hsv(0, 0, 1, 0.3)
			)

#####################
### Instantiation ###
#####################

func _ready() -> void:
	z_index = 1000
	Utils.enhanced_inputs.connect(parse_input)
	SignalManager.game_menu_destroy.connect(removed_game_menu)
