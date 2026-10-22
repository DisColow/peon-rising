extends SceneTree

# Validates the weapon-grip convention used by worker.gd / grunt.gd: the KayKit
# handslot bone must have local +Z = world up and local +Y = world forward, so
# that handles run vertical and blades/club-heads extend upward. Run with
# --headless --script res://tests/test_weapon_grip.gd

var _fail := 0

func _initialize() -> void:
	for path in ["res://assets/models/kaykit/Knight.glb",
			"res://assets/models/kaykit/Barbarian.glb",
			"res://assets/models/kaykit/Skeleton_Warrior.glb"]:
		_check_model(path)
	print("WEAPON_GRIP fail=%d" % _fail)
	quit(0 if _fail == 0 else 1)

func _check_model(path: String) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var rig := KayKitRig.create(world, path, 1.0)
	var sk: Skeleton3D = rig.skeleton
	var file := path.get_file()
	if sk == null:
		_check(false, file + " has Skeleton3D")
		return
	var bone := "handslot.r" if sk.find_bone("handslot.r") >= 0 else "hand.r"
	_check(sk.find_bone(bone) >= 0, file + " has grip bone '" + bone + "'")
	if sk.find_bone(bone) < 0:
		return
	var idx := sk.find_bone(bone)
	var rest := sk.get_bone_global_rest(idx)
	var o: Vector3 = rest.origin
	var z: Vector3 = rest.basis.z
	var y: Vector3 = rest.basis.y
	_check(absf(z.y - 1.0) < 0.05, file + " grip +Z is world up (got %+.2f,%+.2f,%+.2f)" % [z.x, z.y, z.z])
	_check(absf(y.z - 1.0) < 0.05, file + " grip +Y is world forward (got %+.2f,%+.2f,%+.2f)" % [y.x, y.y, y.z])
	_check(o.y > 0.8 and o.y < 1.4, file + " grip at hand height (y=%.2f)" % o.y)
	_check(absf(o.x) > 0.3, file + " grip displaced sideways (x=%.2f)" % o.x)

func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK   ", label)
	else:
		_fail += 1
		print("FAIL ", label)
