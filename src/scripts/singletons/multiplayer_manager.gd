extends Node

var current_connection: WebRTCMultiplayerPeer = null
var wip_connection: WebRTCPeerConnection = null
var wip_packet: Dictionary
var unique_id: int
var connection_type: String = "Neither"
var wip_code: String = ""

# var req := HTTPRequest.new()

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)

func close_connection() -> void:
	if current_connection != null:
		current_connection.close()
		Utils.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		print("Connection closed")

func cancel_peer_connection() -> void:
	wip_connection.close()
	reset_wip()

func initialize_server() -> void:
	close_connection()
	connection_type = "Server"
	current_connection = WebRTCMultiplayerPeer.new()
	current_connection.create_server()
	Utils.multiplayer.multiplayer_peer = current_connection

func add_client() -> void:
	wip_code = Utils.random_string(6)
	match GameProperties.multiplayer_method:
		GameProperties.MultiplayerMethod.P2P:
			add_client_p2p()
		GameProperties.MultiplayerMethod.P2P_SHORTENED:
			add_client_p2p_shortened()

func add_client_p2p() -> void:
	reset_wip()
	print("[Server] Adding new client.")
	# Unique id for client
	wip_packet.id = unique_id
	wip_connection.initialize(Globals.RTC_CONFIG)
	Utils.multiplayer.multiplayer_peer.add_peer(wip_connection, wip_packet.id)
	unique_id += 1
	await server_offer()
	await gather_ice_candidates_p2p()
	# ICE Candidates
	print("[Server] Gathered ", wip_packet.ice_candidates.size(), " ice candidates... Encoding packet...")
	SignalManager.mplay_code_created.emit(encode_packet(wip_packet))
	# Wait for client to respond
	var code: String = await SignalManager.mplay_code_received
	# Found peer code
	var _packet: Dictionary = decode_packet(code)
	wip_connection.set_remote_description(_packet.sdp[0], _packet.sdp[1])
	for ice_candidate: Array in _packet.ice_candidates:
		wip_connection.add_ice_candidate(ice_candidate[0], ice_candidate[1], ice_candidate[2])
	print("[Server] Done")
	await SignalManager.mplay_go_to_wait
	var result: bool = await wait_for_connection()
	if result == true:
		SignalManager.mplay_connection_result.emit(result)
	return

func gather_ice_candidates_p2p() -> bool:
	var timeout: float = 0.0
	var timer_amt: float = 0.3
	while wip_connection.get_gathering_state() != wip_connection.GATHERING_STATE_COMPLETE and timeout < Globals.ICE_TIMEOUT:
		await Utils.get_tree().create_timer(timer_amt).timeout
		print("Number of ICE candidates gathered: ", wip_packet.ice_candidates.size(), " current state: ",wip_connection.get_gathering_state(), ", timeout: ",timeout)
		if wip_connection.get_gathering_state() == wip_connection.GATHERING_STATE_GATHERING:
			timeout += timer_amt
		SignalManager.mplay_offer_percentage.emit(timeout / Globals.ICE_TIMEOUT)
	return true

func server_offer() -> bool:
	# Server creates offer
	wip_connection.create_offer()
	# Session Description Protocol
	var sdp: Array = await wip_connection.session_description_created
	print("[",connection_type,"] New SDP created: ", sdp)
	wip_packet.sdp = sdp
	wip_connection.set_local_description(sdp[0], sdp[1])
	return true

func add_server() -> void:
	wip_code = Utils.random_string(6)
	match GameProperties.multiplayer_method:
		GameProperties.MultiplayerMethod.P2P:
			add_server_p2p()
		GameProperties.MultiplayerMethod.P2P_SHORTENED:
			add_server_p2p_shortened()

func add_server_p2p() -> void:
	connection_type = "Client"
	reset_wip()
	print("[Client] Connecting to server")
	print("[Client] Waiting for code from user...")
	var code: String = await SignalManager.mplay_code_received
	# Found server code
	var _packet: Dictionary = decode_packet(code)
	initialize_client(_packet.id)
	wip_connection.set_remote_description(_packet.sdp[0], _packet.sdp[1])
	var sdp: Array = await wip_connection.session_description_created
	wip_packet.sdp = sdp
	wip_connection.set_local_description(sdp[0], sdp[1])
	for ice_candidate: Array in _packet.ice_candidates:
		wip_connection.add_ice_candidate(ice_candidate[0], ice_candidate[1], ice_candidate[2])
	await gather_ice_candidates_p2p()
	await Utils.get_tree().create_timer(0.5).timeout
	print("[Client] Gathered ", wip_packet.ice_candidates.size(), " ice candidates... Encoding packet...")
	SignalManager.mplay_code_created.emit(encode_packet(wip_packet))
	await SignalManager.mplay_go_to_wait
	var result: bool = await wait_for_connection()
	SignalManager.mplay_connection_result.emit(result)
	return

func code_wait_loop() -> void:
	while wip_connection.get_connection_state() not in [wip_connection.STATE_CONNECTED, wip_connection.STATE_CLOSED]:
		await Utils.get_tree().create_timer(0.5).timeout
		print("Current connection state: ",wip_connection.get_connection_state())

func wait_for_connection() -> bool:
	SignalManager.mplay_establishing_connection.emit()
	while wip_connection.get_connection_state() not in [wip_connection.STATE_CONNECTED, wip_connection.STATE_CLOSED]:
		await Utils.get_tree().create_timer(0.5).timeout
		print("Current connection state: ",wip_connection.get_connection_state())
	return wip_connection.get_connection_state() == wip_connection.STATE_CONNECTED

