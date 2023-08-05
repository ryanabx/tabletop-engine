extends Node

signal enhanced_inputs(inputs: Dictionary)
enum INPUT_TYPE {START_SHORT_HOLD, SHORT_PRESS, LONG_PRESS, SHORT_HOLD, START_LONG_HOLD, LONG_HOLD}

const KEYPRESS_THRESHOLD: float = 0.2

var input_time_dictionary: Dictionary = {}

func _ready() -> void:
	for action in InputMap.get_actions():
		input_time_dictionary[action] = {"count": 0.0, "passed_threshold": false, "action_was_pressed": false}	

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		_add_to_input_times(2.0, true)

func _process(delta: float) -> void:
	_add_to_input_times(delta, false)
	_check_inputs()

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
	return action in input_actions and input_actions[action] == INPUT_TYPE.SHORT_PRESS

func just_short_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == INPUT_TYPE.START_SHORT_HOLD

func short_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == INPUT_TYPE.SHORT_HOLD
	
func just_long_released(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == INPUT_TYPE.LONG_PRESS

func just_long_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == INPUT_TYPE.START_LONG_HOLD

func long_held(action: String, input_actions: Dictionary) -> bool:
	return action in input_actions and input_actions[action] == INPUT_TYPE.LONG_HOLD

func just_held(action: String, input_actions: Dictionary) -> bool:
	return just_short_held(action, input_actions) or just_long_held(action, input_actions)
	
func held(action: String, input_actions: Dictionary) -> bool:
	return short_held(action, input_actions) or long_held(action, input_actions)

func just_released(action: String, input_actions: Dictionary) -> bool:
	return just_short_released(action, input_actions) or just_long_released(action, input_actions)

# Custom input actions

## Fired as true when inputs to select are pressed
func is_select_pressed(input_actions: Dictionary) -> bool:
	return just_long_held("game_select", input_actions)

## Fired as true when inputs to stack select are pressed
func is_stack_select_pressed(input_actions: Dictionary) -> bool:
	return just_long_held("game_select_stack", input_actions)

## Fired as true when menu button is pressed
func is_menu_pressed(input_actions: Dictionary) -> bool:
	return just_short_released("game_menu", input_actions)

func is_deselect_pressed(input_actions: Dictionary) -> bool:
	return just_long_released("game_select", input_actions) or just_long_released("game_select_stack", input_actions)

func is_flip_pressed(input_actions: Dictionary) -> bool:
	return just_released("game_flip", input_actions)