extends Node

var _player_id: int = 0

const VERSION_NUMBER: String = "0.0.1"

const OUTLINE_THICKNESS: float = 6.0
const THICKNESS_RATIO: float = 0.8


func set_player_id(id: int) -> void:
	_player_id = id

func get_player_id() -> int:
	return _player_id
