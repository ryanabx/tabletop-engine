class_name BoardManager
extends Node

@onready var board_scene: PackedScene = preload("res://src/scenes/game_elements/board.tscn")


const MTU: int = 1476

# Crucial base operation nodes
@onready var user_interface: UserInterface = $UserInterfaceLayer/UserInterface
@onready var camera_controller: CameraController = $CameraController
@onready var dialogs: Node = $UserInterfaceLayer/Dialogs
@onready var board_spawner: BoardSpawner = $BoardSpawner

var config_bytes: PackedByteArray = []

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
	var config: Dictionary = gc.unpack_data()
	var cfg_bytes: PackedByteArray = var_to_bytes(config)
	config_bytes = cfg_bytes

	await remove_tabletop()
	if not multiplayer.is_server():
		return
	
	var beg: int = 0
	var end: int = MTU

	while(true):
		var slice: PackedByteArray = cfg_bytes.slice(beg, end)
		receive_config_part.rpc(slice, end >= cfg_bytes.size())
		if end >= cfg_bytes.size():
			spawn_board()
			break
		beg += MTU
		end += MTU
			
	
	print("host_loaded_config")
		

@rpc("authority","call_remote","reliable")
func receive_config_part(bytes: PackedByteArray, final: bool) -> void:
	config_bytes.append_array(bytes)
	if final:
		spawn_board()

func spawn_board() -> void:
	print("Spawning board")
	var gc_d: Dictionary = bytes_to_var(config_bytes)
	print("Converted bytes to var")
	var gc: GameConfig = GameConfig.repack(gc_d)
	var board_new: Board = board_scene.instantiate()
	board_new.name = gc.name
	Globals.set_current_tabletop(board_new)
	board_new.game = gc
	add_child(board_new)
