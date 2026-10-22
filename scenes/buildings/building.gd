class_name Building
extends StaticBody3D

# A base structure. Built by the worker (ghost -> solid, rising from the ground).
# Towers additionally fire homing projectiles at enemies.

signal destroyed(building: Building)

const TOWER_RANGE := 10.0
const TOWER_COOLDOWN := 1.4
const TOWER_DAMAGE := 14.0

var building_key: String = "farm"
var team: String = GameData.TEAM_PLAYER
var max_hp: float = 400.0
var hp: float = 400.0
var progress: float = 0.0
var completed: bool = false

var _solid: Node3D
var _ghost: Node3D
var _collision: CollisionShape3D
var _fire_timer: float = 0.0

static func create_ghost(key: String, pos: Vector3, team: String) -> Building:
	var b := Building.new()
	b.building_key = key
	b.team = team
	b.position = pos
	b.progress = 0.0
	b.completed = false
	return b

static func create_built(key: String, pos: Vector3, team: String) -> Building:
	var b := create_ghost(key, pos, team)
	b.progress = 1.0
	b.completed = true
	return b

func _ready() -> void:
	var data: Dictionary = GameData.BUILDINGS.get(building_key, {})
	max_hp = float(data.get("hp", 400))
	hp = max_hp
	collision_layer = 1
	collision_mask = 1
	add_to_group("building")
	if team == GameData.TEAM_PLAYER:
		add_to_group("building_player")
	else:
		add_to_group("building_enemy")
	if building_key == "town_hall":
		add_to_group("drop_off_player" if team == GameData.TEAM_PLAYER else "drop_off_enemy")
	_build_visual()
	if completed:
		_finish_construction()

func _build_visual() -> void:
	var data: Dictionary = GameData.BUILDINGS.get(building_key, {})
	var color: Color = data.get("color", Color(0.6, 0.6, 0.6))
	var s: Vector3 = data.get("scale", Vector3(2, 2, 2))

	# Ghost: a transparent shell showing the final footprint.
	_ghost = Node3D.new()
	_ghost.name = "Ghost"
	add_child(_ghost)
	var ghost_box := Builder.box(s, color, 0.8)
	ghost_box.material_override = _ghost_mat(color)
	ghost_box.position = Vector3(0, s.y * 0.5, 0)
	_ghost.add_child(ghost_box)

	# Solid body, revealed as construction progresses.
	_solid = Node3D.new()
	_solid.name = "Solid"
	add_child(_solid)
	_build_solid_visual(_solid, color, s)
	_solid.scale = Vector3(1, 0.001, 1)

	# Collision becomes active only when complete.
	_collision = Builder.collider(self, Builder.box_shape(s))
	_collision.position = Vector3(0, s.y * 0.5, 0)
	_collision.disabled = true

func _ghost_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _build_solid_visual(root: Node3D, color: Color, s: Vector3) -> void:
	var wood := GameData.COLOR_WOOD_STACK
	var stone := GameData.COLOR_ROCK
	var team_col := Color(0.25, 0.4, 0.8) if team == GameData.TEAM_PLAYER else Color(0.82, 0.24, 0.2)
	match building_key:
		"town_hall":
			# Stone base + timber upper + gable roof + door/windows + trim.
			var base := Builder.box(Vector3(s.x, s.y * 0.45, s.z), stone)
			base.position = Vector3(0, s.y * 0.23, 0)
			root.add_child(base)
			var upper := Builder.box(Vector3(s.x * 0.94, s.y * 0.45, s.z * 0.94), color)
			upper.position = Vector3(0, s.y * 0.6, 0)
			root.add_child(upper)
			_add_gable_roof(root, s.x * 1.05, s.y * 0.4, s.z * 1.05, wood, s.y * 0.82)
			var door := Builder.box(Vector3(0.6, 1.0, 0.12), wood)
			door.position = Vector3(0, 0.5, s.z * 0.5)
			root.add_child(door)
			for side in [-1.0, 1.0]:
				var win := Builder.box(Vector3(0.5, 0.5, 0.08), Color(0.35, 0.55, 0.85))
				win.position = Vector3(side * s.x * 0.25, s.y * 0.6, s.z * 0.5 + 0.02)
				root.add_child(win)
			var banner := Builder.box(Vector3(0.08, 0.8, 0.45), team_col)
			banner.position = Vector3(0, s.y * 1.0, 0)
			root.add_child(banner)
		"farm":
			# Small barn + a tilled crop field.
			var barn := Builder.box(Vector3(s.x * 0.7, s.y * 0.6, s.z * 0.7), color)
			barn.position = Vector3(-s.x * 0.15, s.y * 0.3, 0)
			root.add_child(barn)
			_add_gable_roof(root, s.x * 0.78, s.y * 0.35, s.z * 0.78, wood, s.y * 0.6)
			var field := Builder.box(Vector3(s.x * 0.8, 0.06, s.z * 0.5), Color(0.4, 0.52, 0.22))
			field.position = Vector3(s.x * 0.3, 0.03, s.z * 0.1)
			root.add_child(field)
			for i in 3:
				var row := Builder.box(Vector3(s.x * 0.7, 0.02, 0.1), Color(0.55, 0.42, 0.2))
				row.position = Vector3(s.x * 0.3, 0.07, -s.z * 0.12 + i * s.z * 0.12)
				root.add_child(row)
		"barracks":
			var base := Builder.box(Vector3(s.x, s.y * 0.6, s.z), color)
			base.position = Vector3(0, s.y * 0.3, 0)
			root.add_child(base)
			_add_gable_roof(root, s.x * 1.05, s.y * 0.4, s.z * 1.05, wood, s.y * 0.68)
			var banner := Builder.box(Vector3(0.1, 1.0, 0.5), team_col)
			banner.position = Vector3(s.x * 0.1, s.y * 0.95, s.z * 0.45)
			root.add_child(banner)
			# Training dummy out front.
			var dummy := Builder.cylinder(0.14, 0.9, GameData.COLOR_WOOD_STACK)
			dummy.position = Vector3(s.x * 0.5, 0.45, s.z * 0.6)
			root.add_child(dummy)
			var dummy_head := Builder.sphere(0.18, GameData.COLOR_PLAYER_SKIN if team == GameData.TEAM_PLAYER else GameData.COLOR_ENEMY_SKIN)
			dummy_head.position = Vector3(s.x * 0.5, 0.95, s.z * 0.6)
			root.add_child(dummy_head)
		"tower":
			var shaft := Builder.cylinder(s.x * 0.38, s.y * 0.75, stone)
			shaft.position = Vector3(0, s.y * 0.38, 0)
			root.add_child(shaft)
			var platform := Builder.cylinder(s.x * 0.55, 0.2, wood)
			platform.position = Vector3(0, s.y * 0.78, 0)
			root.add_child(platform)
			var roof := Builder.cone(s.x * 0.55, s.y * 0.28, team_col)
			roof.position = Vector3(0, s.y * 0.92, 0)
			root.add_child(roof)
			var crystal := Builder.sphere(0.2, Color(0.5, 0.75, 1.0))
			crystal.position = Vector3(0, s.y * 1.04, 0)
			root.add_child(crystal)
		_:
			var base := Builder.box(s, color)
			base.position = Vector3(0, s.y * 0.5, 0)
			root.add_child(base)

