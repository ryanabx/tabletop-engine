extends Window

var connection: WebRTCPeerConnection
var packet: Dictionary = {
	'sdp': {},
	'ice_candidates': [],
	'id': 0
}

@onready var offer_create_notice: Label = $PanelContainer/MarginContainer/VBoxContainer/OfferCreateNotice
@onready var paste_client_offer: Button = $PanelContainer/MarginContainer/VBoxContainer/PasteOffer
@onready var done: Button = $PanelContainer/MarginContainer/VBoxContainer/Done
@onready var player_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/PlayerList

func _on_close_requested() -> void:
	hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.server_add_peer.connect(popup)
	about_to_popup.connect(_on_popup)
	multiplayer.peer_connected.connect(peer_connected)

func _on_popup() -> void:
	MultiplayerManager.create_server()

func _on_create_offer_pressed() -> void:
	packet = {
		'sdp': {},
		'ice_candidates': [],
		'id': 0
	}
	# Remove previous connections
	if connection != null:
		connection.session_description_created.disconnect(_sdp_created)
		connection.ice_candidate_created.disconnect(_ice_created)
		connection = null
	# New connection created
	connection = WebRTCPeerConnection.new()
	connection.session_description_created.connect(_sdp_created)
	connection.ice_candidate_created.connect(_ice_created)
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
	print("[SERVER] Creating connection offer")
	packet.id = get_new_id()
	multiplayer.multiplayer_peer.add_peer(connection, packet.id)
	connection.create_offer()

func _sdp_created(type: String, sdp: String) -> void:
	print("[SERVER] sdp created")
	packet.sdp = {
		"type": type,
		"sdp": sdp,
	}
	
	connection.set_local_description(type, sdp)
	await get_tree().create_timer(0.2).timeout
	DisplayServer.clipboard_set(Utils.encode_offer(packet))

	offer_create_notice.show()
	paste_client_offer.set_disabled(false)
	
func get_new_id() -> int:
	var i: int = 2
	while i in multiplayer.get_peers():
		i += 1
	return i

func _on_paste_offer_pressed() -> void:
	var cl_packet: Dictionary = Utils.decode_offer(DisplayServer.clipboard_get())
	if cl_packet.is_empty():
		OS.alert("Improper information!")
		return
	connection.set_remote_description(cl_packet.sdp.type, cl_packet.sdp.sdp)
	for ice in cl_packet.ice_candidates:
		connection.add_ice_candidate(ice.media, ice.index, ice.name)
	
	await get_tree().create_timer(0.2).timeout

	offer_create_notice.hide()
	paste_client_offer.set_disabled(true)

func _ice_created(media: String, index: int, _name: String) -> void:
	var ice_candidate: Dictionary = {
		"media": media, "index": index, "name": _name
	}
	packet.ice_candidates.append(ice_candidate)
	print("[server] ice candidate: ",ice_candidate)

func peer_connected(id: int) -> void:
	done.set_disabled(multiplayer.get_peers().size() == 0)
	player_list.add_item(str("Player ",id))

func _on_done_pressed() -> void:
	hide()
	get_tree().reload_current_scene()