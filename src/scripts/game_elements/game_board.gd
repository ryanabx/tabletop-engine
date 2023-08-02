class_name GameBoard
extends Node2D

var border: Rect2 = Rect2(-640, -360, 1280, 720)
const STACK_LERP: float = 0.8


var selected_objects: Array[String] = []
var selection_box: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0)
var highlighted_piece: String = ""
var stackable_item: String = ""

var board_texture_string: String = ""

@onready var game_object_manager: Node2D = $GameObjectManager
@onready var board_texture: Sprite2D = $BoardTexture

enum STATE {NONE, DOWN, MULTI, MULTI_DOWN, MENU, MENU_MULTI, SELECTION_BOX}

var state: STATE = STATE.NONE

func _ready() -> void:
	Utils.enhanced_inputs.connect(process_input)
	SignalManager.game_menu_destroy.connect(removed_game_menu)

func _process(_delta):
	set_highlighted_piece(get_overlapping_obj(get_local_mouse_position(), get_tree().get_nodes_in_group("piece")))

	if state in [STATE.MULTI, STATE.MULTI_DOWN] and (Input.is_action_just_pressed("game_select") or Input.is_action_just_pressed("game_select_stack")):
		set_object_grab_offsets()
	if (Input.is_action_pressed("game_select") or Input.is_action_pressed("game_select_stack")):
		if state in [STATE.DOWN, STATE.MULTI_DOWN]:
			move_selected_items()
	elif state == STATE.SELECTION_BOX:
		group_selection_instantiated()
	if state == STATE.SELECTION_BOX:
		update_selection_rect()
	queue_redraw()

# Process functions

func set_object_grab_offsets() -> void:
	for object in get_selected_items():
		object.set_grab_offset(object.position - get_local_mouse_position())

func update_selection_rect() -> void:
	selection_box.end = get_local_mouse_position()
	selection_box.position = selection_box.position.clamp(border.position, border.end)
	selection_box.end = selection_box.end.clamp(border.position, border.end)

func move_selected_items() -> void:
	for object in get_selected_items():
		if object.has_collection() and object.get_collection().get_permanence():
			object.get_collection().remove_game_object(object)
		object.position = get_local_mouse_position() + object.get_grab_offset()
		object.position = object.position.clamp(border.position, border.end)
	# CHECK STACKING
	var stackable_collection: GameCollection = find_stackable_collection(get_selected_items())
	if stackable_collection == null:
		var stackable_object: Piece = find_stackable_object(get_selected_items())
		set_stackable_item(stackable_object)
	else:
		set_stackable_item(stackable_collection)

func over_item():
	return stackable_item != null

func get_stackable_item() -> GameObject:
	return Utils.get_game_object(stackable_item)
	
func set_stackable_item(item: GameObject) -> void:
	if over_item() and get_stackable_item() != item and get_stackable_item() != null:
		get_stackable_item().dehighlight()
	# If stack is permitted
	if item and item.can_access(Player.get_id()) == false:
		pass
	else:
		if item == null:
			stackable_item = ""
		else:
			stackable_item = item.get_name()
	if over_item() and get_stackable_item() != null:
		get_stackable_item().highlight()

func find_stackable_object(objects: Array) -> Piece:
	var game_objs: Array = get_tree().get_nodes_in_group("piece")
	var best_object: Piece = null
	var best_dist: float = 0.0
	var ref_position = get_local_mouse_position()
	for object in game_objs:
		if object.unselectable() or object in objects:
			pass
		elif object_overlaps_point(object, ref_position):
			if best_object == null or ref_position.distance_to(object.position) < best_dist or (ref_position.distance_to(object.position) == best_dist and object.z_index > best_object.z_index):
				best_dist = ref_position.distance_to(object.position)
				best_object = object
	return best_object

func find_stackable_collection(objects: Array) -> GameCollection:
	var collections: Array = get_tree().get_nodes_in_group("collections")
	var best_object: GameCollection = null
	var best_dist: float = 0.0
	var ref_position = get_local_mouse_position()
	for collection in collections:
		if collection.disabled() or Utils.has_any(collection.get_game_objects(), objects):
			continue
		elif collection_overlaps_point(collection, ref_position):
			if best_object == null or ref_position.distance_to(collection.position) < best_dist:
				best_dist = ref_position.distance_to(collection.position)
				best_object = collection
	return best_object

# State management

