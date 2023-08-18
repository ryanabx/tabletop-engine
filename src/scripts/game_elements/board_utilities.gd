class_name BoardUtilities
extends Node2D

var board: Board

func _init(_board: Board) -> void:
	board = _board
	SignalManager.shuffle_selection.connect(shuffle)
	SignalManager.convert_to_stack.connect(convert_to_stack)
	SignalManager.set_object_face.connect(set_object_face)
	SignalManager.flip_objects.connect(flip_objects)

## Brings an object to the front
func move_object_to_top(piece: Piece) -> void:
	board.set_gobject_property(piece.name, true, "z_index", board.max_z_index)
	board.max_z_index += 0.001

## Brings an object to the back
func move_object_to_back(piece: Piece) -> void:
	board.set_gobject_property(piece.name, true, "z_index", board.min_z_index)
	board.min_z_index -= 0.001

func set_object_face(pieces: Array, face_up: bool) -> void:
	for pc in pieces:
		board.set_gobject_property(pc.name, true, "face_up", face_up, true)

func flip_objects(pieces: Array) -> void:
	for pc in pieces:
		flip_object(pc)

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
			"index": pc1.get_index(),
			"collection": pc1.collection
		}
		var contents2: Dictionary = {
			"position": pc2.position,
			"rotation": pc2.rotation,
			"index": pc2.get_index(),
			"collection": pc2.collection
		}
		_swap(pc1, contents2)
		_swap(pc2, contents1)

func _swap(pc1: Piece, contents: Dictionary) -> void:
	pc1.position = contents.position
	pc1.rotation = contents.rotation
	pc1.move_to_index.rpc(contents.index)
	if pc1.collection != contents.collection:
		pc1.add_to_collection(contents.collection)

## Converts game objects to stack
func convert_to_stack(objs: Array[Piece]) -> void:
	var inside: Dictionary = {}
	for obj in objs:
		inside[obj.name] = true
	Collection.construct(board,{
		"name": board.unique_name("collection"),
		"position": objs[-1].position,
		"permanent": false,
		"inside": inside
		})

## Stacks an object to a collection
func stack_to_collection(objs: Array[Piece], item: Collection) -> void:
	for obj in objs:
		obj.add_to_collection(item)
