class_name PieceSpawner
extends MultiplayerSpawner


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_function(Callable(self, "replicate_piece"))

func replicate_piece(piece_name: String) -> Piece:
	var piece_object: Piece = get_tree().get_first_node_in_group(piece_name)
	piece_object.queue_free()
	await piece_object.tree_exited
	return piece_object