extends Window

var connection: WebRTCPeerConnection

var packet: Dictionary = {}

func _on_close_requested() -> void:
	hide()

@onready var client_offer: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer2/ClientOffer
@onready var server_offer: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/ServerOffer

func _sdp_created(type: String, sdp: String) -> void:
	packet.sdp = {"type": type, "sdp": sdp}
	connection.set_local_description(type, sdp)
	get_tree().create_timer(1.0).timeout.connect(update_text_packet)

func _ice_created(media: String, index: int, _name: String) -> void:
	var ice_candidate: Dictionary = {
		"media": media, "index": index, "name": _name
	}
	if "ice_candidates" not in packet:
		packet.ice_candidates = []
	packet.ice_candidates.append(ice_candidate)
	print("[client] ice candidate: ",ice_candidate)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.client_add_peer.connect(popup)
	about_to_popup.connect(_on_popup)

func _on_popup() -> void:
	connection = WebRTCPeerConnection.new()
	packet = {}
	client_offer.text = ""
	server_offer.text = ""
	connection.initialize({
		"iceServers": [{
			"urls": [
				"stun:stun.l.google.com:19302",
				"stun1.l.google.com:19302",
				"stun2.l.google.com:19302",
				"stun3.l.google.com:19302",
				"stun4.l.google.com:19302",
				"stun01.sipphone.com",
				"stun.ekiga.net",
				"stun.fwdnet.net",
				"stun.ideasip.com"
		]
		}]
	})
	packet.id = multiplayer.get_unique_id()
	connection.session_description_created.connect(_sdp_created)
	connection.ice_candidate_created.connect(_ice_created)
	multiplayer.multiplayer_peer.add_peer(connection, 1)
	connection.create_offer()


func _on_connect_pressed() -> void:
	var pckt: Dictionary = Utils.decode_offer(server_offer.text)
	connection.set_remote_description(pckt.sdp.type, pckt.sdp.sdp)
	for ice in pckt.ice_candidates:
		connection.add_ice_candidate(ice.media, ice.index, ice.name)
	get_tree().reload_current_scene()

func update_text_packet() -> void:
	client_offer.text = Utils.encode_offer(packet)
	print("[client] Encoded ", packet)