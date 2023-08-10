class_name BoardSpawner
extends MultiplayerSpawner

@onready var board_scene: PackedScene = preload("res://src/scenes/game_elements/board.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_function(Callable(self, "spawn_board"))

func spawn_board(gc_d: Dictionary) -> Board:
	var gc: GameConfig = GameConfig.repack(gc_d)
	var board_new: Board = board_scene.instantiate()
	board_new.name = gc.name
	Globals.set_current_tabletop(board_new)
	board_new.game = gc
	return board_new
