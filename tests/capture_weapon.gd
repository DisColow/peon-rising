extends SceneTree

# Close-up capture of a weapon held in the KayKit hand, using the same
# attachment code as worker.gd / grunt.gd, so grip orientation is visually
# confirmed. Env: MODEL, WEAPON (sword|mace|pickaxe), SHOT_OUT, FRAME.

var frames := 0
var settle := 20

func _initialize() -> void:
	var model := OS.get_environment("MODEL")
	var weapon := OS.get_environment("WEAPON")
	var out := OS.get_environment("SHOT_OUT")
	if model == "":
		model = "res://assets/models/kaykit/Knight.glb"
	if weapon == "":
		weapon = "sword"
	if out == "":
		out = "/tmp/weapon.png"
	if OS.get_environment("FRAME") != "":
		settle = int(OS.get_environment("FRAME"))

	var world := Node3D.new()
	root.add_child(world)
	_build_scene(world)

	var rig := KayKitRig.create(world, model, 1.2)
	_attach_weapon(rig, weapon)
	if rig.anim != null and rig.anim.has_animation("Idle"):
		rig.anim.play("Idle")

	# Frame the right hand + weapon (hand rest ~ (-0.88, 1.05, 0) at scale 1).
	var cam := Camera3D.new()
	cam.position = Vector3(0.9, 1.5, 2.1)
	cam.transform = cam.transform.looking_at(Vector3(-0.9, 1.45, 0.0), Vector3.UP)
	world.add_child(cam)
	cam.current = true
	cam.fov = 35.0

func _process(_delta: float) -> bool:
	frames += 1
	if frames == settle:
		var img: Image = root.get_texture().get_image()
		var err := img.save_png(OS.get_environment("SHOT_OUT"))
		print("CAPTURE ", OS.get_environment("SHOT_OUT"), " err=", err)
		quit(0 if err == OK else 1)
	return false

func _build_scene(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var ground := MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(40, 40)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.30, 0.34, 0.20)
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

func _attach_weapon(rig: KayKitRig, kind: String) -> void:
	var hand: Node3D = rig.tool_r
	if hand == null:
		return
	var handle := Builder.cylinder(0.045, 0.85, GameData.COLOR_WOOD_STACK)
	handle.rotation_degrees = Vector3(90, 0, 0)
	handle.position = Vector3(0, 0.05, 0.2)
	hand.add_child(handle)
	match kind:
		"mace":
			var head := Builder.cone(0.16, 0.42, Color(0.4, 0.3, 0.25))
			head.rotation_degrees = Vector3(90, 0, 0)
			head.position = Vector3(0, 0.05, 0.62)
			hand.add_child(head)
		"pickaxe":
			var hbar := Builder.box(Vector3(0.46, 0.09, 0.09), GameData.COLOR_ROCK)
			hbar.position = Vector3(0, 0.05, 0.7)
			hand.add_child(hbar)
			var pick := Builder.cone(0.07, 0.3, GameData.COLOR_ROCK)
			pick.rotation_degrees = Vector3(0, 0, -90)
			pick.position = Vector3(0.34, 0.05, 0.7)
			hand.add_child(pick)
			var flat := Builder.cone(0.07, 0.2, GameData.COLOR_GOLD)
			flat.rotation_degrees = Vector3(0, 0, 90)
			flat.position = Vector3(-0.3, 0.05, 0.7)
			hand.add_child(flat)
		_:
			var pommel := Builder.sphere(0.06, GameData.COLOR_GOLD)
			pommel.position = Vector3(0, 0.05, -0.18)
			hand.add_child(pommel)
			var guard := Builder.box(Vector3(0.18, 0.04, 0.04), GameData.COLOR_GOLD)
			guard.position = Vector3(0, 0.05, 0.4)
			hand.add_child(guard)
			var blade := Builder.box(Vector3(0.13, 0.03, 0.55), GameData.COLOR_ROCK)
			blade.position = Vector3(0, 0.05, 0.72)
			hand.add_child(blade)
