extends SceneTree

# Off-screen screenshot capture of a real KayKit character (software GL under Xvfb).
# Env: SHOT_OUT (path), MODEL (glb), ANIM (animation name), FRAME (frames before shot).

var frames := 0
var settle := 30

func _initialize() -> void:
	var out := OS.get_environment("SHOT_OUT")
	if out == "":
		out = "/tmp/peon_shot.png"
	var model := OS.get_environment("MODEL")
	if model == "":
		model = "res://assets/models/kaykit/Knight.glb"
	var anim_name := OS.get_environment("ANIM")
	if OS.get_environment("FRAME") != "":
		settle = int(OS.get_environment("FRAME"))

	var world := Node3D.new()
	root.add_child(world)

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
	fill.light_color = Color(0.7, 0.8, 1.0)
	world.add_child(fill)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)

	var rig := KayKitRig.create(world, model, 1.4)
	if rig.anim == null:
		printerr("cannot load model ", model)
		quit(1)
		return
	var ap: AnimationPlayer = rig.anim
	if anim_name != "":
		if ap.has_animation(anim_name):
			ap.play(anim_name)
		else:
			print("no anim '", anim_name, "'; have ", ap.get_animation_list().size())

	var cam := Camera3D.new()
	cam.position = Vector3(1.9, 1.5, 2.7)
	cam.transform = cam.transform.looking_at(Vector3(0, 1.0, 0), Vector3.UP)
	world.add_child(cam)
	cam.current = true

func _process(_delta: float) -> bool:
	frames += 1
	if frames == settle:
		var img: Image = root.get_texture().get_image()
		var err := img.save_png(OS.get_environment("SHOT_OUT"))
		print("CAPTURE ", OS.get_environment("SHOT_OUT"), " err=", err)
		quit(0 if err == OK else 1)
	return false

func _find(n: Node, cls: String) -> Node:
	if cls == "AnimationPlayer" and n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null
