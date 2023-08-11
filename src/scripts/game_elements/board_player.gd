class_name BoardPlayer
extends Node2D

var selected_pieces: Array[Piece] = []

var selection_box: Rect2 = Rect2(0,0,0,0)
var selection_boxing: bool = false

enum InputState {
	UNHANDLED, HANDLED
}

var input_state: InputState = InputState.UNHANDLED

var queued_deselection: bool = false

var board: Board

######################
### Getter Methods ###
######################

func get_selected_pieces() -> Array[Piece]:
	return selected_pieces

######################
### Input Handling ###
######################

# func _input(event: InputEvent) -> void:
# 	if event.is_action_released("game_select") or event.is_action_released("game_select_stack"):
# 		print("Deselecting current selection")
# 		call_deferred("deselect_pieces")

######################
### Main Processes ###
######################

func _process(_delta: float) -> void:
	input_state = InputState.UNHANDLED
	if queued_deselection:
		if not selected_pieces.is_empty():
			deselect_pieces()
		queued_deselection = false
	pass

func select_pieces(objs: Array[Piece]) -> void:
	selected_pieces = []
	for obj in objs:
		obj.move_self_to_top()
		selected_pieces.append(obj)
		obj.selected = true

func stack_selection_to_item(item: Piece) -> void:
	if item.get_collection() != null:
		stack_stackables_to_collection(item.get_collection())
	else:
		selected_pieces.push_front(item)
		convert_to_stack(selected_pieces)
	input_state = InputState.HANDLED
	selected_pieces = []

func stack_stackables_to_collection(coll: Collection) -> void:
	print("Stacking stackables to collection")
	for piece in selected_pieces:
		piece.add_to_collection(coll)
		piece.selected = false

func convert_to_stack(items: Array[Piece]) -> void:
	print("Making new stack")
	# First, create new collection
	var collection: Collection = Collection.construct(
		board,
		{
			"name": board.unique_name("newcoll"),
			"position": items[0].position,
			"rotation": items[0].rotation
		}
	)
	for item in items:
		item.add_to_collection(collection)
		item.selected = false

func select_collections(objs: Array[Collection]) -> void:
	selected_pieces = []
	for obj in objs:
		for pc in obj.get_pieces():
			pc.move_self_to_top()
			selected_pieces.append(pc)
			pc.selected = true

func deselect_pieces() -> void:
	for obj in get_selected_pieces():
		obj.selected = false
	selected_pieces = []

func queue_for_deselection() -> void:
	queued_deselection = true
