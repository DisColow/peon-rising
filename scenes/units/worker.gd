extends UnitBase

# The worker the player embodies. It obeys orders issued by the AI commander,
# but the human can still dodge, dash and (via the influence system) steer it.

enum State { IDLE, MOVE, GATHER, RETURN, DEPOSIT, BUILD, ATTACK, DEFEND, REPAIR }

const MANUAL_WINDOW := 1.4
const DASH_SPEED := 11.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 1.2
const SWING_TIME := 0.5

var stats: Dictionary = {}
var order: Order = Order.new()
var carry_type: String = ""
var carry_amount: float = 0.0

var _state: State = State.IDLE
var _move_target: Vector3 = Vector3.ZERO
var _work_timer: float = 0.0
var _gather_node: Node = null
var _build_node: Node = null
var _attack_target: Node = null

var _manual_timer: float = 0.0
var _dodge_dir: Vector2 = Vector2.ZERO
var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _swing_time: float = 0.0

var _arm: Node3D
var _rig: UnitRig
var _carry_visual: Node3D
var _carry_gold_mesh: MeshInstance3D
var _carry_wood_mesh: MeshInstance3D

func _after_ready() -> void:
	add_to_group("ally")
	refresh_stats()
	hp = max_hp

func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Body"
	add_child(_visual)

	_rig = UnitRig.create(_visual, GameData.COLOR_PLAYER, GameData.COLOR_PLAYER_SKIN, GameData.COLOR_PLAYER_ARMOR)

	# Right-hand tool: a pickaxe / axe (swings on gather/build).
	_arm = _rig.tool_r
	var handle := Builder.cylinder(0.05, 0.9, GameData.COLOR_WOOD_STACK)
	handle.rotation_degrees = Vector3(0, 0, 90)
	handle.position = Vector3(0, -0.25, 0.25)
	_arm.add_child(handle)
	var pick := Builder.box(Vector3(0.14, 0.06, 0.4), GameData.COLOR_ROCK)
	pick.position = Vector3(0, -0.65, 0.28)
	_arm.add_child(pick)

	# Carry visual (shown above head when holding resources)
	_carry_visual = _rig.carry_slot
	_carry_gold_mesh = Builder.sphere(0.22, GameData.COLOR_GOLD)
	_carry_visual.add_child(_carry_gold_mesh)
	_carry_wood_mesh = Builder.box(Vector3(0.34, 0.2, 0.3), GameData.COLOR_WOOD_STACK)
	_carry_visual.add_child(_carry_wood_mesh)
	_update_carry_visual()

	# Collision capsule
	Builder.collider(self, Builder.capsule_shape(0.42, 1.8))

func is_idle() -> bool:
	return _state == State.IDLE

func is_carrying() -> bool:
	return carry_amount > 0.0

func current_order_type() -> int:
	return order.type

func get_stats() -> Dictionary:
	return stats

func describe_order() -> String:
	return order.describe()

func refresh_stats() -> void:
	stats = Stats.compute(GameState.unlocked_talents)
	move_speed = 4.5 * stats["move_speed"]
	max_hp = stats["max_hp"]
	attack_damage = stats["damage"]
	armor = stats["armor"]
	dodge = stats["dodge"]
	attack_cooldown = 1.0 / stats["attack_speed"]
	hp = clampf(hp, 0.0, max_hp)
	hp_changed.emit(hp, max_hp)

func assign_order(o: Order) -> void:
	order = o
	reset_path()
	carry_type = ""
	carry_amount = 0.0
	_update_carry_visual()
	_attack_target = null
	_build_node = null
	_gather_node = null
	match order.type:
		Order.Type.GATHER_GOLD:
			var mine := _nearest_in_group("gold_mine")
			if mine == null:
				_state = State.IDLE
				EventBus.order_completed.emit(order)
				return
			_gather_node = mine
			_move_target = _approach(mine, 2.6)
			_state = State.MOVE
		Order.Type.GATHER_WOOD:
			var tree := _nearest_tree_with_wood()
			if tree == null:
				_state = State.IDLE
				EventBus.order_completed.emit(order)
				return
			_gather_node = tree
			_move_target = (tree as Node3D).global_position + _approach_offset(tree)
			_state = State.MOVE
		Order.Type.BUILD:
			_move_target = order.position
			_state = State.MOVE
		Order.Type.ATTACK:
			if order.target == null or not is_instance_valid(order.target):
				_state = State.IDLE
				EventBus.order_completed.emit(order)
				return
			_attack_target = order.target
			_state = State.MOVE
		Order.Type.DEFEND:
			_move_target = order.position
			_state = State.MOVE
		Order.Type.REPAIR:
			_move_target = order.position
			_state = State.MOVE
		Order.Type.MOVE:
			_move_target = order.position
			_state = State.MOVE
		_:
			_state = State.IDLE

