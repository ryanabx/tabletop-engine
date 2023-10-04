extends MarginContainer

@onready var client := MultiplayerClient.new()
@onready var room := $VBoxContainer/Connect/RoomSecret
@onready var mesh := $VBoxContainer/Connect/Mesh
@onready var console := $VBoxContainer/Console

func _ready() -> void:
    add_child(client)
    client.lobby_joined.connect(self._lobby_joined)
    client.lobby_sealed.connect(self._lobby_sealed)
    client.connected.connect(self._connected)
    client.disconnected.connect(self._disconnected)

    multiplayer.connected_to_server.connect(self._mp_server_connected)
    multiplayer.connection_failed.connect(self._mp_server_disconnect)
    multiplayer.server_disconnected.connect(self._mp_server_disconnect)
    multiplayer.peer_connected.connect(self._mp_peer_connected)
    multiplayer.peer_disconnected.connect(self._mp_peer_disconnected)

func _process(_delta: float) -> void:
    %Start.disabled = not _is_local()
    %Stop.disabled = _is_local()
    %Peers.disabled = _is_local()
    %Seal.disabled = _is_local() or not multiplayer.is_server() or multiplayer.get_peers().is_empty()
    %Ping.disabled = _is_local()

func _is_local() -> bool:
    return multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer

@rpc("any_peer", "call_local")
func ping(argument: float) -> void:
    _log("[Multiplayer] Ping from peer %d: arg: %s" % [multiplayer.get_remote_sender_id(), argument])

func _mp_server_connected() -> void:
    _log("[Multiplayer] Server connected (I am %d)" % client.rtc_mp.get_unique_id())

func _mp_server_disconnect() -> void:
    _log("[Multiplayer] Server disconnected (I am %d)" % client.rtc_mp.get_unique_id())

func _mp_peer_connected(id: int) -> void:
    _log("[Multiplayer] Peer %d connected" % id)
    if multiplayer.is_server():
        _log("[Server] Press 'Seal' to seal the lobby before selecting a configuration.")

func _mp_peer_disconnected(id: int) -> void:
    _log("[Multiplayer] Peer %d disconnected" % id)

func _connected(id: int, _mesh: bool) -> void:
    _log("[Signaling] Server connected with ID: %d" % id)

func _disconnected() -> void:
    _log("[Signaling] Server disconnected: %d - %s" % [client.code, client.reason])

func _lobby_joined(lobby: String) -> void:
    _log("[Signaling] Joined lobby %s" % lobby)

func _lobby_sealed() -> void:
    _log("[Signaling] Lobby has been sealed. You can now select a configuration and click 'Ready' to start the game!")

func _log(msg: Variant) -> void:
    print(msg)
    console.text += str(msg) + "\n"

func _on_peers_pressed() -> void:
    _log(multiplayer.get_peers())

func _on_ping_pressed() -> void:
    ping.rpc(randf())

func _on_seal_pressed() -> void:
    client.seal_lobby()

func _on_start_pressed() -> void:
    client.start(GlobalBridge.global.GetUserSetting("signaling_server"), room.text, mesh.button_pressed)
    _log("Connecting to signaling server... This may take a minute...")

func _on_stop_pressed() -> void:
    client.stop()