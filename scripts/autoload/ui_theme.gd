# res://scripts/autoload/ui_theme.gd
# Synth-pop arcade theme + juice toolkit.
# Inspired by Arcade Spirits, Dream Daddy, and Date Everything!
extends Node

# ─── PALETTE ──────────────────────────────────────────────────────────
const COLOR_BG          := Color("#120829") # Deepest Indigo
const COLOR_PANEL       := Color("#1e0d3a") # Panel Purple
const COLOR_PANEL_LIGHT := Color("#2d1654") # Button Fill
const COLOR_PANEL_DARK  := Color("#0a0418") # Input Interior
const COLOR_ACCENT      := Color("#ff2a7a") # Neon Pink (Hot!)
const COLOR_ACCENT_2    := Color("#00f0ff") # Cyber Cyan
const COLOR_ACCENT_3    := Color("#ffde00") # Arcade Marquee Yellow
const COLOR_ACCENT_4    := Color("#b967ff") # Ultraviolet
const COLOR_GOOD        := Color("#39ff14") # Neon Green
const COLOR_BAD         := Color("#ff2020") # CRT Red
const COLOR_TEXT        := Color("#ffffff") # Pure White
const COLOR_TEXT_DIM    := Color("#a390d4") # Faded Purple
const COLOR_OUTLINE     := Color("#0a0418") # Deep Shadow Outline

var character_colors := {}

var _name_badge_pins: Array = []   # Array of {badge: Control, textbox: Control}

# ─── TWEEN TOKENS ─────────────────────────────────────────────────────
const TWEEN_FAST := 0.15
const TWEEN_MED  := 0.3
const TWEEN_SLOW := 0.5
# Change this to SPRING for natural, dopamine-inducing wobbles
const BOUNCE_TRANS := Tween.TRANS_SPRING 
const BOUNCE_EASE  := Tween.EASE_OUT

# ─── FONT SIZES ───────────────────────────────────────────────────────
const FONT_SIZE_BASE   := 16
const FONT_SIZE_BUTTON := 20
const FONT_SIZE_TITLE  := 28

# ─── MARGIN CONSTANTS ─────────────────────────────────────────────────
const MARGIN_PANEL     := 16   # MarginContainer default padding
const MARGIN_INNER     := 12   # HBoxContainer / VBoxContainer separation

var is_juice_enabled: bool = true
var global_theme: Theme

func _ready() -> void:
	_build_and_apply_global_theme()
	_download_and_apply_fonts()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_sweep_existing", get_tree().root)

func _process(_delta: float) -> void:
	# Continuously pin name badges above their textbox panels.
	# This is the only reliable way to fight Dialogic's layout system.
	var to_remove: Array = []
	for entry in _name_badge_pins:
		# ── FIX: Check validity BEFORE assigning to typed variables ──
		if not is_instance_valid(entry.badge) or not is_instance_valid(entry.textbox):
			to_remove.append(entry)
			continue
			
		# Now it is completely safe to cast them
		var badge: Control = entry.badge
		var textbox: Control = entry.textbox
		
		# Sit the badge ENTIRELY above the textbox top edge
		var badge_h: float = max(badge.size.y, 56.0)
		badge.global_position = textbox.global_position + Vector2(50, -badge_h - 6)
		
	for e in to_remove:
		_name_badge_pins.erase(e)

