class_name BoardUtilities
extends RefCounted

var board: Board

func _init(_board: Board) -> void:
	board = _board
	SignalManager.shuffle_selection.connect(shuffle)
	SignalManager.convert_to_stack.connect(convert_to_stack)

## Brings an object to the front
func move_object_to_top(piece: Piece) -> void:
	board.set_gobject_property(piece.name, true, "z_index", board.max_z_index)
	board.max_z_index += 0.001

## Brings an object to the back
func move_object_to_back(piece: Piece) -> void:
	board.set_gobject_property(piece.name, true, "z_index", board.min_z_index)
	board.min_z_index -= 0.001

## Flips an object
func flip_object(piece: Piece) -> void:
	piece.face_up = not piece.face_up

## Shuffles objects
func shuffle(pcs: Array[Piece]) -> void:
	var pcs_shuffled: Array[Piece] = pcs.duplicate(false)
	pcs_shuffled.shuffle()
	for i in range(pcs.size()):
		var pc1: Piece = pcs[i]
		var pc2: Piece = pcs_shuffled[i]
		var contents1: Dictionary = {
			"position": pc1.position,
			"rotation": pc1.rotation,
			"z_index": pc1.z_index,
			"collection": pc1.collection
		}
		var contents2: Dictionary = {
			"position": pc2.position,
			"rotation": pc2.rotation,
			"z_index": pc2.z_index,
			"collection": pc2.collection
		}
		_swap(pc1, contents2)
		_swap(pc2, contents1)

func _swap(pc1: Piece, contents: Dictionary) -> void:
	board.set_gobject_property(pc1.name, true, "position", contents.position)
	board.set_gobject_property(pc1.name, true, "rotation", contents.rotation)
	board.set_gobject_property(pc1.name, true, "z_index", contents.z_index)
	if pc1.collection != contents.collection:
		add_piece_to_collection(pc1, board.collections[contents.collection])


## Adds a piece to the collection specified. Removes a piece from current collection if it exists
func add_piece_to_collection(piece: Piece, c_name: String) -> void:
	if piece.collection != "":
		remove_piece_from_collection(piece)
	board.set_gobject_property(piece.name, true, "collection", c_name)
	var collection = board.get_collection(c_name)
	if collection == null:
		return
	var new_inside: Dictionary = collection.inside.duplicate(false)
	new_inside[piece.name] = true
	board.set_gobject_property(collection.name, false, "inside", new_inside)
	board.set_gobject_property(collection.name, false, "top", piece.name)
	board.set_gobject_property(piece.name, true, "position", collection.position)

## Removes a piece from a collection, if it has any
func remove_piece_from_collection(piece: Piece) -> void:
	if piece == null:
		return
	var c: Collection = board.get_collection(piece.collection)
	board.set_gobject_property(piece.name, true, "collection", "")
	if c == null:
		return
	var new_inside: Dictionary = c.inside.duplicate(false)
	new_inside.erase(piece.name)
	board.set_gobject_property(c.name, false, "inside", new_inside)
	if not c.permanent:
		if c.inside.size() == 1:
			remove_piece_from_collection(board.get_piece(c.inside.keys()[0]))
		elif c.inside.is_empty():
			# Essentially queue free
			board.set_gobject_property(c.name, false, "erased", true)

## Converts game objects to stack
func convert_to_stack(objs: Array[Piece]) -> void:
	var sorted_objs: Dictionary = {}
	for obj in objs:
		sorted_objs[obj.name] = true
	board.construct_collection({
		"name": board.unique_name("collection"),
		"position": objs[-1].position,
		"permanent": false,
		"inside": sorted_objs
		})

## Stacks an object to a collection
func stack_to_collection(objs: Array[Piece], item: Collection) -> void:
	var sorted_objs: Array[Piece] = []
	sorted_objs.assign(objs)
	sorted_objs.sort_custom(board.sort_by_draw_order)
	for obj in sorted_objs:
		add_piece_to_collection(obj, item.name)
