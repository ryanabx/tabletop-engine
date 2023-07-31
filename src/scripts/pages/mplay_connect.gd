extends Control

var peers: Dictionary = {}

@onready var player_dropdown: MenuButton = $Margins/Columns/ServerColumn/PlayerDropdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	for i in range(Globals.DEFAULT_MAX_PLAYERS):
		player_dropdown.get_popup().add_item(str("Player ",i+1))
	player_dropdown.get_popup().index_pressed.connect(_set_player)

func _set_player(index: int) -> void:
	player_dropdown.get_popup().set_item_disabled(Player.get_id(), false)
	Player.set_id(index)
	player_dropdown.get_popup().set_item_disabled(Player.get_id(), true)


func _on_peer_connected(id: int) -> void:
	peers[id] = $Margins/Columns/ServerColumn/PeerList.add_item(str("Peer: ",id))

func _on_peer_disconnected(id: int) -> void:
	$Margins/Columns/ServerColumn/PeerList.remove_item(peers[id])
	peers.erase(id)

func _on_create_server_pressed() -> void:
	# Start as server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(Globals.DEFAULT_PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	print("Server created successfully!")

func _on_connect_server_pressed() -> void:
	# Start as client.
	var txt : String = $Margins/Columns/ServerColumn/ConnectRow/IP.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, Globals.DEFAULT_PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	print("Connected successfully!")