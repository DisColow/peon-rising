extends Node

# The AI "player" that runs the match and tells the *human* what to do.
# It only picks objectives; the human does the walking, chopping, building and
# fighting. Objectives are shown permanently on the HUD.

var hero: Node = null          # the player-controlled peon
var base: Node = null          # player town hall
var mine: Node = null
var enemy_base: Node = null

var objective: Order = Order.new(Order.Type.GATHER_WOOD)
var _active_ghost: Building = null

var _tick: float = 0.0
var _tick_interval: float = 2.0
var _game_time: float = 0.0

var _focus: String = ""        # "", "gold" or "wood"
var _focus_timer: float = 0.0
var _attack_rally: bool = false

var towers_built: int = 0
var barracks_built: int = 0
var farms_built: int = 0

func setup(p_hero: Node, p_base: Node, p_mine: Node, p_enemy_base: Node) -> void:
	hero = p_hero
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
	_tick -= delta
	if _tick <= 0.0:
		_tick = _tick_interval
		_evaluate()

func describe_objective() -> String:
	return objective.describe()

func _evaluate() -> void:
	# A build objective stays until the ghost the commander placed is complete.
	if _active_ghost != null and is_instance_valid(_active_ghost) and not _active_ghost.is_completed():
		return
	_active_ghost = null
	var next := _choose_objective()
	if next != null:
		_set_objective(next)

func _choose_objective() -> Order:
	# Defend against an immediate threat.
	var threat := _nearest_enemy_near_base(10.0)
	if threat != null:
		return Order.new(Order.Type.ATTACK, threat)

	if _attack_rally and _army_ready():
		return Order.new(Order.Type.ATTACK, enemy_base)

	# Build economy / defense / army, in priority order.
	var build := _next_building_to_build()
	if build != "":
		var spot := _find_build_spot()
		return Order.new(Order.Type.BUILD, null, spot, build)

	# Late game: push the enemy base.
	if _army_ready() and _game_time > 90.0:
		return Order.new(Order.Type.ATTACK, enemy_base)

	# Economy gathering.
	if _focus == "wood":
		return Order.new(Order.Type.GATHER_WOOD)
	if _focus == "gold":
		return Order.new(Order.Type.GATHER_GOLD)
	var gold_ratio := float(GameState.gold) / 220.0
	var wood_ratio := float(GameState.wood) / 220.0
	if gold_ratio <= wood_ratio:
		return Order.new(Order.Type.GATHER_GOLD)
	return Order.new(Order.Type.GATHER_WOOD)

func _next_building_to_build() -> String:
	if farms_built < 1 and _can_build("farm"):
		return "farm"
	if towers_built < 1 and _can_build("tower"):
		return "tower"
	if barracks_built < 1 and _can_build("barracks"):
		return "barracks"
	if towers_built < 2 and _can_build("tower"):
		return "tower"
	return ""

func _set_objective(o: Order) -> void:
	objective = o
	if o.type == Order.Type.BUILD:
		_place_ghost(o.building_type, o.position)
	EventBus.order_assigned.emit(o)

func _place_ghost(key: String, pos: Vector3) -> void:
	if _active_ghost != null and is_instance_valid(_active_ghost):
		return
	var data: Dictionary = GameData.BUILDINGS[key]
	var discount := _discount()
	var cost_gold := int(data["gold"] * (1.0 - discount))
	var cost_wood := int(data["wood"] * (1.0 - discount))
	if not GameState.spend(cost_gold, cost_wood):
		return
	var g := Building.create_ghost(key, pos, GameData.TEAM_PLAYER)
	if base != null and is_instance_valid(base):
		base.get_parent().add_child(g)
	_active_ghost = g

func _discount() -> float:
	if hero != null and is_instance_valid(hero) and hero.has_method("get_stats"):
		return hero.get_stats().get("build_discount", 0.0)
	return 0.0

func _can_build(key: String) -> bool:
	var b: Dictionary = GameData.BUILDINGS[key]
	return GameState.can_afford(int(b["gold"] * (1.0 - _discount())), int(b["wood"] * (1.0 - _discount())))

func suggest(action: String, data = null) -> void:
	match action:
		"attack_now":
			_attack_rally = true
			EventBus.toast.emit("Je lance l'assaut !")
		"defend":
			EventBus.toast.emit("On fortifie la base.")
		"focus_gold":
			_focus = "gold"
			_focus_timer = 30.0
			EventBus.toast.emit("Objectif : de l'or !")
		"focus_wood":
			_focus = "wood"
			_focus_timer = 30.0
			EventBus.toast.emit("Objectif : du bois !")

func _army_ready() -> bool:
	return barracks_built >= 1

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

func notify_building_done(key: String) -> void:
	match key:
		"farm":
			farms_built += 1
		"barracks":
			barracks_built += 1
		"tower":
			towers_built += 1
