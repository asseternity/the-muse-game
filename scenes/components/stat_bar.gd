# res://scripts/ui/stat_bar.gd
class_name StatBar
extends Control

@export var character_id: String = ""

# Note the updated paths pointing inside $Bg
@onready var name_label: Label       = $Bg/HBox/NameLabel
@onready var morale_bar: ProgressBar = $Bg/HBox/Bars/MoraleRow/MoraleBar
@onready var morale_lbl: Label       = $Bg/HBox/Bars/MoraleRow/MoraleLabel
@onready var rel_bar:    ProgressBar = $Bg/HBox/Bars/RelRow/RelBar
@onready var rel_lbl:    Label       = $Bg/HBox/Bars/RelRow/RelLabel
@onready var bg:         PanelContainer = $Bg
@onready var particles:  GPUParticles2D = $Particles

func _ready() -> void:
	add_to_group("stat_bar")
	_setup_particles()
	_style_panel()
	_style_bars()
	_style_text()
	_refresh_immediate()
	GameState.stat_changed.connect(_on_stat_changed)

	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)

	# Slight crooked tilt for handwritten feel
	rotation = deg_to_rad(randf_range(-1.5, 1.5))
	UITheme.pop_in(self, randf() * 0.25)

func _style_panel() -> void:
	var c_color := UITheme.get_character_color(character_id)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.01, 0.08, 0.94)
	sb.border_color = c_color
	sb.border_width_left   = 3
	sb.border_width_right  = 3
	sb.border_width_top    = 3
	sb.border_width_bottom = 6
	sb.corner_radius_top_left     = 18
	sb.corner_radius_top_right    = 18
	sb.corner_radius_bottom_left  = 18
	sb.corner_radius_bottom_right = 18
	sb.shadow_color = Color(c_color.r, c_color.g, c_color.b, 0.75)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left   = 14
	sb.content_margin_right  = 14
	sb.content_margin_top    = 10
	sb.content_margin_bottom = 10
	bg.add_theme_stylebox_override("panel", sb)

func _style_bars() -> void:
	var c_color := UITheme.get_character_color(character_id)
	for bar in [morale_bar, rel_bar]:
		var bg_sb := StyleBoxFlat.new()
		bg_sb.bg_color = Color(0, 0, 0, 0.65)
		bg_sb.border_color = Color(c_color.r, c_color.g, c_color.b, 0.7)
		bg_sb.border_width_bottom = 2
		bg_sb.border_width_top    = 2
		bg_sb.border_width_left   = 2
		bg_sb.border_width_right  = 2
		bg_sb.corner_radius_top_left     = 11
		bg_sb.corner_radius_top_right    = 11
		bg_sb.corner_radius_bottom_left  = 11
		bg_sb.corner_radius_bottom_right = 11
		bar.add_theme_stylebox_override("background", bg_sb)

		var fill_sb := StyleBoxFlat.new()
		fill_sb.bg_color = c_color
		fill_sb.corner_radius_top_left     = 11
		fill_sb.corner_radius_top_right    = 11
		fill_sb.corner_radius_bottom_left  = 11
		fill_sb.corner_radius_bottom_right = 11
		fill_sb.shadow_color = Color(c_color.r, c_color.g, c_color.b, 0.95)
		fill_sb.shadow_size = 6
		bar.add_theme_stylebox_override("fill", fill_sb)
	rel_bar.modulate = Color(1, 1, 1, 0.88)

