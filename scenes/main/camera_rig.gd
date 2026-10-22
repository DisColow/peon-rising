extends Camera3D

# First-person camera: mouse/gamepad look (yaw/pitch), smooth follow at head
# height, plus a simple screen shake. The player reads `yaw` to move relative
# to where the camera is facing.

const MOUSE_SENS := 0.0025
const GAMEPAD_SENS := 2.6  # radians per second at full stick deflection

var target: Node3D = null
var yaw: float = 0.0
var pitch: float = -0.12
var head_height: float = 1.62

var _shake: float = 0.0

func setup(t: Node3D) -> void:
	target = t
	current = true

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var s := MOUSE_SENS * Settings.mouse_sensitivity
		yaw -= event.relative.x * s
		pitch = clampf(pitch - event.relative.y * s, -1.45, 1.45)
	elif event is InputEventScreenDrag:
		yaw -= event.relative.x * 0.004
		pitch = clampf(pitch - event.relative.y * 0.004, -1.45, 1.45)

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	# Gamepad / Steam Deck right-stick look.
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look.length_squared() > 0.01:
		yaw -= look.x * GAMEPAD_SENS * delta
		pitch = clampf(pitch - look.y * GAMEPAD_SENS * delta, -1.45, 1.45)

	rotation = Vector3(pitch, yaw, 0.0)
	var focus := target.global_position + Vector3(0, head_height, 0)
	global_position = global_position.lerp(focus, 1.0 - exp(-28.0 * delta))

	# Screen shake: random rotational jitter that decays over time.
	if _shake > 0.001:
		_shake = maxf(0.0, _shake - delta * 2.4)
		var s := _shake * 0.05
		rotation.x += randf_range(-s, s)
		rotation.y += randf_range(-s, s)
