extends MultiplayerSpawner

@onready var tt_scene: PackedScene = preload("res://src/scenes/game_elements/tabletop.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_function(spawn_tabletop)

func spawn_tabletop(gc_d: Dictionary) -> Tabletop:
	var gc: GameConfig = GameConfig.repack(gc_d)
	var tt_new: Tabletop = tt_scene.instantiate()
	tt_new.name = gc.name
	Globals.set_current_tabletop(tt_new)
	tt_new.game = gc
	return tt_new