# ─── THEME GENERATION ─────────────────────────────────────────────────
func _build_and_apply_global_theme() -> void:
	global_theme = Theme.new()
	global_theme.default_font_size = FONT_SIZE_BASE

	# ── Panel: chunky double-border with strong shadow
	var panel_style := _make_box(Color(0.04, 0.02, 0.10, 0.96), COLOR_ACCENT, 5, 26, Vector4(24, 24, 18, 18))
	panel_style.border_width_bottom = 7
	panel_style.border_width_right = 7
	panel_style.shadow_color = Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 0.75)
	panel_style.shadow_size = 18
	panel_style.shadow_offset = Vector2(0, 6)

	# ── Button Normal
	var btn_normal := _make_box(COLOR_PANEL_LIGHT, COLOR_ACCENT, 3, 10, Vector4(22, 22, 10, 10))
	btn_normal.shadow_color = Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 0.35)
	btn_normal.shadow_size = 4
	btn_normal.shadow_offset = Vector2(0, 3)

	# ── Button Hover: pink fill, white border, cyan glow
	var btn_hover := _make_box(COLOR_ACCENT, COLOR_TEXT, 3, 10, Vector4(22, 22, 10, 10))
	btn_hover.shadow_color = Color(COLOR_ACCENT_2.r, COLOR_ACCENT_2.g, COLOR_ACCENT_2.b, 0.8)
	btn_hover.shadow_size = 10
	btn_hover.shadow_offset = Vector2.ZERO

	# ── Button Pressed
	var btn_pressed := _make_box(COLOR_PANEL_DARK, COLOR_ACCENT, 3, 10, Vector4(22, 22, 10, 10))

	# ── Button Focus: cyan accent ring
	var btn_focus := _make_box(Color(0, 0, 0, 0), COLOR_ACCENT_2, 4, 10, Vector4(22, 22, 10, 10))
	btn_focus.shadow_color = Color(COLOR_ACCENT_2.r, COLOR_ACCENT_2.g, COLOR_ACCENT_2.b, 0.6)
	btn_focus.shadow_size = 8

	# ── LineEdit
	var input_normal := _make_box(COLOR_PANEL_DARK, COLOR_ACCENT_2, 3, 8, Vector4(14, 14, 10, 10))
	var input_focus  := _make_box(COLOR_PANEL_DARK, COLOR_ACCENT, 4, 8, Vector4(14, 14, 10, 10))
	input_focus.shadow_color = Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 0.6)
	input_focus.shadow_size = 6

	# ── ProgressBar
	var pbar_bg   := _make_box(COLOR_PANEL_DARK, COLOR_ACCENT_2, 2, 8, Vector4(0, 0, 0, 0))
	var pbar_fill := _make_box(COLOR_ACCENT, COLOR_TEXT, 0, 6, Vector4(0, 0, 0, 0))

	# ── Apply all stylebox overrides
	global_theme.set_stylebox("panel", "Panel", panel_style)
	global_theme.set_stylebox("panel", "PanelContainer", panel_style)

	global_theme.set_stylebox("normal",   "Button", btn_normal)
	global_theme.set_stylebox("hover",    "Button", btn_hover)
	global_theme.set_stylebox("pressed",  "Button", btn_pressed)
	global_theme.set_stylebox("focus",    "Button", btn_focus)
	global_theme.set_stylebox("disabled", "Button", btn_pressed)

	global_theme.set_stylebox("normal",    "LineEdit", input_normal)
	global_theme.set_stylebox("focus",     "LineEdit", input_focus)
	global_theme.set_stylebox("read_only", "LineEdit", input_normal)

	global_theme.set_stylebox("background", "ProgressBar", pbar_bg)
	global_theme.set_stylebox("fill",       "ProgressBar", pbar_fill)

	# ── Font colors & sizes
	global_theme.set_color("font_color",         "Label", COLOR_TEXT)
	global_theme.set_color("font_outline_color",  "Label", COLOR_OUTLINE)
	global_theme.set_constant("outline_size",     "Label", 4)

	global_theme.set_color("font_color",          "Button", COLOR_TEXT)
	global_theme.set_color("font_hover_color",    "Button", COLOR_TEXT)
	global_theme.set_color("font_pressed_color",  "Button", COLOR_ACCENT_3)
	global_theme.set_color("font_outline_color",  "Button", COLOR_OUTLINE)
	global_theme.set_constant("outline_size",     "Button", 5)
	global_theme.set_font_size("font_size",       "Button", FONT_SIZE_BUTTON)

	global_theme.set_color("font_color",      "LineEdit", COLOR_TEXT)
	global_theme.set_color("caret_color",     "LineEdit", COLOR_ACCENT_2)
	global_theme.set_color("selection_color", "LineEdit", COLOR_ACCENT)

	global_theme.set_color("font_color",         "ProgressBar", COLOR_TEXT)
	global_theme.set_color("font_outline_color",  "ProgressBar", COLOR_OUTLINE)
	global_theme.set_constant("outline_size",     "ProgressBar", 3)

	# ── Task 1: Container margins & separation (programmatic)
	global_theme.set_constant("separation", "HBoxContainer",  MARGIN_INNER)
	global_theme.set_constant("separation", "VBoxContainer",  8)
	global_theme.set_constant("separation", "BoxContainer",   MARGIN_INNER)
	global_theme.set_constant("margin_left",   "MarginContainer", MARGIN_PANEL)
	global_theme.set_constant("margin_right",  "MarginContainer", MARGIN_PANEL)
	global_theme.set_constant("margin_top",    "MarginContainer", MARGIN_PANEL)
	global_theme.set_constant("margin_bottom", "MarginContainer", MARGIN_PANEL)
	# GridContainer column gap
	global_theme.set_constant("h_separation", "GridContainer", MARGIN_INNER)
	global_theme.set_constant("v_separation", "GridContainer", 8)

	get_tree().root.theme = global_theme

