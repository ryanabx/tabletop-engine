class_name TabletopManager
extends Node

var piece_scene: PackedScene = preload("res://src/scenes/game_elements/piece.tscn")
var stack_scene: PackedScene = preload("res://src/scenes/game_elements/stack.tscn")
var hand_scene: PackedScene = preload("res://src/scenes/game_elements/hand.tscn")

var base_scene: PackedScene = preload("res://src/scenes/game_elements/game_base.tscn")

var action_queue: Array = []

# Crucial tabletop operation nodes
@onready var board: GameBoard
@onready var user_interface: UserInterface
@onready var camera_controller: Node2D

@onready var tabletop: Node = null

var game: GameConfig = null
var coordinate_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	var _tt: Node = base_scene.instantiate()
	board = _tt.get_node("./GameBoard")
	user_interface = _tt.get_node("./UserInterfaceLayer/UserInterface")
	camera_controller = _tt.get_node("./CameraController")
	tabletop = _tt
	add_child(_tt)

func _process(_delta: float) -> void:
	if not action_queue.is_empty():
		var cmd: Dictionary = action_queue.pop_front()
		await parse_command(cmd)

func reset_tabletop() -> void:
	if tabletop != null:
		tabletop.queue_free()
		await tabletop.tree_exited
		tabletop = null
		board = null
		user_interface = null
		camera_controller = null
	tabletop = base_scene.instantiate()
	board = tabletop.get_node("./GameBoard")
	user_interface = tabletop.get_node("./UserInterfaceLayer/UserInterface")
	camera_controller = tabletop.get_node("./CameraController")
	tabletop.tree_exited.connect(tabletop_exiting_tree)
	tabletop.ready.connect(tabletop_ready)
	add_child(tabletop)

func tabletop_ready() -> void:
	print("TABLETOP READY")

func tabletop_exiting_tree() -> void:
	print("OLD TABLETOP LEFT TREE")

func load_config(config: Resource) -> bool:
	# Load basic game stuff
	game = config
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	await reset_tabletop()
	build_game()
	reset_camera()
	build_board_objects()
	return true

func reset_game() -> bool:
	await reset_tabletop()
	build_game()
	reset_camera()
	build_board_objects()
	return true

func reset_camera() -> void:
	if game == null:
		camera_controller.set_camera_transform(
			Vector2.ZERO,
			Vector2.ONE,
			0.0
		)
		return
	
	var camera_transform: Dictionary = game.camera[Player.get_id()]
	
	if "y" in camera_transform.scale:
		camera_controller.set_camera_transform(
			Vector2(camera_transform.position.x, camera_transform.position.y) * coordinate_scale,
			Vector2(camera_transform.scale.y, camera_transform.scale.y) * coordinate_scale.y / get_viewport().get_visible_rect().size.y,
			camera_transform.rotation
		)
	elif "x" in camera_transform.scale:
		camera_controller.set_camera_transform(
			Vector2(camera_transform.position.x, camera_transform.position.y) * coordinate_scale,
			Vector2(camera_transform.scale.x, camera_transform.scale.x) * coordinate_scale.x / get_viewport().get_visible_rect().size.x,
			camera_transform.rotation
		)

func build_game() -> void:
	print(game.images.keys())
	# Set up game border
	if "border" in game.board:
		board.set_border(
			Rect2(
				(Vector2(game.board.border.position.x, game.board.border.position.y) - Vector2(game.board.border.scale.x, game.board.border.scale.y) / 2) * coordinate_scale,
				Vector2(game.board.border.scale.x, game.board.border.scale.y) * coordinate_scale
			)
		)
	# Set up game bg
	if "background_image" in game.board and game.board.background_image != "":
		board.set_board_texture(game.images[game.board.background_image])

func build_board_objects() -> void:
	for item in game.objects:
		process_object(item)

func process_object(obj: Dictionary) -> void:
	# Use templates if they exist
	if "template" in obj:
		obj.merge(game.templates[obj.template])
	
	# Handle for loops
	if "for" in obj:
		var total_objs: int = 1
		for x in obj["for"].keys():
			total_objs = total_objs * obj["for"][x].size()
		for i in range(total_objs):
			var repls: Dictionary = {}
			var t: int = 1
			for key in obj["for"].keys():
				var size = obj["for"][key].size()
				repls[key] = obj["for"][key][(i/t) % size]
				t = t * size
			var _o: Dictionary = make_object_dict(obj, repls)
			new_object(_o)
	else:
		new_object(obj)
	
	# Create objects

