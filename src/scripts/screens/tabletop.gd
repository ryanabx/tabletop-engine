class_name Tabletop
extends Node

const FNAME_CONF = "conf.json"
const FNAME_OBJECTS = "objects.json"
const FNAME_PLAYER = "player.json"
const FNAME_BOARD = "board.json"
const FNAME_ACTIONS = "actions.json"


@export var player_id: int = 0

func _ready() -> void:
    

func load_json_from_file(fname: String) -> Dictionary:
    if FileAccess.file_exists(fname):
        var data_file = FileAccess.open(fname, FileAccess.READ)
        var parsed_result = JSON.parse_string(data_file.get_as_text())

        if parsed_result is Dictionary:
            return parsed_result
        else:
            print("wtf")
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
    print("HI")