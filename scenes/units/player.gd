extends UnitBase

# The first-person hero: a peon controlled directly by the human.
# The AI commander only *suggests* objectives; the player walks, looks, and
# performs every action (chop, mine, deposit, build, attack) themselves.

signal carry_changed(carrying: bool, type: String, amount: float)

const WALK_SPEED := 5.4
const SPRINT_MULT := 1.45
const DASH_SPEED := 12.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 1.1
const SWING_TIME := 0.45
const REACH := 3.2

var stats: Dictionary = {}
var carry_type: String = ""
var carry_amount: float = 0.0
var camera: Camera3D = null

var _swing_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _bob_time: float = 0.0

var _vm: Node3D          # first-person viewmodel (tool in hand)
var _vm_base: Vector3 = Vector3(0.42, -0.34, -0.6)
var _rig: Node3D
var _carry_visual: Node3D
var _carry_gold_mesh: MeshInstance3D
var _carry_wood_mesh: MeshInstance3D

func _after_ready() -> void:
	add_to_group("worker")
	refresh_stats()
	hp = max_hp
	_visual.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func setup_camera(cam: Camera3D) -> void:
	camera = cam
	_build_viewmodel()

func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Body"
	add_child(_visual)

	var kr := KayKitRig.create(_visual, "res://assets/models/kaykit/Barbarian.glb", 1.2)
	if kr.anim != null:
		_rig = kr
	else:
		kr.queue_free()
		_rig = UnitRig.create(_visual, GameData.COLOR_PLAYER, GameData.COLOR_PLAYER_SKIN, GameData.COLOR_PLAYER_ARMOR)

	_carry_visual = _rig.carry_slot
	_carry_gold_mesh = Builder.sphere(0.22, GameData.COLOR_GOLD)
	_carry_visual.add_child(_carry_gold_mesh)
	_carry_wood_mesh = Builder.box(Vector3(0.34, 0.2, 0.3), GameData.COLOR_WOOD_STACK)
	_carry_visual.add_child(_carry_wood_mesh)
	_update_carry_visual()

	Builder.collider(self, Builder.capsule_shape(0.42, 1.8))

func _build_viewmodel() -> void:
	if camera == null:
		return
	_vm = Node3D.new()
	_vm.name = "Viewmodel"
	camera.add_child(_vm)
	_vm.position = _vm_base

	var hand := Builder.sphere(0.1, GameData.COLOR_PLAYER_SKIN)
	hand.position = Vector3(-0.04, 0.06, 0.02)
	_vm.add_child(hand)

	# A versatile pickaxe/axe held in the right hand.
	var handle := Builder.cylinder(0.035, 0.72, GameData.COLOR_WOOD_STACK)
	handle.rotation_degrees = Vector3(20, 0, 18)
	handle.position = Vector3(0.0, -0.24, 0.0)
	_vm.add_child(handle)
	var head := Builder.box(Vector3(0.07, 0.30, 0.05), GameData.COLOR_ROCK)
	head.position = Vector3(0.0, -0.52, 0.0)
	_vm.add_child(head)
	var point := Builder.cone(0.06, 0.16, GameData.COLOR_GOLD)
	point.rotation_degrees = Vector3(90, 0, 0)
	point.position = Vector3(0.0, -0.72, 0.0)
	_vm.add_child(point)

func refresh_stats() -> void:
	stats = Stats.compute(GameState.unlocked_talents)
	move_speed = WALK_SPEED * stats["move_speed"]
	max_hp = stats["max_hp"]
	attack_damage = stats["damage"]
	armor = stats["armor"]
	dodge = stats["dodge"]
	attack_cooldown = 1.0 / stats["attack_speed"]
	hp = clampf(hp, 0.0, max_hp)
	hp_changed.emit(hp, max_hp)

func is_carrying() -> bool:
	return carry_amount > 0.0

func describe_order() -> String:
	if GameState.commander != null and is_instance_valid(GameState.commander) and GameState.commander.has_method("describe_objective"):
		return GameState.commander.describe_objective()
	return "—"

func get_look_label() -> String:
	var node := _look_at_node()
	if node == null:
		return ""
	if node.is_in_group("tree"):
		return "Couper l'arbre  [Clic]"
	if node.is_in_group("gold_mine"):
		return "Miner  [Clic]"
	if node.is_in_group("drop_off_player"):
		return "Déposer les ressources  [Clic]" if carry_amount > 0.0 else ""
	if node.is_in_group("enemy"):
		return "Attaquer  [Clic]"
	if node.is_in_group("building") and node.has_method("is_completed") and not node.is_completed():
		return "Construire  [Clic]"
	return ""

func _tick(delta: float) -> void:
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_swing_timer = maxf(0.0, _swing_timer - delta)
	_handle_movement(delta)
	_handle_action()
	_update_viewmodel(delta)
	_update_carry_visual()

