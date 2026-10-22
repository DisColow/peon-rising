extends SceneTree

# Captures a live sequence of the actual game loop (worker chopping, mining,
# building) so it can be assembled into an animated proof of game feel.
# Env: SEQ_DIR, SEQ_INTERVAL, SEQ_MAX.

var frames := 0
var interval := 12
var count := 0
var max_frames := 60
var out_dir := ""

func _initialize() -> void:
	out_dir = OS.get_environment("SEQ_DIR")
	if out_dir == "":
		out_dir = "/tmp/peon_frames"
	if OS.get_environment("SEQ_INTERVAL") != "":
		interval = int(OS.get_environment("SEQ_INTERVAL"))
	if OS.get_environment("SEQ_MAX") != "":
		max_frames = int(OS.get_environment("SEQ_MAX"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	for f in DirAccess.get_files_at(out_dir):
		DirAccess.remove_absolute(out_dir + "/" + f)
	var scene: PackedScene = load("res://scenes/main/main.tscn")
	if scene == null:
		print("SEQ_FAIL load main.tscn")
		quit(1)
		return
	var game: Node = scene.instantiate()
	root.add_child(game)

func _process(_delta: float) -> bool:
	frames += 1
	if frames % interval == 0:
		var img: Image = root.get_texture().get_image()
		img.save_png(out_dir + "/frame_%03d.png" % count)
		count += 1
	if count >= max_frames:
		print("SEQ_DONE frames=%d count=%d" % [frames, count])
		quit(0)
	return false
