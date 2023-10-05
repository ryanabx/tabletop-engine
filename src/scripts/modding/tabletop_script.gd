class_name TabletopScript
extends RefCounted

var board: Node2D

# Must implement

## Called by all players when the board spawns in. Use this to set board settings.
## NOTE: MUST be implemented by the configuration creator.
func initialize() -> void:
    assert(false, "Not Implemented! Override this function!")

## Called when the board wants the game to start. Should be used to create all the initial game objects.
## NOTE: MUST be implemented by the configuration creator.
func game_start() -> void:
    assert(false, "Not Implemented! Override this function!")

# Optional functions

## Returns the list of user actions.
## This method may be optionally overridden. By default returns an empty [Array]
func get_actions() -> PackedStringArray:
    print("Default behavior. Function not implemented.")
    return PackedStringArray()

## Runs a specified action based off the action string, retrieved from get_actions()
## should return true if the action was successful, false otherwise.
## This method may be optionally overridden. By default returns [false]
func run_action(action: String) -> bool:
    print("Default behavior. Function not implemented.")
    return false

## Determines whether a selectable object can be stacked to another selectable object.
## This method may be optionally overridden. By default returns [true]
func can_stack(from: Node2D, to: Node2D) -> bool:
    print("Default behavior. Function not implemented.")
    return true

## Determines whether a piece can be taken off a collection.
## This method may be optionally overridden. By default returns [true]
func can_take_piece_off(collection: Node2D) -> bool:
    print("Default behavior. Function not implemented.")
    return true

## Determines whether the selectable object [param _highlighted] can be highlighted,
## optionally given [param _selected] object.
## This method may be optionally overridden. By default returns [true]
func can_highlight(highlighted: Node2D, selected: Node2D) -> bool:
    print("Default behavior. Function not implemented.")
    return true