func _style_text() -> void:
	var c_color := UITheme.get_character_color(character_id)
	# Character name — chunky and bright
	name_label.add_theme_color_override("font_color", c_color)
	name_label.add_theme_color_override("font_outline_color", UITheme.COLOR_PANEL_DARK)
	name_label.add_theme_constant_override("outline_size", 6)
	name_label.add_theme_font_size_override("font_size", 22)
	if UITheme._fonts.has("fun"):
		name_label.add_theme_font_override("font", UITheme._fonts["fun"])
	name_label.text = GameState.characters.get(character_id, {})\
		.get("display_name", character_id).to_upper()

	# Bar labels — sit ON the bar, white with strong outline so they read on any fill
	for lbl in [morale_lbl, rel_lbl]:
		lbl.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
		lbl.add_theme_color_override("font_outline_color", UITheme.COLOR_PANEL_DARK)
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.add_theme_font_size_override("font_size", 13)
		if UITheme._fonts.has("chunky"):
			lbl.add_theme_font_override("font", UITheme._fonts["chunky"])
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_particles() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.gravity = Vector3(0, -120, 0)
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 220.0
	mat.angular_velocity_min = -540.0
	mat.angular_velocity_max = 540.0
	mat.scale_min = 0.5
	mat.scale_max = 1.4
	particles.process_material = mat
	particles.amount = 32
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.emitting = false
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for x in 16:
		for y in 16:
			var d := Vector2(x - 8, y - 8).length()
			if d <= 7:
				img.set_pixel(x, y, Color(1, 1, 1, 1.0 - d / 7.0))
	particles.texture = ImageTexture.create_from_image(img)

func _refresh_immediate() -> void:
	var c: Dictionary = GameState.characters.get(character_id, {})
	var morale: int = int(c.get("morale", 0))
	var rel:    int = int(c.get("relationship", 0))
	morale_bar.value = morale
	rel_bar.value    = rel
	morale_lbl.text  = "MORALE  %d" % morale
	rel_lbl.text     = "RELATIONSHIP  %d" % rel

func _on_stat_changed(cid: String, stat: String, old_value: int, new_value: int) -> void:
	if cid != character_id: return
	Audio.play("stat_up" if new_value > old_value else "stat_down")
	var bar: ProgressBar = morale_bar if stat == "morale" else rel_bar
	var lbl: Label       = morale_lbl if stat == "morale" else rel_lbl
	_animate_bar(bar, lbl, stat, old_value, new_value)
	_burst(new_value > old_value)
	UITheme.squish(self, 0.35)
	UITheme.flash(bar, UITheme.COLOR_TEXT, 0.45)
	if new_value < old_value:
		UITheme.shake(self, 7.0, 0.28)
	else:
		UITheme.confetti(self, 18)

func _animate_bar(bar: ProgressBar, lbl: Label, stat: String, from_v: int, to_v: int) -> void:
	bar.value = from_v
	var stat_label: String = "MORALE" if stat == "morale" else "RELATIONSHIP"
	
	# Create an intense overshoot
	var overshoot: float = float(to_v) + (15.0 if to_v > from_v else -15.0)
	overshoot = clamp(overshoot, 0.0, 100.0)
	
	var t := create_tween()
	
	if to_v > from_v:
		# POSITIVE GAIN JUICE
		# 1. Flash the bar pure white instantly
		bar.self_modulate = Color(2.0, 2.0, 2.0, 1.0) # HDR overbright
		
		# 2. Shoot past the target quickly
		t.tween_property(bar, "value", overshoot, 0.15)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		# 3. Settle back to the actual value with a spring
		t.tween_property(bar, "value", to_v, 0.6)\
			.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			
		# 4. Fade color back to normal
		t.parallel().tween_property(bar, "self_modulate", Color.WHITE, 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		# NEGATIVE LOSS JUICE
		bar.self_modulate = UITheme.COLOR_BAD * 1.5
		t.tween_property(bar, "value", to_v, 0.4)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(bar, "self_modulate", Color.WHITE, 0.4)

	# Live-update the label text
	t.parallel().tween_method(
		func(v: float): lbl.text = "%s  %d" % [stat_label, int(round(v))],
		float(from_v), float(to_v), 0.4
	)

	# Heartbeat pump on the label
	lbl.pivot_offset = lbl.size / 2.0
	lbl.scale = Vector2(1.6, 1.6)
	var lt := create_tween()
	lt.tween_property(lbl, "scale", Vector2.ONE, 0.6)\
		.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

func _burst(positive: bool) -> void:
	var mat: ParticleProcessMaterial = particles.process_material
	mat.color = UITheme.COLOR_GOOD if positive else UITheme.COLOR_BAD
	particles.restart()
	particles.emitting = true

func _on_hover(is_in: bool) -> void:
	pivot_offset = size / 2.0
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "scale",
		Vector2(1.06, 1.06) if is_in else Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y",
		-4.0 if is_in else 0.0, 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
