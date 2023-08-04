class_name BoardPlayer
extends Node2D

var selected_pieces: Array[String] = []
var selectable_piece: String = ""
var highlighted_item: Dictionary = {}

var selection_box: Rect2 = Rect2(0,0,0,0)

enum STATE {
	IDLE, SELECT, MENU
}

var state: STATE = STATE.IDLE

@onready var board: Board = $'..'

######################
### Main Processes ###
######################

func _process(_delta: float) -> void:
	check_for_overlapping_piece()
	queue_redraw()
	if Input.is_action_pressed("game_select") or Input.is_action_pressed("game_select_stack"):
		move_selected_objects()

func move_selected_objects() -> void:
	for obj in selected_pieces:
		board.get_piece(obj).position = get_local_mouse_position()

## Ran every process frame. Checks all the pieces for one that can be highlighted
func check_for_overlapping_piece() -> void:
	if selected_pieces.is_empty():
		var best_piece: String = ""
		for key in board.pieces.keys():
			if selected_pieces.has(key): continue
			var piece: Dictionary = board.get_piece(key)
			if not board.can_access_piece(piece): continue
			if board.obj_overlaps_point(piece, get_local_mouse_position()):
				if best_piece == "" or board.draw_order.find(key) > board.draw_order.find(best_piece):
					best_piece = key
		selectable_piece = best_piece
		highlighted_item = board.get_piece(best_piece) if best_piece != "" else {}
		return
	else:
		var best_obj: Dictionary = check_for_overlapping_obj(get_local_mouse_position())
		if best_obj.is_empty():
			selectable_piece = ""
			highlighted_item = {}
		else:
			selectable_piece = ""
			highlighted_item = best_obj

## Ran every frame, used for highlighting items and checking deselection stacking
func check_for_overlapping_obj(pos: Vector2) -> Dictionary:
	# First check collections for overlap
	var best_collection: String = ""
	for key in board.collections.keys():
		var collection: Dictionary = board.get_collection(key)
		if not board.can_access_collection(collection): continue
		if board.obj_overlaps_point(collection, pos):
			if best_collection == "" or collection.position.distance_to(pos) < board.get_collection(best_collection).position.distance_to(pos):
				best_collection = key
	if best_collection != "": return board.get_collection(best_collection)
	# If collection wasn't found, check pieces
	var best_piece: String = ""
	for key in board.pieces.keys():
		if selected_pieces.has(key): continue
		var piece: Dictionary = board.get_piece(key)
		if not board.can_access_piece(piece): continue
		if board.obj_overlaps_point(piece, pos):
			if best_piece == "" or board.draw_order.find(key) > board.draw_order.find(best_piece):
				best_piece = key
	if best_piece != "": return board.get_piece(best_piece)
	return {}

#####################
### State changes ###
#####################

func removed_game_menu() -> void:
	if state in [STATE.MENU]:
		state = STATE.IDLE

####################
### State checks ###
####################

func can_select() -> bool:
	return state in [STATE.IDLE]

func can_menu() -> bool:
	return state in [STATE.IDLE]

##########################
### Drawing Highlights ###
##########################

func _draw() -> void:
	if not highlighted_item.is_empty():
		draw_colored_polygon(
			board.get_obj_extents(highlighted_item),
			Color.from_hsv(0.4, 0.2, 1, 0.3)
			)

########################
### Input Management ###
########################

func parse_input(input_actions: Dictionary) -> void:
	# Selection
	if InputManager.is_select_pressed(input_actions):
		if selectable_piece != "":
			print("Selecting object")
			select_objects([board.get_piece(selectable_piece)])
	# Deselection
	if InputManager.is_deselect_pressed(input_actions):
		if not selected_pieces.is_empty():
			print("Deselecting objects")
			deselect_objects()
	# Flipping object
	if InputManager.is_flip_pressed(input_actions):
		if not selected_pieces.is_empty():
			print("Flipping object")
			flip_objects()


########################
### Useful Functions ###
########################

## Select objects
func select_objects(objs: Array, append: bool = false) -> void:
	if not append:
		deselect_objects()
	for obj in objs:
		_select_object(obj, true)
	
	if state in [STATE.IDLE]:
		state = STATE.SELECT

## Select one object
func _select_object(obj: Dictionary, append: bool = false) -> void:
	obj.state = multiplayer.get_unique_id()
	# Piece exclusive stuff
	if obj.type == Board.TYPE.PIECE:
		board.remove_piece_from_collection(obj)
		board.move_object_to_top(obj)
	if append:
		selected_pieces.append(obj.name)
	else:
		selected_pieces = [obj.name]

## Deselect any available objects
func deselect_objects() -> void:
	if selected_pieces.is_empty():
		return

	if not highlighted_item.is_empty():
		if highlighted_item.type == Board.TYPE.PIECE:
			print("Stacking objects to piece")
			convert_to_stack(selected_pieces + [highlighted_item.name])
		elif highlighted_item.type == Board.TYPE.COLLECTION:
			print("Stacking objects to collection")
			stack_to_collection(selected_pieces, highlighted_item)
	
	selected_pieces = []

## Flip any available objects
func flip_objects() -> void:
	if selected_pieces.is_empty():
		return
	
	for key in selected_pieces:
		var piece: Dictionary = board.get_piece(key)
		board.flip_object(piece)

func convert_to_stack(objs: Array) -> void:
	var c: Dictionary = board.spawn_object(
		board.construct_collection({
			"position": board.get_piece(objs[-1]).position,
			"permanent": false
		}
		)
	)
	if not c.is_empty():
		for key in objs:
			var piece = board.get_piece(key)
			board.add_piece_to_collection(piece, c)

func stack_to_collection(objs: Array, item: Dictionary) -> void:
	for key in objs:
		var piece = board.get_piece(key)
		board.add_piece_to_collection(piece, item)

#####################
### Instantiation ###
#####################

func _ready() -> void:
	z_index = 1000
	InputManager.enhanced_inputs.connect(parse_input)
	SignalManager.game_menu_destroy.connect(removed_game_menu)