func initialize_client(id: int) -> void:
	connection_type = "Client"
	current_connection = WebRTCMultiplayerPeer.new()
	current_connection.create_client(id)
	wip_connection.initialize(Globals.RTC_CONFIG)
	current_connection.add_peer(wip_connection, 1)
	Utils.multiplayer.multiplayer_peer = current_connection

func encode_packet(_packet: Dictionary) -> String:
	var _string: String = Utils.FileManager.decode_string(Utils.FileManager.compress_dictionary(_packet))
	return _string

func decode_packet(_string: String) -> Dictionary:
	return Utils.FileManager.decompress_to_dictionary(Utils.FileManager.encode_string(_string))

func ice_candidate_created(media: String, index: int, _name: String) -> void:
	match GameProperties.multiplayer_method:
		GameProperties.MultiplayerMethod.P2P:
			var ice_candidate: Array = [media, index, _name]
			print("[",connection_type,"] New ice candidate for connection: ", ice_candidate)
			wip_packet.ice_candidates.append(ice_candidate)
		GameProperties.MultiplayerMethod.P2P_SHORTENED:
			var req := Utils.req
			var result := req.request(str(Globals.FIREBASE_API_URL,"/",wip_code,"/ICE_CANDIDATES"),
			PackedStringArray(), HTTPClient.METHOD_POST, JSON.stringify(
				{
					"media": media,
					"index": index,
					"name": _name
				}
			))
			if result != OK:
				print("Problem with the request")

func reset_wip() -> void:
	# Reset packet
	wip_packet = {
		"sdp": "", "id": 0, "ice_candidates": []
	}
	wip_code = ""
	# Reset connection variable
	if wip_connection != null:
		wip_connection.ice_candidate_created.disconnect(ice_candidate_created)
	wip_connection = WebRTCPeerConnection.new()
	wip_connection.ice_candidate_created.connect(ice_candidate_created)

func peer_connected(id: int) -> void:
	print("Hello, peer ",id)

func peer_disconnected(id: int) -> void:
	print("Goodbye, peer ",id)

func add_server_p2p_shortened() -> void:
	unique_id = 1
	add_peer_p2p_shortened(WebRTCPeerConnection.new(), true)

func add_client_p2p_shortened() -> void:
	unique_id = RandomNumberGenerator.new().randi_range(2, 4000)
	add_peer_p2p_shortened(WebRTCPeerConnection.new(), false)

func add_peer_p2p_shortened(connection: WebRTCPeerConnection, is_server: bool) -> void:
	var fbase_manager := FirebaseManager.new()
	SignalManager.mplay_code_created.emit(fbase_manager.code)
	connection.session_description_created.connect(
		func(_type: String, _sdp: String) -> void:
			connection.set_local_description(_type, _sdp)
			fbase_manager.add_sdp(_type, _sdp, unique_id)
			)
	connection.ice_candidate_created.connect(
		func(_media: String, _index: int, _name: String) -> void:
			fbase_manager.add_ice_candidate(_media, _index, _name)
			)
	if is_server:
		connection.create_offer()
	var peer_code: String = await SignalManager.mplay_code_received
	while connection.get_connection_state() not in [connection.STATE_CONNECTED, connection.STATE_CLOSED]:
		await get_tree().create_timer(2).timeout
		var results := await fbase_manager.poll_database(peer_code)
		if not results.is_empty():
			if "SDP" in results:
				multiplayer.multiplayer_peer.add_peer(connection, results.SDP[2])
				connection.set_remote_description(results.SDP[0], results.SDP[1])
			if "ICE_CANDIDATES" in results:
				for candidate: Array in results.ICE_CANDIDATES:
					connection.add_ice_candidate(candidate[0], candidate[1], candidate[2])
	if connection.get_connection_state() == connection.STATE_CONNECTED:
		print("Connected successfully!")
	else:
		print("Connection failed...")

class FirebaseManager:
	var req := HTTPRequest.new()
	var code := Utils.random_string(6)
	const FIREBASE_API_URL = "https://tt-framework-default-rtdb.firebaseio.com/codes"

	func add_sdp(_type: String, _sdp: String, _id: int) -> bool:
		print("Posting SDP to Firebase: %s, %s" % [_type, _sdp])
		var sdp: Array = [_type, _sdp, _id]
		var result := req.request(
			str(FIREBASE_API_URL,"/",code),
			PackedStringArray(),
			HTTPClient.METHOD_PUT, JSON.stringify({"SDP": sdp})
		)
		if result != OK:
			print("There was a problem contacting the firebase server to PUT SDP.")
			return false
		return true

	func add_ice_candidate(_media: String, _index: int, _name: String) -> bool:
		print("Posting ICE Candidate to Firebase: %s, %d, %s" % [_media, _index, _name])
		var ice_request: Array = [_media, _index, _name]
		var result := req.request(
			str(FIREBASE_API_URL,"/",code,"/ICE_REQUESTS"),
			PackedStringArray(),
			HTTPClient.METHOD_POST, JSON.stringify(ice_request)
		)
		if result != OK:
			print("There was a problem contacting the firebase server to POST ice_candidate.")
			return false
		return true
	
	func poll_database(_code: String) -> Dictionary:
		print("Polling from Firebase code %s" % [_code])
		var result := req.request(
			str(FIREBASE_API_URL, "/",_code), PackedStringArray(),
			HTTPClient.METHOD_GET, ""
		)
		if result != OK:
			print("There was a problem polling from firebase server.")
			return {}
		var response: Array = await req.request_completed
		print("Received response: ",response)
		if response[3] == "":
			return {}
		result = req.request(
			str(FIREBASE_API_URL,"/",_code), PackedStringArray(),
			HTTPClient.METHOD_DELETE, ""
		)
		if result != OK:
			print("There was a problem deleting peer data from firebase server.")
		await req.request_completed
		return JSON.parse_string(response[3])