extends UnitBase

# Simple melee AI unit used by both the enemy commander and the player's barracks.
# Either marches toward the enemy base ("seek_base") or patrols a defense point ("defend").

var target_position: Vector3 = Vector3.ZERO
var attack_mode: String = "seek_base"
var aggro_range: float = 6.5

func _after_ready() -> void:
	if team == GameData.TEAM_ENEMY:
		add_to_group("enemy")
	else:
		add_to_group("ally")

func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Body"
	add_child(_visual)

	var body_color := GameData.COLOR_ENEMY if team == GameData.TEAM_ENEMY else Color(0.25, 0.55, 0.28)
	var skin_color := GameData.COLOR_ENEMY_SKIN if team == GameData.TEAM_ENEMY else GameData.COLOR_PLAYER_SKIN
	var armor_color := GameData.COLOR_ENEMY_ARMOR if team == GameData.TEAM_ENEMY else GameData.COLOR_PLAYER_ARMOR

	var torso := Builder.capsule(0.48, 1.0, body_color)
	torso.position = Vector3(0, 1.05, 0)
	_visual.add_child(torso)

	var head := Builder.sphere(0.36, skin_color)
	head.position = Vector3(0, 1.85, 0)
	_visual.add_child(head)

	if team == GameData.TEAM_ENEMY:
		# Horns for the bad guys.
		for side in [-1.0, 1.0]:
			var horn := Builder.cone(0.08, 0.5, Color(0.95, 0.95, 0.85))
			horn.position = Vector3(side * 0.22, 2.1, 0)
			horn.rotation_degrees = Vector3(0, 0, side * 22)
			_visual.add_child(horn)
	else:
		var plume := Builder.cone(0.1, 0.4, Color(0.2, 0.4, 0.6))
		plume.position = Vector3(0, 2.15, 0)
		_visual.add_child(plume)

	for side in [-1.0, 1.0]:
		var leg := Builder.box(Vector3(0.24, 0.4, 0.28), armor_color)
		leg.position = Vector3(side * 0.17, 0.22, 0)
		_visual.add_child(leg)

	# Weapon (club for enemy, sword for ally).
	var weapon := Node3D.new()
	weapon.position = Vector3(0.55, 1.2, 0)
	_visual.add_child(weapon)
	var handle := Builder.cylinder(0.05, 0.8, GameData.COLOR_WOOD_STACK)
	handle.rotation_degrees = Vector3(0, 0, 90)
	weapon.add_child(handle)
	if team == GameData.TEAM_ENEMY:
		var club := Builder.sphere(0.16, Color(0.4, 0.3, 0.25))
		club.position = Vector3(0, -0.2, 0.35)
		weapon.add_child(club)
	else:
		var blade := Builder.box(Vector3(0.06, 0.02, 0.5), GameData.COLOR_ROCK)
		blade.position = Vector3(0, -0.35, 0)
		weapon.add_child(blade)

	Builder.collider(self, Builder.capsule_shape(0.48, 1.9))

func _tick(delta: float) -> void:
	var enemy := _nearest_enemy()
	if enemy != null and global_position.distance_to((enemy as Node3D).global_position) <= aggro_range:
		_attack_node(enemy, delta)
	else:
		navigate_to(target_position, delta, move_speed, 1.2)

func _attack_node(target: Node, delta: float) -> void:
	var tp := (target as Node3D).global_position
	var edge_dist := global_position.distance_to(tp) - _target_radius(target)
	if edge_dist > attack_range:
		var nav := tp
		if target is Building or target.is_in_group("building"):
			nav = _approach(target, _target_radius(target) + attack_range * 0.9)
		navigate_to(nav, delta, move_speed, 0.4)
		return
	_face_target(tp)
	velocity.x = lerpf(velocity.x, 0.0, minf(1.0, ACCEL * delta))
	velocity.z = lerpf(velocity.z, 0.0, minf(1.0, ACCEL * delta))
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		target.take_damage(attack_damage, self)

func _nearest_enemy() -> Node:
	var groups: Array = []
	if team == GameData.TEAM_ENEMY:
		groups = ["worker", "ally", "building_player"]
	else:
		groups = ["enemy", "building_enemy"]
	var best: Node = null
	var best_d := INF
	for g in groups:
		for n in get_tree().get_nodes_in_group(g):
			if not is_instance_valid(n) or n == self:
				continue
			if n.has_method("is_dead") and n.is_dead():
				continue
			var d := global_position.distance_squared_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
	return best
