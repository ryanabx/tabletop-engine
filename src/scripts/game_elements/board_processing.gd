class_name BoardProcessing
extends RefCounted

var board: Board
var board_player: BoardPlayer
var board_utilities: BoardUtilities

func _init(_board: Board, _board_player: BoardPlayer, _board_utilities: BoardUtilities) -> void:
	board = _board
	board_player = _board_player
	board_utilities = _board_utilities

## Where all the magic happens
func board_process() -> void:
	pass # Testing
	# var pos: Vector2 = board.get_local_mouse_position()
	# # Collection operations
	# var best_collection: Collection = null
	# var best_piece: Piece = null
	# for obj in board.get_game_objects():
	# 	if obj is Collection: # Collections
	# 		if obj.can_access() and not board_player.selected_collections.has(obj.name):
	# 			if obj.overlaps_point(pos):
	# 				if best_collection == null or obj.get_index() > obj.get_index():
	# 					best_collection = obj
	# 	elif obj is Piece: # Pieces
	# 		if obj.can_access() and not board_player.selected_pieces.has(obj.name):
	# 			if obj.overlaps_point(pos):
	# 				if best_piece == null or obj.get_index() > best_piece.get_index():
	# 					best_piece = obj
	
	# if board_player.selected_pieces.is_empty():
	# 	if best_piece != null:
	# 		board_player.selectable_piece = best_piece.name
	# 		board_player.highlighted_item = best_piece.name
	# 	else:
	# 		board_player.selectable_piece = ""
	# 		board_player.highlighted_item = ""
	# else:
	# 	board_player.selectable_piece = ""
	# 	if best_collection != null:
	# 		board_player.highlighted_item = best_collection.name
	# 	elif best_piece != null:
	# 		board_player.highlighted_item = best_piece.name
	# 	else:
	# 		board_player.highlighted_item = ""

	
	
