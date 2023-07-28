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

func _ready() -> void:
	var _tt: Node = base_scene.instantiate()
	board = _tt.get_node("./GameBoard")
	user_interface = _tt.get_node("./UiLayer/UserInterface")
	camera_controller = _tt.get_node("./CameraController")
	tabletop = _tt
	add_child(_tt)

func set_game(_g: GameConfig) -> void:
	print("Freeing the old tabletop")
	# Free the old tabletop
	tabletop.free()
	# Set the new game
	print("Setting the new game")
	game = _g
	# Make new tabletop
	print("Making the new tabletop")
	var _tt: Node = base_scene.instantiate()
	board = _tt.get_node("./GameBoard")
	user_interface = _tt.get_node("./UiLayer/UserInterface")
	camera_controller = _tt.get_node("./CameraController")
	tabletop = _tt
	add_child(_tt)
	print("Basic Configuration Stuff")
	# Basic Configuration Stuff
	board.set_border(game.board_settings.bounds)
	if game.background_image != -1:
		board.set_board_texture(game.textures[game.background_image])
	camera_controller.set_camera_transform(game.board_settings.camera)
	print("Reset the board")
	# Reset the board
	reset_board()

func reset_board() -> void:
	for obj in game.board_objects:
		if obj is GameConfig.CollectionResource:
			match (obj as GameConfig.CollectionResource).behavior:
				"stack": instantiate_collection(ObjectStack.new(), obj)
				"hand": instantiate_collection(Hand.new(), obj)
				_: pass
		elif obj is GameConfig.PieceResource:
			instantiate_piece(piece_scene.instantiate(), obj)

func instantiate_piece(pc: Piece, obj: GameConfig.PieceResource) -> void:
	pc.position = obj.transform.get_origin()
	pc.rotation = obj.transform.get_rotation()
	pc.face_up = obj.face_up
	pc._obj_images = [obj.image_up, obj.image_down]
	pc.update_texture()
	pc._set_scale(obj.transform.get_scale())
	board.game_object_manager.add_child(pc)

func instantiate_collection(coll: GameCollection, obj: GameConfig.CollectionResource) -> void:
	coll.position = obj.transform.get_origin()
	coll.rotation = obj.transform.get_rotation()
	coll._scale = obj.transform.get_scale()
	coll.permanent = obj.permanent
	coll.force_state = obj.force_state
	coll.view_perms = obj.view_perms
	board.game_object_manager.add_child(coll)
	for pc in obj.inside:
		if pc is GameConfig.PieceResource:
			var piece: Piece = piece_scene.instantiate()
			coll.add_game_object_to_top(piece)
			instantiate_piece(piece, pc)