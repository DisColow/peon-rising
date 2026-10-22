extends StaticBody3D

# The gold mine. Workers must walk up to its entrance to mine. Spawns physics
# gold nuggets that fly back to the worker.

const GOLD_PER_TICK := 8.0
const MAX_GOLD := 2000.0
const VARIANCE := 0.3

var gold_left: float = MAX_GOLD

func _ready() -> void:
	add_to_group("gold_mine")
	add_to_group("resource")
	gold_left = MAX_GOLD * randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	_build_visual()

func _build_visual() -> void:
	# Real KayKit mine model (with procedural mound as fallback).
	var mine := KayKitProp.create(self, "res://assets/models/kaykit_props/buildings_green/building_mine_green.gltf", 1.0)
	if mine != null:
		KayKitProp.scale_to_height(mine, 2.4)
	else:
		var mound := Builder.sphere(2.0, GameData.COLOR_MINE)
		mound.scale = Vector3(1.3, 0.8, 1.3)
		mound.position = Vector3(0, 0.7, 0)
		add_child(mound)
		var opening := Builder.sphere(0.9, Color(0.08, 0.06, 0.1))
		opening.position = Vector3(0, 0.9, 1.2)
		add_child(opening)

	# Gold crystals poking out.
	for i in 6:
		var crystal := Builder.cone(0.14, randf_range(0.4, 0.9), GameData.COLOR_GOLD)
		crystal.position = Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 1.4), randf_range(-0.6, 0.9))
		crystal.rotation_degrees = Vector3(randf_range(-25, 25), randf_range(0, 360), randf_range(-25, 25))
		add_child(crystal)

	Builder.collider(self, Builder.box_shape(Vector3(3.4, 2.2, 3.0)))
	var cs := get_child(get_child_count() - 1) as CollisionShape3D
	cs.position = Vector3(0, 1.0, 0)

func mine(multiplier: float = 1.0, worker: Node = null) -> float:
	if is_empty():
		return 0.0
	var amount := minf(GOLD_PER_TICK * multiplier, gold_left)
	gold_left -= amount
	if OS.has_environment("PEON_DEBUG"):
		print("[mine] mine() restant=%.0f amount=%.1f" % [gold_left, amount])
	# Spawn a gold nugget that flies to the worker.
	var chunk := preload("res://scenes/resources/gold_chunk.gd").new()
	get_parent().add_child(chunk)
	chunk.global_position = global_position + Vector3(0, 1.2, 1.0)
	if worker != null and worker is Node3D:
		chunk.target = worker
	return amount

func is_empty() -> bool:
	return gold_left <= 0.0
