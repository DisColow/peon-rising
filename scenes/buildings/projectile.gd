extends Node3D

# A homing projectile fired by towers. Deals damage on contact.

var target: Node = null
var damage: float = 12.0
var speed: float = 13.0
var color: Color = Color.WHITE

func _ready() -> void:
	var m := Builder.sphere(0.13, color, 0.3)
	add_child(m)

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	var tp := (target as Node3D).global_position + Vector3(0, 0.8, 0)
	var dir := tp - global_position
	if dir.length() < 0.6:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		FX.burst(get_parent(), global_position, color, 6, 0.3, 2.0, 0.3)
		queue_free()
		return
	global_position += dir.normalized() * speed * delta