func _approach_offset(node: Node) -> Vector3:
	var off := global_position - (node as Node3D).global_position
	off.y = 0.0
	if off.length() < 0.5:
		off = Vector3(1, 0, 0)
	return off.normalized() * 1.8

func _build_margin(key: String) -> float:
	var s: Vector3 = GameData.BUILDINGS.get(key, {}).get("scale", Vector3(2, 2, 2))
	return maxf(s.x, s.z) * 0.5 + 1.3

func _tick(delta: float) -> void:
	if OS.has_environment("PEON_DEBUG") and Engine.get_physics_frames() % 90 == 0:
		print("[worker] state=%d pos=(%.1f,%.1f,%.1f) carry=%.1f order=%d" % [_state, global_position.x, global_position.y, global_position.z, carry_amount, order.type])
	_swing_time = maxf(0.0, _swing_time - delta)
	_update_carry_visual()

	# Procedural walk/idle animation.
	if _rig != null:
		var hspeed := Vector2(velocity.x, velocity.z).length()
		_rig.update_animation(delta, move_speed, hspeed > 0.4)

	# Autonomous worker: if nothing to do, pick a gather job.
	if _state == State.IDLE and order.type == Order.Type.IDLE:
		_assign_autonomous_gather()

	match _state:
		State.IDLE:
			_state_idle(delta)
		State.MOVE:
			_state_move(delta)
		State.GATHER:
			_state_gather(delta)
		State.RETURN:
			_state_return(delta)
		State.DEPOSIT:
			_state_deposit(delta)
		State.BUILD:
			_state_build(delta)
		State.ATTACK:
			_state_attack(delta)
		State.DEFEND:
			_state_defend(delta)
		State.REPAIR:
			_state_repair(delta)

func _assign_autonomous_gather() -> void:
	if GameState.gold <= GameState.wood:
		assign_order(Order.new(Order.Type.GATHER_GOLD))
	else:
		assign_order(Order.new(Order.Type.GATHER_WOOD))

# --- States ---

func _state_idle(_delta: float) -> void:
	velocity.x = lerpf(velocity.x, 0.0, minf(1.0, ACCEL * _delta))
	velocity.z = lerpf(velocity.z, 0.0, minf(1.0, ACCEL * _delta))

func _state_move(delta: float) -> void:
	var spd := move_speed
	if carry_amount > 0.0:
		spd *= stats["carry_speed"]
	if navigate_to(_move_target, delta, spd, 1.2):
		_arrive()

func _arrive() -> void:
	match order.type:
		Order.Type.GATHER_GOLD, Order.Type.GATHER_WOOD:
			_state = State.GATHER
			_work_timer = 0.0
		Order.Type.BUILD:
			_state = State.BUILD
			_start_build()
		Order.Type.ATTACK:
			_state = State.ATTACK
		Order.Type.DEFEND:
			_state = State.DEFEND
		Order.Type.REPAIR:
			_state = State.REPAIR
		Order.Type.MOVE:
			_state = State.IDLE
			EventBus.order_completed.emit(order)

