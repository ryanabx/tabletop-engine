extends Window

var connection: WebRTCPeerConnection

var packet: Dictionary = {
	'sdp': {},
	'ice_candidates': [],
	'id': 0
}

@onready var paste_offer: Button = $PanelContainer/MarginContainer/VBoxContainer/PasteOffer
@onready var is_connected_label: Label = $PanelContainer/MarginContainer/VBoxContainer/IsConnectedLabel
@onready var done: Button = $PanelContainer/MarginContainer/VBoxContainer/Done

func _on_close_requested() -> void:
	hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.client_add_peer.connect(popup)
	about_to_popup.connect(_on_popup)
	multiplayer.peer_connected.connect(peer_connected)

func _on_popup() -> void:
	paste_offer.set_disabled(false)
	is_connected_label.set_text("Not connected")
	done.set_disabled(true)
	connection = WebRTCPeerConnection.new()
	packet = {
		'sdp': {},
		'ice_candidates': [],
		'id': 0
	}
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

func _on_paste_offer_pressed() -> void:
	var sv_packet: Dictionary = Utils.decode_offer(DisplayServer.clipboard_get())
	if sv_packet.is_empty():
		OS.alert("Improper information!")
		return
	MultiplayerManager.create_client(sv_packet.id)
	packet.id = sv_packet.id
	multiplayer.multiplayer_peer.add_peer(connection, 1)
	connection.set_remote_description(sv_packet.sdp.type, sv_packet.sdp.sdp)
	for ice in sv_packet.ice_candidates:
		connection.add_ice_candidate(ice.media, ice.index, ice.name)
	
func _sdp_created(type: String, sdp: String) -> void:
	packet.sdp = {"type": type, "sdp": sdp}
	connection.set_local_description(type, sdp)
	await get_tree().create_timer(0.2).timeout

	DisplayServer.clipboard_set(Utils.encode_offer(packet))
	print("[client] Encoded ", packet)


func _ice_created(media: String, index: int, _name: String) -> void:
	var ice_candidate: Dictionary = {
		"media": media, "index": index, "name": _name
	}
	if "ice_candidates" not in packet:
		packet.ice_candidates = []
	packet.ice_candidates.append(ice_candidate)
	print("[client] ice candidate: ",ice_candidate)

func peer_connected(_id: int) -> void:
	paste_offer.set_disabled(true)
	is_connected_label.set_text("Connected!")
	done.set_disabled(false)

func _on_done_pressed() -> void:
	hide()
	get_tree().reload_current_scene()
