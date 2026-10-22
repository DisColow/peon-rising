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
	_key_action("cancel_order", [KEY_C])
	_key_action("open_talents", [KEY_T])
	_key_action("open_influence", [KEY_I])
	_key_action("interact", [KEY_E])
	_mouse_action("ping", MOUSE_BUTTON_LEFT)

func _key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _mouse_action(action: String, button: int) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
