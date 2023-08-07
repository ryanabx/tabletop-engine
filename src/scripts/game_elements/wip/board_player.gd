class_name BoardPlayer
extends Node2D

var selected_pieces: Array[Board.Gpiece] = []
var selected_collections: Array[Board.Gcollection] = []

var selectable_piece: Board.Gpiece = null
var highlighted_item: Board.Gobject = null

var selection_box: Rect2 = Rect2(0,0,0,0)
var selection_boxing: bool = false

var currently_moving_selection: bool = false

var grab_offsets: Dictionary = {"pieces": {}, "collections": {}}

enum STATE {
	IDLE, SELECT, MENU
}

var state: STATE = STATE.IDLE

@onready var board: Board = $'..'

######################
### Main Processes ###
######################

func _process(_delta: float) -> void:
	if not Input.is_action_pressed("game_select") and not Input.is_action_pressed("game_select_stack"):
		release_grab_offsets()
	if Input.is_action_just_pressed("game_select") or Input.is_action_just_pressed("game_select_stack"):
		if position_overlaps_selected_pieces(get_local_mouse_position()):
			set_grab_offsets()
	check_for_overlapping_piece()
	update_selection_box()
	queue_redraw()
	if currently_moving_selection:
		move_selected_objects()

func set_grab_offsets() -> void:
	grab_offsets = {"pieces": {}, "collections": {}}
	for obj in selected_pieces:
		grab_offsets.pieces[obj.name] = obj.position - get_local_mouse_position()
	for obj in selected_collections:
		grab_offsets.collections[obj.name] = obj.position - get_local_mouse_position()
	currently_moving_selection = true

func release_grab_offsets() -> void:
	currently_moving_selection = false
	grab_offsets = {"pieces": {}, "collections": {}}

func move_selected_objects() -> void:
	for obj in selected_pieces:
		obj.position = get_local_mouse_position() + grab_offsets.pieces[obj.name]
	for obj in selected_collections:
		obj.position = get_local_mouse_position() + grab_offsets.collections[obj.name]

func update_selection_box() -> void:
	if selection_boxing:
		selection_box.end = get_local_mouse_position()

## Ran every process frame. Checks all the pieces for one that can be highlighted
func check_for_overlapping_piece() -> void:
	if not selected_pieces.is_empty() and currently_moving_selection:
		var best_obj: Board.Gobject = check_for_overlapping_obj(get_local_mouse_position())
		if best_obj == null:
			selectable_piece = null
			highlighted_item = null
		else:
			selectable_piece = null
			highlighted_item = best_obj
	else:
		var best_piece: Board.Gpiece = check_overlapping_piece(get_local_mouse_position())
		selectable_piece = best_piece
		highlighted_item = best_piece
	

## Ran every frame, used for highlighting items and checking deselection stacking
func check_for_overlapping_obj(pos: Vector2) -> Board.Gobject:
	var coll: Board.Gcollection = check_overlapping_collections(pos)
	if coll != null: return coll
	var piece: Board.Gpiece = check_overlapping_piece(pos)
	return piece

## Checks if an overlapping collection exists
func check_overlapping_collections(pos: Vector2) -> Board.Gcollection:
	var best_collection: Board.Gcollection = null
	for collection in board.collections.values():
		if selected_collections.has(collection): continue
		if not board.can_access_collection(collection): continue
		if board.obj_overlaps_point(collection, pos):
			if best_collection == null or collection.position.distance_to(pos) < best_collection.position.distance_to(pos):
				best_collection = collection
	return best_collection

## Checks if an overlapping piece exists
func check_overlapping_piece(pos: Vector2) -> Board.Gpiece:
	var best_piece: Board.Gpiece = null
	for piece in board.pieces.values():
		if selected_pieces.has(piece): continue
		if not board.can_access_piece(piece): continue
		if board.obj_overlaps_point(piece, pos):
			if best_piece == null or piece.z_index > best_piece.z_index:
				best_piece = piece
	return best_piece

#####################
### State changes ###
#####################

func removed_game_menu() -> void:
	if state in [STATE.MENU]:
		print("Menu state to idle state")
		state = STATE.IDLE

####################
### State checks ###
####################

func can_select() -> bool:
	return (state == STATE.IDLE
	or state == STATE.SELECT and not position_overlaps_selected_pieces(get_local_mouse_position()))

func can_deselect() -> bool:
	return (state in [STATE.SELECT] and
	(not position_overlaps_selected_pieces(get_local_mouse_position()) or highlighted_item != null)
	)

func can_menu() -> bool:
	return state in [STATE.IDLE, STATE.SELECT]

##########################
### Drawing Highlights ###
##########################

func _draw() -> void:
	if highlighted_item != null:
		draw_colored_polygon(
			board.get_obj_extents(highlighted_item),
			Color.from_hsv(0.4, 0.2, 1, 0.3)
			)
	if selection_boxing:
		draw_rect(selection_box, Color.BLUE * Color(1,1,1,0.3))
	for obj in selected_pieces:
		draw_colored_polygon(
			board.get_obj_extents(obj),
			Color.GREEN * Color(1,1,1,0.2)
			)

########################
### Input Management ###
########################

