extends RigidBody3D

# A gold nugget that pops out of the mine and then magnetically flies to the
# worker. Pure satisfaction: the actual gold is counted by the mine.

var target: Node3D = null
var _homing_timer: float = 0.35

func _ready() -> void:
	var dir := Vector3(randf_range(-0.5, 0.5), randf_range(0.5, 1.0), randf_range(-0.5, 0.5)).normalized()
	apply_central_impulse(dir * 2.2)
	var m := Builder.sphere(0.15, GameData.COLOR_GOLD, 0.4)
	add_child(m)
	Builder.collider(self, Builder.sphere_shape(0.15))

func _physics_process(delta: float) -> void:
	_homing_timer -= delta
	if _homing_timer <= 0.0 and target != null and is_instance_valid(target):
		var dir := target.global_position + Vector3(0, 0.6, 0) - global_position
		if dir.length() < 0.7:
			queue_free()
		else:
			linear_velocity = dir.normalized() * 9.0