func group_selection_instantiated() -> bool:
	if state in [STATE.SELECTION_BOX]:
		var items: Array = []
		for object in get_tree().get_nodes_in_group("piece"):
			if object.can_access(Player.get_id()) == false:
				continue
			if _rect_obj_areas_overlap(object, selection_box):
				items.append(object)
		select_objects(items)
		selection_box = Rect2(0.0, 0.0, 0.0, 0.0)
		return true
	else:
		print("Cannot change from ",state," in group_selection_instantiated")
		return false

func group_selection_released() -> bool:
	if state in [STATE.MULTI]:
		state = STATE.NONE
		return true
	else:
		print("Cannot change from ",state," in group_selection_released")
		return false

func objects_selected() -> bool:
	if state in [STATE.NONE]:
		state = STATE.DOWN
		return true
	if state in [STATE.SELECTION_BOX]:
		state = STATE.MULTI
		return true
	else:
		print("Cannot change from ",state," in objects_selected")
		return false

func objects_deselected() -> bool:
	if state in [STATE.DOWN, STATE.MULTI,  STATE.MULTI_DOWN, STATE.SELECTION_BOX]:
		state = STATE.NONE
		return true
	else:
		print("Cannot change from ",state," in objects_deselected")
		return false

func made_game_menu() -> bool:
	if state in [STATE.NONE]:
		state = STATE.MENU
		return true
	elif state in [STATE.MULTI]:
		state = STATE.MENU_MULTI
		return true
	else:
		print("Cannot change from ",state," in made_game_menu")
		return false

func removed_game_menu() -> bool:
	if state in [STATE.MENU]:
		state = STATE.NONE
		return true
	elif state in [STATE.MENU_MULTI]:
		state = STATE.MULTI
		return true
	else:
		print("Cannot change from ",state," in removed_game_menu")
		return false

func multi_select_down() -> bool:
	if state in [STATE.MULTI]:
		state = STATE.MULTI_DOWN
		return true
	else:
		print("Cannot change from ",state," in multi_select_down")
		return false

func multi_select_up() -> bool:
	if state in [STATE.MULTI_DOWN]:
		state = STATE.MULTI
		return true
	else:
		print("Cannot change from ",state," in multi_select_down")
		return false

# Input management

func process_input(input_actions: Dictionary) -> void:
	# SELECTING OBJECTS
	if Utils.just_long_held("game_select", input_actions) or Utils.just_long_held("game_select_stack", input_actions):
		if state == STATE.MULTI and Utils.just_long_held("game_select", input_actions):
			check_over_group_selection()
		elif state in [STATE.NONE]:
			check_selecting_obj(input_actions)
	# RIGHT CLICKING
	if state in [STATE.NONE, STATE.MULTI] and Utils.just_short_released("game_menu", input_actions):
		make_game_menu()
	# DESELECTING GROUP SELECTED OBJECTS
	if Utils.just_released("game_select", input_actions) or Utils.just_released("game_select_stack", input_actions) or Utils.just_released("end_group_select", input_actions):
		if state in [STATE.MULTI] and not Utils.just_short_released("game_menu", input_actions):
			deselect_objects()
	# DESELECTING OBJECTS
	if Utils.just_long_released("game_select", input_actions) or Utils.just_long_released("game_select_stack", input_actions):
		if state in [STATE.MULTI_DOWN, STATE.DOWN]:
			release_selection()
	# FLIPPING OBJECTS
	if Utils.just_released("game_flip", input_actions) and state in [STATE.DOWN, STATE.MULTI, STATE.MULTI_DOWN]:
		game_object_manager.flip_objects(get_selected_items())

# Utilities



# Selecting objects

func check_over_group_selection() -> void:
	if get_overlapping_obj(get_local_mouse_position(), get_selected_items()) != null:
		multi_select_down()

func check_selecting_obj(input_actions: Dictionary) -> void:
	var obj_selection: Piece = get_overlapping_obj(get_local_mouse_position(), get_tree().get_nodes_in_group("piece"))
	if obj_selection:
		if obj_selection.has_collection() and Utils.just_held("game_select_stack", input_actions): # Select collection
			selecting_collection(obj_selection)
		else: # Select piece
			selecting_piece(obj_selection)
	elif not Utils.just_long_held("game_select_stack", input_actions): # Selection box
		initialize_selection_rect()

func selecting_piece(obj_selection: Piece) -> void:
	if state == STATE.NONE and obj_selection.has_collection():
		obj_selection.get_collection().remove_game_object(obj_selection)
	select_objects([obj_selection])

