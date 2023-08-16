extends Window

var connection: WebRTCPeerConnection

func _on_close_requested() -> void:
	hide()

@onready var client_sdp: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/ClientSDP
@onready var server_sdp: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/ServerSDP
@onready var client_ice: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer2/ClientICE
@onready var server_ice: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer2/ServerICE
@onready var client_id: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer3/ClientId

func _sdp_created(type: String, sdp: String) -> void:
	connection.set_local_description(type, sdp)
	var session_info: Dictionary = {
		"type": type, "sdp": sdp
	}
	var res: String = Utils.compress_dict_to_string(session_info)
	server_sdp.text = res
	DisplayServer.clipboard_set(res)

func _ice_created(media: String, index: int, _name: String) -> void:
	var ice_candidate: Dictionary = {
		"media": media, "index": index, "name": _name
	}
	var res: String = Utils.compress_dict_to_string(ice_candidate)
	server_ice.text = res
	DisplayServer.clipboard_set(res)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	about_to_popup.connect(_on_popup)
	

func _on_popup() -> void:
	connection = WebRTCPeerConnection.new()
	connection.session_description_created.connect(_sdp_created)
	connection.ice_candidate_created.connect(_ice_created)

func _on_submit_1_pressed() -> void:
	var sdp: Dictionary = Utils.decompress_dict_from_string(client_sdp.text)
	connection.set_remote_description(sdp.type, sdp.sdp)


func _on_submit_2_pressed() -> void:
	var ice: Dictionary = Utils.decompress_dict_from_string(client_ice.text)
	connection.add_ice_candidate(ice.media, ice.index, ice.name)


func _on_add_peer_pressed() -> void:
	var cl_id: int = int(client_id.text)
	if cl_id != 0:
		multiplayer.multiplayer_peer.add_peer(connection, cl_id)
		OS.alert("Peer added successfully!")
