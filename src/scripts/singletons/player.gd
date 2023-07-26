# PLAYER SINGLETON - Manages the player number and other player information
extends Node

# CURRENT PLAYER NUMBER

var _id: int = 0 # TESTING PURPOSES

func set_id(id: int) -> void:
    _id = id

func get_id() -> int:
    return _id