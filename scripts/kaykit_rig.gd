class_name KayKitRig
extends Node3D

# Real, artist-made rigged+textured character (KayKit, CC0) with its embedded
# animation library. Exposes the same interface as UnitRig so units can swap
# procedural primitives for real models transparently.

var anim: AnimationPlayer = null
var skeleton: Skeleton3D = null
var head: Node3D = null      # BoneAttachment3D on the head bone
var tool_r: Node3D = null    # BoneAttachment3D on the right hand (weapon grip)
var carry_slot: Node3D = null

var idle_anim := "Idle"
var walk_anim := "Walking_A"
var attack_anim := "1H_Melee_Attack_Chop"
var death_anim := "Death_A"

var _yaw_offset := 0.0

static func create(parent: Node, model_path: String, scale := 1.0, yaw_offset := 0.0) -> KayKitRig:
	var rig := KayKitRig.new()
	parent.add_child(rig)
	rig._load(model_path, scale, yaw_offset)
	return rig

func _load(model_path: String, scale: float, yaw_offset: float) -> void:
	_yaw_offset = yaw_offset
	var scene: PackedScene = load(model_path)
	if scene == null:
		push_warning("KayKitRig: cannot load %s" % model_path)
		return
	var inst: Node3D = scene.instantiate()
	add_child(inst)
	inst.scale = Vector3.ONE * scale
	inst.rotation.y = yaw_offset
	anim = _find(inst, "AnimationPlayer")
	skeleton = _find(inst, "Skeleton3D")
	if skeleton != null:
		head = _bone_attach(skeleton, "head")
		tool_r = _bone_attach(skeleton, "handslot.r")
		if tool_r == null:
			tool_r = _bone_attach(skeleton, "hand.r")
	carry_slot = Node3D.new()
	carry_slot.position = Vector3(0, 2.1, 0)
	add_child(carry_slot)
	# Ensure attack/death clips are one-shot so update_animation resumes idle/walk.
	if anim != null:
		for one_shot in [attack_anim, death_anim]:
			var a := anim.get_animation(one_shot)
			if a != null:
				a.loop_mode = Animation.LOOP_NONE

func _find(n: Node, cls: String) -> Node:
	if cls == "AnimationPlayer" and n is AnimationPlayer:
		return n
	if cls == "Skeleton3D" and n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null

func _bone_attach(sk: Skeleton3D, bone_name: String) -> Node3D:
	if sk.find_bone(bone_name) < 0:
		return null
	var ba := BoneAttachment3D.new()
	ba.name = bone_name
	ba.bone_name = bone_name
	sk.add_child(ba)
	return ba

func update_animation(_delta: float, speed: float, moving: bool) -> void:
	if anim == null:
		return
	var cur := anim.current_animation
	if (cur == attack_anim or cur == death_anim) and anim.is_playing():
		return
	var target := walk_anim if moving else idle_anim
	if target == "":
		return
	if cur != target:
		anim.play(target)
	anim.speed_scale = clampf(speed / 4.0, 0.8, 1.8)

func swing_tool(_owner: Node, _time := 0.5) -> void:
	if anim == null or attack_anim == "":
		return
	anim.play(attack_anim)
	anim.seek(0.0, true)

func play_death() -> void:
	if anim == null or death_anim == "":
		return
	anim.play(death_anim)
