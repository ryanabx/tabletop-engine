# Copyright Ryanabx 2023. Tabletop Framework
class_name BoardAPI
extends RefCounted
## The API for Tabletop Framework. Establishes a connection between the user's mod and the tabletop itself.
## The script is the main launch point for any user who wishes to create a tabletop mod.

# Private variables. Only for use by the internals

static var _board: Board = null
static var _game: TabletopGame = null

## Enumeration of the types that a GameObject can be.
## [member BoardAPI.GameObjectType.MAX] defines the end of the enum, and can't be used
## to instantiate a GameObject.
enum GameObjectType {
    PIECE,
    DECK,
    HAND,
    MAX
}

## Companion constant to [enum BoardAPI.GameObjectType] that defines strings for each type.
const GAME_OBJECT_TYPE_STRING = [
    "piece", "deck", "hand"
]

### Public functions, usable by modders ###

## Creates a new object on the board, and returns a pointer to that object.
## Takes a [param type] from [enum BoardAPI.GameObjectType].
## A list of modifiable GameObject properties can be found in each GameObject's reference.
static func new_object(type: GameObjectType, properties: Dictionary) -> GameObjectAPI:
    return _wrap_game_object(_board.new_game_object(type, properties))

## Finds and erases a specified GameObject by name.
## Use [param recursive] to specify whether nested game objects should
## be erased too.
## Returns [true] if the operation was successful, [false] otherwise.
static func erase_object(name: String, recursive: bool = false) -> bool:
    var obj: GameObjectAPI = get_object(name)
    if obj == null:
        return false
    obj.erase(recursive)
    return true

## Finds a specified GameObject by name.
## Returns [null] if the GameObject cannot be found.
static func get_object(name: String) -> GameObjectAPI:
    return _wrap_game_object(_board.get_gobject(name))


# Private functions, only for use by the internals

static func _wrap_game_object(obj: GameObject) -> GameObjectAPI:
    if obj == null:
        return null
    match obj.object_type:
        GameObjectType.PIECE:
            return PieceAPI.new(obj)
        GameObjectType.DECK:
            return DeckAPI.new(obj)
        GameObjectType.HAND:
            return HandAPI.new(obj)
    return GameObjectAPI.new(obj)

static func _set_board(board: Board) -> void:
    _board = board

static func _set_game(game: TabletopGame) -> void:
    _game = game