func _state_gather(delta: float) -> void:
	if carry_amount >= stats["carry_capacity"]:
		_state = State.RETURN
		return
	if _gather_node == null or not is_instance_valid(_gather_node):
		_state = State.IDLE
		EventBus.order_completed.emit(order)
		return
	match order.type:
		Order.Type.GATHER_GOLD:
			if not _gather_node.has_method("mine") or (_gather_node as Node3D).is_empty():
				_state = State.IDLE
				EventBus.order_completed.emit(order)
				return
			_work_timer -= delta
			if _work_timer <= 0.0:
				_work_timer = 1.1 / stats["mine_speed"]
				_play_swing()
				Sound.play("mine", 0.5)
				var got: float = _gather_node.mine(stats["mine_yield"], self)
				if got <= 0.0:
					_state = State.IDLE
					EventBus.order_completed.emit(order)
					return
				carry_type = GameData.GOLD
				carry_amount = minf(carry_amount + got, stats["carry_capacity"])
				FX.burst(get_parent(), _gather_node.global_position + Vector3(0, 1.2, 0), GameData.COLOR_GOLD, 5, 0.4, 2.5, 0.5)
		Order.Type.GATHER_WOOD:
			var tree := _gather_node
			if not tree.has_method("chop") or tree.is_empty():
				_state = State.IDLE
				EventBus.order_completed.emit(order)
				return
			_work_timer -= delta
			if _work_timer <= 0.0:
				_work_timer = 1.3 / stats["chop_speed"]
				_play_swing()
				Sound.play("chop", 0.5)
				var got: float = tree.chop(stats["chop_yield"])
				if got <= 0.0:
					_state = State.IDLE
					EventBus.order_completed.emit(order)
					return
				carry_type = GameData.WOOD
				carry_amount = minf(carry_amount + got, stats["carry_capacity"])
				FX.burst(get_parent(), _gather_node.global_position + Vector3(0, 1.4, 0), GameData.COLOR_WOOD_STACK, 5, 0.4, 2.5, 0.5)

func _state_return(delta: float) -> void:
	var drop := _nearest_in_group("drop_off_player")
	if drop == null:
		_state = State.IDLE
		return
	_move_target = _approach(drop, 3.2)
	if navigate_to(_move_target, delta, move_speed * stats["carry_speed"], 1.2):
		_state = State.DEPOSIT
		_work_timer = 0.4

func _state_deposit(delta: float) -> void:
	_work_timer -= delta
	if _work_timer <= 0.0:
		GameState.add_resource(carry_type, int(round(carry_amount)))
		GameState.gain_xp(8)
		if OS.has_environment("PEON_DEBUG"):
			print("[worker] dépôt %s x%d -> total or=%d bois=%d" % [carry_type, int(round(carry_amount)), GameState.gold, GameState.wood])
		FX.float_text(get_parent(), global_position, "+%d" % int(round(carry_amount)), GameData.COLOR_GOLD if carry_type == GameData.GOLD else GameData.COLOR_WOOD_STACK)
		carry_amount = 0.0
		carry_type = ""
		_update_carry_visual()
		# Pick the next gather job based on current scarcity.
		match order.type:
			Order.Type.GATHER_GOLD, Order.Type.GATHER_WOOD:
				_assign_autonomous_gather()
			_:
				_state = State.IDLE
				EventBus.order_completed.emit(order)

func _start_build() -> void:
	if _build_node != null and is_instance_valid(_build_node):
		return
	var b: Dictionary = GameData.BUILDINGS[order.building_type]
	var cost_gold := int(b["gold"] * (1.0 - stats["build_discount"]))
	var cost_wood := int(b["wood"] * (1.0 - stats["build_discount"]))
	if not GameState.spend(cost_gold, cost_wood):
		EventBus.toast.emit("Ressources insuffisantes pour %s" % GameData.building_name(order.building_type))
		_state = State.IDLE
		EventBus.order_completed.emit(order)
		return
	_build_node = Building.create_ghost(order.building_type, order.position, GameData.TEAM_PLAYER)
	get_parent().add_child(_build_node)
	_work_timer = 0.0

