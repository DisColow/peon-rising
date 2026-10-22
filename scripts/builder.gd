class_name Builder
extends Object

# Factory helpers for building simple cartoon meshes + colliders in code.
# Everything is created procedurally to keep the project light and portable.

const TOON := preload("res://shaders/toon.gdshader")

static func mat(color: Color, roughness: float = 0.7) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("roughness", roughness)
	return m

static func box(size: Vector3, color: Color, roughness: float = 0.7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color, roughness)
	return mi

static func sphere(radius: float, color: Color, roughness: float = 0.7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat(color, roughness)
	return mi

static func capsule(radius: float, height: float, color: Color, roughness: float = 0.7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat(color, roughness)
	return mi

static func cylinder(radius: float, height: float, color: Color, roughness: float = 0.7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat(color, roughness)
	return mi

static func cone(radius: float, height: float, color: Color, roughness: float = 0.7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat(color, roughness)
	return mi

static func collider(parent: Node, shape: Shape3D) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	parent.add_child(cs)
	return cs

static func box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s

static func sphere_shape(radius: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = radius
	return s

static func capsule_shape(radius: float, height: float) -> CapsuleShape3D:
	var s := CapsuleShape3D.new()
	s.radius = radius
	s.height = height
	return s