func _make_box(
	bg: Color,
	border: Color,
	border_w: int,
	corner: int,
	margins: Vector4
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = border_w
	s.border_width_right  = border_w
	s.border_width_top    = border_w
	s.border_width_bottom = border_w
	s.corner_radius_top_left     = corner
	s.corner_radius_top_right    = corner
	s.corner_radius_bottom_left  = corner
	s.corner_radius_bottom_right = corner
	s.content_margin_left   = margins.x
	s.content_margin_right  = margins.y
	s.content_margin_top    = margins.z
	s.content_margin_bottom = margins.w
	s.anti_aliasing = true
	return s

# ─── FONT DOWNLOAD SYSTEM (Task 5) ────────────────────────────────────
const FONT_CACHE_DIR := "user://fonts/"

# Orbitron: futuristic for UI body text.
# Press Start 2P: pixel arcade for buttons & titles.
const _FONT_DEFS := {
	"body":   "https://raw.githubusercontent.com/google/fonts/main/ofl/russoone/RussoOne-Regular.ttf",
	"title":  "https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/PressStart2P-Regular.ttf",
	"fun":    "https://raw.githubusercontent.com/google/fonts/main/ofl/bangers/Bangers-Regular.ttf",
	"hand":   "https://raw.githubusercontent.com/google/fonts/main/ofl/indieflower/IndieFlower-Regular.ttf",
	"chunky": "https://raw.githubusercontent.com/google/fonts/main/ofl/bungee/Bungee-Regular.ttf"
}

var _fonts: Dictionary = {}
var _fonts_needed: int = 0
var _fonts_ready:  int = 0

func _download_and_apply_fonts() -> void:
	DirAccess.make_dir_recursive_absolute(FONT_CACHE_DIR)
	_fonts_needed = _FONT_DEFS.size()
	for key: String in _FONT_DEFS:
		var url: String       = _FONT_DEFS[key]
		var filename: String  = url.get_file()
		var cache_path: String = FONT_CACHE_DIR + filename
		_load_or_download_font(key, url, cache_path)

func _load_or_download_font(key: String, url: String, cache_path: String) -> void:
	if FileAccess.file_exists(cache_path):
		_on_font_cached(key, cache_path)
		return

	var http := HTTPRequest.new()
	http.name = "FontHTTP_" + key
	add_child(http)
	# Capture args by value in the lambda
	http.request_completed.connect(
		func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray,
				_key: String = key, _path: String = cache_path, _http: HTTPRequest = http):
			_http.queue_free()
			if result != HTTPRequest.RESULT_SUCCESS or code != 200:
				push_warning("[UITheme] Font download failed '%s' (err=%d http=%d)" % [_key, result, code])
				return
			var f := FileAccess.open(_path, FileAccess.WRITE)
			if not f:
				push_warning("[UITheme] Cannot write font cache: " + _path)
				return
			f.store_buffer(body)
			f.close()
			_on_font_cached(_key, _path)
	)
	var err := http.request(url)
	if err != OK:
		push_warning("[UITheme] HTTPRequest failed for: " + url)
		http.queue_free()

func _on_font_cached(key: String, path: String) -> void:
	var ff := FontFile.new()
	var err := ff.load_dynamic_font(path)
	if err != OK:
		push_warning("[UITheme] load_dynamic_font failed: " + path)
		return
	_fonts[key] = ff
	_fonts_ready += 1
	# Apply as soon as each individual font is ready for faster perceived loading.
	_apply_fonts_to_theme()

func _apply_fonts_to_theme() -> void:
	var body:  Font = _fonts.get("body")
	var title: Font = _fonts.get("title")
	# Use whichever is available as fallback for the other.
	var use_body  : Font = body  if body  != null else title
	var use_title : Font = title if title != null else body
	if use_body == null:
		return

	global_theme.default_font = use_body
	global_theme.set_font("font", "Label",       use_body)
	global_theme.set_font("font", "LineEdit",    use_body)
	global_theme.set_font("font", "ProgressBar", use_body)
	global_theme.set_font("font", "RichTextLabel", use_body)
	global_theme.set_font("font", "Button",      use_title)

	# Broadcast NOTIFICATION_THEME_CHANGED so every live Control re-draws.
	if is_inside_tree():
		get_tree().root.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)