func make_object_dict(original: Dictionary, repls: Dictionary) -> Dictionary:
	var obj: Dictionary = original.duplicate(true)
	for key in obj.keys():
		for repl in repls.keys():
			if typeof(obj[key]) == TYPE_STRING:
				obj[key] = obj[key].replacen(repl, repls[repl])
	return obj
	
func new_object(obj: Dictionary) -> void:
	var amount: int = obj.repeat if "repeat" in obj else 1

	for i in range(amount):
		if "type" not in obj:
			print("Error: object does not contain a type")
			break
		match obj.type:
			"piece":
				new_piece(obj)
			"stack":
				new_collection(obj)
			"hand":
				new_collection(obj)
			_:
				print("Huh?")

func new_piece(obj: Dictionary) -> void:
	var piece: Piece = piece_scene.instantiate()
	if "name" in obj:
		piece.add_to_group(obj.name)
		piece.set_name(obj.name)
	# Add child
	board.game_object_manager.add_child(piece)
	# Piece transforms
	piece.position = Vector2(obj.position.x, obj.position.y) * coordinate_scale if "position" in obj else Vector2.ZERO
	piece.rotation_degrees = obj.rotation if "rotation" in obj else 0.0
	# Piece exclusives
	piece.image_up = game.images[obj.image_up]
	piece.image_down = game.images[obj.image_down]
	piece.set_side(obj.face_up)
	piece.set_sprite_scale(Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE)
	# Collections
	if "collection" in obj:
		var coll: GameCollection = (get_tree().get_nodes_in_group(obj.collection)[0] as GameCollection)
		coll.add_game_object_to_top(piece)
		piece.position = coll.position

func new_collection(obj: Dictionary) -> void:
	var collection: GameCollection
	match obj.type:
		"hand": collection = hand_scene.instantiate()
		"stack": collection = stack_scene.instantiate()
		_: return
	if "name" in obj:
		collection.add_to_group(obj.name)
		collection.set_name(obj.name)
	# Add child
	board.game_object_manager.add_child(collection)
	# Collection transforms
	collection.position = Vector2(obj.position.x, obj.position.y) * coordinate_scale if "position" in obj else Vector2.ZERO
	collection.base_size = Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE
	collection._scale = Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE
	collection.rotation_degrees = obj.rotation if "rotation" in obj else 0.0
	# Collection exclusives
	if "permanent" in obj:
		collection.permanent = obj.permanent
	if "force_state" in obj:
		collection.force_state = obj.force_state
	if "view_perms" in obj:
		collection.view_perms = obj.view_perms
	if "access_perms" in obj:
		collection.access_perms = obj.access_perms
	
func run_action(index: int) -> void:
	var action: Array = game.actions[index].actions.duplicate(true)
	for cmd in action:
		action_queue.append(cmd)
	print("Action ",game.actions[index].name, " added to queue.")

func parse_command(cmd: Dictionary) -> void:
	var result: bool = true
	var repeat = cmd.repeat if "repeat" in cmd else 1
	print("Running command ",cmd.cmd)
	for i in range(repeat):
		match cmd.cmd:
			"reset_board":
				result = await cmd_reset_board(cmd)
			"shuffle":
				result = cmd_shuffle(cmd)
			"move_top":
				result = cmd_move_top(cmd)
			_:
				result = false
	print("Command ",cmd.cmd, " returned ",result)

### ACTION COMMANDS ###

func cmd_reset_board(_cmd: Dictionary) -> bool:
	await reset_game()
	print("Done resetting board")
	return true

func cmd_shuffle(cmd: Dictionary) -> bool:
	if not "targets" in cmd.args:
		return false
	for group_name in cmd.args.targets:
		var collections = get_tree().get_nodes_in_group(group_name)
		for c in collections:
			c.shuffle()
	return true

func cmd_move_top(cmd: Dictionary) -> bool:
	if not "from" in cmd.args:
		return false
	var from = get_tree().get_first_node_in_group(cmd.args.from)
	if "to" in cmd.args:
		var to = get_tree().get_first_node_in_group(cmd.args.to)
		print("from: ",from, "to: ",to)
		if from.get_num_objects() == 0:
			print("No objects")
			return false
		var piece: Piece = from.get_game_objects()[-1]
		print("Piece name: ",piece.name)
		board.game_object_manager.stack_objects_to_item([piece], to)
	return true
