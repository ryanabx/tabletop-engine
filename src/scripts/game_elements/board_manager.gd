class_name BoardManager
extends Node

var board: Board = null

const MTU = 1476

# Signals
signal game_load_started()
signal game_percent_loaded(pct: float)
signal game_load_finished(brd: Board)

# Crucial base operation nodes
@onready var user_interface: UserInterface = $UserInterfaceLayer/UserInterface
@onready var camera_controller: CameraController = $CameraController

var config_bytes: PackedByteArray = PackedByteArray([])

var peers_ready: int = 0
signal peer_ready(id: int)
signal server_ready()

@rpc("any_peer","call_remote","reliable")
func notify_ready(id: int) -> void:
    print("%d received ready from %d" % [multiplayer.get_unique_id(), id])
    if multiplayer.is_server():
        peer_ready.emit(id)
    elif id == 1:
        server_ready.emit()

func _ready() -> void:
    if multiplayer.is_server():
        print("Server notifying ready")
        notify_ready.rpc(1)
        make_tabletop()
    else:
        await server_ready
        print("Server is ready. Let's go!")
        print("Client notifying ready")
        notify_ready.rpc(multiplayer.get_unique_id())

func make_tabletop() -> void:
    print("Waiting for peers to be ready...")
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
    print("Loading Game Config")
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
    print("Spawning board!")
    var gc: TabletopGame = TabletopGame.import_config(config_bytes)
    var board_new: Board = load("res://src/scenes/game_elements/board.tscn").instantiate()
    board_new.game = gc
    board_new.name = gc.name
    
    add_child(board_new)
    board = board_new
