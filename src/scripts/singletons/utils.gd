extends Node

signal long_press(input: String)
signal short_press(input: String)
signal long_hold(input: String)
signal start_long_hold(input: String)

const SHORT_LONG_THRESHOLD: float = 0.1
const LONG_HOLD_THRESHOLD: float = 0.15

var input_time_dictionary: Dictionary = {}

func _ready() -> void:
	for action in InputMap.get_actions():
		input_time_dictionary[action] = {"count": 0, "passed_threshold": false}

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
		_add_to_input_times(1.0)

func _process(delta: float) -> void:
	_add_to_input_times(delta)

func _add_to_input_times(delta: float) -> void:
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			if input_time_dictionary[action].count >= LONG_HOLD_THRESHOLD: # Long press:
				if not input_time_dictionary[action].passed_threshold:
					start_long_hold.emit(action) # Trigger the start of a long hold
					input_time_dictionary[action].passed_threshold = true
					print("Wow")
				else:
					long_hold.emit(action) # Trigger a long hold
			input_time_dictionary[action].count += delta
		elif Input.is_action_just_released(action):
			if input_time_dictionary[action].count < SHORT_LONG_THRESHOLD: # Short press
				short_press.emit(action) # Trigger a short input
			else:
				long_press.emit(action) # Trigger a long input
			input_time_dictionary[action].count = 0.0
			input_time_dictionary[action].passed_threshold = false
			# TODO: FIX WHATEVER TF IS HAPPENING WITH THE RIGHT CLICK MENU
			