# ─── AUTO-JUICE SYSTEM ────────────────────────────────────────────────
func _sweep_existing(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_sweep_existing(child)

func _on_node_added(node: Node) -> void:
	if node.name == "DialogicNode_NameLabel":
		call_deferred("_apply_juicy_name_label", node)
	if node is Control:
		node.theme = global_theme
		_strip_overrides.call_deferred(node)

	# NEW: forcefully style the Dialogic dialog text panel
	if node is Panel or node is PanelContainer:
		var nm := String(node.name).to_lower()
		if "dialog" in nm and ("text" in nm or "panel" in nm) and not "name" in nm:
			call_deferred("_apply_juicy_dialog_panel", node)

	if (node is Panel or node is PanelContainer) and not (node is ScrollContainer):
		_attach_panel_fx.call_deferred(node)

	if node is BaseButton:
		if not node.is_connected("mouse_entered", _on_btn_hover):
			node.mouse_entered.connect(_on_btn_hover.bind(node, true))
			node.mouse_exited.connect(_on_btn_hover.bind(node, false))
			node.button_down.connect(_on_btn_pressed.bind(node))
			node.resized.connect(func(): node.pivot_offset = node.size / 2.0)
			_set_pivot.call_deferred(node)

func _set_pivot(node: Control) -> void:
	if is_instance_valid(node):
		node.pivot_offset = node.size / 2.0

func _strip_overrides(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.name == "DialogicNode_NameLabel":
		return
	# NEW: don't strip the dialog text panel — we explicitly style it
	if (node is Panel or node is PanelContainer):
		var nm := String(node.name).to_lower()
		if "dialog" in nm and ("text" in nm or "panel" in nm) and not "name" in nm:
			return
	# NEW: don't strip dialog text panel — we set padding there.
	var name_lower := String(node.name).to_lower()
	if (node is Panel or node is PanelContainer) and "dialog" in name_lower and "text" in name_lower:
		return
	if node is Button:
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			if node.has_theme_stylebox_override(s):
				node.remove_theme_stylebox_override(s)
	if node is LineEdit:
		for s in ["normal", "focus", "read_only"]:
			if node.has_theme_stylebox_override(s):
				node.remove_theme_stylebox_override(s)
	if node is ProgressBar:
		for s in ["background", "fill"]:
			if node.has_theme_stylebox_override(s):
				node.remove_theme_stylebox_override(s)

# ─── BUTTON JUICE ─────────────────────────────────────────────────────
func _on_btn_hover(node: Control, is_hovering: bool) -> void:
	if not is_instance_valid(node):
		return
		
	node.pivot_offset = node.size / 2.0
	
	var target_scale := Vector2(1.12, 1.12) if is_hovering else Vector2.ONE
	var target_rot: float = deg_to_rad(randf_range(-3.0, 3.0)) if is_hovering else 0.0

	var t := node.create_tween().set_parallel(true)
	
	# Spring ignores duration somewhat to simulate actual physics, making it snappy
	t.tween_property(node, "scale", target_scale, 0.4)\
		.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "rotation", target_rot, 0.4)\
		.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

	if is_hovering:
		# Add an immediate bright flash when the mouse enters
		flash(node, COLOR_ACCENT_2, 0.2)
		_start_pulse(node)
		# Wiggle it just a little bit to demand attention
		wiggle(node, 2.0, 1)
	else:
		_stop_pulse(node)

func _on_btn_pressed(node: Control) -> void:
	if not is_instance_valid(node):
		return
	squish(node, 0.2)
	burst(node, COLOR_ACCENT_2, 14)

var _pulse_tweens: Dictionary = {}

func _start_pulse(node: Control) -> void:
	_stop_pulse(node)
	var t := node.create_tween().set_loops()
	t.tween_property(node, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(node, "modulate", Color.WHITE, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tweens[node] = t

func _stop_pulse(node: Control) -> void:
	if _pulse_tweens.has(node):
		var t: Tween = _pulse_tweens[node]
		if t and t.is_valid():
			t.kill()
		_pulse_tweens.erase(node)
	if is_instance_valid(node):
		node.modulate = Color.WHITE

# ─── PARTICLE JUICE ───────────────────────────────────────────────────
func burst(node: Control, color: Color = COLOR_ACCENT, amount: int = 16) -> void:
	if not is_instance_valid(node):
		return
	var p := CPUParticles2D.new()
	node.add_child(p)
	p.position = node.size / 2.0
	p.z_index = 100
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.7
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 280)
	p.scale_amount_min = 2.5
	p.scale_amount_max = 6.0
	p.color = color
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.2).timeout.connect(p.queue_free)

func confetti(node: Control, amount: int = 28) -> void:
	var colors := [COLOR_ACCENT, COLOR_ACCENT_2, COLOR_ACCENT_3, COLOR_ACCENT_4, COLOR_GOOD]
	var per_color: int = int(amount / float(colors.size()))
	for c in colors:
		burst(node, c, per_color)

# ─── PUBLIC HELPERS ───────────────────────────────────────────────────
## Call from any script to force-attach the panel FX to a specific node.
## Useful when a node is added outside the normal scene-tree signal path.
func attach_fx(panel: Control) -> void:
	_attach_panel_fx(panel)

func get_character_color(id: String) -> Color:
	return character_colors.get(id, COLOR_ACCENT)

func pop_in(node: Control, delay: float = 0.0) -> void:
	if not is_instance_valid(node):
		return
	Audio.play("menu_open", -4.0)
	node.scale = Vector2.ZERO
	node.pivot_offset = node.size * 0.5
	var t := node.create_tween()
	if delay > 0:
		t.tween_interval(delay)
	t.tween_property(node, "scale", Vector2.ONE, TWEEN_MED)\
		.set_trans(BOUNCE_TRANS).set_ease(BOUNCE_EASE)

func squish(node: Control, intensity: float = 0.25) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	var t := node.create_tween()
	t.tween_property(node, "scale", Vector2(1.0 + intensity, 1.0 - intensity), 0.08)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector2.ONE, TWEEN_MED)\
		.set_trans(BOUNCE_TRANS).set_ease(BOUNCE_EASE)

