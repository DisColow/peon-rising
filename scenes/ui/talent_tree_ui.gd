extends CanvasLayer

# The roguelite talent tree overlay (toggle with T). Spend talent points to
# specialize in harvesting, construction or combat. Reset on death.

var _root: Control
var _points_label: Label
var _columns: HBoxContainer

func _ready() -> void:
	layer = 20
	_build()
	EventBus.talent_unlocked.connect(func(_t, _i): refresh())
	EventBus.talent_point_gained.connect(func(_p): refresh())

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.72)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	center.add_child(main_vbox)

	var title := Label.new()
	title.text = "Arbres de talents (roguelite — perdus à la mort)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	main_vbox.add_child(title)

	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.add_theme_font_size_override("font_size", 22)
	_points_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	main_vbox.add_child(_points_label)

	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", 20)
	_columns.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(_columns)

	var close := Label.new()
	close.text = "T / Échap pour fermer"
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.add_theme_font_size_override("font_size", 16)
	close.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	main_vbox.add_child(close)

	_root.visible = false

func toggle() -> void:
	_root.visible = not _root.visible
	if _root.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		refresh()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func refresh() -> void:
	_points_label.text = "Points de talent : %d" % GameState.talent_points
	for c in _columns.get_children():
		c.queue_free()
	for tree in TalentDB.tree_ids():
		_columns.add_child(_build_tree_column(tree))

func _build_tree_column(tree: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(260, 0)

	var header := Label.new()
	header.text = TalentDB.tree_name(tree)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", TalentDB.TREES[tree]["color"])
	col.add_child(header)

	for node in TalentDB.nodes_in(tree):
		var btn := Button.new()
		btn.text = "%s\n%s" % [node["name"], node["desc"]]
		btn.custom_minimum_size = Vector2(0, 54)
		btn.add_theme_font_size_override("font_size", 16)
		var unlocked := GameState.has_talent(tree, node["id"])
		btn.disabled = unlocked or GameState.talent_points < 1
		if unlocked:
			btn.text = "✓ " + btn.text
		btn.pressed.connect(_unlock.bind(tree, node["id"]))
		col.add_child(btn)
	return col

func _unlock(tree: String, id: String) -> void:
	GameState.spend_talent_point(tree, id)
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		_root.visible = false
		get_viewport().set_input_as_handled()
