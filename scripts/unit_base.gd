class_name UnitBase
extends CharacterBody3D

# Common base for the player worker and the AI grunts.
# Handles HP, damage, death, knockback and movement helpers.

signal died(unit: UnitBase)
signal hp_changed(current: float, maximum: float)

const GRAVITY := 22.0
const ACCEL := 12.0

@export var team: String = GameData.TEAM_PLAYER
@export var max_hp: float = 100.0
@export var move_speed: float = 4.5
@export var attack_damage: float = 12.0
@export var attack_range: float = 1.9
@export var attack_cooldown: float = 1.0
@export var armor: float = 0.0
@export var dodge: float = 0.0

var hp: float
var dead: bool = false
var _attack_timer: float = 0.0

var _stuck_time: float = 0.0
var _avoid_timer: float = 0.0
var _avoid_dir: float = 1.0

var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _path_target: Vector3 = Vector3.ZERO
var _repath_timer: float = 0.0

var _visual: Node3D
var _flash_tween: Tween

func _ready() -> void:
	hp = max_hp
	collision_layer = 1
	collision_mask = 1
	_build_visual()
	_after_ready()

func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_tick(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5
	move_and_slide()

func _tick(_delta: float) -> void:
	pass

func _after_ready() -> void:
	pass

func _build_visual() -> void:
	pass

func move_to(target: Vector3, delta: float, speed: float, arrive_dist: float = 1.0) -> bool:
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist <= arrive_dist:
		_stuck_time = 0.0
		_avoid_timer = 0.0
		velocity.x = lerpf(velocity.x, 0.0, minf(1.0, ACCEL * delta))
		velocity.z = lerpf(velocity.z, 0.0, minf(1.0, ACCEL * delta))
		return true
	var dir := to / dist
	# Stuck recovery: if we are pushing against an obstacle (barely moving but
	# still far away), steer perpendicular for a while to go around it. The
	# direction stays consistent so a large obstacle is circled rather than
	# oscillated against.
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.6 and dist > arrive_dist + 0.6:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	if _stuck_time > 0.3:
		_stuck_time = 0.0
		if _avoid_timer > 0.0:
			_avoid_dir = -_avoid_dir
		_avoid_timer = 1.5
	if _avoid_timer > 0.0:
		_avoid_timer -= delta
		var perp := Vector3(-dir.z, 0.0, dir.x) * _avoid_dir
		dir = (dir + perp).normalized()
	var desired := dir * speed
	velocity.x = lerpf(velocity.x, desired.x, minf(1.0, ACCEL * delta))
	velocity.z = lerpf(velocity.z, desired.z, minf(1.0, ACCEL * delta))
	_face_dir(dir)
	return false

func reset_path() -> void:
	_path = PackedVector3Array()
	_path_index = 0

# Point safely outside `target`'s collision, in the direction this unit is coming
# from. Used to approach buildings/mines without getting stuck inside them.
func _approach(target: Node, margin: float) -> Vector3:
	var tp := (target as Node3D).global_position
	var dir := global_position - tp
	dir.y = 0.0
	if dir.length() < 0.5:
		dir = Vector3.FORWARD
	return tp + dir.normalized() * margin

func _target_radius(t: Node) -> float:
	if t is Building:
		var s: Vector3 = GameData.BUILDINGS.get(t.building_key, {}).get("scale", Vector3(2, 2, 2))
		return maxf(s.x, s.z) * 0.5
	return 0.6

# Navigate to a point using grid pathfinding around obstacles, then steer the
# final approach. Returns true once within `arrive_dist` of the target.
func navigate_to(target: Vector3, delta: float, speed: float, arrive_dist: float = 1.0) -> bool:
	_repath_timer -= delta
	if _path.is_empty() or _path_target.distance_to(target) > 2.0 or _repath_timer <= 0.0:
		_repath_timer = 0.8
		_path_target = target
		_path = Pathfinder.find_path(global_position, target)
		_path_index = 0
	while _path_index < _path.size():
		var wp: Vector3 = _path[_path_index]
		if move_to(wp, delta, speed, 0.7):
			_path_index += 1
		else:
			return false
	return move_to(target, delta, speed, arrive_dist)

func set_velocity_xz(dir: Vector3, speed: float, delta: float) -> void:
	var d := dir.normalized()
	var desired := d * speed
	velocity.x = lerpf(velocity.x, desired.x, minf(1.0, ACCEL * delta))
	velocity.z = lerpf(velocity.z, desired.z, minf(1.0, ACCEL * delta))
	if d.length() > 0.01:
		_face_dir(d)

func _face_dir(dir: Vector3) -> void:
	if _visual == null:
		return
	var target_yaw := atan2(dir.x, dir.z)
	var current := _visual.rotation.y
	_visual.rotation.y = lerp_angle(current, target_yaw, 0.2)

func _face_target(target: Vector3) -> void:
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		_face_dir(dir.normalized())

func take_damage(amount: float, attacker: Node = null) -> void:
	if dead:
		return
	if dodge > 0.0 and randf() < dodge:
		FX.float_text(get_parent(), global_position, "Esquive !", Color(0.7, 0.9, 1.0))
		return
	var actual := amount * (1.0 - armor)
	hp -= actual
	hp_changed.emit(hp, max_hp)
	_flash_hit()
	if attacker != null and attacker is Node3D:
		var away := (global_position - (attacker as Node3D).global_position)
		away.y = 0.0
		_knockback(away.normalized(), 4.0)
	if hp <= 0.0:
		if attacker != null and attacker.is_in_group("worker"):
			GameState.gain_xp(30)
		_die()

func _knockback(dir: Vector3, power: float) -> void:
	if dir.length() < 0.01:
		dir = Vector3.FORWARD
	velocity.x += dir.x * power
	velocity.z += dir.z * power
	velocity.y = minf(velocity.y + 2.0, 3.0)

func _flash_hit() -> void:
	if _visual == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_visual.scale = Vector3.ONE * 1.15
	_flash_tween = create_tween()
	_flash_tween.tween_property(_visual, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _die() -> void:
	if dead:
		return
	dead = true
	died.emit(self)
	FX.burst(get_parent(), global_position + Vector3(0, 0.8, 0), _death_color(), 20, 0.6, 4.0, 0.8)
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)

func _death_color() -> Color:
	if team == GameData.TEAM_PLAYER:
		return GameData.COLOR_PLAYER
	return GameData.COLOR_ENEMY

func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)
