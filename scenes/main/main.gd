extends Node3D

# Entry point. Builds the whole world procedurally and wires everything together.

const WorkerScript := preload("res://scenes/units/worker.gd")
const GruntScript := preload("res://scenes/units/grunt.gd")
const CommanderScript := preload("res://scenes/commander/commander.gd")
const EnemyCommanderScript := preload("res://scenes/commander/enemy_commander.gd")
const TreeScript := preload("res://scenes/resources/tree.gd")
const MineScript := preload("res://scenes/resources/gold_mine.gd")
const CameraScript := preload("res://scenes/main/camera_rig.gd")
const HudScript := preload("res://scenes/ui/hud.gd")
const TalentUIScript := preload("res://scenes/ui/talent_tree_ui.gd")

var world: Node3D
var units: Node3D
var camera: Camera3D
var commander: Node
var enemy_commander: Node
var hud: CanvasLayer
var talent_ui: CanvasLayer

var player_townhall: Building
var player_mine: Node
var enemy_townhall: Building
var enemy_mine: Node

var _respawn_timer: float = 0.0
var _respawn_delay: float = 5.0
var _tower_mode: bool = false
var _ally_spawn_timer: float = 0.0
var _barracks: Building = null
var _debug_timer: float = 1.0
var _game_time: float = 0.0

const MAP_HALF := 60.0

func _ready() -> void:
	GameState.main = self
	GameState.reset_run()
	_build_environment()
	_build_bases()
	_register_navigation_obstacles()
	_build_units_and_brains()
	_build_ui()
	_wire_signals()
	# Kick the commander so the worker gets an order almost immediately.
	commander._tick = 0.6
	EventBus.toast.emit("Incarne un péon : obéis aux ordres !")

func _process(delta: float) -> void:
	if not GameState.match_running:
		return
	_game_time += delta
	if OS.has_environment("PEON_DEBUG"):
		_debug_timer -= delta
		if _debug_timer <= 0.0:
			_debug_timer = 5.0
			var w := GameState.worker
			var alive := w != null and is_instance_valid(w)
			print("[peon] t=%.0fs gold=%d wood=%d lvl=%d pts=%d order=%s worker=%s" % [
				_game_time, GameState.gold, GameState.wood, GameState.level,
				GameState.talent_points,
				("—" if not alive else w.describe_order()),
				("vivant" if alive else "mort"),
			])
	# Respawn the worker after it dies.
	if GameState.worker == null or not is_instance_valid(GameState.worker):
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_spawn_worker()
	# Friendly reinforcements from the barracks.
	if _barracks != null and is_instance_valid(_barracks) and _barracks.completed:
		_ally_spawn_timer -= delta
		if _ally_spawn_timer <= 0.0:
			_ally_spawn_timer = 6.0
			_spawn_ally_grunt()

func _build_environment() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)

	# Ground.
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	world.add_child(ground)
	var ground_mesh := Builder.box(Vector3(MAP_HALF * 2.0, 1.0, MAP_HALF * 2.0), GameData.COLOR_GRASS, 0.9)
	ground_mesh.position = Vector3(0, -0.5, 0)
	ground.add_child(ground_mesh)
	var gcol := Builder.collider(ground, Builder.box_shape(Vector3(MAP_HALF * 2.0, 1.0, MAP_HALF * 2.0)))
	gcol.position = Vector3(0, -0.5, 0)

	# A dirt path between the two bases.
	var path := Builder.box(Vector3(4.0, 0.06, 46.0), GameData.COLOR_PATH, 0.95)
	path.position = Vector3(22.5, 0.03, 22.5)
	path.rotation_degrees = Vector3(0, 45, 0)
	world.add_child(path)

	# Sky + ambient.
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.30, 0.58, 0.90)
	sky_mat.sky_horizon_color = Color(0.72, 0.86, 0.92)
	sky_mat.ground_bottom_color = GameData.COLOR_GRASS
	sky_mat.ground_horizon_color = GameData.COLOR_GRASS
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	env.environment = e
	world.add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.shadow_enabled = true
	light.light_energy = 1.15
	world.add_child(light)