func parse_input(input_actions: Dictionary) -> void:
	# Individual selection
	if InputManager.is_select_pressed(input_actions) and can_select():
		if selectable_piece != null:
			print("Selecting object")
			select_pieces([selectable_piece])
			set_grab_offsets()
		else:
			print("Starting selection rectangle")
			deselect_objects()
			selection_box.position = get_local_mouse_position()
			selection_boxing = true
	# Stack selection (or regular if no collection exists)
	if InputManager.is_stack_select_pressed(input_actions) and can_select():
		if selectable_piece != null:
			if selectable_piece.collection != null:
				var c: Board.Gcollection = selectable_piece.collection
				if not c.permanent:
					print("Stack selecting")
					select_pieces(c.inside, false, false)
					select_collection(c)
			else:
				print("Selecting object")
				select_pieces([selectable_piece])
			set_grab_offsets()
	# Deselection
	if InputManager.is_deselect_pressed(input_actions):
		if not selected_pieces.is_empty():
			if can_deselect():
				print("Deselecting objects")
				deselect_objects()
				release_grab_offsets()
		if selection_boxing:
			select_pieces(get_within_selection_box(), false, false)
			select_collections_from_pieces()
			selection_box = Rect2(0,0,0,0)
			selection_boxing = false
	# Flipping object
	if InputManager.is_flip_pressed(input_actions):
		if not selected_pieces.is_empty():
			print("Flipping object")
			flip_objects()
	# Game menu
	if InputManager.is_menu_pressed(input_actions):
		if can_menu():
			print("Attempting to make a game menu")
			game_menu()

########################
### Useful Functions ###
########################

## Find all objects within selection_box
func get_within_selection_box() -> Array[Board.Gpiece]:
	var res: Array[Board.Gpiece] = []
	var selection_polygon: PackedVector2Array = PackedVector2Array([
		Vector2(selection_box.position.x, selection_box.position.y),
		Vector2(selection_box.end.x, selection_box.position.y),
		Vector2(selection_box.end.x, selection_box.end.y),
		Vector2(selection_box.position.x, selection_box.end.y)
	])
	for piece in board.pieces.values():
		if board.obj_overlaps_polygon(piece, selection_polygon):
			res.append(piece)
	return res

## True if a position overlaps any selected piece
func position_overlaps_selected_pieces(pos: Vector2) -> bool:
	for piece in selected_pieces:
		if board.obj_overlaps_point(piece, pos):
			return true
	return false

func select_collections_from_pieces() -> void:
	for pc in selected_pieces:
		if pc.collection != null:
			if not pc.collection.permanent:
				select_collection(pc.collection)
			else:
				if pc.collection.inside.all(func(val: Board.Gpiece) -> bool: return selected_pieces.has(val)):
					convert_to_stack(pc.collection.inside)
					select_collection(pc.collection)
				else:
					board.remove_piece_from_collection(pc)

		

## Select objects
func select_pieces(objs: Array, append: bool = false, remove_from_collection = true) -> void:
	if not append:
		deselect_objects()
	objs.sort_custom(board.sort_by_draw_order)
	for obj in objs:
		_sel_piece(obj, true, remove_from_collection)
	
	if state in [STATE.IDLE]:
		state = STATE.SELECT

## Select one object
func _sel_piece(obj: Board.Gpiece, append: bool = false, remove_from_collection = true) -> void:
	# Piece exclusive stuff
	if obj is Board.Gpiece:
		if remove_from_collection:
			board.remove_piece_from_collection(obj)
		board.move_object_to_top(obj)
	if append:
		selected_pieces.append(obj)
	else:
		selected_pieces = [obj]

func select_collection(coll: Board.Gcollection) -> void:
	selected_collections = [coll]

## Deselect any available objects
func deselect_objects() -> void:
	selected_collections = []
	if selected_pieces.is_empty():
		return
	state = STATE.IDLE

	if highlighted_item != null:
		if highlighted_item is Board.Gpiece:
			print("Stacking objects to piece")
			var objects: Array[Board.Gpiece] = []
			objects.assign(selected_pieces + [highlighted_item])
			convert_to_stack(objects)
		elif highlighted_item is Board.Gcollection:
			print("Stacking objects to collection")
			stack_to_collection(selected_pieces, highlighted_item)
	
	selected_pieces = []
	
	if state in [STATE.SELECT]:
		state = STATE.IDLE

## Flip any available objects
func flip_objects() -> void:
	if selected_pieces.is_empty():
		return
	for piece in selected_pieces:
		board.flip_object(piece)

## Makes a game menu
func game_menu() -> void:
	print(state)
	if state == STATE.IDLE:
		if selectable_piece != null:
			if selectable_piece.collection != null:
				SignalManager.game_menu_create.emit(selectable_piece.collection.inside)
			else:
				var s: Array[Board.Gpiece] = []
				s.assign([selectable_piece])
				SignalManager.game_menu_create.emit(s)
	elif state == STATE.SELECT:
		print("State is here")
		SignalManager.game_menu_create.emit(selected_pieces)

## Converts game objects to stack
func convert_to_stack(objs: Array[Board.Gpiece]) -> void:
	var c: Board.Gcollection = board.construct_collection(
		{
		"position": objs[-1].position,
		"permanent": false
		}
	)
	if c != null:
		board.make_name_exclusive(c)
		board.spawn_object(c)
		var sorted_objs: Array[Board.Gpiece] = []
		sorted_objs.assign(objs)
		sorted_objs.sort_custom(board.sort_by_draw_order)
		for piece in sorted_objs:
			board.add_piece_to_collection(piece, c)

## Stacks an object to a collection
func stack_to_collection(objs: Array[Board.Gpiece], item: Board.Gcollection) -> void:
	var sorted_objs: Array[Board.Gpiece] = []
	sorted_objs.assign(objs)
	sorted_objs.sort_custom(board.sort_by_draw_order)
	for obj in sorted_objs:
		board.add_piece_to_collection(obj, item)

#####################
### Instantiation ###
#####################

func _ready() -> void:
	z_index = 1000
	InputManager.enhanced_inputs.connect(parse_input)
	SignalManager.game_menu_destroy.connect(removed_game_menu)
	SignalManager.convert_to_stack.connect(convert_to_stack)
