# Copyright Ryanabx 2023. Tabletop Framework
class_name BoardAPI
extends RefCounted
## The API for Tabletop Framework. Establishes a connection between the user's mod and the tabletop itself.
## The script is the main launch point for any user who wishes to create a tabletop mod.


static var _board: Board = null
static var _game: TabletopGame = null

## Enumeration
enum GameObjectType {
    PIECE,
    DECK,
    HAND,
    MAX
}

## Companion constant to [enum BoardAPI.GameObjectType] that defines strings for each type.
const GAME_OBJECT_TYPE_STRING = [
    "piece", "deck", "hand", "max"
]

### Public functions, usable by modders ###

## Creates a new object on the board, and returns a pointer to that object.
## Takes a [param type] from [enum BoardAPI.GameObjectType].
## A list of modifiable GameObject properties can be found in each GameObject's reference.
static func new_object(type: GameObjectType, properties: Dictionary) -> GameObjectAPI:
    # TODO: Implement
    return null

## Finds and erases a specified GameObject by name.
## Use [param recursive] to specify whether nested game objects should
## be erased too.
## Returns [true] if the operation was successful, [false] otherwise.
static func erase_object(name: String, recursive: bool = false) -> bool:
    # TODO: Implement
    return false

## Finds a specified GameObject by name.
## Returns [null] if the GameObject cannot be found.
static func get_object(name: String) -> GameObjectAPI:
    # TODO: Implement
    return null


# Private functions, only for use by the game

static func _set_board(board: Board) -> void:
    _board = board

static func _set_game(game: TabletopGame) -> void:
    _game = game

