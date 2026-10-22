extends Control

# Main menu. Built procedurally like the rest of the UI.

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.18, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "PEON RISING"
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Incarne un péon et obéis au commandant.\nCoupe, mine, construis et défends la base."
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.88, 0.93, 0.88))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var essence := Label.new()
	essence.text = "Essence disponible : %d" % Meta.essence
	essence.add_theme_font_size_override("font_size", 18)
	essence.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	essence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(essence)

	vbox.add_child(_spacer(12))
	vbox.add_child(_button("▶  Jouer", _on_play))
	vbox.add_child(_button("★  Progression permanente", _on_meta))
	vbox.add_child(_button("✕  Quitter", _on_quit))

	var footer := Label.new()
	footer.text = "ZQSD/WASD + souris  ·  manette supportée  ·  tactile sur mobile"
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)

func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b

func _on_play() -> void:
	Sound.play("click")
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_meta() -> void:
	Sound.play("click")
	get_tree().change_scene_to_file("res://scenes/menu/meta_ui.tscn")

func _on_quit() -> void:
	get_tree().quit()
