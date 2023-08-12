class_name BoardPlayer
extends Node2D

var selected_pieces: Array[Piece] = []
var selected_collections: Array[Collection] = []

var selection_box: Rect2 = Rect2(0,0,0,0)
var selection_boxing: bool = false

enum InputState {
	UNHANDLED, HANDLED
}

var input_state: InputState = InputState.UNHANDLED

var queued_deselection: bool = false

var moved_since_selected: bool = true

var board: Board

var timer: Timer

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
	if event is InputEventMouseMotion and not moved_since_selected and not selected_pieces.is_empty():
		moved_since_selected = true
		for pc in selected_pieces:
			if not selected_collections.has(board.get_collection(pc.collection)):
				pc.remove_from_collection()

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(game_menu_check)
	timer.wait_time = 0.5

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
	timer.stop()
	selected_pieces = []
	board.grab_authority_on_objs(objs)
	for obj in objs:
		obj.move_self_to_top()
		selected_pieces.append(obj)
		obj.selected = true
		obj.grab_offset = board.get_local_mouse_position() - obj.position
	
	moved_since_selected = false
	timer.start()

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
	board.grab_authority_on_objs(selected_pieces + [coll])
	for piece in selected_pieces:
		piece.add_to_collection(coll)
		piece.selected = false

func convert_to_stack(items: Array[Piece]) -> void:
	print("Making new stack")
	board.grab_authority_on_objs(items)
	# First, create new collection
	var collection: Collection = board.create_collection(
		var_to_bytes({
			"name": board.unique_name("newcoll"),
			"position": items[0].position,
			"rotation": items[0].rotation
		})
	)
	board.grab_authority_on_objs([collection])
	for item in items:
		item.add_to_collection(collection)
		item.selected = false

func select_collections(objs: Array[Collection]) -> void:
	timer.stop()
	board.grab_authority_on_objs(objs)
	selected_pieces = []
	for obj in objs:
		board.grab_authority_on_objs(obj.get_pieces())
		for pc in obj.get_pieces():
			pc.move_self_to_top()
			selected_pieces.append(pc)
			pc.selected = true
			pc.grab_offset = board.get_local_mouse_position() - pc.position
		selected_collections.append(obj)
	moved_since_selected = false
	timer.start()

func deselect_pieces() -> void:
	board.grab_authority_on_objs(get_selected_pieces())
	for obj in get_selected_pieces():
		obj.selected = false
	selected_pieces = []
	selected_collections = []
	moved_since_selected = true

func queue_for_deselection() -> void:
	queued_deselection = true


func game_menu_check() -> void:
	if not moved_since_selected:
		print("Could create game menu")
		if selected_pieces.size() == 1 and selected_pieces[0].collection != "":
			SignalManager.game_menu_create.emit(selected_pieces[0].get_collection().get_pieces())
		else:
			SignalManager.game_menu_create.emit(selected_pieces)
		deselect_pieces()
