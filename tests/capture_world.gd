extends SceneTree

# Captures the real KayKit world props (castle, farm, barracks, tower, mine,
# tree) in one composed scene — visual proof the environment is no longer
# procedural primitives. Env: SHOT_OUT, FRAME.

var frames := 0
var settle := 25

func _initialize() -> void:
	var out := OS.get_environment("SHOT_OUT")
	if out == "":
		out = "/tmp/world.png"
	if OS.get_environment("FRAME") != "":
		settle = int(OS.get_environment("FRAME"))

	var world := Node3D.new()
	root.add_child(world)
	_scene(world)

	var props := [
		["res://assets/models/kaykit_props/buildings_green/building_castle_green.gltf", Vector3(-6, 0, -3), 3.2],
		["res://assets/models/kaykit_props/buildings_green/building_barracks_green.gltf", Vector3(0, 0, -4), 2.4],
		["res://assets/models/kaykit_props/buildings_green/building_home_A_green.gltf", Vector3(5, 0, -3), 1.6],
		["res://assets/models/kaykit_props/buildings_green/building_tower_A_green.gltf", Vector3(7, 0, 1), 3.4],
		["res://assets/models/kaykit_props/nature/tree_single_A.gltf", Vector3(-4, 0, 3), 3.6],
		["res://assets/models/kaykit_props/nature/tree_single_B.gltf", Vector3(-2, 0, 5), 3.2],
		["res://assets/models/kaykit_props/buildings_green/building_mine_green.gltf", Vector3(3, 0, 4), 2.4],
	]
	for pr in props:
		var m := KayKitProp.create(world, pr[0], 1.0)
		if m != null:
			KayKitProp.scale_to_height(m, pr[2])
			m.position = pr[1]

	var cam := Camera3D.new()
	cam.position = Vector3(2.5, 7.5, 13.0)
	cam.transform = cam.transform.looking_at(Vector3(0, 1.2, 0), Vector3.UP)
	world.add_child(cam)
	cam.current = true
	cam.fov = 45.0

func _process(_delta: float) -> bool:
	frames += 1
	if frames == settle:
		var img: Image = root.get_texture().get_image()
		var err := img.save_png(OS.get_environment("SHOT_OUT"))
		print("CAPTURE ", OS.get_environment("SHOT_OUT"), " err=", err)
		quit(0 if err == OK else 1)
	return false

func _scene(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var ground := MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(60, 60)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.32, 0.52, 0.23)
	ground.material_override = gmat
	world.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_energy = 0.5
	world.add_child(fill)
