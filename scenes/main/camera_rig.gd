extends Camera3D

# Third-person camera that smoothly follows the worker. Orbit with the right
# mouse button, zoom with the scroll wheel.

var target: Node3D = null
var yaw: float = 0.0
var pitch: float = -24.0
var distance: float = 9.0

func setup(t: Node3D) -> void:
	target = t
	current = true
	global_position = t.global_position + _offset()

func _offset() -> Vector3:
	var d := Vector3(0, 0, distance)
	d = d.rotated(Vector3(1, 0, 0), deg_to_rad(pitch))
	d = d.rotated(Vector3(0, 1, 0), yaw)
	return d

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var focus := target.global_position + Vector3(0, 1.1, 0)
	var desired := focus + _offset()
	global_position = global_position.lerp(desired, 1.0 - exp(-8.0 * delta))
	look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.005
		pitch = clampf(pitch - event.relative.y * 0.005, -70.0, -5.0)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = clampf(distance - 1.0, 4.0, 18.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance = clampf(distance + 1.0, 4.0, 18.0)
	elif event is InputEventScreenDrag:
		yaw -= event.relative.x * 0.005
		pitch = clampf(pitch - event.relative.y * 0.005, -70.0, -5.0)
	elif event is InputEventMagnifyGesture:
		distance = clampf(distance / event.factor, 4.0, 18.0)