func _build_bases() -> void:
	# Player base near the origin.
	player_townhall = Building.create_built("town_hall", Vector3(0, 0, 0), GameData.TEAM_PLAYER)
	world.add_child(player_townhall)
	player_mine = MineScript.new()
	world.add_child(player_mine)
	player_mine.global_position = Vector3(10, 0, -6)
	_scatter_trees(Vector3(-8, 0, -8), 12.0, 12)
	_scatter_trees(Vector3(8, 0, 8), 10.0, 6)
	_scatter_rocks(Vector3(0, 0, 0), 18.0, 8)

	# Enemy base across the map.
	var enemy_pos := Vector3(45, 0, 45)
	enemy_townhall = Building.create_built("town_hall", enemy_pos, GameData.TEAM_ENEMY)
	world.add_child(enemy_townhall)
	enemy_mine = MineScript.new()
	world.add_child(enemy_mine)
	enemy_mine.global_position = enemy_pos + Vector3(-8, 0, 6)
	_scatter_trees(enemy_pos, 12.0, 10)
	# Enemy defense towers.
	var t1 := Building.create_built("tower", enemy_pos + Vector3(5, 0, 5), GameData.TEAM_ENEMY)
	world.add_child(t1)
	var t2 := Building.create_built("tower", enemy_pos + Vector3(-5, 0, 5), GameData.TEAM_ENEMY)
	world.add_child(t2)

func _build_units_and_brains() -> void:
	units = Node3D.new()
	units.name = "Units"
	add_child(units)

	commander = CommanderScript.new()
	commander.name = "Commander"
	add_child(commander)
	commander.setup(null, player_townhall, player_mine, enemy_townhall)

	enemy_commander = EnemyCommanderScript.new()
	enemy_commander.name = "EnemyCommander"
	add_child(enemy_commander)
	enemy_commander.setup(enemy_townhall, player_townhall, units)

	_spawn_worker()

func _spawn_worker() -> void:
	var w = WorkerScript.new()
	units.add_child(w)
	w.global_position = player_townhall.global_position + Vector3(0, 1.0, 2.5)
	GameState.worker = w
	commander.worker = w
	_respawn_timer = 0.0
	EventBus.worker_respawned.emit()
	FX.burst(units, w.global_position + Vector3(0, 1.0, 0), GameData.COLOR_PLAYER, 10, 0.5, 2.5, 0.5)

func _spawn_ally_grunt() -> void:
	var g = GruntScript.new()
	g.team = GameData.TEAM_PLAYER
	g.max_hp = 110.0
	g.attack_damage = 13.0
	g.move_speed = 3.8
	g.attack_mode = "seek_base"
	g.target_position = enemy_townhall.global_position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	units.add_child(g)
	g.global_position = _barracks.global_position + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2))

func _build_ui() -> void:
	camera = CameraScript.new()
	add_child(camera)
	camera.setup(GameState.worker)

	hud = HudScript.new()
	hud.name = "HUD"
	add_child(hud)

	talent_ui = TalentUIScript.new()
	talent_ui.name = "TalentUI"
	add_child(talent_ui)

func _wire_signals() -> void:
	EventBus.worker_died.connect(_on_worker_died)
	EventBus.base_destroyed.connect(_on_base_destroyed)
	EventBus.building_completed.connect(_on_building_completed)

func _on_worker_died() -> void:
	_respawn_timer = _respawn_delay
	GameState.reset_worker_progression()
	EventBus.toast.emit("Péon éliminé ! Entraînement d'un nouveau…")

func _on_base_destroyed(team: String) -> void:
	if not GameState.match_running:
		return
	GameState.match_running = false
	if team == GameData.TEAM_ENEMY:
		GameState.victory = true
		EventBus.toast.emit("Base ennemie détruite ! Victoire !")
	else:
		GameState.victory = false
		EventBus.toast.emit("Notre base est tombée… Défaite.")
	# Award meta essence on victory.
	if GameState.victory:
		Meta.add_essence(100 + GameState.level * 20)
	EventBus.match_ended.emit(GameState.victory)

func _building_radius(b: Building) -> float:
	var s: Vector3 = GameData.BUILDINGS.get(b.building_key, {}).get("scale", Vector3(2, 2, 2))
	return maxf(s.x, s.z) * 0.5

