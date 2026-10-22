extends CanvasLayer

# First-person HUD: resources, the persistent objective, crosshair, context
# prompt, carried resources, health, XP, influence and the suggestion buttons.

var gold_label: Label
var wood_label: Label
var food_label: Label
var carry_label: Label
var order_label: Label
var context_label: Label
var hp_bar: ProgressBar
var hp_text: Label
var xp_bar: ProgressBar
var level_label: Label
var talent_points_label: Label
var influence_bar: ProgressBar
var toast_label: Label
var end_label: Label
var _end_buttons: VBoxContainer

var _toast_tween: Tween

func _ready() -> void:
	layer = 10
	_build()
	_connect()

func _process(_delta: float) -> void:
	var w := GameState.worker
	if w == null or not is_instance_valid(w):
		context_label.text = ""
		carry_label.text = ""
		return
	if w.has_method("get_look_label"):
		context_label.text = w.get_look_label()
	else:
		context_label.text = ""
	if w.has_method("is_carrying") and w.is_carrying():
		var amt: int = int(w.get("carry_amount"))
		var typ: String = str(w.get("carry_type"))
		carry_label.text = "Transporte : %d %s  → dépose à l'hôtel de ville" % [amt, ("or" if typ == GameData.GOLD else "bois")]
	else:
		carry_label.text = ""

func _build() -> void:
	# --- Resources (top-left) ---
	gold_label = _label(Vector2(16, 12), "Or : 0", Color(1.0, 0.85, 0.3), 22)
	wood_label = _label(Vector2(16, 42), "Bois : 0", Color(0.8, 0.6, 0.35), 22)
	food_label = _label(Vector2(16, 72), "Nourriture : 0/0", Color(0.9, 0.95, 0.9), 20)
	carry_label = _label(Vector2(16, 100), "", Color(1.0, 0.9, 0.4), 19)

	# --- Objective (top-center, always visible) ---
	order_label = _label(Vector2(0, 12), "Objectif : —", Color(1, 1, 1), 27)
	order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	order_label.set_anchors_preset(Control.PRESET_CENTER_TOP)

	# --- Crosshair + context prompt (center) ---
	var cross := _label(Vector2(0, 0), "+", Color(1, 1, 1, 0.9), 34)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	context_label = _label(Vector2(0, 40), "", Color(1, 1, 1), 20)
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_label.set_anchors_preset(Control.PRESET_CENTER)

	# --- Health (bottom-left) ---
	hp_bar = _bar(Vector2(16, 640), Vector2(240, 18), Color(0.3, 0.8, 0.35))
	hp_text = _label(Vector2(16, 618), "PV", Color.WHITE, 16)

	# --- XP / level / talents (bottom-right) ---
	xp_bar = _bar(Vector2(1024, 640), Vector2(240, 14), Color(0.4, 0.55, 1.0))
	level_label = _label(Vector2(1024, 612), "Niv. 1", Color.WHITE, 18)
	talent_points_label = _label(Vector2(1024, 632), "", Color(0.5, 0.9, 1.0), 16)

	# --- Influence (bottom-center) ---
	influence_bar = _bar(Vector2(500, 660), Vector2(280, 12), Color(0.9, 0.75, 0.3))
	_label(Vector2(500, 636), "INFLUENCE (pierre de contrôle)", Color(0.9, 0.8, 0.5), 16)

	# --- Suggestion buttons (bottom-center row) ---
	_suggestion_buttons()

	# --- Hints (top-right) ---
	var hint := _label(Vector2(0, 12), "ZQSD/WASD : bouger  ·  Maj : sprint  ·  Espace : dash\nClic gauche / E : agir  ·  T : talents", Color(0.85, 0.9, 0.85), 15)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)

	# --- Toast (center) ---
	toast_label = _label(Vector2(0, 150), "", Color.WHITE, 24)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)

	# --- End screen ---
	end_label = _label(Vector2(0, 0), "", Color.WHITE, 60)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_label.visible = false

	_end_buttons = VBoxContainer.new()
	_end_buttons.set_anchors_preset(Control.PRESET_CENTER)
	_end_buttons.position = Vector2(0, 90)
	_end_buttons.add_theme_constant_override("separation", 12)
	add_child(_end_buttons)

	var replay := Button.new()
	replay.text = "▶  Rejouer"
	replay.custom_minimum_size = Vector2(260, 50)
	replay.add_theme_font_size_override("font_size", 20)
	replay.pressed.connect(_on_replay)
	_end_buttons.add_child(replay)

	var menu := Button.new()
	menu.text = "★  Menu principal"
	menu.custom_minimum_size = Vector2(260, 50)
	menu.add_theme_font_size_override("font_size", 20)
	menu.pressed.connect(_on_menu)
	_end_buttons.add_child(menu)
	_end_buttons.visible = false

