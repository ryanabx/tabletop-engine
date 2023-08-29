class_name BoardManager
extends Node

@onready var board_scene: PackedScene = preload("res://src/scenes/game_elements/board.tscn")

var board: Board = null

const MTU: int = 1476

# Crucial base operation nodes
@onready var user_interface: UserInterface = $UserInterfaceLayer/UserInterface
@onready var camera_controller: CameraController = $CameraController
@onready var dialogs: Node = $UserInterfaceLayer/Dialogs

var config_bytes: PackedByteArray = []

var peers_ready: int = 0
signal peer_ready(id: int)

@rpc("any_peer","call_remote","reliable")
func notify_ready(id: int) -> void:
	if multiplayer.is_server():
		peer_ready.emit(id)

func _ready() -> void:
	Globals.set_shared_tabletop_manager(self)
	if multiplayer.is_server():
		make_tabletop()
	else:
		notify_ready.rpc(multiplayer.get_unique_id())

func make_tabletop():
	if multiplayer.get_peers().size() > 0:
		Utils.go_to_scene.rpc("res://src/scenes/game_elements/board_manager.tscn")
	while peers_ready != multiplayer.get_peers().size():
		var id: int = await peer_ready
		print("Peer ",id, " is ready!")
		peers_ready += 1
	load_game_config(Globals.current_game)

func remove_tabletop() -> void:
	if board != null:
		board.queue_free()
		await board.tree_exited
	return

func load_game_config(gc: GameConfig2) -> void:
	config_bytes = gc.to_bytes()

	await remove_tabletop()
	if not multiplayer.is_server():
		return
	
	var beg: int = 0
	var end: int = MTU

	while(true):
		var slice: PackedByteArray = config_bytes.slice(beg, end)
		receive_config_part.rpc(slice, end >= config_bytes.size())
		if end >= config_bytes.size():
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
	var gc: GameConfig2 = GameConfig2.new()
	gc.fill_bytes(config_bytes)
	var board_new: Board = board_scene.instantiate()
	board_new.name = gc.name
	Globals.set_current_tabletop(board_new)
	board_new.game = gc
	add_child(board_new)
	board = board_new
