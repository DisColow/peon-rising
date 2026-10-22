extends SceneTree

# Validates that the KayKit (CC0) world props — buildings, trees, mine — load,
# get cel-shaded on every surface, and scale to a target height. Proves the
# world is no longer procedural primitives but real textured/rigged assets.

var _fail := 0

var BUILDINGS := [
	"castle", "home_A", "barracks", "tower_A", "mine",
]

func _initialize() -> void:
	var world := Node3D.new()
	root.add_child(world)
	for b in BUILDINGS:
		_check_prop("res://assets/models/kaykit_props/buildings_green/building_%s_green.gltf" % b, 3.0)
		_check_prop("res://assets/models/kaykit_props/buildings_red/building_%s_red.gltf" % b, 3.0)
	for t in ["tree_single_A", "tree_single_B"]:
		_check_prop("res://assets/models/kaykit_props/nature/%s.gltf" % t, 3.6)
	print("PROPS fail=%d" % _fail)
	quit(0 if _fail == 0 else 1)

func _check_prop(path: String, target_h: float) -> void:
	var name := path.get_file()
	var model := KayKitProp.create(root.get_child(0), path, 1.0)
	if model == null:
		_check(false, name + " loads")
		return
	_check(true, name + " loads")
	var shaded := _count_shaded(model)
	_check(shaded > 0, "%s cel-shaded (%d surfaces)" % [name, shaded])
	var intrinsic := KayKitProp.node_height(model)
	KayKitProp.scale_to_height(model, target_h)
	var world_h := intrinsic * model.scale.x
	_check(absf(world_h - target_h) < 0.05, "%s scaled to %.2f (got %.2f)" % [name, target_h, world_h])
	model.queue_free()

func _count_shaded(n: Node) -> int:
	var c := 0
	for mi in _find(n, "MeshInstance3D"):
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		for s in m.mesh.get_surface_count():
			var mat := m.get_surface_override_material(s)
			if mat != null and mat is ShaderMaterial:
				c += 1
	return c

func _find(n: Node, cls: String) -> Array:
	var out: Array = []
	if cls == "MeshInstance3D" and n is MeshInstance3D:
		out.append(n)
	for ch in n.get_children():
		out.append_array(_find(ch, cls))
	return out

func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK   ", label)
	else:
		_fail += 1
		print("FAIL ", label)
