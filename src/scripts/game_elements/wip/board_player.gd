class_name BoardPlayer
extends Node2D

var selected_pieces: Array[String] = []
var selected_collections: Array[String] = []

var selectable_piece: String = ""
var highlighted_item: String = ""

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
### Getter Methods ###
######################

func get_selected_pieces() -> Array[Piece]:
	var result: Array[Piece] = []
	result.assign(selected_pieces.map(func(val: String) -> Piece: return board.get_piece(val)))
	return result

func get_selected_collections() -> Array[Collection]:
	var result: Array[Collection] = []
	result.assign(selected_collections.map(func(val: String) -> Collection: return board.get_collection(val)))
	return result

func get_selectable_piece() -> Piece:
	return board.get_piece(selectable_piece)

func get_highlighted_item() -> Gobject:
	var result: Gobject = null
	result = board.get_collection(highlighted_item)
	if result == null:
		result = board.get_piece(highlighted_item)
	return result

######################
### Main Processes ###
######################

func _process(_delta: float) -> void:
	# if not (Input.is_action_pressed("game_select_stack") or Input.is_action_pressed("game_select_stack")) and currently_moving_selection:
	# 	release_grab_offsets()
	check_for_overlapping_piece()
	update_selection_box()
	queue_redraw()
	if currently_moving_selection and (Input.is_action_pressed("game_select") or Input.is_action_pressed("game_select_stack")):
		move_selected_objects()

func set_grab_offsets() -> void:
	grab_offsets = {"pieces": {}, "collections": {}}
	for obj in get_selected_pieces():
		if not grab_offsets.pieces.has(obj.name):
			grab_offsets.pieces[obj.name] = Vector2.ZERO
		
		if obj == null:
			print("Uh oh 2")
			continue
		
		grab_offsets.pieces[obj.name] = obj.position - get_local_mouse_position()
	for obj in get_selected_collections():
		if not grab_offsets.collections.has(obj.name):
			grab_offsets.collections[obj.name] = Vector2.ZERO
		
		if obj == null:
			print("Uh oh 2")
			continue
		
		grab_offsets.collections[obj.name] = obj.position - get_local_mouse_position()
	currently_moving_selection = true
	print("Set grab offsets!")

func release_grab_offsets() -> void:
	currently_moving_selection = false
	grab_offsets = {"pieces": {}, "collections": {}}
	print("Release grab offsets!")

func move_selected_objects() -> void:
	for obj in get_selected_pieces():
		if not grab_offsets.pieces.has(obj.name):
			grab_offsets.pieces[obj.name] = obj.position - get_local_mouse_position()
		board.move_piece(obj, get_local_mouse_position() + grab_offsets.pieces[obj.name])
	for obj in get_selected_collections():
		if not grab_offsets.pieces.has(obj.name):
			grab_offsets.pieces[obj.name] = obj.position - get_local_mouse_position()
		board.move_collection(obj, get_local_mouse_position() + grab_offsets.collections[obj.name])

func update_selection_box() -> void:
	if selection_boxing:
		selection_box.end = get_local_mouse_position()

## Ran every process frame. Checks all the pieces for one that can be highlighted
func check_for_overlapping_piece() -> void:
	if not selected_pieces.is_empty() and currently_moving_selection:
		var best_obj: Gobject = check_for_overlapping_obj(get_local_mouse_position())
		if best_obj == null:
			selectable_piece = ""
			highlighted_item = ""
		else:
			selectable_piece = ""
			highlighted_item = best_obj.name
	else:
		var best_piece: Piece = check_overlapping_piece(get_local_mouse_position())
		if best_piece == null:
			selectable_piece = ""
			highlighted_item = ""
		else:
			selectable_piece = best_piece.name
			highlighted_item = best_piece.name
	

## Ran every frame, used for highlighting items and checking deselection stacking
func check_for_overlapping_obj(pos: Vector2) -> Gobject:
	var coll: Collection = check_overlapping_collections(pos)
	if coll != null: return coll
	var piece: Piece = check_overlapping_piece(pos)
	return piece

## Checks if an overlapping collection exists
func check_overlapping_collections(pos: Vector2) -> Collection:
	var best_collection: Collection = null
	for collection in board.collections.values():
		if selected_collections.has(collection.name): continue
		if not board.can_access_collection(collection): continue
		if board.obj_overlaps_point(collection, pos):
			if best_collection == null or collection.position.distance_to(pos) < best_collection.position.distance_to(pos):
				best_collection = collection
	return best_collection