func _state_build(delta: float) -> void:
	if _build_node == null or not is_instance_valid(_build_node):
		_state = State.IDLE
		EventBus.order_completed.emit(order)
		return
	_face_target((_build_node as Node3D).global_position)
	if navigate_to(_approach(_build_node, _build_margin(order.building_type)), delta, move_speed, 1.2):
		_work_timer -= delta
		if _work_timer <= 0.0:
			_work_timer = 0.35
			_play_swing()
			Sound.play("build", 0.5)
			_build_node.add_build_progress(0.18 * stats["build_speed"])
			FX.burst(get_parent(), _build_node.global_position + Vector3(0, 1.0, 0), GameData.COLOR_ROCK, 4, 0.5, 2.0, 0.4)
			if _build_node.is_completed():
				EventBus.toast.emit("%s construit !" % GameData.building_name(order.building_type))
				GameState.gain_xp(20)
				_state = State.IDLE
				EventBus.order_completed.emit(order)
				EventBus.building_completed.emit(_build_node)

func _state_attack(delta: float) -> void:
	if _attack_target == null or not is_instance_valid(_attack_target):
		_state = State.IDLE
		EventBus.order_completed.emit(order)
		return
	var tp := (_attack_target as Node3D).global_position
	var edge_dist := global_position.distance_to(tp) - _target_radius(_attack_target)
	if edge_dist > attack_range:
		var nav := tp
		if _attack_target is Building or _attack_target.is_in_group("building"):
			nav = _approach(_attack_target, _target_radius(_attack_target) + attack_range * 0.9)
		navigate_to(nav, delta, move_speed, 0.4)
		return
	_face_target(tp)
	velocity.x = lerpf(velocity.x, 0.0, minf(1.0, ACCEL * delta))
	velocity.z = lerpf(velocity.z, 0.0, minf(1.0, ACCEL * delta))
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_play_swing()
		Sound.play("hit", 0.5)
		_attack_target.take_damage(attack_damage, self)

func _state_defend(delta: float) -> void:
	var enemy := _nearest_in_group("enemy")
	if enemy != null and global_position.distance_to((enemy as Node3D).global_position) < 9.0:
		_attack_target = enemy
		_state = State.ATTACK
		return
	# Patrol around the defense point.
	if global_position.distance_to(_move_target) > 2.0:
		navigate_to(_move_target, delta, move_speed, 2.0)
	else:
		velocity.x = lerpf(velocity.x, 0.0, minf(1.0, ACCEL * delta))
		velocity.z = lerpf(velocity.z, 0.0, minf(1.0, ACCEL * delta))

func _state_repair(delta: float) -> void:
	var b: Node = order.target
	if b == null or not is_instance_valid(b):
		_state = State.IDLE
		EventBus.order_completed.emit(order)
		return
	if not b.has_method("is_damaged"):
		_state = State.IDLE
		EventBus.order_completed.emit(order)
		return
	if navigate_to(_approach(b, 3.0), delta, move_speed, 1.2):
		_work_timer -= delta
		if _work_timer <= 0.0:
			_work_timer = 0.5 / stats["repair_speed"]
			_play_swing()
			b.repair(6.0 * stats["repair_speed"])
			if not b.is_damaged():
				_state = State.IDLE
				EventBus.order_completed.emit(order)

func _play_swing() -> void:
	if _rig == null:
		return
	_swing_time = SWING_TIME
	_rig.swing_tool(self, SWING_TIME)

func _update_carry_visual() -> void:
	if _carry_visual == null:
		return
	_carry_gold_mesh.visible = carry_type == GameData.GOLD and carry_amount > 0.0
	_carry_wood_mesh.visible = carry_type == GameData.WOOD and carry_amount > 0.0
	_carry_visual.visible = carry_amount > 0.0

func _nearest_tree_with_wood() -> Node:
	var best: Node = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("tree"):
		if not is_instance_valid(n) or not n.has_method("is_empty") or n.is_empty():
			continue
		var d := global_position.distance_squared_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _nearest_in_group(group: String) -> Node:
	var best: Node = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group(group):
		if not is_instance_valid(n) or n == self:
			continue
		if n.has_method("is_empty") and n.is_empty():
			continue
		var d := global_position.distance_squared_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _die() -> void:
	if dead:
		return
	dead = true
	Sound.play("enemy_die")
	FX.burst(get_parent(), global_position + Vector3(0, 0.8, 0), GameData.COLOR_PLAYER, 20, 0.6, 4.0, 0.8)
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)
