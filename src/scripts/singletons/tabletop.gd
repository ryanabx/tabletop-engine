# TABLETOP SINGLETON - Contains all the data about the current tabletop session
extends Node

var piece_scene: PackedScene = preload("res://src/scenes/game_objects/piece.tscn")

var EMPTY_GAME: Dictionary = {
	"name": "Untitled",
	"version": [0,0,1],
	"obf_api_version": Globals.CURRENT_API_VERSION,
	"board_settings": {
		"scale_x": 1,
		"scale_y": 1
	},
	"board_objects": []
}

# Crucial tabletop operation nodes
@onready var board: GameBoard = $/root/Base/GameBoard
@onready var user_interface: UserInterface = $/root/Base/UiLayer/UserInterface
@onready var camera_controller: Node2D = $/root/Base/CameraController

var game: Dictionary = EMPTY_GAME # Empty game

func reset_tabletop() -> void:
	game = EMPTY_GAME
	board.reset_board()
	# TODO: Continue implementing this

func _on_config_file_loaded(fname: String) -> void:
	reset_tabletop()
	load_game_from_file(fname)

func _ready() -> void:
	SignalManager.config_file_opened.connect(_on_config_file_loaded)
	SignalManager.reset_tabletop.connect(reset_tabletop)

func load_game_from_file(fname: String) -> void:
	game = Utils.load_json_from_file(fname)
	if game.is_empty():
		print("There was a problem loading the game from file: ",fname)
	# If the game loaded well, attempt to initialize the game
	initialize_game()

func initialize_game() -> void:
	init_general()
	init_board()

func init_general() -> void:
	# INITIALIZE GENERAL SETTINGS
	camera_controller.set_background_from_file(game.background, game.image_directory)
	board.set_border(Rect2(
		game.board_settings.bounds[0] * game.board_settings.scale_x,
		game.board_settings.bounds[1] * game.board_settings.scale_y,
		game.board_settings.bounds[2] * game.board_settings.scale_x,
		game.board_settings.bounds[3] * game.board_settings.scale_y
		))
	pass

func init_board() -> void:
	# INITIALIZE BOARD
	for object in game.board_objects:
		parse_object(object, null, [])

func parse_object(object: Dictionary, collection: GameCollection, vars: Array) -> void:
	match object.type:
		# FUNCTIONAL TYPES
		"foreach": new_foreach(object, collection, vars)
		"repeat": new_repeat(object, collection, vars)
		# OBJECT TYPES
		"piece":
			new_piece(object, collection, vars)
		"collection": new_collection(object, collection, vars)
		_: print("Invalid type: ", object.type)

func new_foreach(object: Dictionary, collection: GameCollection, vars: Array) -> void:
	print("NEW FOREACH")
	var confvar = ConfigVariable.new(object.foreach, object.from)
	var vars_new = vars.duplicate(false)
	vars_new.append(confvar)
	for i in range(object.from.size()):
		confvar.set_ind(i)
		for x in object.do:
			parse_object(x, collection, vars_new)

func new_repeat(object: Dictionary, collection: GameCollection, vars: Array) -> void:
	print("NEW REPEAT")
	for i in range(object.amount):
		for x in object.do:
			parse_object(x, collection, vars)

func new_collection(object: Dictionary, collection: GameCollection, vars: Array) -> void:
	print("NEW COLLECTION")
	if collection:
		print("Config Error: Attempted to put collection inside collection")
		return
	# Create collection and add it to the board
	var c: GameCollection = null
	match object.options.behavior:
		"stack": c = ObjectStack.new()
		"hand": c = Hand.new()
		_: c = ObjectStack.new()
	board.game_object_manager.add_child(c)
	c.position = Vector2(object.location[0] * game.board_settings.scale_x, object.location[1] * game.board_settings.scale_y)

	for x in object.inside:
		parse_object(x, c, vars)
	
	if object.options.permanent:
		c.permanent = true
		c.base_size = Vector2(object.base_size[0] * game.board_settings.scale_x, object.base_size[1] * game.board_settings.scale_y)
	
	if c.get_num_objects() != 0:
		c.get_game_objects()[-1].position = c.position

func new_piece(object: Dictionary, collection: GameCollection, vars: Array) -> void:
	# Piece trait config variable substitution
	var p_type: String = object.piece_type
	for cvar in vars:
		p_type = p_type.replacen(cvar.get_repl(), cvar.get_val())
	# Create piece and add it to board
	var piece: Piece = piece_scene.instantiate()
	board.game_object_manager.add_child(piece)
	# Set piece variables
	piece._obj_images = Utils.load_images_into_array(game.piece_types[p_type].image, game.image_directory)
	piece.set_side(object.face_up)
	piece._set_scale(Vector2(object.scale[0] * game.board_settings.scale_x, object.scale[1] * game.board_settings.scale_y))
	piece.position = Vector2(object.location[0] * game.board_settings.scale_x, object.location[1] * game.board_settings.scale_y)
	if collection:
		collection.add_game_object_to_top(piece)

class ConfigVariable:
	var _repl: String
	var _vals: Array
	var _index: int = 0
	
	func _init(repl: String, vals: Array) -> void:
		_repl = repl
		_vals = vals
	
	func get_repl() -> String:
		return _repl
	
	func set_ind(ind: int) -> void:
		_index = ind
	
	func get_val() -> String:
		return _vals[_index]
