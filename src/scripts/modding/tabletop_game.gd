# Copyright Ryanabx 2023. Reference for the Open Tabletop API. Extend this class when making a tabletop
class_name TabletopGame
extends RefCounted

var board: Board
var settings: TabletopSettings

class TabletopSettings:
    var name: String
    var schema_version: int
    var game_version: int
    var image_directory: String
    var background_image: String

## Initializes the Tabletop Game
func _init(_board: Board) -> void:
    # NOTE: To be implemented by the configuration creator
    pass

## Called when the board wants the game to start. Should be used to create all the initial game objects
func game_start() -> void:
    # NOTE: To be implemented by the configuration creator
    pass

## Returns the list of user actions 
func get_actions() -> Array[String]:
    # NOTE: To be implemented by the configuration creator
    return []

## Runs a specified action based off the action string, retrieved from get_actions()
## should return true if the action was successful, false otherwise
func run_action(_action: String) -> bool:
    # NOTE: To be implemented by the configuration creator
    return false