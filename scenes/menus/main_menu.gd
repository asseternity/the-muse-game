# res://scenes/menus/main_menu.gd
extends Control

# ── UPDATE THIS PATH to wherever your logo image lives.
const LOGO_PATH := "res://assets/"
const GAME_SCENE_PATH := "res://scenes/main/main.tscn"

@onready var logo:		  TextureRect = $Logo
@onready var btn_new:     Button = $ButtonsCenter/VBox/BtnNewGame
@onready var btn_cont:    Button = $ButtonsCenter/VBox/BtnContinue
@onready var btn_set:     Button = $ButtonsCenter/VBox/BtnSettings
@onready var btn_quit:    Button = $ButtonsCenter/VBox/BtnQuit
@onready var version_lbl: Label  = $VersionLabel

func _ready() -> void:
	# Hide the global synthwave background while we're on the main menu.
	var bg := get_tree().root.get_node_or_null("SynthwaveBackground")
	if bg:
		bg.visible = false
	# Re-enable it when we leave (handled in _transition_to_game)

	# Make sure the synthwave shader background from UITheme is visible.
	# UITheme spawns it onto root automatically, but we ensure our menu
	# doesn't block it with an opaque background.
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Load logo if available
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	else:
		# Fallback: replace logo with a stylized text label
		var fallback := Label.new()
		fallback.text = "THE MUSE"
		fallback.add_theme_font_size_override("font_size", 72)
		fallback.add_theme_color_override("font_color", UITheme.COLOR_ACCENT)
		fallback.add_theme_color_override("font_outline_color", UITheme.COLOR_PANEL_DARK)
		fallback.add_theme_constant_override("outline_size", 12)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		logo.add_child(fallback)
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Wire up buttons
	btn_new.pressed.connect(_on_new_game)
	btn_cont.pressed.connect(_on_continue)
	btn_set.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

	# Disable Continue if no save exists
	btn_cont.disabled = not _save_exists()

	# Style the version label
	version_lbl.add_theme_color_override("font_color", UITheme.COLOR_TEXT_DIM)
	version_lbl.add_theme_color_override("font_outline_color", UITheme.COLOR_PANEL_DARK)
	version_lbl.add_theme_constant_override("outline_size", 4)

	# ── ENTRANCE ANIMATIONS ─────────────────────────────────────────
	# Logo drops from above
	logo.modulate.a = 0.0
	logo.position.y -= 60
	var lt := create_tween().set_parallel(true)
	lt.tween_property(logo, "position:y", logo.position.y + 60, 0.9)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lt.tween_property(logo, "modulate:a", 1.0, 0.6)

	# Buttons cascade in
	var buttons := [btn_new, btn_cont, btn_set, btn_quit]
	for i in buttons.size():
		var b: Button = buttons[i]
		b.modulate.a = 0.0
		b.position.x -= 400
		var d: float = 0.25 + i * 0.08
		var bt := create_tween().set_parallel(true)
		bt.tween_interval(d)
		bt.chain().tween_property(b, "position:x", b.position.x + 400, 0.55)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var bt2 := create_tween()
		bt2.tween_interval(d)
		bt2.tween_property(b, "modulate:a", 1.0, 0.4)

	# Logo idle bob
	await get_tree().create_timer(1.0).timeout
	_start_logo_bob()

	# Welcome confetti from the New Game button
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(btn_new):
		UITheme.burst(btn_new, UITheme.COLOR_ACCENT_3, 24)

func _start_logo_bob() -> void:
	if not is_instance_valid(logo):
		return
	var t := create_tween().set_loops()
	t.tween_property(logo, "position:y", logo.position.y - 8, 1.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(logo, "position:y", logo.position.y, 1.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ─── BUTTON HANDLERS ──────────────────────────────────────────────────
func _on_new_game() -> void:
	Audio.play("new_game")
	UITheme.confetti(btn_new, 40)
	UITheme.squish(btn_new, 0.4)
	await get_tree().create_timer(0.25).timeout
	# Reset GameState if you have a method for it
	if GameState.has_method("reset"):
		GameState.reset()
	_transition_to_game()

func _on_continue() -> void:
	UITheme.squish(btn_cont, 0.3)
	# Hook up your save loading here
	if GameState.has_method("load_game"):
		GameState.load_game()
	_transition_to_game()

func _on_settings() -> void:
	UITheme.squish(btn_set, 0.3)
	UITheme.toast("Settings coming soon!", UITheme.COLOR_ACCENT_2)

func _on_quit() -> void:
	Audio.play("quit")
	UITheme.squish(btn_quit, 0.4)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	await t.finished
	get_tree().quit()

# ─── HELPERS ──────────────────────────────────────────────────────────
func _save_exists() -> bool:
	# Adjust to match your save system. Returns false by default.
	return FileAccess.file_exists("user://save_slot_0.tres")

func _transition_to_game() -> void:
	# Re-enable the synthwave background for the main game
	var bg := get_tree().root.get_node_or_null("SynthwaveBackground")
	if bg:
		bg.visible = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await t.finished
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
