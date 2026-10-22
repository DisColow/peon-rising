extends Node3D

# Entry point. Builds the whole world procedurally and wires everything together.

const WorkerScript := preload("res://scenes/units/worker.gd")
const PlayerScript := preload("res://scenes/units/player.gd")
const GruntScript := preload("res://scenes/units/grunt.gd")
const CommanderScript := preload("res://scenes/commander/commander.gd")
const EnemyCommanderScript := preload("res://scenes/commander/enemy_commander.gd")
const TreeScript := preload("res://scenes/resources/tree.gd")
const MineScript := preload("res://scenes/resources/gold_mine.gd")
const CameraScript := preload("res://scenes/main/camera_rig.gd")
const HudScript := preload("res://scenes/ui/hud.gd")
const TalentUIScript := preload("res://scenes/ui/talent_tree_ui.gd")
const PauseMenuScript := preload("res://scenes/ui/pause_menu.gd")
const TouchUIScript := preload("res://scenes/ui/touch_ui.gd")
const GroundShader := preload("res://shaders/ground.gdshader")

var world: Node3D
var units: Node3D
var camera: Camera3D
var commander: Node
var enemy_commander: Node
var hud: CanvasLayer
var talent_ui: CanvasLayer
var pause_menu: CanvasLayer

var player_townhall: Building
var player_mine: Node
var enemy_townhall: Building
var enemy_mine: Node

var _respawn_timer: float = 0.0
var _respawn_delay: float = 5.0
var _ally_spawn_timer: float = 0.0
var _barracks: Building = null
var _objective_beacon: Node3D = null
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
	# Kick the commander so an objective appears almost immediately.
	commander._tick = 0.6
	EventBus.toast.emit("Incarne un péon : suis les objectifs du commandant !")

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
	# Respawn the player after death.
	if GameState.worker == null or not is_instance_valid(GameState.worker):
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_spawn_player()
	# Friendly reinforcements from the barracks.
	if _barracks != null and is_instance_valid(_barracks) and _barracks.completed:
		_ally_spawn_timer -= delta
		if _ally_spawn_timer <= 0.0:
			_ally_spawn_timer = 6.0
			_spawn_ally_grunt()
	_update_objective_beacon(delta)

func _update_objective_beacon(delta: float) -> void:
	if _objective_beacon == null:
		return
	if not GameState.match_running or commander == null or not is_instance_valid(commander):
		_objective_beacon.visible = false
		return
	_objective_beacon.visible = true
	var pos: Vector3 = commander.get_objective_position() + Vector3(0, 3.0, 0)
	pos.y += sin(_game_time * 2.2) * 0.25
	_objective_beacon.global_position = pos
	_objective_beacon.rotate_y(delta * 1.6)

func _build_environment() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)

	# Ground (procedurally textured grass via shader).
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	world.add_child(ground)
	var ground_mesh := Builder.box(Vector3(MAP_HALF * 2.0, 1.0, MAP_HALF * 2.0), GameData.COLOR_GRASS, 0.95)
	ground_mesh.position = Vector3(0, -0.5, 0)
	ground_mesh.material_override = _ground_mat()
	ground.add_child(ground_mesh)
	var gcol := Builder.collider(ground, Builder.box_shape(Vector3(MAP_HALF * 2.0, 1.0, MAP_HALF * 2.0)))
	gcol.position = Vector3(0, -0.5, 0)

	# A dirt path between the two bases.
	var path := Builder.box(Vector3(4.0, 0.06, 46.0), GameData.COLOR_PATH, 0.95)
	path.position = Vector3(22.5, 0.03, 22.5)
	path.rotation_degrees = Vector3(0, 45, 0)
	world.add_child(path)

	# Sky + ambient + post-processing.
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.52, 0.86)
	sky_mat.sky_horizon_color = Color(0.92, 0.85, 0.70)
	sky_mat.ground_bottom_color = Color(0.22, 0.32, 0.18)
	sky_mat.ground_horizon_color = Color(0.60, 0.70, 0.50)
	sky_mat.sun_angle_max = 12.0
	sky_mat.sun_curve = 0.08
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.0
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Filmic tone mapping + gentle color grade for a vibrant cartoon look.
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.08
	e.tonemap_white = 5.0
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.18
	e.adjustment_contrast = 1.03
	e.glow_enabled = true
	e.glow_intensity = 0.5
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 1.0
	e.ssao_enabled = true
	e.ssao_intensity = 1.6
	e.ssao_radius = 1.0
	e.fog_enabled = true
	e.fog_light_color = Color(0.82, 0.78, 0.68)
	e.fog_density = 0.0022
	# High-end global illumination + atmospheric light scattering (Forward+ only).
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		e.sdfgi_enabled = true
		e.sdfgi_bounce_feedback = 0.55
		e.sdfgi_cascades = 4
		e.volumetric_fog_enabled = true
		e.volumetric_fog_density = 0.018
		e.volumetric_fog_albedo = Color(0.82, 0.78, 0.68)
		e.volumetric_fog_emission = Color(1.0, 0.88, 0.70)
		e.volumetric_fog_emission_energy = 0.6
		e.volumetric_fog_length = 64.0
	env.environment = e
	world.add_child(env)

	# Warm key light (soft shadows) + cool fill for depth.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.shadow_enabled = true
	sun.light_color = Color(1.0, 0.95, 0.82)
	sun.light_energy = 1.25
	sun.shadow_blur = 0.6
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 140, 0)
	fill.light_color = Color(0.55, 0.65, 0.95)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	world.add_child(fill)

