extends CanvasLayer

# Pause menu (Échap / manette Start). Met le jeu en pause et propose Reprendre,
# le réglage de sensibilité/volume et le retour au menu principal.

var _panel: Control
var _sens_slider: HSlider
var _vol_slider: HSlider
var _building := true

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_building = false
	_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if _panel.visible:
		close()
	else:
		open()

func open() -> void:
	_panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close() -> void:
	_panel.visible = false
	get_tree().paused = false
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = dim

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.17, 0.13, 0.96)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 44
	sb.content_margin_right = 44
	sb.content_margin_top = 32
	sb.content_margin_bottom = 32
	box.add_theme_stylebox_override("panel", sb)
	center.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(420, 0)
	box.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSE"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_spacer(6))

	var resume := Button.new()
	resume.text = "▶  Reprendre"
	resume.custom_minimum_size = Vector2(0, 48)
	resume.add_theme_font_size_override("font_size", 20)
	resume.pressed.connect(close)
	vbox.add_child(resume)

	vbox.add_child(_spacer(6))
	vbox.add_child(_slider_row("Sensibilité souris", 0.2, 3.0, Settings.mouse_sensitivity, "_sens_slider", _on_sens_changed))
	vbox.add_child(_slider_row("Volume", 0.0, 1.0, Settings.master_volume, "_vol_slider", _on_vol_changed))
	vbox.add_child(_spacer(6))

	var quit := Button.new()
	quit.text = "✕  Quitter vers le menu"
	quit.custom_minimum_size = Vector2(0, 48)
	quit.add_theme_font_size_override("font_size", 20)
	quit.pressed.connect(_on_quit_menu)
	vbox.add_child(quit)

func _slider_row(label_text: String, minv: float, maxv: float, value: float, var_name: String, cb: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lab := Label.new()
	lab.text = "%s : %.2f" % [label_text, value]
	lab.add_theme_font_size_override("font_size", 16)
	lab.add_theme_color_override("font_color", Color(0.88, 0.93, 0.88))
	row.add_child(lab)

	var slider := HSlider.new()
	slider.min_value = minv
	slider.max_value = maxv
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 30)
	slider.value_changed.connect(func(v): lab.text = "%s : %.2f" % [label_text, v])
	slider.value_changed.connect(cb)
	row.add_child(slider)

	set(var_name, slider)
	return row

func _on_sens_changed(v: float) -> void:
	if _building:
		return
	Settings.mouse_sensitivity = v
	Settings.save_settings()

func _on_vol_changed(v: float) -> void:
	if _building:
		return
	Settings.master_volume = v
	Settings.save_settings()
	Sound.play("click", 0.4)

func _on_quit_menu() -> void:
	Sound.play("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
