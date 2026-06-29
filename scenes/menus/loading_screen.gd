# res://scenes/menus/loading_screen.gd
# Deliberate loading screen shown between Main Menu and the game.
# Runs for a guaranteed minimum duration with a simulated progress fill
# and a rotating tip. Background is an optional image; if none is set,
# falls back to the master theme's base background color.
extends Control

const MIN_DURATION := 5.0

# Where to go once loading finishes. Set by whoever calls change_scene_to
# this scene — see main_menu.gd. Falls back to the main game scene if unset.
var next_scene_path := "res://scenes/main/Main.tscn"

# Optional background image. Set this before the scene's _ready() runs —
# e.g. right after instancing it — or just set background_image_path and
# let _ready() load it for you. Leave both empty for the flat theme color.
var background_texture: Texture2D = null
var background_image_path: String = ""

const TIPS := [
	"Tip: You can revisit choices later — nothing here is permanent yet.",
	"Tip: Dialogue advances faster if you click instead of waiting.",
	"Tip: This screen is a placeholder — swap these tips for real ones!",
	"Tip: Hold on to your snacks. Things are about to get narrative.",
]

@onready var bg_rect: TextureRect = $BgImage
@onready var bg_fill: ColorRect = $BgFill
@onready var progress_bar: ProgressBar = $CenterColumn/ProgressBar
@onready var status_label: Label = $CenterColumn/StatusLabel
@onready var tip_label: Label = $CenterColumn/TipLabel
@onready var title_label: Label = $CenterColumn/TitleLabel

var _elapsed := 0.0
var _tip_timer := 0.0
var _tip_index := -1
var _finished := false

func _ready() -> void:
	_apply_background()

	progress_bar.value = 0.0
	progress_bar.max_value = 100.0

	title_label.text = "LOADING"
	title_label.add_theme_color_override("font_color", UITheme.COLOR_ACCENT)
	title_label.add_theme_color_override("font_outline_color", UITheme.COLOR_PANEL_DARK)
	title_label.add_theme_constant_override("outline_size", 8)

	status_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_DIM)
	tip_label.add_theme_color_override("font_color", UITheme.COLOR_ACCENT_2)

	_next_tip()

	# Gentle pulse on the title so the screen doesn't feel static.
	var t := create_tween().set_loops()
	t.tween_property(title_label, "modulate:a", 0.6, 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(title_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _apply_background() -> void:
	# Resolve a texture from either the direct reference or a path,
	# direct reference taking priority if both happen to be set.
	var tex: Texture2D = background_texture
	if tex == null and not background_image_path.is_empty():
		if ResourceLoader.exists(background_image_path):
			tex = load(background_image_path)
		else:
			push_warning("[LoadingScreen] Background image not found: " + background_image_path)

	if tex != null:
		bg_rect.texture = tex
		bg_rect.visible = true
		bg_fill.visible = false
	else:
		bg_rect.visible = false
		bg_fill.visible = true
		bg_fill.color = UITheme.COLOR_BG

func _process(delta: float) -> void:
	if _finished:
		return

	_elapsed += delta
	_tip_timer += delta

	# Rotate tips every ~2 seconds.
	if _tip_timer >= 2.0:
		_tip_timer = 0.0
		_next_tip()

	# Simulated progress: smooth easing toward 100% over MIN_DURATION,
	# but never actually claim 100% until we're truly about to leave —
	# that final snap to 100 happens in _finish_loading().
	var t: float = clamp(_elapsed / MIN_DURATION, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - t, 3.0)  # ease-out cubic, feels less robotic than linear
	progress_bar.value = eased * 96.0  # hold just under 100 until finish

	status_label.text = "Loading%s  %d%%" % [_dots(), int(progress_bar.value)]

	if _elapsed >= MIN_DURATION:
		_finish_loading()

func _dots() -> String:
	var n := int(_elapsed * 2.0) % 4
	return ".".repeat(n)

func _next_tip() -> void:
	if TIPS.is_empty():
		return
	var idx := _tip_index
	if TIPS.size() > 1:
		while idx == _tip_index:
			idx = randi() % TIPS.size()
	else:
		idx = 0
	_tip_index = idx
	tip_label.text = TIPS[_tip_index]

	tip_label.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(tip_label, "modulate:a", 1.0, 0.3)

func _finish_loading() -> void:
	_finished = true
	status_label.text = "Ready!"

	var t := create_tween()
	t.tween_property(progress_bar, "value", 100.0, 0.25)
	await t.finished

	Audio.play("saved")
	await get_tree().create_timer(0.2).timeout

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	await fade.finished

	get_tree().change_scene_to_file(next_scene_path)