extends Node

var unique_id: int

const FIREBASE_API_URL = "https://tt-framework-default-rtdb.firebaseio.com/server-list"

var req := HTTPRequest.new()

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	add_child(req)

func close_connection() -> void:
	if multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		print("Connection closed")

func peer_connected(id: int) -> void:
	print("Hello, peer ",id)

func peer_disconnected(id: int) -> void:
	print("Goodbye, peer ",id)

func create_server() -> void:
	unique_id = RandomNumberGenerator.new().randi_range(2, 2147483647)
	add_peer_p2p_shortened(WebRTCPeerConnection.new(), true, "")

func create_client(code: String) -> void:
	unique_id = 1
	add_peer_p2p_shortened(WebRTCPeerConnection.new(), false, code)

func add_peer_p2p_shortened(connection: WebRTCPeerConnection, is_server: bool = true, code: String = "") -> void:
	print("Is server: ",is_server, ", code: ",code)
	var fbase_manager := FirebaseManager.new()
	add_child(fbase_manager)
	SignalManager.mplay_code_created.emit(fbase_manager.code)
	print("New code created: ",fbase_manager.code)
	connection.session_description_created.connect(
		func(_type: String, _sdp: String) -> void:
			connection.set_local_description(_type, _sdp)
			print("New local sdp: ", _type, ", ", _sdp)
			fbase_manager.add_sdp(_type, _sdp, unique_id)
			)
	connection.ice_candidate_created.connect(
		func(_media: String, _index: int, _name: String) -> void:
			print("New ice candidate!: ", _media, ", ", _index, ", ", _name)
			fbase_manager.add_ice_candidate(_media, _index, _name)
			)
	if is_server: # Server initial setup
		print("SERVER: Creating offer, adding multiplayer peer")
		if not multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
			var new_peer := WebRTCMultiplayerPeer.new()
			new_peer.create_server()
			multiplayer.multiplayer_peer = new_peer
		multiplayer.multiplayer_peer.add_peer(connection, unique_id)
		connection.create_offer()
		code = await SignalManager.client_code_received
	# Polling loop
	while connection.get_connection_state() not in [connection.STATE_CONNECTED, connection.STATE_CLOSED]:
		print("Polling...")
		await get_tree().create_timer(2).timeout
		var results := await fbase_manager.poll_database(code)
		if not results.is_empty():
			print("Found results! ",results)
			if "ID" in results and not is_server: # Client initial setup
				print("Received ID")
				var new_peer := WebRTCMultiplayerPeer.new()
				new_peer.create_client(results.ID)
				multiplayer.multiplayer_peer = new_peer
				multiplayer.multiplayer_peer.add_peer(connection, 1)
			if "SDP" in results:
				print("Received remote description")
				connection.set_remote_description(results.SDP.type, results.SDP.sdp)
			if "ICE_CANDIDATES" in results:
				print("Received ", results.ICE_CANDIDATES.values().size(), " ice candidates")
				for candidate: Dictionary in results.ICE_CANDIDATES.values():
					connection.add_ice_candidate(candidate.media, candidate.index, candidate.name)
	if connection.get_connection_state() == connection.STATE_CONNECTED:
		print("Connected successfully!")
	else:
		print("Connection failed...")
	fbase_manager.queue_free()

func http_get_json(url: String) -> Dictionary:
	var result := req.request(
		url,
		PackedStringArray(), HTTPClient.METHOD_GET
	)
	if result != OK:
		print_connect_error("Getting Server List")
		return {}
	var data: Array = await req.request_completed
	if PackedByteArray(data[3]).get_string_from_utf8() == "null":
		return {}
	
	var obj: Dictionary = JSON.parse_string(PackedByteArray(data[3]).get_string_from_utf8())
	print(obj)
	return obj

func get_server_list() -> Array:
	var result: Dictionary = await http_get_json(str(FIREBASE_API_URL,".json"))
	return result.keys()

func print_connect_error(msg: String) -> void:
	print("There was a problem contacting the firebase server: ",msg)

class FirebaseManager extends Node:
	var code := Utils.random_string(6)
	const FIREBASE_API_URL = "https://tt-framework-default-rtdb.firebaseio.com/server-list"

	func add_sdp(_type: String, _sdp: String, _id: int) -> bool:
		var req := HTTPRequest.new()
		add_child(req)
		print("Posting SDP to Firebase: %s, %s" % [_type, _sdp])
		var sdp: Dictionary = {
			"type": _type,
			"sdp": _sdp,
			"ID": _id
		}
		var result := req.request(
			str(FIREBASE_API_URL,"/",code,".json"),
			PackedStringArray(),
			HTTPClient.METHOD_PUT, JSON.stringify({"SDP": sdp})
		)
		if result != OK:
			print("There was a problem contacting the firebase server to PUT SDP.")
			req.queue_free()
			return false
		await req.request_completed
		print("Success PUT ICE SDP!")
		req.queue_free()
		return true

	func add_ice_candidate(_media: String, _index: int, _name: String) -> bool:
		var req := HTTPRequest.new()
		add_child(req)
		print("Posting ICE Candidate to Firebase: %s, %d, %s" % [_media, _index, _name])
		var ice_request: Dictionary = {
			"media": _media,
			"index": _index,
			"name": _name,
		}
		var result := req.request(
			str(FIREBASE_API_URL,"/",code,"/ICE_REQUESTS.json"),
			PackedStringArray(),
			HTTPClient.METHOD_POST, JSON.stringify(ice_request)
		)
		if result != OK:
			print("There was a problem contacting the firebase server to PUT ICE CANDIDATE.")
			req.queue_free()
			return false
		await req.request_completed
		print("Success PUT ICE CANDIDATE!")
		req.queue_free()
		return true
	
	func poll_database(_code: String) -> Dictionary:
		var req := HTTPRequest.new()
		add_child(req)
		print("Polling from Firebase code %s" % [_code])
		var result := req.request(
			str(FIREBASE_API_URL, "/",_code,".json"), PackedStringArray(),
			HTTPClient.METHOD_GET, ""
		)
		if result != OK:
			print("There was a problem polling from firebase server.")
			return {}
		var response: Array = await req.request_completed
		print("Received response: ",response)
		if PackedByteArray(response[3]).get_string_from_utf8() == "null":
			return {}
		result = req.request(
			str(FIREBASE_API_URL,"/",_code,".json"), PackedStringArray(),
			HTTPClient.METHOD_DELETE, ""
		)
		if result != OK:
			print("There was a problem deleting peer data from firebase server.")
		await req.request_completed
		req.queue_free()
		return JSON.parse_string(PackedByteArray(response[3]).get_string_from_utf8())


class SignalingServerPeer extends Node:
	var wsp := WebSocketPeer.new()
	var url: String

	func _init(_url: String) -> void:
		url = str("ws://",_url)
	
	func _ready() -> void:
		wsp.connect_to_url(url)

	func _process(_delta: float) -> void:
		wsp.poll()
		var state := wsp.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while wsp.get_available_packet_count():
				var msg: String = wsp.get_packet().get_string_from_utf8()
				_process_packet(msg)
		elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			var code := wsp.get_close_code()
			var reason := wsp.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false) # Stop processing.
	
	func _process_packet(msg: String) -> void:
		pass