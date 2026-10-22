extends Node

# Holds the state of the current match. Autoload singleton accessible as `GameState`.

# --- Economy ---
var gold: int = 0
var wood: int = 0
var food_used: int = 0
var food_max: int = 0

# --- Per-run progression (roguelite) ---
var level: int = 1
var xp: int = 0
var talent_points: int = 0
var unlocked_talents: Array = []   # list of [tree, id]

# --- Influence (the "pet" mechanic) ---
var influence: float = 3.0
var influence_max: float = 3.0

# --- Match state ---
var match_running: bool = false
var victory: bool = false

# References injected by Main.
var main: Node = null
var worker: Node = null
var commander: Node = null

const XP_PER_LEVEL := 100.0

func reset_run() -> void:
	gold = 120
	wood = 100
	food_used = 0
	food_max = 10
	level = 1
	xp = 0
	talent_points = 0
	unlocked_talents.clear()
	influence = influence_max
	match_running = true
	victory = false
	_emit_resources()

# Roguelite reset: the talent tree (and points) are lost when the worker dies,
# but the base economy and permanent meta progression survive.
func reset_worker_progression() -> void:
	level = 1
	xp = 0
	talent_points = 0
	unlocked_talents.clear()
	EventBus.xp_changed.emit(xp, xp_needed(), level)
	EventBus.talent_point_gained.emit(talent_points)

func _process(delta: float) -> void:
	if match_running and influence < influence_max:
		gain_influence(delta / 12.0)

func _emit_resources() -> void:
	EventBus.resource_changed.emit(gold, wood, food_used, food_max)

func add_resource(type: String, amount: int) -> void:
	match type:
		GameData.GOLD: gold += amount
		GameData.WOOD: wood += amount
		GameData.FOOD: food_used += amount
	_emit_resources()

func can_afford(g: int, w: int) -> bool:
	return gold >= g and wood >= w

func spend(g: int, w: int) -> bool:
	if not can_afford(g, w):
		return false
	gold -= g
	wood -= w
	_emit_resources()
	return true

func gain_xp(amount: int) -> void:
	xp += amount
	var needed := xp_needed()
	while xp >= needed:
		xp -= needed
		level += 1
		talent_points += 1
		EventBus.talent_point_gained.emit(talent_points)
		EventBus.toast.emit("Niveau %d ! +1 point de talent" % level)
		needed = xp_needed()
	EventBus.xp_changed.emit(xp, needed, level)

func xp_needed() -> int:
	return XP_PER_LEVEL + (level - 1) * 40

func spend_talent_point(tree: String, id: String) -> bool:
	if talent_points <= 0:
		return false
	var node := TalentDB.node(tree, id)
	if node.is_empty():
		return false
	if has_talent(tree, id):
		return false
	talent_points -= 1
	unlocked_talents.append([tree, id])
	EventBus.talent_unlocked.emit(tree, id)
	if worker != null:
		worker.refresh_stats()
	return true

func has_talent(tree: String, id: String) -> bool:
	for t in unlocked_talents:
		if t[0] == tree and t[1] == id:
			return true
	return false

func gain_influence(amount: float) -> void:
	influence = clampf(influence + amount, 0.0, influence_max)
	EventBus.influence_changed.emit(influence, influence_max)

func consume_influence(amount: float) -> bool:
	if influence < amount:
		return false
	influence -= amount
	EventBus.influence_changed.emit(influence, influence_max)
	return true