## Checks if an overlapping piece exists
func check_overlapping_piece(pos: Vector2) -> Piece:
	var best_piece: Piece = null
	for piece in board.pieces.values():
		if selected_pieces.has(piece.name): continue
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
	or state == STATE.SELECT)

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
	if get_highlighted_item() != null:
		draw_colored_polygon(
			board.get_obj_extents(get_highlighted_item()),
			Color.from_hsv(0.4, 0.2, 1, 0.3)
			)
	if selection_boxing:
		draw_rect(selection_box, Color.BLUE * Color(1,1,1,0.3))
	for obj in get_selected_pieces():
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
		var over_piece = position_overlaps_selected_pieces(get_local_mouse_position())
		if not over_piece:
			print("Not over piece!")
			if get_selectable_piece() != null:
				print("Selecting object")
				var selection: Array[Piece] = []
				selection.assign([get_selectable_piece()])
				select_pieces(selection, false, true)
				print(selected_pieces.size())
				set_grab_offsets()
			else:
				print("Starting selection rectangle")
				deselect_objects()
				selection_box.position = get_local_mouse_position()
				selection_boxing = true
		else:
			set_grab_offsets()
	# Stack selection (or regular if no collection exists)
	if InputManager.is_stack_select_pressed(input_actions) and can_select():
		if get_selectable_piece() != null:
			if get_selectable_piece().collection != "":
				var c: Collection = board.get_collection(get_selectable_piece().collection)
				if c == null: return
				if not c.permanent:
					print("Stack selecting")
					select_pieces(board.get_pieces(c.inside.keys()), false, false)
					select_collection(c)
					set_grab_offsets()
			else:
				print("Selecting object")
				var selection: Array[Piece] = []
				selection.assign([get_selectable_piece()])
				select_pieces(selection)
				set_grab_offsets()
	# Deselection
	if InputManager.is_deselect_pressed(input_actions):
		if not selected_pieces.is_empty():
			release_grab_offsets()
			if can_deselect():
				print("Deselecting objects")
				deselect_objects()
		if selection_boxing:
			select_pieces(get_within_selection_box(), false, false)
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
func get_within_selection_box() -> Array[Piece]:
	var res: Array[Piece] = []
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
	for piece in get_selected_pieces():
		if board.obj_overlaps_point(piece, pos):
			return true
	return false

func select_collections_from_pieces() -> void:
	for pc in get_selected_pieces():
		if pc.collection != "":
			var collection: Collection = board.get_collection(pc.collection)
			if collection == null: continue
			if collection.permanent:
				if collection.inside.keys().all(func(val: String) -> bool:
					var p = board.get_piece(val)
					return p != null and get_selected_pieces().has(p)
					):
					# print("Option 3")
					convert_to_stack(board.get_pieces(collection.inside.keys()))
					select_collection(collection)
				else:
					# print("Option 2")
					board.remove_piece_from_collection(pc)
			else:
				# print("Option 1")
				select_collection(collection)

		

## Select objects
func select_pieces(objs: Array[Piece], append: bool = false, remove_from_collection = true) -> void:
	if not append:
		print("Deselecting objects")
		deselect_objects()
	objs.sort_custom(board.sort_by_draw_order)
	for obj in objs:
		_sel_piece(obj, true, remove_from_collection)
	
	if state in [STATE.IDLE]:
		state = STATE.SELECT
	
	if not remove_from_collection:
		select_collections_from_pieces()

## Select one object
func _sel_piece(obj: Piece, append: bool = false, remove_from_collection = true) -> void:
	# Piece exclusive stuff
	if obj is Piece:
		if remove_from_collection:
			board.remove_piece_from_collection(obj)
		board.move_object_to_top(obj)
	if append and not selected_pieces.has(obj.name):
		selected_pieces.append(obj.name)
	else:
		selected_pieces = [obj.name]

func select_collection(coll: Collection, append = true) -> void:
	if append and not selected_collections.has(coll.name):
		print("adding collection to selected")
		selected_collections.append(coll.name)
	else:
		selected_collections = [coll.name]

## Deselect any available objects
func deselect_objects() -> void:
	selected_collections = []
	if selected_pieces.is_empty():
		return
	state = STATE.IDLE

	if highlighted_item != null:
		if get_highlighted_item() is Piece:
			print("Stacking objects to piece")
			var objects: Array[Piece] = []
			objects.assign(get_selected_pieces() + [get_highlighted_item()])
			convert_to_stack(objects)
		elif get_highlighted_item() is Collection:
			print("Stacking objects to collection")
			stack_to_collection(get_selected_pieces(), get_highlighted_item())
	
	selected_pieces = []
	
	if state in [STATE.SELECT]:
		state = STATE.IDLE

## Flip any available objects
func flip_objects() -> void:
	if selected_pieces.is_empty():
		return
	for piece in get_selected_pieces():
		board.flip_object(piece)

## Makes a game menu
func game_menu() -> void:
	print(state)
	if state == STATE.IDLE:
		if get_selectable_piece() != null:
			if get_selectable_piece().collection != "":
				var collection: Collection = board.get_collection(get_selectable_piece().collection)
				if collection != null:
					SignalManager.game_menu_create.emit(board.get_pieces(collection.inside.keys()))
			else:
				var s: Array[Piece] = []
				s.assign([selectable_piece])
				SignalManager.game_menu_create.emit(s)
	elif state == STATE.SELECT:
		print("State is here")
		SignalManager.game_menu_create.emit(selected_pieces)

## Converts game objects to stack
func convert_to_stack(objs: Array[Piece]) -> void:
	var sorted_objs: Dictionary = {}
	for obj in objs:
		sorted_objs[obj.name] = true
	board.rpc("construct_collection_rpc",(var_to_bytes({
		"name": board.unique_name("collection"),
		"position": objs[-1].position,
		"permanent": false,
		"inside": sorted_objs
		})))
		

## Stacks an object to a collection
func stack_to_collection(objs: Array[Piece], item: Collection) -> void:
	var sorted_objs: Array[Piece] = []
	sorted_objs.assign(objs)
	sorted_objs.sort_custom(board.sort_by_draw_order)
	for obj in sorted_objs:
		board.add_piece_to_collection(obj, item.name)

#####################
### Instantiation ###
#####################

func _ready() -> void:
	z_index = 1000
	InputManager.enhanced_inputs.connect(parse_input)
	SignalManager.game_menu_destroy.connect(removed_game_menu)
	SignalManager.convert_to_stack.connect(convert_to_stack)
