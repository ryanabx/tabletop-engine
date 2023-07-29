class_name TabletopManager
extends Node

var piece_scene: PackedScene = preload("res://src/scenes/game_elements/piece.tscn")
var base_scene: PackedScene = preload("res://src/scenes/game_elements/game_base.tscn")

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
	user_interface = _tt.get_node("./UiLayer/UserInterface")
	camera_controller = _tt.get_node("./CameraController")
	tabletop = _tt
	add_child(_tt)

func reset_tabletop() -> void:
	if tabletop != null:
		tabletop.queue_free()
		tabletop = null
	var _tt: Node = base_scene.instantiate()
	board = _tt.get_node("./GameBoard")
	user_interface = _tt.get_node("./UiLayer/UserInterface")
	camera_controller = _tt.get_node("./CameraController")
	tabletop = _tt
	add_child(_tt)

func load_config(config: Resource) -> void:
	# Load basic game stuff
	game = config
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	reset_tabletop()
	build_game()
	build_board_objects()

func build_game() -> void:
	print(game.images.keys())
	# Set up camera transform
	if "y" in game.camera.scale:
		camera_controller.set_camera_transform(
			Vector2(game.camera.position.x, game.camera.position.y) * coordinate_scale,
			Vector2(game.camera.scale.y, game.camera.scale.y) * (coordinate_scale / get_viewport().get_visible_rect().size.y),
			game.camera.rotation
		)
	elif "x" in game.camera.scale:
		camera_controller.set_camera_transform(
			Vector2(game.camera.position.x, game.camera.position.y) * coordinate_scale,
			Vector2(game.camera.scale.x, game.camera.scale.x) * (coordinate_scale / get_viewport().get_visible_rect().size.x),
			game.camera.rotation
		)
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
		for key in obj.keys():
			if key == "for" or key == "in" or typeof(obj[key]) != TYPE_STRING:
				continue
			for i in range(obj["for"].size()):
				for j in range(obj["in"][i].size()):
					var repl: String = obj["for"][i]
					var val: String = obj["in"][i][j]
					obj[key] = obj[key].replacen(repl, val)
	
	# Create objects
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
	print(Vector2(obj.scale.x, obj.scale.y) * coordinate_scale)
	print(piece._sprite.scale)
	# Collections
	if "collection" in obj:
		var coll: GameCollection = (get_tree().get_nodes_in_group(obj.collection)[0] as GameCollection)
		coll.add_game_object_to_top(piece)
		piece.position = coll.position

func new_collection(obj: Dictionary) -> void:
	var collection: GameCollection
	match obj.type:
		"hand": collection = Hand.new()
		"stack": collection = ObjectStack.new()
		_: return
	if "name" in obj:
		collection.add_to_group(obj.name)
	# Add child
	board.game_object_manager.add_child(collection)
	# Collection transforms
	collection.position = Vector2(obj.position.x, obj.position.y) * coordinate_scale if "position" in obj else Vector2.ZERO
	collection.base_size = Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE
	collection._scale = Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE
	collection.rotation_degrees = obj.rotation if "rotation" in obj else 0.0
	# Collection exclusives
	collection.permanent = obj.permanent
	collection.force_state = obj.force_state
	collection.view_perms = obj.view_perms
	
