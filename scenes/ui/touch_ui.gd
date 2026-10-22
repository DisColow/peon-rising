extends CanvasLayer

# Virtual touch controls for Android / touch devices: a left joystick (move),
# right-side drag (look, handled by the camera) and action/dash buttons.

var _base: Panel
var _knob: Panel
var _joy_id: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _joy_radius: float = 58.0

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		queue_free()
		return
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	_base = _circle(150.0, Color(1, 1, 1, 0.12))
	_base.visible = false
	add_child(_base)

	_knob = _circle(64.0, Color(1, 1, 1, 0.3))
	_knob.visible = false
	add_child(_knob)

	var action := Button.new()
	action.text = "AGIR"
	action.custom_minimum_size = Vector2(130, 130)
	action.add_theme_font_size_override("font_size", 22)
	action.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action.position = Vector2(-150, -150)
	action.button_down.connect(func(): GameState.touch_action_pressed = true)
	add_child(action)

	var dash := Button.new()
	dash.text = "DASH"
	dash.custom_minimum_size = Vector2(100, 100)
	dash.add_theme_font_size_override("font_size", 18)
	dash.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dash.position = Vector2(-280, -190)
	dash.button_down.connect(func(): GameState.touch_dash_pressed = true)
	add_child(dash)

func _circle(size: float, color: Color) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	var r := int(size * 0.5)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	p.add_theme_stylebox_override("panel", sb)
	return p

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

func _handle_touch(t: InputEventScreenTouch) -> void:
	var half := get_viewport().get_visible_rect().size.x * 0.5
	if t.pressed:
		if t.position.x < half:
			_joy_id = t.index
			_joy_center = t.position
			_base.visible = true
			_knob.visible = true
			_base.position = _joy_center - Vector2(75, 75)
			_knob.position = _joy_center - Vector2(32, 32)
			GameState.touch_move = Vector2.ZERO
			get_viewport().set_input_as_handled()
	else:
		if t.index == _joy_id:
			_joy_id = -1
			_base.visible = false
			_knob.visible = false
			GameState.touch_move = Vector2.ZERO
			get_viewport().set_input_as_handled()

func _handle_drag(d: InputEventScreenDrag) -> void:
	if d.index == _joy_id:
		var dv: Vector2 = d.position - _joy_center
		var clamped: Vector2 = dv.limit_length(_joy_radius)
		_knob.position = _joy_center + clamped - Vector2(32, 32)
		GameState.touch_move = clamped / _joy_radius
		get_viewport().set_input_as_handled()
