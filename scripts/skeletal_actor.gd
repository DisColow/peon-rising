class_name SkeletalActor
extends Node3D

# Loads a real, artist-made GLB model (with skeletal animation) and drives its
# AnimationPlayer. This is the pipeline for dropping real animated characters
# into the game, replacing the procedural UnitRig where needed.

var _anim: AnimationPlayer
var _move_anim: String = ""
var _idle_anim: String = ""

static func create(parent: Node, glb_path: String, scale := 1.0) -> SkeletalActor:
	var actor := SkeletalActor.new()
	parent.add_child(actor)
	actor._load(glb_path, scale)
	return actor

func _load(glb_path: String, scale: float) -> void:
	var scene: PackedScene = load(glb_path)
	if scene == null:
		push_warning("SkeletalActor: cannot load %s" % glb_path)
		return
	var inst := scene.instantiate()
	add_child(inst)
	inst.scale = Vector3.ONE * scale
	_anim = _find_anim(inst)
	if _anim == null:
		push_warning("SkeletalActor: no AnimationPlayer in %s" % glb_path)
		return
	# Remember the first animation as the movement clip (and idle if a 2nd exists).
	var names := _anim.get_animation_list()
	if names.size() > 0:
		_move_anim = names[0]
	if names.size() > 1:
		_idle_anim = names[1]

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

# Drive movement animation by horizontal speed. Returns the animation name.
func set_moving(moving: bool) -> String:
	if _anim == null:
		return ""
	var target := (_move_anim if moving else (_idle_anim if _idle_anim != "" else _move_anim))
	if target == "":
		return ""
	if _anim.current_animation != target:
		_anim.play(target)
	_anim.speed_scale = 1.0
	return target

func is_animating() -> bool:
	return _anim != null and _anim.is_playing()
