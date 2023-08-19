class_name BoardPlayer
extends Node2D

var selected_pieces: Array[Piece] = []
var selected_collections: Array[Collection] = []

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
			pc.flip()
	if (event.is_action_released("game_select") or event.is_action_released("game_select_stack")):
		queue_for_deselection()
	if event is InputEventMouseMotion and\
		 not moved_since_selected and not selected_pieces.is_empty():
		moved_since_selected = true
		for pc in selected_pieces:
			if not selected_collections.has(board.get_collection(pc.collection)):
				pc.remove_from_collection()
		return
	
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	params.position = get_local_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1

	if event.is_action_pressed("game_select"):
		var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
		if results.size() > 0:
			results.sort_custom(compare_by_z_index)
			print(results[0].collider.get_parent().get_name())
			results[0].collider.get_parent()._on_gobject_input(event)
	elif event.is_action_released("game_select"):
		var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
		if results.size() > 0:
			results.sort_custom(compare_by_z_index)
			print(results[0].collider.get_parent().get_name())
			results[0].collider.get_parent()._on_gobject_input(event)
	


func compare_by_z_index(a: Dictionary, b: Dictionary) -> bool:
	return a.collider.get_parent().get_index() > b.collider.get_parent().get_index()

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(game_menu_check)
	timer.wait_time = 0.5
	SignalManager.select_objects.connect(select_objects_from_menu)
	physics_state = get_world_2d().get_direct_space_state()

######################
### Main Processes ###
######################

func _process(_delta: float) -> void:
	if queued_deselection:
		if not selected_pieces.is_empty():
			deselect_pieces()
		queued_deselection = false
	pass

func select_objects_from_menu(objs: Array[Piece], with_collections: bool) -> void:
	timer.stop()
	selected_pieces = []
	board.grab_authority_on_objs(objs)
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
			


func select_pieces(objs: Array[Piece]) -> void:
	timer.stop()
	selected_pieces = []
	board.grab_authority_on_objs(objs)
	for obj in objs:
		obj.move_self_to_top.rpc()
		selected_pieces.append(obj)
		obj.set_selected(true)
		obj.grab_offset = board.get_local_mouse_position() - obj.position
	
	moved_since_selected = false
	timer.start()

func stack_selection_to_item(item: Piece) -> void:
	if item.get_collection() != null:
		stack_stackables_to_collection(item.get_collection())
	else:
		selected_pieces.push_front(item)
		convert_to_stack(selected_pieces)
	selected_pieces = []

func stack_stackables_to_collection(coll: Collection) -> void:
	print("Stacking stackables to collection")
	board.grab_authority_on_objs(selected_pieces + [coll])
	for piece in selected_pieces:
		piece.add_to_collection(coll)
		piece.set_selected(false)

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
		item.set_selected(false)

func select_collections(objs: Array[Collection]) -> void:
	timer.stop()
	board.grab_authority_on_objs(objs)
	selected_pieces = []
	for obj in objs:
		board.grab_authority_on_objs(obj.get_pieces())
		for pc in obj.get_pieces():
			pc.move_self_to_top.rpc()
			selected_pieces.append(pc)
			pc.set_selected(true)
			pc.grab_offset = board.get_local_mouse_position() - pc.position
		selected_collections.append(obj)
		obj.set_selected(true)
	moved_since_selected = false
	timer.start()

func deselect_pieces() -> void:
	board.grab_authority_on_objs(get_selected_pieces())
	for obj in get_selected_pieces():
		if is_instance_valid(obj):
			obj.set_selected(false)
	selected_pieces = []
	for obj in get_selected_collections():
		if is_instance_valid(obj):
			obj.set_selected(false)
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