func _ground_mat() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GroundShader
	m.set_shader_parameter("grass", GameData.COLOR_GRASS)
	m.set_shader_parameter("grass_light", GameData.COLOR_GRASS.lightened(0.15))
	m.set_shader_parameter("grass_dark", GameData.COLOR_GRASS.darkened(0.18))
	m.set_shader_parameter("dirt", GameData.COLOR_PATH)
	return m

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
	_scatter_grass(Vector3(0, 0, 0), 50.0, 110)

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
	GameState.commander = commander

	enemy_commander = EnemyCommanderScript.new()
	enemy_commander.name = "EnemyCommander"
	add_child(enemy_commander)
	enemy_commander.setup(enemy_townhall, player_townhall, units)

	_spawn_player()
	commander.setup(GameState.worker, player_townhall, player_mine, enemy_townhall)
	# A few autonomous allied workers keep the economy running on their own.
	for i in 3:
		_spawn_ally_worker()

func _spawn_player() -> void:
	var p = PlayerScript.new()
	units.add_child(p)
	p.global_position = player_townhall.global_position + Vector3(0, 1.0, 2.5)
	GameState.worker = p
	if commander != null:
		commander.hero = p
	if camera != null and is_instance_valid(camera):
		camera.target = p
		p.setup_camera(camera)
	_respawn_timer = 0.0
	EventBus.worker_respawned.emit()
	FX.burst(units, p.global_position + Vector3(0, 1.0, 0), GameData.COLOR_PLAYER, 10, 0.5, 2.5, 0.5)

func _spawn_ally_worker() -> void:
	var w = WorkerScript.new()
	units.add_child(w)
	w.global_position = player_townhall.global_position + Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3))

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
	if GameState.worker != null and is_instance_valid(GameState.worker):
		GameState.worker.setup_camera(camera)

	hud = HudScript.new()
	hud.name = "HUD"
	add_child(hud)

	talent_ui = TalentUIScript.new()
	talent_ui.name = "TalentUI"
	add_child(talent_ui)

	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)

	var touch_ui = TouchUIScript.new()
	touch_ui.name = "TouchUI"
	add_child(touch_ui)

	_create_objective_beacon()

func _create_objective_beacon() -> void:
	_objective_beacon = Node3D.new()
	_objective_beacon.name = "ObjectiveBeacon"
	world.add_child(_objective_beacon)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.86, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.05)
	mat.emission_energy_multiplier = 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var arrow := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.5
	cm.height = 1.0
	arrow.mesh = cm
	arrow.material_override = mat
	arrow.rotation_degrees = Vector3(180, 0, 0)
	_objective_beacon.add_child(arrow)

	var glow := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.26
	sm.height = 0.52
	glow.mesh = sm
	glow.material_override = mat
	glow.position = Vector3(0, 0.9, 0)
	_objective_beacon.add_child(glow)

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
		Sound.play("victory")
		EventBus.toast.emit("Base ennemie détruite ! Victoire !")
	else:
		GameState.victory = false
		Sound.play("defeat")
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
	Sound.play("build_done")
	if b.team == GameData.TEAM_PLAYER and b.building_key == "barracks":
		_barracks = b
		_ally_spawn_timer = 3.0

# --- Influence / input handling ---

func suggest(action: String) -> void:
	if GameState.consume_influence(1.0):
		commander.suggest(action)
	else:
		EventBus.toast.emit("Pas assez d'influence (se recharge)")

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("open_talents"):
		talent_ui.toggle()
	elif event.is_action_pressed("suggest_attack"):
		suggest("attack_now")
	elif event.is_action_pressed("suggest_defend"):
		suggest("defend")
	elif event.is_action_pressed("suggest_gold"):
		suggest("focus_gold")
	elif event.is_action_pressed("suggest_wood"):
		suggest("focus_wood")

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

func _scatter_grass(center: Vector3, radius: float, count: int) -> void:
	for i in count:
		var is_flower := randf() < 0.18
		var col := Color(0.5, 0.78, 0.32) if not is_flower else Color(0.9, 0.85, 0.4)
		var tuft := Builder.cone(randf_range(0.08, 0.2), randf_range(0.25, 0.7), col, 0.9)
		var ang := randf_range(0, TAU)
		var rad := randf_range(0, radius)
		tuft.position = center + Vector3(cos(ang) * rad, 0.12, sin(ang) * rad)
		world.add_child(tuft)
