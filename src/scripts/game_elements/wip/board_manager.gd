class_name BoardManager
extends Node


# Crucial base operation nodes
@onready var user_interface: UserInterface = $UserInterfaceLayer/UserInterface
@onready var camera_controller: CameraController = $CameraController
@onready var dialogs: Node = $UserInterfaceLayer/Dialogs
@onready var board_spawner: BoardSpawner = $BoardSpawner

var current_game: String = ""

func _ready() -> void:
	Globals.set_shared_tabletop_manager(self)

func remove_tabletop() -> void:
	if Globals.get_current_tabletop() != null:
		Globals.get_current_tabletop().queue_free()
		await Globals.get_current_tabletop().tree_exited
	return

func load_game_config(gc: GameConfig) -> void:
	await remove_tabletop()
	if multiplayer.is_server():
		current_game = gc.name
		print("host_loaded_config")
		board_spawner.call_deferred("spawn",gc.unpack_data())