func shake(node: Control, magnitude: float = 8.0, duration: float = 0.3) -> void:
	if not is_instance_valid(node):
		return
	var orig_pos: Vector2 = node.position
	var t := node.create_tween()
	var steps := 10
	for i in steps:
		var off := Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
		t.tween_property(node, "position", orig_pos + off, duration / steps)
	t.tween_property(node, "position", orig_pos, 0.05)

func flash(node: CanvasItem, color: Color = COLOR_TEXT, duration: float = 0.4) -> void:
	if not is_instance_valid(node):
		return
	node.modulate = color * 1.6
	var t := node.create_tween()
	t.tween_property(node, "modulate", Color.WHITE, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func whoosh(node: Control, from_dir: Vector2 = Vector2.LEFT, distance: float = 200.0) -> void:
	if not is_instance_valid(node):
		return
	Audio.play("menu_open")
	var final_pos: Vector2 = node.position
	node.position = final_pos + from_dir * distance
	node.modulate.a = 0.0
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node, "position", final_pos, TWEEN_SLOW)\
		.set_trans(BOUNCE_TRANS).set_ease(BOUNCE_EASE)
	t.tween_property(node, "modulate:a", 1.0, TWEEN_MED)

func wiggle(node: Control, angle_deg: float = 8.0, times: int = 3) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	var t := node.create_tween()
	for i in times:
		t.tween_property(node, "rotation", deg_to_rad(angle_deg), 0.06)\
			.set_trans(Tween.TRANS_SINE)
		t.tween_property(node, "rotation", deg_to_rad(-angle_deg), 0.06)\
			.set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "rotation", 0.0, 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ─── BACKGROUND SHADER ────────────────────────────────────────────────
const BG_SHADER_CODE := """
shader_type canvas_item;
uniform float speed : hint_range(0.0, 2.0) = 0.25;

void fragment() {
	vec2 uv = UV;
	vec3 col;
	float horizon = 0.58;

	if (uv.y < horizon) {
		float t = uv.y / horizon;
		vec3 top = vec3(0.04, 0.02, 0.14);
		vec3 mid = vec3(0.42, 0.08, 0.55);
		vec3 btm = vec3(1.0, 0.16, 0.48);
		col = mix(top, mid, smoothstep(0.0, 0.7, t));
		col = mix(col, btm, smoothstep(0.7, 1.0, t));

		vec2 sun_pos = vec2(0.5, horizon - 0.08);
		float sun_d = length((uv - sun_pos) * vec2(1.0, 2.2));
		float sun = smoothstep(0.20, 0.16, sun_d);
		float stripes = step(0.04, fract((uv.y - horizon + 0.22) * 22.0));
		sun *= mix(1.0, stripes, smoothstep(0.0, 0.18, horizon - uv.y));
		col = mix(col, vec3(1.0, 0.87, 0.25), sun);

		vec2 s_uv = uv * vec2(420.0, 220.0);
		float star = step(0.997,
			fract(sin(dot(floor(s_uv), vec2(12.9898, 78.233))) * 43758.5453));
		col += vec3(star) * (1.0 - t) * 0.9;
	} else {
		col = vec3(0.02, 0.01, 0.07);
		float gy = (uv.y - horizon) / (1.0 - horizon);
		float y = gy + 0.05;
		float px = (uv.x - 0.5) / y;
		float py = 1.0 / y + TIME * speed;
		vec2 grid = abs(fract(vec2(px, py) * 4.0) - 0.5);
		float line = min(grid.x, grid.y) * y * 2.2;
		float glow = smoothstep(0.08, 0.0, line);
		col += vec3(1.0, 0.16, 0.7) * glow * 0.95;
	}
	COLOR = vec4(col, 1.0);
}
"""

func _spawn_background() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SynthwaveBackground"
	layer.layer = -100
	get_tree().root.add_child.call_deferred(layer)

	var rect := ColorRect.new()
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = 0
	rect.offset_right = 0
	rect.offset_top = 0
	rect.offset_bottom = 0
	rect.z_index = 10

	var shader := Shader.new()
	shader.code = BG_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat

	layer.add_child.call_deferred(rect)

