extends Node

# Sets up global input actions and engine-wide defaults before the game starts.

func _ready() -> void:
	Engine.max_fps = 60
	_setup_input()

func _setup_input() -> void:
	_key_action("move_forward", [KEY_W, KEY_UP])
	_key_action("move_back", [KEY_S, KEY_DOWN])
	_key_action("move_left", [KEY_A, KEY_LEFT])
	_key_action("move_right", [KEY_D, KEY_RIGHT])
	_key_action("sprint", [KEY_SHIFT])
	_key_action("dash", [KEY_SPACE])
	_key_action("open_talents", [KEY_T])
	_key_action("open_influence", [KEY_I])
	_key_action("pause", [KEY_ESCAPE])
	_key_action("suggest_attack", [KEY_1])
	_key_action("suggest_defend", [KEY_2])
	_key_action("suggest_gold", [KEY_3])
	_key_action("suggest_wood", [KEY_4])

	# Interact: left mouse button (primary action) or E key.
	if InputMap.has_action("interact"):
		InputMap.erase_action("interact")
	InputMap.add_action("interact")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("interact", click)
	var key_e := InputEventKey.new()
	key_e.physical_keycode = KEY_E
	InputMap.action_add_event("interact", key_e)

	# Gamepad / Steam Deck support (left stick move, right stick look).
	_joy_axis_action("move_left", JOY_AXIS_LEFT_X, -1.0)
	_joy_axis_action("move_right", JOY_AXIS_LEFT_X, 1.0)
	_joy_axis_action("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_joy_axis_action("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_joy_axis_action("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_joy_axis_action("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_joy_axis_action("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_joy_axis_action("look_down", JOY_AXIS_RIGHT_Y, 1.0)
	_joy_button_action("interact", [JOY_BUTTON_A])
	_joy_button_action("sprint", [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_B])
	_joy_button_action("dash", [JOY_BUTTON_X])
	_joy_button_action("pause", [JOY_BUTTON_START])
	_joy_button_action("open_talents", [JOY_BUTTON_Y])

func _key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _joy_button_action(action: String, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for b in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = b
		InputMap.action_add_event(action, ev)

func _joy_axis_action(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)

func _mouse_action(action: String, button: int) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
