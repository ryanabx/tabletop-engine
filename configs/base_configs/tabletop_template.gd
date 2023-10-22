# tabletop_template.gd
# Copyright Ryanabx 2023
extends TabletopGame

# MUST IMPLEMENT

## Called by all players when the board spawns in. Use this to set board settings.
## NOTE: MUST be implemented by the configuration creator.
func initialize() -> void:
    pass

## Called by the server only when the board wants the game to start. Should be used to create all the initial game objects.
## NOTE: MUST be implemented by the configuration creator.
func game_start() -> void:
    pass

# OPTIONAL

## Returns the list of user actions.
## This method may be optionally overridden. By default returns an empty [Array]
func get_actions() -> Array[String]:
    var res: Array[String] = []
    return res

## Runs a specified action based off the action string, retrieved from get_actions()
## should return true if the action was successful, false otherwise.
## This method may be optionally overridden. By default returns [false]
func run_action(_action: String) -> bool:
    return false

## Determines whether a selectable object can be stacked to another selectable object.
## This method may be optionally overridden. By default returns [true]
func can_stack(_from: Selectable, _to: Selectable) -> bool:
    return true

## Determines whether a piece can be taken off a collection.
## This method may be optionally overridden. By default returns [true]
func can_take_piece_off(_collection: Collection) -> bool:
    return true

## Determines whether the selectable object [param _highlighted] can be highlighted,
## optionally given [param _selected] object.
## This method may be optionally overridden. By default returns [true]
func can_highlight(_highlighted: Selectable, _selected: Selectable) -> bool:
    return true