func _register_navigation_obstacles() -> void:
	Pathfinder.clear()
	for b in get_tree().get_nodes_in_group("building"):
		if not is_instance_valid(b):
			continue
		Pathfinder.register_obstacle((b as Node3D).global_position, _building_radius(b))
	for t in get_tree().get_nodes_in_group("tree"):
		if is_instance_valid(t):
			Pathfinder.register_obstacle((t as Node3D).global_position, 1.0)
	for m in get_tree().get_nodes_in_group("gold_mine"):
		if is_instance_valid(m):
			Pathfinder.register_obstacle((m as Node3D).global_position, 1.7)
	for r in get_tree().get_nodes_in_group("rock"):
		if is_instance_valid(r):
			Pathfinder.register_obstacle((r as Node3D).global_position, 0.7)

func _on_building_completed(b: Building) -> void:
	Pathfinder.register_obstacle(b.global_position, _building_radius(b))
	commander.notify_building_done(b.building_key)
	if b.team == GameData.TEAM_PLAYER and b.building_key == "barracks":
		_barracks = b
		_ally_spawn_timer = 3.0

# --- Influence / input handling ---

func suggest(action: String) -> void:
	if GameState.consume_influence(1.0):
		commander.suggest(action)
	else:
		EventBus.toast.emit("Pas assez d'influence (se recharge)")

func toggle_tower_mode() -> void:
	_tower_mode = not _tower_mode
	if _tower_mode:
		EventBus.toast.emit("Clique sur le sol pour placer une tour (clic droit annule).")
	else:
		EventBus.toast.emit("Placement de tour annulé.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_ping(event.position)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _tower_mode:
			_tower_mode = false
			EventBus.toast.emit("Placement de tour annulé.")
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_ping(get_viewport().get_mouse_position())
	elif event.is_action_pressed("open_talents"):
		talent_ui.toggle()
	elif event.is_action_pressed("cancel_order"):
		_cancel_current_order()

func _handle_ping(screen_pos: Vector2) -> void:
	var pos := _ray_to_ground(screen_pos)
	_ping_marker(pos)
	if _tower_mode:
		_tower_mode = false
		if GameState.consume_influence(1.0):
			commander.suggest("build_tower_here", pos)
		else:
			EventBus.toast.emit("Pas assez d'influence (se recharge)")

func _ray_to_ground(screen_pos: Vector2) -> Vector3:
	if camera == null:
		return Vector3.ZERO
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return from
	var t := -from.y / dir.y
	return from + dir * t

func _ping_marker(pos: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = 0.06
	ring.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(ring)
	ring.global_position = pos + Vector3(0, 0.06, 0)
	var t := ring.create_tween()
	t.set_parallel(true)
	t.tween_property(ring, "scale", Vector3(2.2, 1.0, 2.2), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "transparency", 1.0, 0.9)
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(ring.queue_free)

func _cancel_current_order() -> void:
	var w := GameState.worker
	if w == null or not is_instance_valid(w):
		return
	# Refusing an order lets the commander re-think, at a small influence cost.
	if GameState.consume_influence(1.0):
		EventBus.toast.emit("Ordre refusé : le commandant réévalue.")
		commander._tick = 0.3
	else:
		EventBus.toast.emit("Pas assez d'influence pour désobéir.")

func _scatter_trees(center: Vector3, radius: float, count: int) -> void:
	for i in count:
		var t = TreeScript.new()
		world.add_child(t)
		var ang := randf_range(0, TAU)
		var r := randf_range(2.0, radius)
		t.global_position = center + Vector3(cos(ang) * r, 0.0, sin(ang) * r)

func _scatter_rocks(center: Vector3, radius: float, count: int) -> void:
	for i in count:
		var r := StaticBody3D.new()
		var m := Builder.sphere(randf_range(0.4, 0.9), GameData.COLOR_ROCK, 0.8)
		m.scale = Vector3(1, randf_range(0.5, 0.8), 1)
		r.add_child(m)
		Builder.collider(r, Builder.sphere_shape(0.7))
		r.add_to_group("rock")
		world.add_child(r)
		var ang := randf_range(0, TAU)
		var rad := randf_range(2.0, radius)
		r.global_position = center + Vector3(cos(ang) * rad, 0.3, sin(ang) * rad)