func _handle_movement(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if DisplayServer.is_touchscreen_available() and GameState.touch_move != Vector2.ZERO:
		input = GameState.touch_move
	var yaw := camera.rotation.y if camera != null else 0.0
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var dir := (fwd * input.y + right * input.x)

	var speed := move_speed
	var sprinting := Input.is_action_pressed("sprint")
	if DisplayServer.is_touchscreen_available() and input.length() > 0.9:
		sprinting = true
	if sprinting and input != Vector2.ZERO:
		speed *= SPRINT_MULT

	var dash_pressed := Input.is_action_just_pressed("dash")
	if DisplayServer.is_touchscreen_available() and GameState.touch_dash_pressed:
		dash_pressed = true
		GameState.touch_dash_pressed = false
	if dash_pressed and _dash_cooldown <= 0.0:
		_dash_timer = DASH_TIME
		_dash_cooldown = DASH_COOLDOWN
		FX.burst(get_parent(), global_position + Vector3(0, 0.4, 0), Color(1, 1, 1, 0.6), 8, 0.3, 2.2, 0.4)
	if _dash_timer > 0.0:
		_dash_timer -= delta
		speed = DASH_SPEED
		if dir.length() < 0.01:
			dir = fwd

	if dir.length() > 0.01:
		dir = dir.normalized()
		set_velocity_xz(dir, speed, delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, minf(1.0, ACCEL * delta))
		velocity.z = lerpf(velocity.z, 0.0, minf(1.0, ACCEL * delta))

func _handle_action() -> void:
	var pressed := Input.is_action_just_pressed("interact")
	if DisplayServer.is_touchscreen_available() and GameState.touch_action_pressed:
		pressed = true
		GameState.touch_action_pressed = false
	if not pressed:
		return
	if _swing_timer > 0.0:
		return
	var node := _look_at_node()
	if node == null:
		_play_swing()
		return
	if node.is_in_group("tree"):
		_chop(node)
	elif node.is_in_group("gold_mine"):
		_mine(node)
	elif node.is_in_group("drop_off_player"):
		_deposit()
	elif node.is_in_group("enemy"):
		_attack(node)
	elif node.is_in_group("building") and node.has_method("is_completed") and not node.is_completed():
		_build(node)
	else:
		_play_swing()

func _look_at_node() -> Node:
	if camera == null:
		return null
	var from := camera.global_position
	var dir := -camera.global_basis.z
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * REACH)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return null
	return hit.collider

func _chop(tree: Node) -> void:
	var tp := (tree as Node3D).global_position
	if global_position.distance_to(tp) > REACH + 0.6:
		return
	_play_swing()
	Sound.play("chop")
	var got: float = tree.chop(stats["chop_yield"], self)
	if got <= 0.0:
		return
	carry_type = GameData.WOOD
	carry_amount = minf(carry_amount + got, stats["carry_capacity"])
	carry_changed.emit(true, carry_type, carry_amount)
	_update_carry_visual()
	FX.burst(get_parent(), tp + Vector3(0, 1.2, 0), GameData.COLOR_WOOD_STACK, 5, 0.4, 2.5, 0.5)

func _mine(mine: Node) -> void:
	if global_position.distance_to((mine as Node3D).global_position) > 3.6:
		return
	_play_swing()
	Sound.play("mine")
	var got: float = mine.mine(stats["mine_yield"], self)
	if got <= 0.0:
		return
	carry_type = GameData.GOLD
	carry_amount = minf(carry_amount + got, stats["carry_capacity"])
	carry_changed.emit(true, carry_type, carry_amount)
	_update_carry_visual()
	FX.burst(get_parent(), global_position + Vector3(0, 1.0, 0), GameData.COLOR_GOLD, 5, 0.5, 2.5, 0.5)

func _deposit() -> void:
	if carry_amount <= 0.0:
		return
	Sound.play("deposit")
	GameState.add_resource(carry_type, int(round(carry_amount)))
	GameState.gain_xp(8)
	FX.float_text(get_parent(), global_position, "+%d" % int(round(carry_amount)), GameData.COLOR_GOLD if carry_type == GameData.GOLD else GameData.COLOR_WOOD_STACK)
	carry_amount = 0.0
	carry_type = ""
	carry_changed.emit(false, "", 0.0)
	_update_carry_visual()

func _build(node: Node) -> void:
	if not node.has_method("add_build_progress") or node.is_completed():
		return
	if global_position.distance_to((node as Node3D).global_position) > 4.2:
		return
	_play_swing()
	Sound.play("build")
	node.add_build_progress(0.2 * stats["build_speed"])
	FX.burst(get_parent(), (node as Node3D).global_position + Vector3(0, 1.0, 0), GameData.COLOR_ROCK, 4, 0.5, 2.0, 0.4)
	if node.is_completed():
		GameState.gain_xp(20)
		EventBus.building_completed.emit(node)
		EventBus.toast.emit("%s construit !" % GameData.building_name(node.building_key))

func _attack(target: Node) -> void:
	var tp := (target as Node3D).global_position
	if global_position.distance_to(tp) > REACH + 1.0:
		return
	_play_swing()
	Sound.play("hit")
	target.take_damage(attack_damage, self)
	FX.hit_stop(get_tree(), 0.05, 0.1)

func _play_swing() -> void:
	if _vm == null:
		return
	_swing_timer = SWING_TIME
	var t := create_tween()
	t.tween_property(_vm, "rotation:x", -1.15, SWING_TIME * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_vm, "rotation:x", 0.0, SWING_TIME * 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _update_viewmodel(delta: float) -> void:
	if _vm == null:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 0.5:
		_bob_time += delta * speed * 1.6
	var sway := minf(1.0, speed / move_speed)
	_vm.position.y = _vm_base.y + sin(_bob_time * 2.0) * 0.018 * sway
	_vm.position.x = _vm_base.x + cos(_bob_time) * 0.016 * sway

func _update_carry_visual() -> void:
	if _carry_visual == null:
		return
	_carry_gold_mesh.visible = carry_type == GameData.GOLD and carry_amount > 0.0
	_carry_wood_mesh.visible = carry_type == GameData.WOOD and carry_amount > 0.0
	_carry_visual.visible = carry_amount > 0.0

func _die() -> void:
	if dead:
		return
	dead = true
	if _vm != null and is_instance_valid(_vm):
		_vm.queue_free()
		_vm = null
	if camera != null:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Sound.play("enemy_die")
	GameState.worker = null
	EventBus.worker_died.emit()
	FX.burst(get_parent(), global_position + Vector3(0, 0.8, 0), GameData.COLOR_PLAYER, 24, 0.7, 4.5, 0.9)
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)
