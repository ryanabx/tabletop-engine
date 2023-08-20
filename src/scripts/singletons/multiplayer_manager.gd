extends Node

func _process(_delta: float) -> void:
	if multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
		multiplayer.poll()

func create_client(id: int) -> void:
	var peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	peer.create_client(id)
	multiplayer.multiplayer_peer = peer

func create_server() -> void:
	var peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	peer.create_server()
	multiplayer.multiplayer_peer = peer