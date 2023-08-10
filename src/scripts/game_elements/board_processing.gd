class_name BoardProcessing
extends Node

var board: Board
var board_player: BoardPlayer
var board_utilities: BoardUtilities

func _init(_board: Board, _board_player: BoardPlayer, _board_utilities: BoardUtilities) -> void:
	board = _board
	board_player = _board_player
	board_utilities = _board_utilities

## Where all the magic happens
func _process(_delta: float) -> void:
	var pos: Vector2 = board.get_local_mouse_position()
	# Collection operations
	var best_collection: Collection = null
	for collection in board.collections.values():
		if collection.inside.size() == 0:
			# print(collection.name, ", ", collection.permanent)
			if not collection.permanent:
				# Queue free empty collections
				board.set_gobject_property(collection.name, false, "erased", true)
		# Check overlapping with mouse
		if board_utilities.can_access_collection(collection) and not board_player.selected_collections.has(collection.name):
			if board_utilities.obj_overlaps_point(collection, pos):
				if best_collection == null or collection.z_index > best_collection.z_index:
					best_collection = collection
	
	# Piece operations
	var best_piece: Piece = null
	for piece in board.pieces.values():
		var collection: Collection = board.get_collection(piece.collection)
		if collection != null:
			board.set_gobject_property(piece.name, true, "position", collection.position, false)
			board.set_gobject_property(piece.name, true, "rotation", collection.rotation, false)
			if collection.force_state != null:
				board.set_gobject_property(piece.name, true, "face_up", collection.force_state, false)
			board.set_gobject_property(collection.name, false, "scale", Vector2(maxf(collection.scale.x, piece.scale.x), maxf(collection.scale.y, piece.scale.y)), false)

		# Check overlapping with mouse
		if board_utilities.can_access_piece(piece) and not board_player.selected_pieces.has(piece.name):
			if board_utilities.obj_overlaps_point(piece, pos):
				if best_piece == null or piece.z_index > best_piece.z_index:
					best_piece = piece
	
	if board_player.selected_pieces.is_empty():
		board_player.selectable_piece = best_piece.name if best_piece != null else ""
		board_player.highlighted_item = best_piece.name if best_piece != null else ""
	else:
		board_player.selectable_piece = ""
		if best_collection != null:
			board_player.highlighted_item = best_collection.name
		else:
			board_player.highlighted_item = best_piece.name if best_piece != null else ""