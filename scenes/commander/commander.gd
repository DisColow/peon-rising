extends Node

# The AI "player" that runs the RTS match and orders the worker around.
# It is deliberately a little imperfect so the human can meaningfully steer it
# through the influence system (suggestions / pings).

var worker: Node = null
var base: Node = null          # player town hall
var mine: Node = null
var enemy_base: Node = null

var _tick: float = 0.0
var _tick_interval: float = 2.0

var _focus: String = ""        # "", "gold" or "wood"
var _focus_timer: float = 0.0
var _attack_rally: bool = false
var _defend_now: bool = false
var _ping_build: bool = false
var _ping_position: Vector3 = Vector3.ZERO

var towers_built: int = 0
var barracks_built: int = 0
var farms_built: int = 0
var _game_time: float = 0.0

func setup(p_worker: Node, p_base: Node, p_mine: Node, p_enemy_base: Node) -> void:
	worker = p_worker
	base = p_base
	mine = p_mine
	enemy_base = p_enemy_base

func _process(delta: float) -> void:
	if not GameState.match_running:
		return
	_game_time += delta
	_focus_timer = maxf(0.0, _focus_timer - delta)
	if _focus_timer <= 0.0:
		_focus = ""
	if worker == null or not is_instance_valid(worker):
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = _tick_interval
		_evaluate()

func _evaluate() -> void:
	if worker == null or not is_instance_valid(worker):
		return
	var intended := _intended_order()
	if OS.has_environment("PEON_DEBUG"):
		print("[cmd] ordre=%s fermes=%d tours=%d casernes=%d or=%d bois=%d" % [
			intended.describe() if intended != null else "null",
			farms_built, towers_built, barracks_built, GameState.gold, GameState.wood,
		])
	if intended == null:
		return
	var w := worker
	# Never interrupt an in-progress construction: the worker spent resources on
	# it already, and re-checking affordability would wrongly abandon it.
	if w.current_order_type() == Order.Type.BUILD and not w.is_idle():
		return
	var same_type: bool = w.current_order_type() == intended.type
	if w.is_idle() or (not same_type and not w.is_carrying()):
		w.assign_order(intended)
		EventBus.order_assigned.emit(intended)
	elif same_type and intended.type == Order.Type.BUILD and w.order.building_type != intended.building_type and not w.is_carrying():
		w.assign_order(intended)
		EventBus.order_assigned.emit(intended)

func _intended_order() -> Order:
	# Influence overrides.
	if _ping_build:
		_ping_build = false
		return Order.new(Order.Type.BUILD, null, _ping_position, "tower")

	if _defend_now:
		_defend_now = false
		EventBus.toast.emit("Bien vu : je fortifie la base !")
		return Order.new(Order.Type.BUILD, null, _find_build_spot(), "tower")

	if _attack_rally:
		if _army_ready():
			return Order.new(Order.Type.ATTACK, enemy_base)
		EventBus.toast.emit("Pas encore prêt à attaquer… je me prépare.")
		_attack_rally = false

	# Defensive: enemy near our base -> defend.
	var threat := _nearest_enemy_near_base(9.0)
	if threat != null:
		return Order.new(Order.Type.ATTACK, threat)

	# Economy growth: food, defense, army.
	if farms_built < 1 and _can_build("farm"):
		return Order.new(Order.Type.BUILD, null, _find_build_spot(), "farm")
	if towers_built < 1 and _can_build("tower"):
		return Order.new(Order.Type.BUILD, null, _find_build_spot(), "tower")
	if barracks_built < 1 and _can_build("barracks"):
		return Order.new(Order.Type.BUILD, null, _find_build_spot(), "barracks")
	if towers_built < 2 and _can_build("tower"):
		return Order.new(Order.Type.BUILD, null, _find_build_spot(), "tower")

	# Late game: push the enemy base.
	if _army_ready() and _game_time > 90.0:
		return Order.new(Order.Type.ATTACK, enemy_base)

	# Repair damaged buildings.
	var damaged := _nearest_damaged_building()
	if damaged != null:
		return Order.new(Order.Type.REPAIR, damaged, (damaged as Node3D).global_position)

	# Economy.
	if _focus == "wood":
		return Order.new(Order.Type.GATHER_WOOD)
	if _focus == "gold":
		return Order.new(Order.Type.GATHER_GOLD)
	# Gather whichever resource is relatively scarcer.
	var gold_ratio := float(GameState.gold) / 220.0
	var wood_ratio := float(GameState.wood) / 220.0
	if gold_ratio <= wood_ratio:
		return Order.new(Order.Type.GATHER_GOLD)
	return Order.new(Order.Type.GATHER_WOOD)

