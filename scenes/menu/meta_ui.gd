extends Control

# Permanent progression screen: spend "essence" (earned at the end of a match)
# on upgrades that persist between games (roguelite meta layer).

const UPGRADES := {
	"stamina": ["Endurance", "+10 PV max par niveau"],
	"strength": ["Force", "+1,5 dégâts par niveau"],
	"speed": ["Vitesse", "+3 % vitesse de déplacement par niveau"],
	"economy": ["Économie", "+1 capacité de transport par niveau"],
	"build_mastery": ["Maîtrise du bâtiment", "+4 % vitesse de construction par niveau"],
	"luck": ["Chance", "+1 % esquive par niveau"],
}

var _essence_label: Label

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.16, 0.13)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var back := Button.new()
	back.text = "←  Retour"
	back.position = Vector2(24, 20)
	back.custom_minimum_size = Vector2(140, 44)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(_on_back)
	add_child(back)

	var title := Label.new()
	title.text = "Progression permanente"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(0, 20)
	add_child(title)

	_essence_label = Label.new()
	_essence_label.add_theme_font_size_override("font_size", 22)
	_essence_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	_essence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_essence_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_essence_label.position = Vector2(0, 78)
	add_child(_essence_label)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_CENTER_TOP)
	scroll.position = Vector2(240, 130)
	scroll.size = Vector2(800, 520)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	for key in UPGRADES:
		vbox.add_child(_build_card(key))

	_refresh()

func _build_card(key: String) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.24, 0.18)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = "%s  (niv. %d)" % [UPGRADES[key][0], Meta.meta[key]]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info.add_child(name_label)

	var desc := Label.new()
	desc.text = UPGRADES[key][1]
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.75))
	info.add_child(desc)

	var buy := Button.new()
	buy.text = "Améliorer (%d)" % Meta.upgrade_cost(key)
	buy.custom_minimum_size = Vector2(170, 44)
	buy.add_theme_font_size_override("font_size", 16)
	buy.pressed.connect(_on_buy.bind(key, buy, name_label))
	row.add_child(buy)

	return panel

func _on_buy(key: String, buy_btn: Button, name_label: Label) -> void:
	if Meta.upgrade(key):
		Sound.play("levelup")
		name_label.text = "%s  (niv. %d)" % [UPGRADES[key][0], Meta.meta[key]]
		buy_btn.text = "Améliorer (%d)" % Meta.upgrade_cost(key)
		_refresh()
	else:
		Sound.play("hit")

func _refresh() -> void:
	_essence_label.text = "Essence disponible : %d" % Meta.essence

func _on_back() -> void:
	Sound.play("click")
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
