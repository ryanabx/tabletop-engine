class_name BoardPlayer
extends Node2D

var selected_pieces: Array[Piece] = []
var selected_collections: Array[Collection] = []
var queue_take_piece_off: Collection = null

var grab_position: Vector2 = Vector2.ZERO

var selection_box: Rect2 = Rect2(0,0,0,0)
var selection_boxing: bool = false

var queued_deselection: bool = false

var moved_since_selected: bool = true

var board: Board

var timer: Timer

var physics_state: PhysicsDirectSpaceState2D

######################
### Getter Methods ###
######################

func get_selected_pieces() -> Array[Piece]:
	return selected_pieces

func get_selected_collections() -> Array[Collection]:
	return selected_collections

func is_selecting() -> bool:
	return not (selected_pieces.is_empty() and selected_collections.is_empty())

######################
### Input Handling ###
######################

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("game_flip"):
		for pc in get_selected_pieces():
			pc.face_up = not pc.face_up
	if (event.is_action_released("game_select") or event.is_action_released("game_select_stack")):
		queue_for_deselection()
	if event is InputEventMouseMotion and\
		 not moved_since_selected:
		timer.stop()
		if queue_take_piece_off != null:
			var pc: Piece = queue_take_piece_off.remove_from_top()
			pc.position = queue_take_piece_off.position
			pc.rotation = queue_take_piece_off.rotation
			select_pieces([pc])
			deselect_queue_take_piece_off()
		moved_since_selected = true
		return
	
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	params.position = get_local_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1

	if event.is_action_pressed("game_select"):
		grab_position = get_local_mouse_position()
		var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
		if results.size() > 0:
			results.sort_custom(compare_by_z_index)
			print(results[0].collider.get_parent().get_name())
			results[0].collider.get_parent()._on_select(event)
		else:
			SignalManager.camera_move_start.emit()
	elif event.is_action_released("game_select"):
		SignalManager.camera_move_end.emit()
		if is_selecting():
			var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
			if results.size() > 0:
				results.sort_custom(compare_by_z_index)
				print(results[0].collider.get_parent().get_name())
				results[0].collider.get_parent()._on_deselect(event)

func compare_by_z_index(a: Dictionary, b: Dictionary) -> bool:
	return a.collider.get_parent().get_index() > b.collider.get_parent().get_index()

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


func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(game_menu_check)
	timer.wait_time = 0.5
	SignalManager.select_objects.connect(select_objects_from_menu)
	SignalManager.shuffle_selection.connect(shuffle)
	physics_state = get_world_2d().get_direct_space_state()

######################
### Main Processes ###
######################

func _process(_delta: float) -> void:
	if queued_deselection:
		if not (selected_pieces.is_empty() and selected_collections.is_empty() and queue_take_piece_off == null):
			deselect()
		queued_deselection = false
	pass

func select_objects_from_menu(objs: Array[Piece], with_collections: bool) -> void:
	timer.stop()
	deselect_pieces()
	if with_collections == true:
		# NOTE: With collections expects that all objs being selected are in the same collection
		var collection: Collection = objs[0].get_collection()
		if collection.permanent == true:
			convert_to_stack(objs)
			collection = objs[0].get_collection()
		selected_collections.append(collection)
		collection.set_selected(true)

	for obj in objs:
		obj.move_self_to_top.rpc()
		selected_pieces.append(obj)
		obj.set_selected(true)
		obj.grab_offset = Vector2.ZERO
	timer.stop()
			
func select_pieces(objs: Array[Piece]) -> void:
	timer.stop()
	deselect_pieces()
	for obj in objs:
		obj.move_self_to_top.rpc()
		selected_pieces.append(obj)
		obj.set_selected(true)
		obj.grab_offset = grab_position - obj.position
	
	moved_since_selected = false
	timer.start()

func select_collections(objs: Array[Collection]) -> void:
	timer.stop()
	deselect_collections()
	for obj in objs:
		obj.move_self_to_top.rpc()
		selected_collections.append(obj)
		obj.set_selected(true)
		obj.grab_offset = grab_position - obj.position
	
	moved_since_selected = false
	timer.start()

func select_collection(obj: Collection) -> void:
	timer.stop()
	deselect_queue_take_piece_off()
	obj.move_self_to_top.rpc()
	queue_take_piece_off = obj
	moved_since_selected = false
	timer.start()

func stack_selection_to_item(item: Gobject) -> void:
	item.auth = multiplayer.get_unique_id()
	if item is Collection:
		stack_stackables_to_collection(item)
	elif item is Piece:
		selected_pieces.push_front(item)
		convert_to_stack(selected_pieces)
	deselect()

func stack_stackables_to_collection(coll: Collection) -> void:
	print("Stacking stackables to collection")
	for piece in get_selected_pieces():
		piece.add_to_collection(coll)
	for collection in get_selected_collections():
		coll.inside.append_array(collection.inside)
		coll.call_inside_changed()
		collection.clear_inside()

func convert_to_stack(items: Array[Piece]) -> void:
	print("Making new stack")
	# First, create new collection
	var collection: Collection = board.create_collection(
		var_to_bytes({
			"name": board.unique_name("newcoll"),
			"position": items[0].position,
			"rotation": items[0].rotation
		})
	)
	collection.auth = multiplayer.get_unique_id()
	for item in items:
		item.add_to_collection(collection)
		item.set_selected(false)

func deselect() -> void:
	deselect_pieces()
	deselect_collections()
	deselect_queue_take_piece_off()
	moved_since_selected = true

func deselect_pieces() -> void:
	for obj in get_selected_pieces():
		if is_instance_valid(obj):
			obj.set_selected(false)
	selected_pieces = []

func deselect_collections() -> void:
	for obj in get_selected_collections():
		if is_instance_valid(obj):
			obj.set_selected(false)
	selected_collections = []

func deselect_queue_take_piece_off() -> void:
	if queue_take_piece_off != null:
		queue_take_piece_off.set_selected(false)
		queue_take_piece_off = null

func queue_for_deselection() -> void:
	queued_deselection = true

func rotate_selection(amount: float, axis: float) -> void:
	for obj in get_selected_collections():
		if not is_instance_valid(obj):
			continue
		obj.rotation += amount
		if absf(axis) < 0.1 and absf(roundf(obj.rotation_degrees / 45.0) * 45.0 - obj.rotation_degrees) < 7.5:
			obj.rotation_degrees = roundf(obj.rotation_degrees / 45.0) * 45.0
	
	for obj in get_selected_pieces():
		if not is_instance_valid(obj):
			continue
		obj.rotation += amount
		if absf(axis) < 0.1 and absf(roundf(obj.rotation_degrees / 45.0) * 45.0 - obj.rotation_degrees) < 7.5:
			obj.rotation_degrees = roundf(obj.rotation_degrees / 45.0) * 45.0

func game_menu_check() -> void:
	if not moved_since_selected:
		if not get_selected_pieces().is_empty():
			SignalManager.game_menu_create.emit(selected_pieces)
		elif queue_take_piece_off != null:
			SignalManager.game_menu_create_collection.emit(queue_take_piece_off)
		else:
			print("Could not create game menu")
		deselect()
