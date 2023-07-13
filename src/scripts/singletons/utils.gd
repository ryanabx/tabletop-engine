extends Node

signal enhanced_inputs(inputs: Dictionary)
enum INPUT_TYPE {START_SHORT_HOLD, SHORT_PRESS, LONG_PRESS, SHORT_HOLD, START_LONG_HOLD, LONG_HOLD}

const KEYPRESS_THRESHOLD: float = 0.2

var input_time_dictionary: Dictionary = {}

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
	var result: Array = []
	var _image = Image.new()
	var _err = _image.load(image_directory + fname)
	if _err != OK:
		print("Failed to load image: ",image_directory + fname)
	var _texture = ImageTexture.new()
	_texture = ImageTexture.create_from_image(_image)
	return _texture

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		_add_to_input_times(2.0, true)

func _process(delta: float) -> void:
	_add_to_input_times(delta, false)

func _add_to_input_times(delta: float, mouse_only: bool) -> void:
	var input_actions: Dictionary = {}
	for action in InputMap.get_actions():
		if InputMap.action_get_events(action).is_empty() or (not InputMap.action_get_events(action)[0] is InputEventMouseButton and mouse_only):
			continue
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
			input_time_dictionary[action].count += delta
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

func is_action_just_short_released(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.SHORT_PRESS

func is_action_just_short_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.START_SHORT_HOLD

func is_action_short_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.SHORT_HOLD
	
func is_action_just_long_released(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.LONG_PRESS

func is_action_just_long_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.START_LONG_HOLD

func is_action_long_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == Utils.INPUT_TYPE.LONG_HOLD

func is_action_just_held(action: String, input_actions: Dictionary) -> bool:
	return is_action_just_short_held(action, input_actions) or is_action_just_long_held(action, input_actions)
	
func is_action_held(action: String, input_actions: Dictionary) -> bool:
	return is_action_short_held(action, input_actions) or is_action_long_held(action, input_actions)

func is_action_just_released(action: String, input_actions: Dictionary) -> bool:
	return is_action_just_short_released(action, input_actions) or is_action_just_long_released(action, input_actions)
