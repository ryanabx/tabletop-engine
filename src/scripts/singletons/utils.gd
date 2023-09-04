extends Node

var req: HTTPRequest

func _ready() -> void:
	multiplayer.peer_connected.connect(MultiplayerManager.peer_connected)
	multiplayer.peer_disconnected.connect(MultiplayerManager.peer_disconnected)
	req = HTTPRequest.new()
	add_child(req)

func load_images_into_array(image_strings: Array, image_directory: String) -> Array:
	var result: Array = []
	for image_path in image_strings:
		var _image = Image.new()
		var _err = _image.load(image_directory + image_path)
		if _err != OK:
			print("Failed to load image: ",image_directory + image_path)
			return []
		var _texture = ImageTexture.new()
		_texture = ImageTexture.create_from_image(_image)
		result.append(_texture)
	return result

func load_texture_from_string(fname: String, image_directory: String) -> Texture2D:
	var _image = Image.new()
	var _err = _image.load(image_directory + fname)
	if _err != OK:
		print("Failed to load image: ",image_directory + fname)
		return null
	var _texture = ImageTexture.new()
	_texture = ImageTexture.create_from_image(_image)
	return _texture

func rect_with_padding(rct: Rect2, padding: float) -> Rect2:
	return Rect2(rct.position - Vector2(padding, padding), rct.size + Vector2(padding * 2, padding * 2))

func load_json_from_file(fname: String) -> Dictionary:
	if FileAccess.file_exists(fname):
		var data_file = FileAccess.open(fname, FileAccess.READ)
		var parsed_result = JSON.parse_string(data_file.get_as_text())
		if parsed_result is Dictionary:
			return parsed_result
		else:
			print("Error parsing file: ",fname)
			return {}
	else:
		print("File not found: ",fname)
		return {}

func random_string(length: int) -> String:
	return generate_word(Globals.CODE_CHARS, length)

func generate_word(chars, length) -> String:
	var word: String = ""
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word

func load_images_from_directory(dir: String) -> Dictionary:
	var textures: Dictionary = {}
	var directory_access = DirAccess.open(dir)
	if directory_access.dir_exists("."):
		for fname in directory_access.get_files():
			var file_ext: String = fname.rsplit(".")[-1]
			if file_ext in ["png", "jpg", "jpeg", "bmp", "svg"]:
				var _tx = load_texture_from_string(fname, str(dir,"/"))
				if _tx != null:
					textures[fname] = _tx
	return textures

func has_any(arr1: Array, arr2: Array) -> bool:
	for x in arr1:
		for y in arr2:
			if x == y:
				return true
	return false

@rpc("any_peer", "call_remote", "reliable")
func go_to_scene(fpath: String) -> void:
	SignalManager.scene_transition.emit(fpath)

