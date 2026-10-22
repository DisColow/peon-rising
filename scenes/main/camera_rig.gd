extends Camera3D

# First-person camera: mouse look (yaw/pitch), smooth follow at head height.
# The player reads `yaw` to move relative to where the camera is facing.

const MOUSE_SENS := 0.0025

var target: Node3D = null
var yaw: float = 0.0
var pitch: float = -0.12
var head_height: float = 1.62

func setup(t: Node3D) -> void:
	target = t
	current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * MOUSE_SENS
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -1.45, 1.45)
	elif event is InputEventScreenDrag:
		yaw -= event.relative.x * 0.004
		pitch = clampf(pitch - event.relative.y * 0.004, -1.45, 1.45)

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	rotation = Vector3(pitch, yaw, 0.0)
	var focus := target.global_position + Vector3(0, head_height, 0)
	global_position = global_position.lerp(focus, 1.0 - exp(-28.0 * delta))