# ─── PANEL OVERLAY SHADER (Task 4) ────────────────────────────────────
const PANEL_FX_SHADER_CODE := """
shader_type canvas_item;
uniform float scan_density  : hint_range(10.0, 300.0) = 110.0;
uniform float scan_strength : hint_range(0.0, 0.5)    = 0.12;
uniform vec4  glow_color    : source_color = vec4(1.0, 0.16, 0.48, 1.0);
uniform float pulse_speed   : hint_range(0.0, 5.0)    = 1.8;

void fragment() {
	// The blinking scanlines
	float scan  = sin(UV.y * scan_density + TIME * 4.0) * 0.5 + 0.5;
	
	// The edge glow 
	// Multiplying UV.x prevents the glow from stretching too far inward on wide panels
	vec2 edge_uv = vec2(UV.x * 4.0, UV.y);
	vec2 edge_dist = min(edge_uv, vec2(4.0, 1.0) - edge_uv);
	float edge  = 1.0 - smoothstep(0.0, 0.25, min(edge_dist.x, edge_dist.y));
	
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

	// Apply the color to BOTH the edge glow and the scanlines
	float final_alpha = (scan * scan_strength) + (edge * pulse * 0.45);

	COLOR = vec4(glow_color.rgb, clamp(final_alpha, 0.0, 1.0));
}
"""

var _panel_fx_shader: Shader

func _get_panel_fx_shader() -> Shader:
	if _panel_fx_shader == null:
		_panel_fx_shader = Shader.new()
		_panel_fx_shader.code = PANEL_FX_SHADER_CODE
	return _panel_fx_shader

func _attach_panel_fx(panel: Control) -> void:
	if not is_instance_valid(panel):
		return

	# 1. FIX THE "WHITENED OUT" ISSUE
	# Strip the material from the PanelContainer to restore the StyleBox rendering
	if panel.material != null:
		panel.material = null

	# Skip if we already added our FX overlay
	if panel.has_node("_PanelFXWrapper"):
		return

	# 2. CLIP TO ROUNDED CORNERS
	# This tells Godot to use the Panel's StyleBox (including your 30px rounded corners)
	# as a mask for all children, preventing our rectangular overlay from bleeding outside!
	panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW

	# 3. FIX THE MARGIN ISSUE
	# By wrapping our ColorRect in a Node2D, it completely bypasses the
	# PanelContainer's strict margins. It will snap to the true outer edge.
	var wrapper := Node2D.new()
	wrapper.name = "_PanelFXWrapper"
	
	var rect := ColorRect.new()
	rect.name = "_PanelFX"
	rect.color = Color.WHITE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mat := ShaderMaterial.new()
	mat.shader = _get_panel_fx_shader()
	mat.set_shader_parameter("pulse_speed", randf_range(1.2, 2.4))
	rect.material = mat
	
	# Assemble the bypass structure
	wrapper.add_child(rect)
	panel.add_child(wrapper)
	
	# Move wrapper to the top of the child stack so it renders BEHIND the dialog text
	panel.move_child(wrapper, 0)
	
	# Initial size alignment
	rect.size = panel.size
	
	# Keep the overlay perfectly stretched to the panel's true size
	panel.resized.connect(func():
		if is_instance_valid(rect) and is_instance_valid(panel):
			rect.size = panel.size
	)

func _apply_juicy_name_label(node: Control) -> void:
	if not is_instance_valid(node):
		return

	# --- THE SHADOW REALM BANISHMENT ---
	var original_bg_panel := node.get_parent() as Control
	if is_instance_valid(original_bg_panel):
		# Dialogic actively rebuilds this panel's StyleBox every time a character speaks.
		# We can't delete it, and clearing the StyleBox gets overwritten.
		# Solution: Set it to top_level to escape layout constraints, then banish it offscreen.
		# Because our text 'node' is pinned by _process, it stays on screen perfectly!
		original_bg_panel.top_level = true
		original_bg_panel.global_position = Vector2(-9999, -9999)
		original_bg_panel.self_modulate.a = 0.0
	# -----------------------------------

	# Big punchy font
	if _fonts.has("fun"):
		node.add_theme_font_override("font", _fonts["fun"])
	node.add_theme_font_size_override("font_size", 32)
	node.add_theme_color_override("font_color", COLOR_TEXT)
	node.add_theme_color_override("font_outline_color", COLOR_PANEL_DARK)
	node.add_theme_constant_override("outline_size", 7)

	# Pill-shaped high-contrast badge with gradient-feeling double border
	var style := _make_box(COLOR_ACCENT, COLOR_TEXT, 5, 28, Vector4(32, 32, 14, 14))
	style.shadow_color = Color(COLOR_ACCENT_3.r, COLOR_ACCENT_3.g, COLOR_ACCENT_3.b, 0.9)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	node.add_theme_stylebox_override("normal", style)

	# Wait two frames for Dialogic to finish placing the textbox
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(node):
		return

	var textbox: Control = _find_dialog_text_panel_from_label(node)
	if textbox == null:
		return

	# ── KEY FIX: top_level escapes parent layout entirely
	node.top_level = true
	node.z_index = 50
	node.clip_contents = false

	# Register for permanent _process pinning — survives any layout fight.
	_name_badge_pins = _name_badge_pins.filter(func(e): return e.badge != node)
	_name_badge_pins.append({"badge": node, "textbox": textbox})

	# Add a slight crooked tilt for that handwritten feel
	node.rotation = deg_to_rad(randf_range(-3.5, -1.5))

	pop_in(node, 0.0)
	wiggle(node, 4.0, 1)


