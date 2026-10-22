extends SceneTree

# Headless proof that real, artist-made GLB models with skeletal animation load
# and play correctly through the SkeletalActor pipeline.
# Run: godot --headless --script res://tests/test_skeletal.gd

func _initialize() -> void:
	var ok := true
	for path in ["res://assets/models/CesiumMan.glb", "res://assets/models/Fox.glb"]:
		var actor := SkeletalActor.create(root, path, 1.0)
		var anim := actor.set_moving(true)
		if anim != "" and actor.is_animating():
			print("SKELETAL_OK %s -> anim=%s" % [path.get_file(), anim])
		else:
			ok = false
			printerr("SKELETAL_FAIL %s (anim=%s playing=%s)" % [path, anim, str(actor.is_animating())])
	quit(0 if ok else 1)
