class_name FX
extends Object

# Procedural visual effects: particle bursts and floating 3D text.
# Built entirely in code so there are no external assets to import.

static var _dot: SphereMesh

static func _dot_mesh() -> SphereMesh:
	if _dot == null:
		_dot = SphereMesh.new()
		_dot.radius = 0.08
		_dot.height = 0.16
	return _dot

static func burst(parent: Node, pos: Vector3, color: Color, amount := 12, radius := 0.5, speed := 3.0, life := 0.6) -> void:
	if parent == null:
		return
	var tree := parent.get_tree()
	if tree == null:
		return
	for i in amount:
		var m := Builder.sphere(0.06 + randf() * 0.06, color, 0.5)
		parent.add_child(m)
		m.global_position = pos
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.0), randf_range(-1.0, 1.0)).normalized()
		var dist := speed * randf_range(0.4, 1.2)
		var t := m.create_tween()
		t.set_parallel(true)
		t.tween_property(m, "global_position", pos + dir * dist, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(m, "scale", Vector3.ZERO, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var timer := tree.create_timer(life + 0.05)
		timer.timeout.connect(m.queue_free)

static func float_text(parent: Node, pos: Vector3, text: String, color := Color.WHITE, size := 40) -> void:
	if parent == null:
		return
	var tree := parent.get_tree()
	if tree == null:
		return
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = color
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.7)
	parent.add_child(l)
	l.global_position = pos + Vector3(0, 1.3, 0)
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "global_position", l.global_position + Vector3(0, 1.1, 0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.9)
	var timer := tree.create_timer(1.0)
	timer.timeout.connect(l.queue_free)
