extends Node

signal enhanced_inputs(inputs: Dictionary)
enum INPUT_TYPE {START_SHORT_HOLD, SHORT_PRESS, LONG_PRESS, SHORT_HOLD, START_LONG_HOLD, LONG_HOLD}

const KEYPRESS_THRESHOLD: float = 0.2

var input_time_dictionary: Dictionary = {}

var reparenting_requests: Array = []

func _ready() -> void:
	for action in InputMap.get_actions():
		input_time_dictionary[action] = {"count": 0.0, "passed_threshold": false, "action_was_pressed": false}

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

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		_add_to_input_times(2.0, true)

func _process(delta: float) -> void:
	_add_to_input_times(delta, false)
	_check_inputs()
	_check_reparenting_necessary()

func _check_reparenting_necessary() -> void:
	if reparenting_requests.is_empty(): return
	# If there are open reparenting infos, emit the signal
	rpc("reparent_nodes", reparenting_requests)
	reparenting_requests = []

@rpc("any_peer","call_remote", "reliable")
func reparent_nodes(requests: Array) -> void:
	var game_object_manager: GameObjectManager = get_tree().get_first_node_in_group("game_object_manager")
	for request in requests:
		var node_child: Node = get_tree().get_first_node_in_group(request[0])
		var node_parent: Node = get_tree().get_first_node_in_group(request[1]).game_objects if request[1] != "NONE" else game_object_manager
		node_child.reparent(node_parent)


func _add_to_input_times(delta: float, mouse_only: bool) -> void:
	for action in InputMap.get_actions():
		if InputMap.action_get_events(action).is_empty():
			continue
		if mouse_only and not InputMap.action_get_events(action)[0] is InputEventMouseButton:
			continue
		if Input.is_action_pressed(action):
			input_time_dictionary[action].count += delta

func _check_inputs() -> void:
	var input_actions: Dictionary = {}	
	for action in InputMap.get_actions():
		if not input_time_dictionary[action].action_was_pressed and Input.is_action_pressed(action):
			input_time_dictionary[action].action_was_pressed = true
			input_actions[action] = INPUT_TYPE.START_SHORT_HOLD # Trigger the start of a short hold
		elif Input.is_action_pressed(action):
			input_time_dictionary[action].action_was_pressed = true
			if input_time_dictionary[action].count >= KEYPRESS_THRESHOLD: # Long press:
				if not input_time_dictionary[action].passed_threshold:
					input_actions[action] = INPUT_TYPE.START_LONG_HOLD # Trigger the start of a long hold
					input_time_dictionary[action].passed_threshold = true
				else:
					input_actions[action] = INPUT_TYPE.LONG_HOLD # Trigger a long hold
			else:
				input_actions[action] = INPUT_TYPE.SHORT_HOLD # Trigger a short hold
		elif input_time_dictionary[action].action_was_pressed:
			input_time_dictionary[action].action_was_pressed = false
			if input_time_dictionary[action].count < KEYPRESS_THRESHOLD: # Short press
				input_actions[action] = INPUT_TYPE.SHORT_PRESS # Trigger a short press
				input_time_dictionary[action].count = 0.0
				input_time_dictionary[action].passed_threshold = false
			else:
				input_actions[action] = INPUT_TYPE.LONG_PRESS # Trigger a long press
				input_time_dictionary[action].count = 0.0
				input_time_dictionary[action].passed_threshold = false
	if not input_actions.keys().is_empty():
		enhanced_inputs.emit(input_actions)

func just_short_released(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.SHORT_PRESS

func just_short_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.START_SHORT_HOLD

func short_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.SHORT_HOLD
	
func just_long_released(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.LONG_PRESS

func just_long_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.START_LONG_HOLD

func long_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.LONG_HOLD

func just_held(action: String, input_actions: Dictionary) -> bool:
	return just_short_held(action, input_actions) or just_long_held(action, input_actions)
	
func held(action: String, input_actions: Dictionary) -> bool:
	return short_held(action, input_actions) or long_held(action, input_actions)

func just_released(action: String, input_actions: Dictionary) -> bool:
	return just_short_released(action, input_actions) or just_long_released(action, input_actions)

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

func load_images_from_directory(dir: String) -> Dictionary:
	var textures: Dictionary = {}
	var directory_access = DirAccess.open(dir)
	if directory_access.dir_exists("."):
		for fname in directory_access.get_files():
			var file_ext: String = fname.rsplit(".")[-1]
			if file_ext in ["png", "jpg", "jpeg", "bmp"]:
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