func selecting_collection(obj_selection: Piece) -> void:
	if obj_selection.get_collection().get_permanence(): return
	select_objects(obj_selection.get_collection().get_game_objects())

func set_highlighted_piece(pc: Piece) -> void:
	if pc == null:
		highlighted_piece = ""
	else:
		highlighted_piece = pc.get_name()

func get_highlighted_piece() -> Piece:
	return Utils.get_game_object(highlighted_piece) as Piece

# Game menu

func make_game_menu() -> void:
	if state == STATE.NONE and get_highlighted_piece() != null:
		if get_highlighted_piece().has_collection():
			SignalManager.game_menu_create.emit(RightClickMenu.TYPE.COLLECTION, [get_highlighted_piece().get_collection()])
		else:
			SignalManager.game_menu_create.emit(RightClickMenu.TYPE.GAME_OBJECT, [get_highlighted_piece()])
		made_game_menu()
	elif state == STATE.MULTI:
		if get_overlapping_obj(get_local_mouse_position(), get_selected_items()) != null:
			if get_selected_items().size() > 1:
				SignalManager.game_menu_create.emit(RightClickMenu.TYPE.OBJECT_GROUP, get_selected_items())
			else:
				SignalManager.game_menu_create.emit(RightClickMenu.TYPE.GAME_OBJECT, [get_selected_items()[0]])
			made_game_menu()

# Border stuff

func set_border(bord: Rect2) -> void:
	border = bord

func get_border() -> Rect2:
	return border

# Board Texture

func set_board_texture() -> void:
	if board_texture_string == "" or Globals.get_current_game() == null:
		board_texture.set_texture(null)
		return
	else:
		board_texture.set_texture(Globals.get_current_game().images[board_texture_string])
	board_texture.scale = (get_border().size) / board_texture.get_rect().size
	board_texture.position = get_border().get_center()

func _draw() -> void:
	draw_rect(border, Color.from_hsv(0.0, 0.0, 1.0, 1.0), false, Globals.OUTLINE_THICKNESS * 3.0)

func select_objects(objects: Array) -> void:
	if objects.is_empty() and objects_deselected():
		for object in get_selected_items():
			object.deselect()
		selected_objects = []
		return
	if objects_selected():
		selected_objects = []
		for object in objects:
			object.select()
			object.rotation = Globals.get_shared_tabletop_manager().camera_controller.camera.rotation
			selected_objects.append(object.get_name())
		Utils.rpc("gain_control_over_objects", multiplayer.get_unique_id(), selected_objects)
		game_object_manager.move_objects_to_front(objects)
		set_object_grab_offsets()

func initialize_selection_rect() -> void:
	if state in [STATE.NONE]:
		selection_box.position = get_local_mouse_position()
		state = STATE.SELECTION_BOX
	else:
		print("Cannot transition from ",state," in initialilze_selection_rect")


func get_overlapping_obj(point: Vector2, game_objects: Array) -> Piece:
	var best: Piece = null
	for object in game_objects:
		var g_obj := object as Piece
		if g_obj.has_collection() and g_obj.can_access(Player.get_id()) == false:
			continue
		if (g_obj.get_rect() * g_obj.get_transform().affine_inverse()).has_point(point):
			if best == null or (g_obj.z_index > best.z_index):
				best = g_obj
	return best

func has_selected_items() -> bool:
	return not selected_objects.is_empty()

func get_selected_items() -> Array:
	return (Utils.get_game_objects(selected_objects) as Array[Piece])

func release_selection() -> void:
	# If over an item, stack objects to that item, then also deselect
	if over_item():
		game_object_manager.stack_objects_to_item(selected_objects, stackable_item)
		set_stackable_item(null)
		deselect_objects()
	elif state == STATE.DOWN:
		deselect_objects()
	elif state == STATE.MULTI_DOWN:
		multi_select_up()

func deselect_objects() -> void:
	select_objects([])

func objects_not_in_collection(objects: Array) -> bool:
	for obj in objects:
		if obj.has_collection():
			return false
	return true

func collection_overlaps_point(collection: GameCollection, point: Vector2) -> bool:
	return collection.get_extents().has_point(point)

func object_overlaps_point(object: Piece, point: Vector2):
	return object.get_extents().has_point(point)

func _rect_obj_areas_overlap(obj1: Piece, _rect: Rect2):
	return (obj1.get_rect() * obj1.get_transform().affine_inverse()).intersects(_rect.abs())
