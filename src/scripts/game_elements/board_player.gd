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

var moved_since_selected: bool = true

var board: Board

######################
### Getter Methods ###
######################

func get_selected_pieces() -> Array[Piece]:
	return selected_pieces

######################
### Input Handling ###
######################

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("game_flip"):
		for pc in get_selected_pieces():
			pc.flip()
	if event is InputEventMouseMotion and not selected_pieces.is_empty():
		moved_since_selected = true

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
		obj.grab_offset = board.get_local_mouse_position() - obj.position
	
	moved_since_selected = false
	get_tree().create_timer(0.5).timeout.connect(game_menu_check)

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
			pc.grab_offset = board.get_local_mouse_position() - pc.position

func deselect_pieces() -> void:
	for obj in get_selected_pieces():
		obj.selected = false
	selected_pieces = []
	moved_since_selected = true

func queue_for_deselection() -> void:
	queued_deselection = true


func game_menu_check() -> void:
	if not moved_since_selected:
		print("Could create game menu")
		SignalManager.game_menu_create.emit(selected_pieces)
		deselect_pieces()