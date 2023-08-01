class_name Tabletop
extends Node

@onready var piece_scene: PackedScene = preload("res://src/scenes/game_elements/spawnables/piece.tscn")
@onready var stack_scene: PackedScene = preload("res://src/scenes/game_elements/spawnables/stack.tscn")
@onready var hand_scene: PackedScene = preload("res://src/scenes/game_elements/spawnables/hand.tscn")


var game: GameConfig
var coordinate_scale: Vector2

var piece_counter: int = 0

@onready var board: GameBoard = $GameBoard

func _ready() -> void:
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	set_up_board_props()
	edit_menu_bar()
	build_board_objects()

func edit_menu_bar():
	var menu_bar: MenuBar = Globals.get_shared_tabletop_manager().user_interface.menu_bar
	menu_bar.new_game_loaded(game.player.max, game.actions)

func set_up_board_props() -> void:
	if "border" in game.board:
		board.set_border(
			Rect2(
				(Vector2(game.board.border.position.x, game.board.border.position.y) - Vector2(game.board.border.scale.x, game.board.border.scale.y) / 2) * coordinate_scale,
				Vector2(game.board.border.scale.x, game.board.border.scale.y) * coordinate_scale
			)
		)
	# Set up game bg
	if "background_image" in game.board and game.board.background_image != "":
		board.board_texture_string = game.board.background_image
		board.set_board_texture()

func _process(_delta: float) -> void:
	Globals.get_shared_tabletop_manager().camera_controller.camera.position = Globals.get_shared_tabletop_manager().camera_controller.camera.position.clamp(board.get_border().position, board.get_border().end)

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
		piece_counter += 1

func new_piece(obj: Dictionary) -> void:
	var piece: Piece = piece_scene.instantiate()
	if "name" in obj:
		piece.add_to_group(obj.name)
		piece.set_name(str(obj.name,piece_counter))
	else:
		piece.set_name(str("PIECE",piece_counter))
	# Add child
	board.game_object_manager.add_child(piece)
	# Piece transforms
	piece.position = Vector2(obj.position.x, obj.position.y) * coordinate_scale if "position" in obj else Vector2.ZERO
	piece.rotation_degrees = obj.rotation if "rotation" in obj else 0.0
	# Piece exclusives
	piece.image_up_string = obj.image_up
	piece.image_down_string = obj.image_down
	piece.set_piece_texture()
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
	else:
		collection.set_name(str("Collection",piece_counter))
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

