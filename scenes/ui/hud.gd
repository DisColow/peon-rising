extends CanvasLayer

# In-game HUD: resources, current order, health, XP, influence and the
# "pet" suggestion buttons that let the human steer the AI commander.

var gold_label: Label
var wood_label: Label
var food_label: Label
var order_label: Label
var hp_bar: ProgressBar
var hp_text: Label
var xp_bar: ProgressBar
var level_label: Label
var talent_points_label: Label
var influence_bar: ProgressBar
var toast_label: Label
var end_label: Label

var _toast_tween: Tween

func _ready() -> void:
	layer = 10
	_build()
	_connect()

func _build() -> void:
	# --- Resources (top-left) ---
	gold_label = _label(Vector2(16, 12), "Or : 0", Color(1.0, 0.85, 0.3), 22)
	wood_label = _label(Vector2(16, 42), "Bois : 0", Color(0.8, 0.6, 0.35), 22)
	food_label = _label(Vector2(16, 72), "Nourriture : 0/0", Color(0.9, 0.95, 0.9), 20)

	# --- Current order (top-center) ---
	order_label = _label(Vector2(0, 14), "Ordre : —", Color(1, 1, 1), 24)
	order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	order_label.set_anchors_preset(Control.PRESET_CENTER_TOP)

	# --- Health (bottom-left) ---
	hp_bar = _bar(Vector2(16, 640), Vector2(240, 18), Color(0.3, 0.8, 0.35))
	hp_text = _label(Vector2(16, 618), "PV", Color.WHITE, 16)

	# --- XP / level / talents (bottom-right) ---
	xp_bar = _bar(Vector2(1024, 640), Vector2(240, 14), Color(0.4, 0.55, 1.0))
	level_label = _label(Vector2(1024, 612), "Niv. 1", Color.WHITE, 18)
	talent_points_label = _label(Vector2(1024, 632), "", Color(0.5, 0.9, 1.0), 16)

	# --- Influence (bottom-center) ---
	influence_bar = _bar(Vector2(500, 660), Vector2(280, 12), Color(0.9, 0.75, 0.3))
	var inf_label := _label(Vector2(500, 636), "INFLUENCE (pierre de contrôle)", Color(0.9, 0.8, 0.5), 16)

	# --- Suggestion buttons (bottom-center row) ---
	_suggestion_buttons()

	# --- Hints (top-right) ---
	var hint := _label(Vector2(0, 14), "Clic gauche : ping  ·  C : désobéir  ·  T : talents\nWASD : esquiver  ·  Espace : dash  ·  Clic droit : orbite", Color(0.85, 0.9, 0.85), 15)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)

	# --- Toast (center) ---
	toast_label = _label(Vector2(0, 120), "", Color.WHITE, 24)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)

	# --- End screen ---
	end_label = _label(Vector2(0, 0), "", Color.WHITE, 60)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_label.visible = false

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
		["Attaquer", "attack_now"],
		["Défendre", "defend"],
		["+ Or", "focus_gold"],
		["+ Bois", "focus_wood"],
	]
	var x := 460.0
	for a in actions:
		var btn := Button.new()
		btn.text = a[0]
		btn.position = Vector2(x, 686)
		btn.size = Vector2(90, 30)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_suggestion.bind(a[1]))
		add_child(btn)
		x += 96.0
	var tower_btn := Button.new()
	tower_btn.text = "Tour ici"
	tower_btn.position = Vector2(x, 686)
	tower_btn.size = Vector2(90, 30)
	tower_btn.add_theme_font_size_override("font_size", 15)
	tower_btn.pressed.connect(_on_tower_mode)
	add_child(tower_btn)

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
	order_label.text = "Ordre : %s" % order.describe()

func _refresh_order() -> void:
	var w := GameState.worker
	if w != null and is_instance_valid(w) and w.has_method("describe_order"):
		order_label.text = "Ordre : %s" % w.describe_order()
	else:
		order_label.text = "Ordre : —"

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

func _on_respawn() -> void:
	_on_talent_points(GameState.talent_points)
	_refresh_order()

func _on_suggestion(action: String) -> void:
	if GameState.main != null:
		GameState.main.suggest(action)

func _on_tower_mode() -> void:
	if GameState.main != null:
		GameState.main.toggle_tower_mode()
