class_name BoardUtilities
extends Node2D

var board: Board

func _init(_board: Board) -> void:
	board = _board
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