func _find_dialog_text_panel_from_label(label: Control) -> Control:
	var root: Node = label
	for _i in 10:
		if root.get_parent() == null or root.get_parent() == get_tree().root:
			break
		root = root.get_parent()
	return _find_dialog_text_panel_recursive(root)


func _find_dialog_text_panel_recursive(node: Node) -> Control:
	if node is RichTextLabel:
		var nm := String(node.name).to_lower()
		var script_name := ""
		if node.get_script() != null:
			script_name = String(node.get_script().resource_path).to_lower()
		if "dialog" in nm or "dialogictext" in nm.replace("_", "") or "dialog" in script_name:
			var p: Node = node.get_parent()
			while p != null:
				if p is Panel or p is PanelContainer:
					return p as Control
				p = p.get_parent()
			return node as Control
	for child in node.get_children():
		var hit := _find_dialog_text_panel_recursive(child)
		if hit:
			return hit
	return null

# ─── OVERLAY / EFFECT REGISTRATION ────────────────────────────────────
var _overlay_root:   Control     = null
var _flash_rect:     ColorRect   = null
var _toast_box:      VBoxContainer = null
var _floating_root:  Control     = null
var _game_layer:     CanvasLayer = null
var _shake_active:   bool        = false

func register_overlays(
	overlay_root: Control,
	flash_rect:   ColorRect,
	toast_box:    VBoxContainer,
	floating_root: Control,
	game_layer:   CanvasLayer
) -> void:
	_overlay_root  = overlay_root
	_flash_rect    = flash_rect
	_toast_box     = toast_box
	_floating_root = floating_root
	_game_layer    = game_layer

# ─── SCREEN SHAKE (CanvasLayer offset) ────────────────────────────────
func screen_shake(magnitude: float = 12.0, duration: float = 0.4) -> void:
	# Add the "not is_juice_enabled" check here!
	if not is_juice_enabled or _game_layer == null or _shake_active:
		return
	_shake_active = true
	var t := create_tween()
	var steps := 14
	for i in steps:
		var falloff := 1.0 - float(i) / float(steps)
		var off := Vector2(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude)
		) * falloff
		t.tween_property(_game_layer, "offset", off, duration / steps)
	t.tween_property(_game_layer, "offset", Vector2.ZERO, 0.06)
	t.tween_callback(func(): _shake_active = false)

