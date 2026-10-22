extends SceneTree

# Game-feel & real-model validation:
#   1. KayKitRig loads a real rigged+textured model, applies the cel/toon shader
#      (textured) and exposes its animation library.
#   2. FX.hit_stop freezes time (weighty hits).
#   3. FX.burst spawns impact particles.
# Run: godot --headless --script res://tests/test_game_feel.gd

var _pass := 0
var _fail := 0

func _initialize() -> void:
	_main()

func _main() -> void:
	_test_rig()

	Engine.time_scale = 1.0
	FX.hit_stop(self, 0.05, 0.1)
	_check(absf(Engine.time_scale - 0.1) < 0.001, "hit_stop drops time_scale (got %.3f)" % Engine.time_scale)
	await create_timer(0.12, true, false, true).timeout
	_check(Engine.time_scale > 0.99, "hit_stop auto-recovers (got %.3f)" % Engine.time_scale)

	var world := Node3D.new()
	root.add_child(world)
	var before := world.get_child_count()
	FX.burst(world, Vector3.ZERO, Color.WHITE, 12)
	_check(world.get_child_count() - before >= 12, "FX.burst spawned particles")

	await create_timer(0.1, true, false, true).timeout
	print("GAME_FEEL pass=%d fail=%d" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)

func _check(ok: bool, label: String) -> void:
	if ok:
		_pass += 1
		print("OK   ", label)
	else:
		_fail += 1
		print("FAIL ", label)

func _test_rig() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var rig := KayKitRig.create(world, "res://assets/models/kaykit/Knight.glb", 1.2)
	_check(rig != null and rig.anim != null, "KayKitRig loaded Knight + AnimationPlayer")
	if rig.anim != null:
		var names: Array = rig.anim.get_animation_list()
		_check(names.has("Walking_A") and names.has("1H_Melee_Attack_Chop") and names.has("Death_A"),
			"KayKitRig has walk/attack/death clips")
	_check(rig.head != null, "KayKitRig head BoneAttachment")
	_check(rig.tool_r != null, "KayKitRig hand BoneAttachment")
	var shaded := 0
	var total := 0
	for n in _collect(rig, "MeshInstance3D"):
		var m: MeshInstance3D = n
		if m.mesh == null:
			continue
		for s in m.mesh.get_surface_count():
			total += 1
			var mat := m.get_surface_override_material(s)
			if mat != null and mat is ShaderMaterial and (mat as ShaderMaterial).shader == KayKitRig.TOON_SHADER:
				shaded += 1
	_check(total > 0 and shaded == total, "cel-shader on all %d surfaces (%d shaded)" % [total, shaded])

func _collect(n: Node, cls: String) -> Array:
	var out: Array = []
	if cls == "MeshInstance3D" and n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_collect(c, cls))
	return out
