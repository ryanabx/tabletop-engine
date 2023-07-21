class_name Tabletop
extends Node

const FNAME_CONF = "conf.json"
const FNAME_OBJECTS = "objects.json"
const FNAME_PLAYER = "player.json"
const FNAME_BOARD = "board.json"
const FNAME_ACTIONS = "actions.json"

var _name: String = ""

@export var player_id: int = 0
@onready var game_board: GameBoard = $GameBoard
@onready var user_interface: UserInterface = $UiLayer/UserInterface
@onready var ui_layer: CanvasLayer = $UiLayer
@onready var camera_controller: Node2D = $CameraController

var _game_object_scene = preload("res://src/scenes/game_objects/game_object.tscn")
var _stack_scene = preload("res://src/scenes/game_objects/stack.tscn")

func get_camera_controller() -> Node2D:
	return camera_controller

func get_user_interface() -> UserInterface:
	return user_interface

func get_board() -> GameBoard:
	return game_board

func _ready() -> void:
	# Test code
	Globals.set_player_id(1)
	var filename: String = "C:/Users/ryanb/source/repos/open-boardgame-framework/data/reference_games/UNO/"
	load_game_from_folder(filename)
	pass

func _set_game_name(_n: String) -> void:
	_name = _n

func load_json_from_file(fname: String) -> Dictionary:
	if FileAccess.file_exists(fname):
		var data_file = FileAccess.open(fname, FileAccess.READ)
		var parsed_result = JSON.parse_string(data_file.get_as_text())
		if parsed_result is Dictionary:
			return parsed_result
		else:
			print("Error parsing file")
			return {}
	else:
		print("File not found: ",fname)
		return {}

func load_game_from_folder(folder_name: String) -> void:
	var conf = load_json_from_file(folder_name + FNAME_CONF)
	var objects = load_json_from_file(folder_name + FNAME_OBJECTS)
	var player = load_json_from_file(folder_name + FNAME_PLAYER)
	var board = load_json_from_file(folder_name + FNAME_BOARD)
	var actions = load_json_from_file(folder_name + FNAME_ACTIONS)
	load_game(conf, objects, player, board, actions)


func load_game(conf: Dictionary, objects: Dictionary, player: Dictionary, board: Dictionary, actions: Dictionary) -> void:
	print("Setting up config...")
	_set_up_config(conf)
	print("Setting up board...")
	_set_up_board(board, objects)
	_set_up_actions(actions, board, objects)

func _set_up_actions(actions: Dictionary, board: Dictionary, objects: Dictionary) -> void:
	pass

func _set_up_config(conf: Dictionary) -> void:
	_set_game_name(conf.name)
	user_interface.set_game_name(conf.name)
	camera_controller.set_bg(Utils.load_texture_from_string(conf.background, conf.image_dir))

func _set_up_board(board: Dictionary, objects: Dictionary) -> void:
	for item in board.board:
		_parse_item(item, objects, [], null)
		# print("Added new child")

func _parse_item(item: Dictionary, objects: Dictionary, config_vars: Array, collection: GameCollection) -> void:
	# print(item)
	match item.type:
		"card":
			_new_card(item, objects, config_vars, collection)
		"stack":
			_new_stack(item, objects, config_vars, collection)
		"foreach":
			_new_foreach(item, objects, config_vars, collection)
		"repeat":
			_new_repeat(item, objects, config_vars, collection)
		"hand":
			_new_hand(item, objects, config_vars, collection)
		_:
			_new_generic_object(item, objects, config_vars, collection)

func _new_foreach(item: Dictionary, objects: Dictionary, config_vars: Array, collection: GameCollection) -> void:
	# Define foreach traits
	var fr: String = item.foreach
	var n: Array = item.in
	var d: Array = item.do
	
	var _var: ConfigVariable = ConfigVariable.new(fr, n)
	var _confvars: Array = config_vars.duplicate(false)
	_confvars.append(_var)
	
	for i in range(n.size()):
		_var.set_ind(i)
		for _d in d:
			_parse_item(_d, objects, _confvars, collection)

func _new_repeat(item: Dictionary, objects: Dictionary, config_vars: Array, collection: GameCollection) -> void:
	# Define repeat traits
	var amt: int = item.amount
	var d: Array = item.do
	
	for i in range(amt):
		for _d in d:
			_parse_item(_d, objects, config_vars, collection)

func _new_hand(item: Dictionary, _objects: Dictionary, _config_vars: Array, _collection: GameCollection) -> void:
	# Define hand traits
	var pl: int = item.player
	var location: Vector2 = Vector2(item.location[0], item.location[1])
	var size: Vector2 = Vector2(item.size[0], item.size[1])
	
	# Create new hand and add it to the board
	var _hand = Hand.new(pl, location, size)
	game_board.get_game_object_manager().add_child(_hand)

func _new_generic_object(_item: Dictionary, _objects: Dictionary, _config_vars: Array, _collection: GameCollection) -> void:
	pass

func _new_stack(item: Dictionary, objects: Dictionary, config_vars: Array, collection: GameCollection) -> void:
	if collection:
		print("Config Error: Attempted to stack a stack")
	# Define stack traits
	var location: Vector2 = Vector2(item.location[0], item.location[1])
	var inside: Array = item.inside
	
	# Create stack and add it to the board
	var _stack = _stack_scene.instantiate()
	game_board.get_game_object_manager().add_child(_stack)
	# Set stack location
	_stack.position = location
	
	for _ins in inside:
		_parse_item(_ins, objects, config_vars, _stack)
	
	_stack.get_game_objects()[-1].position = _stack.position

func _new_card(item: Dictionary, objects: Dictionary, config_vars: Array, collection: GameCollection) -> void:
	# Define card traits
	var type: String = item.type
	var groups: Array = item.groups
	var objref_name: String = item.objref_name
	var face_up: bool = item.face_up
	var location: Vector2 = Vector2(item.location[0], item.location[1])
	var scale: float = item.scale
	# Card trait config variable substitution
	for _var in config_vars:
		for i in range(groups.size()):
			groups[i] = groups[i].replace(_var.get_repl(), _var.get_val())
		objref_name = objref_name.replace(_var.get_repl(), _var.get_val())
	# Define objref traits
	var images: Array = objects.objects[objref_name].image
	# Objref trait config variable substitution
	for _var in config_vars:
		for i in range(images.size()):
			images[i] = images[i].replace(_var.get_repl(), _var.get_val())
	# Create a new card and add it to the board
	var _card = _game_object_scene.instantiate()
	game_board.get_game_object_manager().add_child(_card)
	# Set config variables
	_card._obj_type = _card._type_from_string(type)
	_card._obj_images = Utils.load_images_into_array(images, objects.image_dir)
	_card._side = GameObject.SIDE.UP if face_up else GameObject.SIDE.DOWN
	if _card._side == GameObject.SIDE.UP:
		_card._sprite.set_texture(_card._obj_images[0])
		# print("Set texture")
	else:
		_card._sprite.set_texture(_card._obj_images[1])
		# print("Set texture face down")
	_card._set_scale(Vector2(scale, scale), true)
	_card.position = location
	for _group in groups:
		_card.add_to_group(_group)
	if collection:
		_card.select()
		_card.put_in_collection(collection)
		collection.add_game_object_to_top(_card)

# TODO: PARSE THE NEW BOARD.JSON FILE WITH LOOPS AND SHIT


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