# ─── BACKGROUND FLASH ─────────────────────────────────────────────────
func background_flash(color: Color = COLOR_TEXT, duration: float = 0.25) -> void:
	if not is_juice_enabled: return
	if _flash_rect == null:
		return
	var c := color
	c.a = 0.0
	_flash_rect.color = c
	var peak := color
	peak.a = 0.45
	var t := create_tween()
	t.tween_property(_flash_rect, "color", peak, duration * 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var fade := color
	fade.a = 0.0
	t.tween_property(_flash_rect, "color", fade, duration * 0.75)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ─── TOAST NOTIFICATIONS ──────────────────────────────────────────────
func toast(text: String, color: Color = COLOR_ACCENT_3, lifetime: float = 2.4) -> void:
	if not is_juice_enabled: return
	if _toast_box == null:
		return
	Audio.play("toast")
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.02, 0.10, 0.92)
	sb.border_color = color
	sb.border_width_left   = 4
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left     = 10
	sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_left  = 4
	sb.corner_radius_bottom_right = 10
	sb.shadow_color = Color(color.r, color.g, color.b, 0.7)
	sb.shadow_size = 10
	sb.content_margin_left   = 16
	sb.content_margin_right  = 16
	sb.content_margin_top    = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_color_override("font_outline_color", COLOR_PANEL_DARK)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 18)
	if _fonts.has("title"):
		label.add_theme_font_override("font", _fonts["title"])
	panel.add_child(label)

	_toast_box.add_child(panel)

	# Slide in from right
	panel.modulate.a = 0.0
	panel.position.x = 400
	var t_in := panel.create_tween().set_parallel(true)
	t_in.tween_property(panel, "position:x", 0.0, 0.45)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_in.tween_property(panel, "modulate:a", 1.0, 0.3)

	# Wiggle for emphasis
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(panel):
		wiggle(panel, 4.0, 1)

	# Auto-dismiss
	await get_tree().create_timer(lifetime).timeout
	if not is_instance_valid(panel):
		return
	var t_out := panel.create_tween().set_parallel(true)
	t_out.tween_property(panel, "position:x", 400.0, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t_out.tween_property(panel, "modulate:a", 0.0, 0.3)
	await t_out.finished
	if is_instance_valid(panel):
		panel.queue_free()

# ─── FLOATING STAT NUMBERS ────────────────────────────────────────────
func spawn_floating_stat(character_id: String, stat: String, delta: int) -> void:
	if not is_juice_enabled: return
	if _floating_root == null or delta == 0:
		return

	# No on-screen stat dashboard right now, so floating numbers always
	# rise from top-center.
	var origin: Vector2 = Vector2(_floating_root.size.x / 2.0, 100)

	var label := Label.new()
	var prefix := "+" if delta > 0 else ""
	label.text = "%s%d %s" % [prefix, delta, stat.to_upper()]
	label.add_theme_color_override("font_color",
		COLOR_GOOD if delta > 0 else COLOR_BAD)
	label.add_theme_color_override("font_outline_color", COLOR_PANEL_DARK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 28)
	if _fonts.has("title"):
		label.add_theme_font_override("font", _fonts["title"])
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floating_root.add_child(label)

	# Position label centered on origin
	await get_tree().process_frame
	if not is_instance_valid(label):
		return
	label.position = origin - label.size / 2.0
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(0.4, 0.4)

	var t := label.create_tween().set_parallel(true)
	# Pop in
	t.tween_property(label, "scale", Vector2(1.1, 1.1), 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Float up
	t.tween_property(label, "position:y",
		label.position.y - 80.0, 1.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Drift sideways slightly
	t.tween_property(label, "position:x",
		label.position.x + randf_range(-30.0, 30.0), 1.1)\
		.set_trans(Tween.TRANS_SINE)
	# Fade out at the end
	t.chain().tween_property(label, "modulate:a", 0.0, 0.4)
	await t.finished
	if is_instance_valid(label):
		label.queue_free()

func _apply_juicy_dialog_panel(panel: Control) -> void:
	if not is_instance_valid(panel):
		return

	# ── ESCAPE DIALOGIC'S SIZER CONSTRAINT ──
	var sizer := panel.get_parent() as Control
	if sizer and sizer.name == "Sizer":
		# Calculate width dynamically so it grows from the center
		var screen_w := panel.get_viewport_rect().size.x
		var desired_w := screen_w * 0.88 # 88% of screen width
		var half_w := desired_w / 2.0

		sizer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		sizer.offset_left = -half_w
		sizer.offset_right = half_w
		sizer.offset_bottom = -40
		sizer.offset_top = -260 # 220px tall
		
		# Now tell the panel to fill our perfectly sized Sizer
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.custom_minimum_size = Vector2.ZERO

	# Chunky dark panel with strong pink border + cyan glow
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.02, 0.10, 0.96)
	sb.border_color = COLOR_ACCENT
	sb.border_width_left   = 5
	sb.border_width_right  = 7
	sb.border_width_top    = 5
	sb.border_width_bottom = 8
	sb.corner_radius_top_left     = 30
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_left  = 10
	sb.corner_radius_bottom_right = 30
	sb.shadow_color = Color(COLOR_ACCENT_2.r, COLOR_ACCENT_2.g, COLOR_ACCENT_2.b, 0.85)
	sb.shadow_size = 20
	sb.shadow_offset = Vector2(0, 8)
	sb.content_margin_left   = 48
	sb.content_margin_right  = 48
	sb.content_margin_top    = 32
	sb.content_margin_bottom = 32
	sb.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", sb)

	_style_dialog_text_child(panel)
	_stretch_dialog_text_child(panel)


func _stretch_dialog_text_child(panel: Node) -> void:
	# Because the parent is a PanelContainer, we use size_flags instead of anchors!
	for child in panel.get_children():
		if child is RichTextLabel:
			var rtl := child as RichTextLabel
			rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			rtl.fit_content = false
			rtl.scroll_active = false
			return
		_stretch_dialog_text_child(child)


func _style_dialog_text_child(panel: Node) -> void:
	for child in panel.get_children():
		if child is RichTextLabel:
			var rtl := child as RichTextLabel
			rtl.add_theme_color_override("default_color", COLOR_TEXT)
			rtl.add_theme_color_override("font_outline_color", COLOR_PANEL_DARK)
			rtl.add_theme_constant_override("outline_size", 5)
			rtl.add_theme_font_size_override("normal_font_size", 26)
			rtl.add_theme_font_size_override("bold_font_size", 26)
			rtl.add_theme_font_size_override("italics_font_size", 26)
			if _fonts.has("body"):
				rtl.add_theme_font_override("normal_font", _fonts["body"])
				rtl.add_theme_font_override("bold_font", _fonts["body"])
			return
		_style_dialog_text_child(child)
