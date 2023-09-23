class_name BoardManager
extends Node

var board: Board = null

const MTU = 1476

# Signals

signal game_load_finished(board: Board)


# Crucial base operation nodes
@onready var user_interface: UserInterface = $UserInterfaceLayer/UserInterface
@onready var camera_controller: CameraController = $CameraController

var config_bytes: PackedByteArray = PackedByteArray([])

var peers_ready: int = 0
signal peer_ready(id: int)
signal server_ready()

@rpc("any_peer","call_remote","reliable")
func notify_ready(id: int) -> void:
    if multiplayer.is_server():
        peer_ready.emit(id)
    elif id == 1:
        server_ready.emit()

func _ready() -> void:
    Global.set_shared_tabletop_manager(self)
    if multiplayer.is_server():
        notify_ready.rpc(1)
        make_tabletop()
    else:
        await server_ready
        notify_ready.rpc(multiplayer.get_unique_id())

func make_tabletop() -> void:
    while peers_ready != multiplayer.get_peers().size():
        var id: int = await peer_ready
        print("Peer ",id, " is ready!")
        peers_ready += 1
    load_game_config()

func remove_tabletop() -> void:
    if board != null:
        board.queue_free()
        await board.tree_exited
    return

func load_game_config() -> void:
    await remove_tabletop()
    if not multiplayer.is_server():
        return
    
    config_bytes = Global.load_this_game
    
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

@rpc("authority","call_remote","reliable")
func receive_config_part(bytes: PackedByteArray, final: bool) -> void:
    config_bytes.append_array(bytes)
    if final:
        spawn_board()

func spawn_board() -> void:
    var gc: TabletopGame = TabletopGame.import_config(config_bytes)
    var board_new: Board = load("res://src/scenes/game_elements/board.tscn").instantiate()
    board_new.game = gc
    board_new.name = gc.export_settings().name
    Global.set_current_tabletop(board_new)
    
    add_child(board_new)
    board = board_new