# A pitched (gable) roof built from two sloped planks meeting at a ridge.
func _add_gable_roof(root: Node3D, w: float, h: float, d: float, color: Color, base_y: float) -> void:
	var half_w := w * 0.5
	var slope := sqrt(h * h + half_w * half_w)
	var angle := atan2(h, half_w)
	for side in [-1.0, 1.0]:
		var plank := Builder.box(Vector3(slope, 0.12, d), color)
		plank.position = Vector3(side * half_w * 0.5, base_y + h * 0.5, 0)
		plank.rotation.z = side * angle
		root.add_child(plank)

func _physics_process(delta: float) -> void:
	# Grow the building from the ground during construction.
	if not completed:
		progress = clampf(progress, 0.0, 1.0)
		_solid.scale = Vector3(1, maxf(progress, 0.001), 1)
		if progress >= 1.0:
			_finish_construction()
	if completed and building_key == "tower":
		_tower_tick(delta)

func _tower_tick(delta: float) -> void:
	_fire_timer = maxf(0.0, _fire_timer - delta)
	var target := _nearest_enemy(TOWER_RANGE)
	if target == null or _fire_timer > 0.0:
		return
	_fire_timer = TOWER_COOLDOWN
	var p := preload("res://scenes/buildings/projectile.gd").new()
	get_parent().add_child(p)
	p.global_position = global_position + Vector3(0, GameData.BUILDINGS[building_key]["scale"].y, 0)
	p.target = target
	p.damage = TOWER_DAMAGE
	p.color = Color(0.5, 0.7, 1.0) if team == GameData.TEAM_PLAYER else Color(1.0, 0.4, 0.3)

func _nearest_enemy(range_limit: float) -> Node:
	var groups: Array = ["enemy"] if team == GameData.TEAM_PLAYER else ["worker", "ally"]
	var best: Node = null
	var best_d := INF
	for g in groups:
		for n in get_tree().get_nodes_in_group(g):
			if not is_instance_valid(n):
				continue
			if n.has_method("is_dead") and n.is_dead():
				continue
			var d := global_position.distance_squared_to((n as Node3D).global_position)
			if d < best_d and d <= range_limit * range_limit:
				best_d = d
				best = n
	return best

func add_build_progress(amount: float) -> void:
	if completed:
		return
	progress = minf(1.0, progress + amount)

func is_completed() -> bool:
	return completed

func _finish_construction() -> void:
	completed = true
	_solid.scale = Vector3.ONE
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	if _collision != null:
		_collision.disabled = false
	FX.burst(get_parent(), global_position + Vector3(0, 1.0, 0), Color(1, 0.95, 0.7), 16, 0.6, 3.0, 0.6)
	if building_key == "farm":
		GameState.food_max += GameData.BUILDINGS["farm"]["food"]
		GameState._emit_resources()

func take_damage(amount: float, _attacker: Node = null) -> void:
	if is_dead():
		return
	hp -= amount
	EventBus.building_damaged.emit(self)
	_flash_hit()
	if hp <= 0.0:
		_destroy()

func repair(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	EventBus.building_damaged.emit(self)

func is_damaged() -> bool:
	return hp < max_hp and not is_dead()

func is_dead() -> bool:
	return hp <= 0.0

func _flash_hit() -> void:
	if _solid == null:
		return
	_solid.scale = Vector3(1.05, maxf(_solid.scale.y, 0.05) * 1.05, 1.05)
	var t := create_tween()
	t.tween_property(_solid, "scale", Vector3(1, maxf(progress, 0.001), 1), 0.2)

func _destroy() -> void:
	if building_key == "farm":
		GameState.food_max = maxf(0, GameState.food_max - GameData.BUILDINGS["farm"]["food"])
		GameState._emit_resources()
	FX.burst(get_parent(), global_position + Vector3(0, 1.0, 0), GameData.COLOR_ROCK, 24, 1.0, 4.0, 0.8)
	destroyed.emit(self)
	if building_key == "town_hall":
		EventBus.base_destroyed.emit(team)
	queue_free()
