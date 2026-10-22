extends SceneTree

# Objective "fidelity" metric: reports the triangle count and texture resolution
# of the real KayKit models (characters + world). Proves the assets are textured,
# high-poly models — not the 12-triangle primitives the world was built from before.

var _fail := 0

var MODELS := [
	"res://assets/models/kaykit/Knight.glb",
	"res://assets/models/kaykit_props/buildings_green/building_castle_green.gltf",
	"res://assets/models/kaykit_props/buildings_green/building_barracks_green.gltf",
	"res://assets/models/kaykit_props/buildings_green/building_tower_A_green.gltf",
	"res://assets/models/kaykit_props/nature/tree_single_A.gltf",
]

func _initialize() -> void:
	var world := Node3D.new()
	root.add_child(world)
	for p in MODELS:
		_measure(world, p)
	print("FIDELITY fail=%d" % _fail)
	quit(0 if _fail == 0 else 1)

func _measure(parent: Node, path: String) -> void:
	var sc: PackedScene = load(path)
	if sc == null:
		_check(false, path.get_file() + " loads")
		return
	var inst: Node3D = sc.instantiate()
	parent.add_child(inst)
	var tris := 0
	var max_tex := 0
	for mi in _find(inst, "MeshInstance3D"):
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		for s in m.mesh.get_surface_count():
			var arrays: Array = m.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var n := idx.size() if idx.size() > 0 else verts.size()
			tris += n / 3
		var mat := m.get_active_material(0)
		if mat != null and mat is BaseMaterial3D:
			var tex: Texture2D = (mat as BaseMaterial3D).albedo_texture
			if tex != null:
				max_tex = maxi(max_tex, tex.get_width())
	var name := path.get_file()
	print("FIDELITY %-30s tris=%-6d tex=%dpx" % [name, tris, max_tex])
	_check(tris >= 24, "%s >= 24 triangles (got %d)" % [name, tris])
	_check(max_tex >= 256, "%s has texture >= 256px (got %d)" % [name, max_tex])
	inst.queue_free()

func _find(n: Node, cls: String) -> Array:
	var out: Array = []
	if cls == "MeshInstance3D" and n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find(c, cls))
	return out

func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK   ", label)
	else:
		_fail += 1
		print("FAIL ", label)
