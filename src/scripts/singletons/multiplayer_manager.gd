extends Node



func create_client(id: int) -> void:
	var peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	peer.create_client(id)

func create_server() -> void:
	var peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	peer.create_server()