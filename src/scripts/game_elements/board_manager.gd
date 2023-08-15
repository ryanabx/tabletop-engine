class_name BoardManager
extends Node


# Crucial base operation nodes
@onready var user_interface: UserInterface = $UserInterfaceLayer/UserInterface
@onready var camera_controller: CameraController = $CameraController
@onready var dialogs: Node = $UserInterfaceLayer/Dialogs
@onready var board_spawner: BoardSpawner = $BoardSpawner

var current_game: String = ""

var board: Board = null

func _ready() -> void:
	Globals.set_shared_tabletop_manager(self)
	SignalManager.load_game_config.connect(load_game_config)

func remove_tabletop() -> void:
	if board != null:
		board.queue_free()
		await board.tree_exited
	return

func load_game_config(gc: GameConfig) -> void:
	await remove_tabletop()
	if multiplayer.is_server():
		current_game = gc.name
		print("host_loaded_config")
		board_spawner.call_deferred("spawn",gc.unpack_data())
