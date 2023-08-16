class_name BoardSpawner
extends MultiplayerSpawner


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_function(Callable(self, "spawn_board"))


