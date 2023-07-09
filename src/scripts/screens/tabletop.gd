class_name Tabletop
extends Node

const FNAME_CONF = "conf.json"
const FNAME_OBJECTS = "objects.json"
const FNAME_PLAYER = "player.json"
const FNAME_BOARD = "board.json"
const FNAME_ACTIONS = "actions.json"


@export var player_id: int = 0
@onready var game_board: GameBoard = $GameBoard

var _game_object_scene = preload("res://src/scenes/game_objects/game_object.tscn")

func _ready() -> void:
	# Test code
	var filename: String = "C:/Users/ryanb/source/repos/open-boardgame-framework/data/reference_games/UNO/"
	load_game_from_folder(filename)
	pass

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
	print("Setting up board...")
	_set_up_board(board, objects)

func _set_up_board(board: Dictionary, objects: Dictionary) -> void:
	for item in board.board:
		print(item)
		match item.type:
			"card":
				_new_card(item, objects)
			"stack":
				_new_stack(item)
			_:
				_new_generic_object(item)
		print("Added new child")

func _new_generic_object(item: Dictionary) -> void:
	pass

func _new_card(item: Dictionary, objects: Dictionary) -> void:
	var _new_card = _game_object_scene.instantiate()
	var _objref = objects.objects[item.objref_name]
	print(_objref)
	game_board.get_game_object_manager().add_child(_new_card)
	_new_card.initialize_object(item, _objref, objects.image_dir)

func _new_stack(item: Dictionary) -> void:
	pass
