extends Node

# Lightweight grid-based A* pathfinding for the (mostly flat) map.
# Obstacles (buildings, trees, rocks) are registered as blocked cells so units
# path around them instead of getting stuck. Autoload singleton: `Pathfinder`.

const CELL := 2.0
const BOUNDS := 60.0
const SIZE := int(BOUNDS * 2.0 / CELL)
const KEYBASE := 2 * SIZE + 1
const AGENT_RADIUS := 0.6
const MAX_ITER := 5000

var _blocked := {}

func _key(c: Vector2i) -> int:
	return (c.x + SIZE) * KEYBASE + (c.y + SIZE)

func _unkey(k: int) -> Vector2i:
	return Vector2i(k / KEYBASE - SIZE, k % KEYBASE - SIZE)

func world_to_cell(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x / CELL)), int(floor(p.z / CELL)))

func cell_to_world(c: Vector2i) -> Vector3:
	return Vector3(c.x * CELL + CELL * 0.5, 0.0, c.y * CELL + CELL * 0.5)

func is_blocked(c: Vector2i) -> bool:
	if c.x < -SIZE or c.x >= SIZE or c.y < -SIZE or c.y >= SIZE:
		return true
	return _blocked.has(_key(c))

func register_obstacle(pos: Vector3, radius: float) -> void:
	var c := world_to_cell(pos)
	var effective := radius + AGENT_RADIUS + CELL * 0.5
	var r := maxi(1, int(ceil(effective / CELL)))
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var cell := Vector2i(c.x + dx, c.y + dz)
			if cell_to_world(cell).distance_to(Vector3(pos.x, 0.0, pos.z)) <= effective:
				_blocked[_key(cell)] = true

func clear() -> void:
	_blocked.clear()

func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := world_to_cell(from)
	var goal := world_to_cell(to)
	var out := PackedVector3Array()
	if start == goal:
		out.append(to)
		return out
	if is_blocked(goal):
		goal = _nearest_free(goal)

	var g := {_key(start): 0.0}
	var came := {}
	var open := {_key(start): true}
	var iter := 0
	while not open.is_empty():
		iter += 1
		if iter > MAX_ITER:
			break
		# Find the open node with the lowest f score (small grids, linear scan is fine).
		var current_key := 0
		var best_f := INF
		for k in open.keys():
			var f: float = g.get(k, INF) + _heuristic_key(k, goal)
			if f < best_f:
				best_f = f
				current_key = k
		if current_key == _key(goal):
			break
		open.erase(current_key)
		var current := _unkey(current_key)
		for n in _neighbors(current):
			var nk := _key(n)
			var tentative: float = g.get(current_key, INF) + 1.0
			if tentative < g.get(nk, INF):
				g[nk] = tentative
				came[nk] = current_key
				open[nk] = true

	# Reconstruct.
	var cells := []
	var cur := _key(goal)
	while cur != _key(start):
		cells.append(cur)
		if not came.has(cur):
			break
		cur = came[cur]
	cells.reverse()
	for ck in cells:
		out.append(cell_to_world(_unkey(ck)))
	out.append(to)
	return out

func _nearest_free(c: Vector2i) -> Vector2i:
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var n := Vector2i(c.x + dx, c.y + dz)
				if not is_blocked(n):
					return n
	return c

func _heuristic_key(k: int, goal: Vector2i) -> float:
	var c := _unkey(k)
	return absf(c.x - goal.x) + absf(c.y - goal.y)

func _neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	for d in dirs:
		var n := c + d
		if not is_blocked(n):
			out.append(n)
	return out
