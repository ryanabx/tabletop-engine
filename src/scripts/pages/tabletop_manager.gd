class_name TabletopManager
extends Node

var piece_scene: PackedScene = preload("res://src/scenes/game_elements/piece.tscn")
var base_scene: PackedScene = preload("res://src/scenes/game_elements/game_base.tscn")

var EMPTY_GAME: Dictionary = {
	"name": "Untitled",
	"version": {"major": 1, "minor": 0},
	"obf_api_version": Globals.CURRENT_API_VERSION,
	"player_settings": {
		"players": {"min": 1, "max": 2}
	},
	"board_settings": {
		"scale": {"x": 1, "y": 1},
		"bounds": {
			"position": {"x": 0, "y": 0},
			"scale": {"x": 1280, "y": 720}
		},
		"camera": {
			"position": {"x": 0, "y": 0},
			"scale": {"x": 1280},
			"rotation_degrees": 0.0
		}
	},
	"board_objects": []
}

var initialized: bool = false

# Crucial tabletop operation nodes
@onready var board: GameBoard
@onready var user_interface: UserInterface
@onready var camera_controller: Node2D

@onready var tabletop: Node = null

var game: Dictionary

func load_tabletop(gm: Dictionary) -> void:
	if tabletop != null:
		tabletop.queue_free()
	game = gm
	make_new_tabletop()
	initialize_tabletop()

func reset_tabletop() -> void:
	load_tabletop(game)

func load_tabletop_from_file(fname: String) -> void:
	var gm: Dictionary = Utils.load_json_from_file(fname)
	if gm.is_empty():
		print("There was a problem loading the game from file: ",fname)
		return
	load_tabletop(gm)

func make_new_tabletop() -> void:
	var _tt: Node = base_scene.instantiate()
	board = _tt.get_node("./GameBoard")
	user_interface = _tt.get_node("./UiLayer/UserInterface")
	camera_controller = _tt.get_node("./CameraController")
	tabletop = _tt
	add_child(_tt)

func _on_config_file_loaded(fname: String) -> void:
	load_tabletop_from_file(fname)

func _ready() -> void:
	SignalManager.config_file_opened.connect(_on_config_file_loaded)
	load_tabletop(EMPTY_GAME)

func initialize_tabletop() -> void:
	
	initialize_game()

func initialize_game() -> void:
	init_general()
	init_board()

func init_general() -> void:
	# INITIALIZE GENERAL SETTINGS
	var bord: Rect2 = Rect2(
		game.board_settings.bounds.position.x * game.board_settings.scale.x,
		game.board_settings.bounds.position.y * game.board_settings.scale.y,
		game.board_settings.bounds.scale.x * game.board_settings.scale.x,
		game.board_settings.bounds.scale.y * game.board_settings.scale.y
		)
	bord.position -= Vector2(
		game.board_settings.bounds.scale.x * game.board_settings.scale.x / 2.0,
		game.board_settings.bounds.scale.y * game.board_settings.scale.y / 2.0
		)
	board.set_border(bord)

	if "background" in game and "image_directory" in game:
		board.set_board_texture(game.background, game.image_directory)
	camera_controller.reset_camera()

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
	c.position = Vector2(object.position.x * game.board_settings.scale.x, object.position.y * game.board_settings.scale.y)

	c.force_state = object.options.force_state
	c.can_view = object.players.viewing

	for x in object.inside:
		parse_object(x, c, vars)
	
	if object.options.permanent:
		c.permanent = true
		c.base_size = Vector2(object.scale.x * game.board_settings.scale.x, object.scale.y * game.board_settings.scale.y)
	
	if "rotation_degrees" in object:
		c.rotation_degrees = object.rotation_degrees
	
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
	piece._set_scale(Vector2(object.scale.x * game.board_settings.scale.x, object.scale.y * game.board_settings.scale.y))
	piece.position = Vector2(object.position.x * game.board_settings.scale.x, object.position.y * game.board_settings.scale.y)
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
