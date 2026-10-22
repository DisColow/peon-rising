extends RigidBody3D

# A tree. Every chop carves a visible notch into the trunk (with a little shake
# and flying wood chips), and once enough hits land it topples with real physics.

const WOOD_PER_CHOP := 6.0
const MAX_WOOD := 44.0
const VARIANCE := 0.7
const MAX_HITS := 8

var wood_left: float = MAX_WOOD
var falling: bool = false

var _visual: Node3D
var _trunk_height: float = 3.0
var _hits: int = 0
var _last_dir: Vector3 = Vector3.FORWARD

func _ready() -> void:
	add_to_group("tree")
	add_to_group("resource")
	wood_left = MAX_WOOD * randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_build_visual()

func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "TreeVisual"
	add_child(_visual)

	_trunk_height = randf_range(2.6, 3.4)

	# Tapered trunk (wider at the base).
	var trunk := Builder.cylinder(0.24, _trunk_height, GameData.COLOR_TREE_TRUNK)
	trunk.position = Vector3(0, _trunk_height * 0.5, 0)
	trunk.scale = Vector3(1.0, 1.0, 1.0)
	_visual.add_child(trunk)
	var base_flare := Builder.cone(0.4, 0.5, GameData.COLOR_TREE_TRUNK.darkened(0.1))
	base_flare.position = Vector3(0, 0.25, 0)
	_visual.add_child(base_flare)

	# Soft cloud canopy made of overlapping spheres.
	var base_r := randf_range(1.05, 1.4)
	var crown_y := _trunk_height + base_r * 0.55
	var lobes := [
		[Vector3(0, crown_y, 0), base_r],
		[Vector3(base_r * 0.6, crown_y + base_r * 0.25, base_r * 0.2), base_r * 0.72],
		[Vector3(-base_r * 0.6, crown_y + base_r * 0.2, -base_r * 0.2), base_r * 0.68],
		[Vector3(base_r * 0.25, crown_y + base_r * 0.5, -base_r * 0.55), base_r * 0.6],
		[Vector3(-base_r * 0.3, crown_y + base_r * 0.55, base_r * 0.5), base_r * 0.58],
	]
	for i in lobes.size():
		var pos: Vector3 = lobes[i][0]
		var r: float = lobes[i][1]
		var col := GameData.COLOR_TREE_LEAVES
		if i % 2 == 1:
			col = GameData.COLOR_TREE_LEAVES_DARK
		var lobe := Builder.sphere(r, col)
		lobe.position = pos
		_visual.add_child(lobe)

	Builder.collider(self, Builder.box_shape(Vector3(0.6, _trunk_height + base_r * 1.3, 0.6)))
	var cs := get_child(get_child_count() - 1) as CollisionShape3D
	cs.position = Vector3(0, (_trunk_height + base_r * 1.3) * 0.45, 0)

func chop(multiplier: float = 1.0, chopper: Node = null) -> float:
	if is_empty():
		return 0.0
	_hits += 1
	_spawn_notch(chopper)
	_shake()
	var amount := minf(WOOD_PER_CHOP * multiplier, wood_left)
	wood_left -= amount
	if _hits >= MAX_HITS or wood_left <= 0.0:
		_topple()
	return amount

func is_empty() -> bool:
	return wood_left <= 0.0

func _spawn_notch(chopper: Node) -> void:
	# Direction the blow came from, so the notch appears on the struck side.
	var dir := Vector3.FORWARD
	if chopper != null and chopper is Node3D:
		dir = global_position - (chopper as Node3D).global_position
		dir.y = 0.0
		if dir.length() < 0.01:
			dir = Vector3.FORWARD
		dir = dir.normalized()
	_last_dir = dir
	var height := 1.0 + randf_range(-0.25, 0.25) + float(_hits) * 0.08
	var notch := Builder.box(Vector3(0.06, 0.26, 0.08), GameData.COLOR_TREE_TRUNK.darkened(0.45))
	notch.position = Vector3(dir.x * 0.19, height, dir.z * 0.19)
	notch.rotation.y = atan2(dir.x, dir.z)
	_visual.add_child(notch)

func _shake() -> void:
	var t := create_tween()
	t.tween_property(_visual, "rotation:z", 0.04, 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_visual, "rotation:z", -0.04, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_visual, "rotation:z", 0.0, 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if get_parent() != null:
		FX.burst(get_parent(), global_position + Vector3(_last_dir.x * 0.2, 1.1, _last_dir.z * 0.2), GameData.COLOR_WOOD_STACK, 5, 0.3, 2.2, 0.4)

func _topple() -> void:
	if falling:
		return
	falling = true
	Sound.play("hit", 0.7)
	FX.hit_stop(get_tree(), 0.06, 0.08)
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
