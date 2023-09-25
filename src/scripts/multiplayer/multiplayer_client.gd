class_name MultiplayerClient
extends WSWebRTCClient

var rtc_mp: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var sealed := false

func _init() -> void:
    connected.connect(self._connected)
    disconnected.connect(self._disconnected)

    offer_received.connect(self._offer_received)
    answer_received.connect(self._answer_received)
    candidate_received.connect(self._candidate_received)

    lobby_joined.connect(self._lobby_joined)
    lobby_sealed.connect(self._lobby_sealed)
    peer_connected.connect(self._peer_connected)
    peer_disconnected.connect(self._peer_disconnected)


func start(url: String, _lobby: String = "", _mesh: bool = true) -> void:
    stop()
    sealed = false
    self.mesh = _mesh
    self.lobby = _lobby
    connect_to_url(url)


func stop() -> void:
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    rtc_mp.close()
    close()


func _create_peer(id: int) -> WebRTCPeerConnection:
    var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
    peer.initialize(Global.ICE_SERVERS)
    peer.session_description_created.connect(self._offer_created.bind(id))
    peer.ice_candidate_created.connect(self._new_ice_candidate.bind(id))
    rtc_mp.add_peer(peer, id)
    if id < rtc_mp.get_unique_id(): # So lobby creator never creates offers.
        peer.create_offer()
    return peer


func _new_ice_candidate(mid_name: String, index_name: int, sdp_name: String, id: int) -> void:
    send_candidate(id, mid_name, index_name, sdp_name)


func _offer_created(type: String, data: String, id: int) -> void:
    if not rtc_mp.has_peer(id):
        return
    print("created", type)
    rtc_mp.get_peer(id).connection.set_local_description(type, data)
    if type == "offer": send_offer(id, data)
    else: send_answer(id, data)


func _connected(id: int, use_mesh: bool) -> void:
    print("Connected %d, mesh: %s" % [id, use_mesh])
    if use_mesh:
        rtc_mp.create_mesh(id)
    elif id == 1:
        rtc_mp.create_server()
    else:
        rtc_mp.create_client(id)
    multiplayer.multiplayer_peer = rtc_mp


func _lobby_joined(_lobby: String) -> void:
    self.lobby = _lobby


func _lobby_sealed() -> void:
    sealed = true


func _disconnected() -> void:
    print("Disconnected: %d: %s" % [code, reason])
    if not sealed:
        stop() # Unexpected disconnect


func _peer_connected(id: int) -> void:
    print("Peer connected %d" % id)
    _create_peer(id)


func _peer_disconnected(id: int) -> void:
    if rtc_mp.has_peer(id): rtc_mp.remove_peer(id)


func _offer_received(id: int, offer: String) -> void:
    print("Got offer: %d" % id)
    if rtc_mp.has_peer(id):
        rtc_mp.get_peer(id).connection.set_remote_description("offer", offer)


func _answer_received(id: int, answer: String) -> void:
    print("Got answer: %d" % id)
    if rtc_mp.has_peer(id):
        rtc_mp.get_peer(id).connection.set_remote_description("answer", answer)


func _candidate_received(id: int, mid: String, index: int, sdp: String) -> void:
    if rtc_mp.has_peer(id):
        rtc_mp.get_peer(id).connection.add_ice_candidate(mid, index, sdp)