func suggest(action: String, data = null) -> void:
	match action:
		"attack_now":
			_attack_rally = true
			EventBus.toast.emit("Je lance l'assaut !")
		"defend":
			_defend_now = true
		"focus_gold":
			_focus = "gold"
			_focus_timer = 30.0
			EventBus.toast.emit("On met l'accent sur l'or.")
		"focus_wood":
			_focus = "wood"
			_focus_timer = 30.0
			EventBus.toast.emit("On met l'accent sur le bois.")
		"build_tower_here":
			_ping_build = true
			_ping_position = data
			EventBus.toast.emit("Une tour ici ? D'accord.")

func _army_ready() -> bool:
	return barracks_built >= 1

func _can_build(key: String) -> bool:
	var b: Dictionary = GameData.BUILDINGS[key]
	var discount := 1.0
	if worker != null and is_instance_valid(worker) and worker.has_method("get_stats"):
		discount = 1.0 - worker.get_stats().get("build_discount", 0.0)
	return GameState.can_afford(int(b["gold"] * discount), int(b["wood"] * discount))

func _find_build_spot() -> Vector3:
	var center := (base as Node3D).global_position if base != null else Vector3.ZERO
	for ring in [7.0, 9.0, 11.0, 13.0]:
		for i in 8:
			var ang := TAU * float(i) / 8.0 + randf_range(-0.2, 0.2)
			var pos := center + Vector3(cos(ang) * ring, 0.0, sin(ang) * ring)
			if _is_spot_free(pos):
				return pos
	return center + Vector3(14, 0, 14)

func _is_spot_free(pos: Vector3) -> bool:
	for b in get_tree().get_nodes_in_group("building"):
		if not is_instance_valid(b):
			continue
		if pos.distance_to((b as Node3D).global_position) < 5.5:
			return false
	for t in get_tree().get_nodes_in_group("tree"):
		if not is_instance_valid(t):
			continue
		if pos.distance_to((t as Node3D).global_position) < 2.5:
			return false
	for r in get_tree().get_nodes_in_group("rock"):
		if not is_instance_valid(r):
			continue
		if pos.distance_to((r as Node3D).global_position) < 2.0:
			return false
	if mine != null and is_instance_valid(mine) and pos.distance_to((mine as Node3D).global_position) < 5.0:
		return false
	return true

func _nearest_enemy_near_base(radius: float) -> Node:
	if base == null:
		return null
	var center := (base as Node3D).global_position
	var best: Node = null
	var best_d := radius * radius
	for n in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(n):
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		var d := center.distance_squared_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _nearest_damaged_building() -> Node:
	var best: Node = null
	var best_d := INF
	for b in get_tree().get_nodes_in_group("building_player"):
		if not is_instance_valid(b) or not b.has_method("is_damaged"):
			continue
		if not b.is_damaged():
			continue
		if worker != null and is_instance_valid(worker):
			var d := (worker as Node3D).global_position.distance_squared_to((b as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = b
	return best

func notify_building_done(key: String) -> void:
	match key:
		"farm": farms_built += 1
		"barracks": barracks_built += 1
		"tower": towers_built += 1
