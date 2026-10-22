extends RigidBody3D

# A tree. It starts frozen (static) and topples with real physics once fully
# chopped, before fading away. Yields wood while being chopped.

const WOOD_PER_CHOP := 6.0
const MAX_WOOD := 44.0
const VARIANCE := 0.7

var wood_left: float = MAX_WOOD
var falling: bool = false

func _ready() -> void:
	add_to_group("tree")
	add_to_group("resource")
	wood_left = MAX_WOOD * randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_build_visual()

func _build_visual() -> void:
	var h := randf_range(2.6, 3.4)
	var trunk := Builder.cylinder(0.22, h, GameData.COLOR_TREE_TRUNK)
	trunk.position = Vector3(0, h * 0.5, 0)
	add_child(trunk)

	var foliage_h := randf_range(1.2, 1.8)
	var base_r := randf_range(0.9, 1.2)
	var f1 := Builder.cone(base_r, foliage_h, GameData.COLOR_TREE_LEAVES)
	f1.position = Vector3(0, h + foliage_h * 0.4, 0)
	add_child(f1)
	var f2 := Builder.cone(base_r * 0.7, foliage_h * 0.8, GameData.COLOR_TREE_LEAVES_DARK)
	f2.position = Vector3(0, h + foliage_h * 0.85, 0)
	add_child(f2)

	Builder.collider(self, Builder.box_shape(Vector3(0.55, h + foliage_h * 1.2, 0.55)))
	var cs := get_child(get_child_count() - 1) as CollisionShape3D
	cs.position = Vector3(0, (h + foliage_h * 1.2) * 0.45, 0)

func chop(multiplier: float = 1.0) -> float:
	if is_empty():
		return 0.0
	var amount := minf(WOOD_PER_CHOP * multiplier, wood_left)
	wood_left -= amount
	if wood_left <= 0.0 and not falling:
		_topple()
	return amount

func is_empty() -> bool:
	return wood_left <= 0.0

func _topple() -> void:
	falling = true
	freeze = false
	var dir := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	apply_central_impulse(dir * 1.2)
	apply_torque_impulse(dir.cross(Vector3.UP) * 3.5)
	var t := create_tween()
	t.tween_interval(3.0)
	t.tween_callback(_fade_out)

func _fade_out() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)
