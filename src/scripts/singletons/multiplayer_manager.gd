extends Node



func create_client(id: int) -> void:
	var peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	peer.create_client(id)
	multiplayer.multiplayer_peer = peer

func create_server() -> void:
	var peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	peer.create_server()
	multiplayer.multiplayer_peer = peer