class MultiplayerManager:
	static var current_connection: WebRTCMultiplayerPeer = null
	static var wip_connection: WebRTCPeerConnection = null
	static var wip_packet: Dictionary
	static var unique_id: int = 2
	static var connection_type: String = "Neither"

	static func close_connection() -> void:
		if current_connection != null:
			current_connection.close()
			Utils.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
			print("Connection closed")
	
	static func cancel_peer_connection() -> void:
		wip_connection.close()
		reset_wip()

	static func initialize_server() -> void:
		close_connection()
		connection_type = "Server"
		current_connection = WebRTCMultiplayerPeer.new()
		current_connection.create_server()
		Utils.multiplayer.multiplayer_peer = current_connection

	static func add_client() -> void:
		print("[Server] Adding new client.")
		MultiplayerManager.reset_wip()
		# Unique id for client
		wip_packet.id = unique_id
		wip_connection.initialize(Globals.RTC_CONFIG)
		Utils.multiplayer.multiplayer_peer.add_peer(wip_connection, wip_packet.id)
		unique_id += 1
		await server_offer()
		await gather_ice_candidates()
		# ICE Candidates
		print("[Server] Gathered ", wip_packet.ice_candidates.size(), " ice candidates... Encoding packet...")
		SignalManager.mplay_code_created.emit(encode_packet(wip_packet))
		# Wait for client to respond
		await process_packet_server()
		print("[Server] Done")
		await SignalManager.mplay_go_to_wait
		var result: bool = await wait_for_connection()
		if result == true:
			SignalManager.mplay_connection_result.emit(result)
		return
	
	static func gather_ice_candidates() -> bool:
		var timeout: float = 0.0
		var timer_amt: float = 0.3
		while wip_connection.get_gathering_state() != wip_connection.GATHERING_STATE_COMPLETE and timeout < Globals.ICE_TIMEOUT:
			await Utils.get_tree().create_timer(timer_amt).timeout
			print("Number of ICE candidates gathered: ", wip_packet.ice_candidates.size(), " current state: ",wip_connection.get_gathering_state(), ", timeout: ",timeout)
			if wip_connection.get_gathering_state() == wip_connection.GATHERING_STATE_GATHERING:
				timeout += timer_amt
			SignalManager.mplay_offer_percentage.emit(timeout / Globals.ICE_TIMEOUT)
		return true
	
	static func server_offer() -> bool:
		# Server creates offer
		wip_connection.create_offer()
		# Session Description Protocol
		var sdp: Array = await wip_connection.session_description_created
		print("[",connection_type,"] New SDP created: ", sdp)
		wip_packet.sdp = sdp
		wip_connection.set_local_description(sdp[0], sdp[1])
		return true
	
	static func process_packet_server() -> bool:
		var code: String = await SignalManager.mplay_code_received
		# Found peer code
		var _packet: Dictionary = decode_packet(code)
		wip_connection.set_remote_description(_packet.sdp[0], _packet.sdp[1])
		for ice_candidate in _packet.ice_candidates:
			wip_connection.add_ice_candidate(ice_candidate[0], ice_candidate[1], ice_candidate[2])
		return true

	static func connect_to_server() -> void:
		connection_type = "Client"
		print("[Client] Connecting to server")
		reset_wip()
		print("[Client] Waiting for code from user...")
		await process_packet_client()
		await gather_ice_candidates()
		await Utils.get_tree().create_timer(0.5).timeout
		print("[Client] Gathered ", wip_packet.ice_candidates.size(), " ice candidates... Encoding packet...")
		SignalManager.mplay_code_created.emit(encode_packet(wip_packet))
		await SignalManager.mplay_go_to_wait
		var result: bool = await wait_for_connection()
		if result == true:
			SignalManager.mplay_connection_result.emit(result)
		return
	
	static func wait_for_connection() -> bool:
		SignalManager.mplay_establishing_connection.emit()
		while wip_connection.get_connection_state() not in [wip_connection.STATE_CONNECTED, wip_connection.STATE_CLOSED]:
			await Utils.get_tree().create_timer(0.5).timeout
			print("Current connection state: ",wip_connection.get_connection_state())
		return wip_connection.get_connection_state() == wip_connection.STATE_CONNECTED
	
	static func process_packet_client() -> bool:
		var code: String = await SignalManager.mplay_code_received
		# Found server code
		print("[Client] Received code from server. Decoding...")
		var _packet: Dictionary = decode_packet(code)
		initialize_client(_packet.id)
		print("[Client] Setting remote description from ",_packet.sdp)
		wip_connection.set_remote_description(_packet.sdp[0], _packet.sdp[1])
		var sdp: Array = await wip_connection.session_description_created
		print("[",connection_type,"] New SDP created: ", sdp)
		wip_packet.sdp = sdp
		wip_connection.set_local_description(sdp[0], sdp[1])
		print("[Client] Ice candidates from server: ",_packet.ice_candidates)
		for ice_candidate in _packet.ice_candidates:
			wip_connection.add_ice_candidate(ice_candidate[0], ice_candidate[1], ice_candidate[2])
		return true

	static func initialize_client(id: int) -> void:
		connection_type = "Client"
		current_connection = WebRTCMultiplayerPeer.new()
		current_connection.create_client(id)
		wip_connection.initialize(Globals.RTC_CONFIG)
		current_connection.add_peer(wip_connection, 1)
		Utils.multiplayer.multiplayer_peer = current_connection

	static func encode_packet(_packet: Dictionary) -> String:
		var _string: String = Utils.FileManager.decode_string(Utils.FileManager.compress_dictionary(_packet))
		return _string

	static func decode_packet(_string: String) -> Dictionary:
		return Utils.FileManager.decompress_to_dictionary(Utils.FileManager.encode_string(_string))

	static func ice_candidate_created(media: String, index: int, name: String):
		var ice_candidate: Array = [media, index, name]
		print("[",MultiplayerManager.connection_type,"] New ice candidate for connection: ", ice_candidate)
		wip_packet.ice_candidates.append(ice_candidate)

	static func reset_wip() -> void:
		# Reset packet
		wip_packet = {
			"sdp": "", "id": 0, "ice_candidates": []
		}
		# Reset connection variable
		if wip_connection != null:
			wip_connection.ice_candidate_created.disconnect(MultiplayerManager.ice_candidate_created)
		wip_connection = WebRTCPeerConnection.new()
		wip_connection.ice_candidate_created.connect(MultiplayerManager.ice_candidate_created)
	
	static func peer_connected(id: int) -> void:
		print("Hello, peer ",id)
	
	static func peer_disconnected(id: int) -> void:
		print("Goodbye, peer ",id)

