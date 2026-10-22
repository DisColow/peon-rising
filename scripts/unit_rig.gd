class_name UnitRig
extends Node3D

# A procedurally-built cartoon character with a simple but lively walk/idle
# animation (limb swing + body bob), no external skeletal assets required.
# Units build one and call update_animation() every tick.

var body: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var tool_r: Node3D        # right-hand tool/weapon pivot (swing target)
var carry_slot: Node3D    # above the head, for carried resources

var _t := 0.0
var _skin: Color
var _armor: Color

static func create(parent: Node, body_color: Color, skin: Color, armor: Color) -> UnitRig:
	var rig := UnitRig.new()
	parent.add_child(rig)
	rig._skin = skin
	rig._armor = armor
	rig._build(body_color)
	return rig

func _build(body_color: Color) -> void:
	# Torso.
	body = Builder.capsule(0.42, 0.9, body_color)
	body.position = Vector3(0, 0.95, 0)
	add_child(body)

	# Belt / lower trim.
	var belt := Builder.box(Vector3(0.5, 0.16, 0.36), _armor)
	belt.position = Vector3(0, 0.62, 0)
	add_child(belt)

	# Head + face (eyes on the +Z "front" side).
	head = Node3D.new()
	head.position = Vector3(0, 1.7, 0)
	add_child(head)
	var skull := Builder.sphere(0.34, _skin)
	head.add_child(skull)
	for side in [-1.0, 1.0]:
		var eye_white := Builder.sphere(0.08, Color.WHITE)
		eye_white.position = Vector3(side * 0.14, 0.04, 0.28)
		head.add_child(eye_white)
		var pupil := Builder.sphere(0.04, Color(0.1, 0.1, 0.15))
		pupil.position = Vector3(side * 0.14, 0.04, 0.35)
		head.add_child(pupil)

	# Legs (hip pivots, so rotation swings them).
	leg_l = _limb_pivot(Vector3(-0.16, 0.62, 0))
	leg_r = _limb_pivot(Vector3(0.16, 0.62, 0))
	var leg_mesh_l := Builder.box(Vector3(0.22, 0.46, 0.26), _armor)
	leg_mesh_l.position = Vector3(0, -0.22, 0)
	leg_l.add_child(leg_mesh_l)
	var foot_l := Builder.box(Vector3(0.24, 0.1, 0.32), _armor.darkened(0.15))
	foot_l.position = Vector3(0, -0.46, 0.06)
	leg_l.add_child(foot_l)
	var leg_mesh_r := Builder.box(Vector3(0.22, 0.46, 0.26), _armor)
	leg_mesh_r.position = Vector3(0, -0.22, 0)
	leg_r.add_child(leg_mesh_r)
	var foot_r := Builder.box(Vector3(0.24, 0.1, 0.32), _armor.darkened(0.15))
	foot_r.position = Vector3(0, -0.46, 0.06)
	leg_r.add_child(foot_r)

	# Arms (shoulder pivots).
	arm_l = _limb_pivot(Vector3(-0.46, 1.32, 0))
	arm_r = _limb_pivot(Vector3(0.46, 1.32, 0))
	var arm_mesh_l := Builder.box(Vector3(0.16, 0.48, 0.18), _skin)
	arm_mesh_l.position = Vector3(0, -0.22, 0)
	arm_l.add_child(arm_mesh_l)
	var hand_l := Builder.sphere(0.1, _skin)
	hand_l.position = Vector3(0, -0.48, 0)
	arm_l.add_child(hand_l)

	var arm_mesh_r := Builder.box(Vector3(0.16, 0.48, 0.18), _skin)
	arm_mesh_r.position = Vector3(0, -0.22, 0)
	arm_r.add_child(arm_mesh_r)
	tool_r = Node3D.new()
	tool_r.position = Vector3(0, -0.48, 0)
	arm_r.add_child(tool_r)

	# Carry slot (above head).
	carry_slot = Node3D.new()
	carry_slot.position = Vector3(0, 2.1, 0)
	add_child(carry_slot)

func _limb_pivot(pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	add_child(p)
	return p

# Drive the procedural walk/idle animation. `moving` should reflect whether the
# unit is currently travelling.
func update_animation(delta: float, speed: float, moving: bool) -> void:
	if moving:
		_t += delta * (7.0 + speed * 1.5)
		var swing := sin(_t) * 0.7
		leg_l.rotation.x = swing
		leg_r.rotation.x = -swing
		arm_l.rotation.x = -swing * 0.6
		arm_r.rotation.x = swing * 0.6
		body.position.y = 0.95 + abs(sin(_t)) * 0.05
		body.rotation.x = 0.08
	else:
		_t += delta * 2.0
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, 0.25)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, 0.25)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, 0.25)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, 0.25)
		body.position.y = 0.95 + sin(_t) * 0.02
		body.rotation.x = lerpf(body.rotation.x, 0.0, 0.2)

# A quick attack/gather swing of the right-hand tool.
func swing_tool(tween_owner: Node, time := 0.45) -> void:
	if tool_r == null:
		return
	var t := tween_owner.create_tween()
	tool_r.rotation.x = -1.5
	t.tween_property(tool_r, "rotation:x", 0.55, time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(tool_r, "rotation:x", -1.5, time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
