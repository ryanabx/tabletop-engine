extends Node

const BUFFER_SIZE: int = 1280000

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _process(_delta: float) -> void:
	if multiplayer.multiplayer_peer is WebSocketMultiplayerPeer:
		multiplayer.poll()

## Creates a multiplayer server
func create_server(port: int) -> bool:
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	peer.inbound_buffer_size = BUFFER_SIZE
	peer.outbound_buffer_size = BUFFER_SIZE
	var chn: int = peer.create_server(port)
	print("Chn returned ",chn)
	multiplayer.multiplayer_peer = peer
	return true

## Creates a multiplayer client
func create_client(port: int, address: String = "127.0.0.1") -> bool:
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	peer.inbound_buffer_size = BUFFER_SIZE
	peer.outbound_buffer_size = BUFFER_SIZE
	var chn: int = peer.create_client(str("ws://",address,":",port))
	print("Chn returned ",chn)
	multiplayer.multiplayer_peer = peer
	return true

# SIGNAL FUNCTIONS

func _on_peer_connected(id: int) -> void:
	print("Peer ",id, " connected.")

func _on_peer_disconnected(id: int) -> void:
	print("Peer ",id," disconnected.")