## Programmability Reference for Open Tabletop. Copyright Ryanabx 2023
class_name BoardProgrammer
extends RefCounted

enum GameObjectTypes {
    TYPES_PIECE,
    TYPES_COLLECTION
}

var evaluator: Expression = Expression.new()
var board: Board

var actions: Dictionary = {}

var returned: Array = []

func _init(_board: Board) -> void:
    board = _board

## Runs a specified action on the board
func run_action(name: String) -> bool:
    if name not in actions:
        return false
    # var action: String = actions[name]
    # TODO: Finish this method
    return true

# ACTION COMMANDS

## Runs the given callable function on the given game object with the given arguments
func run_on_object(object_name: String, _call: String, args: Array) -> Variant:
    # Get object that is being referenced
    var object: GameObject = board.get_gobject(object_name)
    if object == null:
        return false
    # Get function that is being attempted to be called
    var callable: Callable = Callable(object, _call)
    if not callable.is_valid():
        return false
    return callable.callv(args)

## Runs the given callable function on the board
func run_on_board(_call: String, args: Array) -> Variant:
    var callable: Callable = Callable(board, _call)
    if not callable.is_valid():
        return false
    return callable.callv(args)

## Creates a game object on the board
func create_game_object(type: GameObjectTypes, config: Dictionary) -> void:
    match type:
        GameObjectTypes.TYPES_PIECE:
            board.create_piece(config)
        GameObjectTypes.TYPES_COLLECTION:
            board.create_collection(config)