class FileManager:
	## Compresses dictionary through Gzip compression
	static func compress_dictionary(_dict: Dictionary) -> PackedByteArray:
		return var_to_bytes(JSON.stringify(_dict)).compress(3)
	
	## Decompresses dictionary through Gzip decompression
	static func decompress_to_dictionary(_bytes: PackedByteArray) -> Dictionary:
		return JSON.parse_string(bytes_to_var(_bytes.decompress_dynamic(-1, 3)))
	
	## Gets string from bytes
	static func decode_string(_bytes: PackedByteArray) -> String:
		return Marshalls.raw_to_base64(_bytes)
	
	## Gets bytes from string
	static func encode_string(_string: String) -> PackedByteArray:
		return Marshalls.base64_to_raw(_string)

	static func create_dir(dir: String) -> void:
		if DirAccess.dir_exists_absolute(dir):
			return
		
		DirAccess.make_dir_absolute(dir)

	static func get_available_configs() -> Array[String]:
		if not DirAccess.dir_exists_absolute(Globals.CONFIG_REPO):
			print("Directory doesn't exist!")
			return []
		
		var configs: Array[String] = []

		var directory: DirAccess = DirAccess.open(Globals.CONFIG_REPO)

		for fname in directory.get_files():
			print(fname)
			var split_fname: PackedStringArray = fname.rsplit(".",1)
			print(split_fname[0], ", ", split_fname[1])
			if fname.rsplit(".",1)[-1] == "obgf":
				configs.append(split_fname[0])
		
		return configs

	static func delete_file(fname: String) -> void:
		if FileAccess.file_exists(fname):
			DirAccess.remove_absolute(fname)

	static func get_file_bytes(fname: String) -> PackedByteArray:
		if FileAccess.file_exists(fname):
			var bytes: PackedByteArray = FileAccess.get_file_as_bytes(fname)
			return bytes
		else:
			print("Could not find file ", fname)
		return PackedByteArray([])

	static func download_file_from_url(url: String) -> bool:
		var fpath: String = await download_file(url)
		if fpath == "":
			print("Could not download file from url ",url)
			return false
		
		return validate_downloaded_file(fpath)

	static func download_file(url: String) -> String:
		var req: HTTPRequest = Utils.req
		req.download_file = Globals.DOWNLOAD_FILE_PATH
		var res: int = req.request(url)
		if res != OK:
			req.queue_free()
			print("Error when making httprequest: ", res)
			return ""
		print("Downloading ", req.get_body_size(), " bytes from ", url)
		var result = await req.request_completed
		print("Download completed: ",result)
		req.queue_free()
		if result[1] == 303:
			var new_url: String = result[2][5].split("Location: ", false, 1)[0]
			print("303 ERROR, going to url ", new_url)
			return await download_file(new_url)
		req.download_file = ""
		return Globals.DOWNLOAD_FILE_PATH

	static func validate_downloaded_file(fpath: String) -> bool:
		var bytes: PackedByteArray = get_file_bytes(fpath)
		if bytes.is_empty():
			print("Config was null")
			delete_file(fpath)
			return false
		print("Looking for fpath ",fpath)
		create_dir(Globals.CONFIG_REPO)
		var conf: TabletopGame = TabletopGame.import_obgf(bytes)

		var conf_path: String = str(Globals.CONFIG_REPO, "/",conf.export_settings().name,Globals.CONFIG_EXTENSION)

		Utils.delete_file(conf_path)
		
		var local_copy: FileAccess = FileAccess.open(conf_path, FileAccess.WRITE)
		

		if local_copy == null:
			print(FileAccess.get_open_error(), ": ", conf_path)
			return false

		local_copy.store_buffer(conf.to_bytes())
		local_copy.close()
		
		delete_file(fpath)
		return true

var current_safe_area: Rect2i = Rect2i(0, 0, 0, 0)

func is_desktop_platform() -> bool:
	return [
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"
	].has(OS.get_name())

func is_web_platform() -> bool:
	return [
		"Web"
	].has(OS.get_name())

func is_mobile_platform() -> bool:
	return [
		"iOS", "Android"
	].has(OS.get_name())

func on_screen_orientation_changed() -> void:
	var w_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())
	var orientation_extents: Rect2i = DisplayServer.get_display_safe_area()
	
	var margin_l: int = orientation_extents.position.x
	var margin_t: int = orientation_extents.position.y
	var margin_r: int = w_size.x - orientation_extents.size.x - margin_l
	var margin_b: int = w_size.y - orientation_extents.size.y - margin_t
	print("SAFE AREA CHANGED to: ", orientation_extents, ", w_size: ", w_size, ", margin_l: ", margin_l, ", margin_t: ", margin_t, ", margin_r: ", margin_r, ", margin_b: ", margin_b)
	Globals.safe_margin_l = margin_l
	Globals.safe_margin_t = margin_t
	Globals.safe_margin_r = margin_r
	Globals.safe_margin_b = margin_b
	current_safe_area = DisplayServer.get_display_safe_area()
	SignalManager.orientation_changed.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Utils.current_safe_area != DisplayServer.get_display_safe_area():
		Utils.on_screen_orientation_changed()
	
	if multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
		multiplayer.poll()
