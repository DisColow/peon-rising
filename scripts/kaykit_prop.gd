class_name KayKitProp
extends Object

# Loads a static KayKit prop (building, tree, rock, resource…) with the same
# textured cel/toon shading as the characters, so the whole world shares one
# cohesive "cartoon clay" look.

const TOON_SHADER := preload("res://shaders/toon_textured.gdshader")

static var _white: ImageTexture

static func create(parent: Node, path: String, scale := 1.0) -> Node3D:
	var scene: PackedScene = load(path)
	if scene == null:
		push_warning("KayKitProp: cannot load %s" % path)
		return null
	var inst: Node3D = scene.instantiate()
	parent.add_child(inst)
	inst.scale = Vector3.ONE * scale
	_apply_toon(inst)
	return inst

# Combined AABB height of a model (its meshes), used to scale props to a target size.
static func node_height(n: Node) -> float:
	var box := AABB()
	var first := true
	for mi in _find_all(n, "MeshInstance3D"):
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		var a := m.transform * m.mesh.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	return box.size.y if not first else 0.0

# Combined AABB min-Y (the prop's base), used to sit props on the ground.
static func node_base_y(n: Node) -> float:
	var box := AABB()
	var first := true
	for mi in _find_all(n, "MeshInstance3D"):
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		var a := m.transform * m.mesh.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	return box.position.y if not first else 0.0

# Scale a loaded prop so its height matches target_h and its base sits on y=0.
static func scale_to_height(model: Node3D, target_h: float) -> void:
	if model == null:
		return
	var h := node_height(model)
	if h <= 0.01:
		return
	var base := node_base_y(model)
	var scale := target_h / h
	model.scale = Vector3.ONE * scale
	model.position.y = -base * scale

static func _apply_toon(inst: Node) -> void:
	for mi in _find_all(inst, "MeshInstance3D"):
		var m: MeshInstance3D = mi
		var mesh := m.mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var mat := m.get_surface_override_material(s)
			if mat == null:
				mat = mesh.surface_get_material(s)
			var tex: Texture2D = null
			if mat != null and mat is BaseMaterial3D:
				tex = (mat as BaseMaterial3D).albedo_texture
			var sm := ShaderMaterial.new()
			sm.shader = TOON_SHADER
			sm.set_shader_parameter("albedo_tex", tex if tex != null else _white_tex())
			m.set_surface_override_material(s, sm)

static func _find_all(n: Node, cls: String) -> Array:
	var out: Array = []
	if cls == "MeshInstance3D" and n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_all(c, cls))
	return out

static func _white_tex() -> ImageTexture:
	if _white == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	return _white