func _label(pos: Vector2, text: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos
	add_child(l)
	return l

func _bar(pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = 100
	b.value = 100
	b.size = size
	b.position = pos
	b.show_percentage = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.5)
	b.add_theme_stylebox_override("background", sb)
	var sf := StyleBoxFlat.new()
	sf.bg_color = color
	b.add_theme_stylebox_override("fill", sf)
	add_child(b)
	return b

func _suggestion_buttons() -> void:
	var actions := [
		["1 Attaquer", "attack_now"],
		["2 Défendre", "defend"],
		["3 + Or", "focus_gold"],
		["4 + Bois", "focus_wood"],
	]
	var x := 508.0
	for a in actions:
		var btn := Button.new()
		btn.text = a[0]
		btn.position = Vector2(x, 686)
		btn.size = Vector2(96, 30)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_suggestion.bind(a[1]))
		add_child(btn)
		x += 102.0

func _connect() -> void:
	EventBus.resource_changed.connect(_on_resources)
	EventBus.worker_hp_changed.connect(_on_hp)
	EventBus.xp_changed.connect(_on_xp)
	EventBus.talent_point_gained.connect(_on_talent_points)
	EventBus.influence_changed.connect(_on_influence)
	EventBus.order_assigned.connect(_on_order)
	EventBus.order_completed.connect(func(_o): _refresh_order())
	EventBus.toast.connect(_on_toast)
	EventBus.match_ended.connect(_on_match_ended)
	EventBus.worker_respawned.connect(_on_respawn)

func _on_resources(gold: int, wood: int, food_used: int, food_max: int) -> void:
	gold_label.text = "Or : %d" % gold
	wood_label.text = "Bois : %d" % wood
	food_label.text = "Nourriture : %d/%d" % [food_used, food_max]

func _on_hp(current: float, maximum: float) -> void:
	hp_bar.max_value = maxf(maximum, 1.0)
	hp_bar.value = clampf(current, 0.0, maximum)
	hp_text.text = "PV %d / %d" % [int(current), int(maximum)]

func _on_xp(current: int, needed: int, level: int) -> void:
	xp_bar.max_value = maxf(needed, 1.0)
	xp_bar.value = current
	level_label.text = "Niv. %d" % level

func _on_talent_points(points: int) -> void:
	if points > 0:
		talent_points_label.text = "★ %d point(s) de talent — appuie sur T" % points
	else:
		talent_points_label.text = ""

func _on_influence(current: float, maximum: float) -> void:
	influence_bar.max_value = maxf(maximum, 1.0)
	influence_bar.value = current

func _on_order(order) -> void:
	order_label.text = "Objectif : %s" % order.describe()

func _refresh_order() -> void:
	var w := GameState.worker
	if w != null and is_instance_valid(w) and w.has_method("describe_order"):
		order_label.text = "Objectif : %s" % w.describe_order()
	else:
		order_label.text = "Objectif : —"

func _on_toast(message: String) -> void:
	toast_label.text = message
	toast_label.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.8)

func _on_match_ended(victory: bool) -> void:
	end_label.text = "VICTOIRE !" if victory else "DÉFAITE"
	end_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.4) if victory else Color(0.95, 0.4, 0.4))
	end_label.visible = true
	_end_buttons.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_replay() -> void:
	Sound.play("click")
	get_tree().reload_current_scene()

func _on_menu() -> void:
	Sound.play("click")
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func _on_respawn() -> void:
	_on_talent_points(GameState.talent_points)
	_refresh_order()

func _on_suggestion(action: String) -> void:
	if GameState.main != null:
		GameState.main.suggest(action)
