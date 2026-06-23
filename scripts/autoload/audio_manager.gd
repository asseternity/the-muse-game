# res://scripts/autoload/audio_manager.gd
# Global music + SFX system. Autoload as "Audio".
extends Node

const MUSIC_PATH := "res://assets/music/one_hour_royalty_free_lofi.mp3"
const SFX_DIR    := "res://assets/sfx/"

# ─── SFX LIBRARY ──────────────────────────────────────────────────────
# Logical name → filename. Scripts call Audio.play("confirm") etc.
const SFX_FILES := {
	"confirm":    "SFX_UI_Confirm.wav",
	"cancel":     "SFX_UI_Cancel.wav",
	"open":       "SFX_UI_OpenMenu.wav",
	"close":      "SFX_UI_CloseMenu.wav",
	"hover":      "SFX_UI_MenuSelections.wav",
	"equip":      "SFX_UI_Equip.wav",
	"unequip":    "SFX_UI_Unequip.wav",
	"exit":       "SFX_UI_Exit.wav",
	"pause":      "SFX_UI_Pause.wav",
	"resume":     "SFX_UI_Resume.wav",
	"saved":      "SFX_UI_Saved.wav",
	"shop":       "SFX_UI_Shop.wav",
}

# Semantic aliases — what each UI moment *means*, mapped to a sfx key.
# This lets us rename one place and have every call site update.
const ALIASES := {
	"button_click":     "confirm",
	"button_hover":     "hover",
	"menu_open":        "open",
	"menu_close":       "close",
	"shelf_open":       "open",
	"shelf_close":      "close",
	"choice_show":      "shop",
	"choice_hover":     "hover",
	"choice_select":    "confirm",
	"input_show":       "open",
	"stat_up":          "equip",
	"stat_down":        "unequip",
	"toast":            "saved",
	"dialogue_advance": "hover",
	"new_game":         "confirm",
	"quit":             "exit",
}

# Prevent double-triggering the same sfx in the same frame (e.g. a button
# that both hovers and clicks on the same event).
const DEDUPE_WINDOW := 0.03

# ─── AUDIO PLAYERS ────────────────────────────────────────────────────
const SFX_POOL_SIZE := 8
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _sfx_cache: Dictionary = {}
var _last_played: Dictionary = {}   # key -> timestamp

var music_volume_db: float = -8.0
var sfx_volume_db:   float = -4.0
var music_enabled:   bool  = true
var sfx_enabled:     bool  = true

func _ready() -> void:
	# ── Music player with loop
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_music_player.volume_db = music_volume_db
	add_child(_music_player)

	if ResourceLoader.exists(MUSIC_PATH):
		var stream: AudioStream = load(MUSIC_PATH)
		# Force looping regardless of source format
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_music_player.stream = stream
		if music_enabled:
			_music_player.play()
	else:
		push_warning("[Audio] Music file not found: " + MUSIC_PATH)

	# ── SFX player pool (so overlapping sounds don't cut each other off)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		p.volume_db = sfx_volume_db
		add_child(p)
		_sfx_players.append(p)

	# ── Preload all SFX so first-play has no hitch
	for key in SFX_FILES.keys():
		var path: String = SFX_DIR + SFX_FILES[key]
		if ResourceLoader.exists(path):
			_sfx_cache[key] = load(path)
		else:
			push_warning("[Audio] SFX not found: " + path)

	# ── Auto-wire every button in the tree to click/hover sounds.
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_sweep_for_buttons", get_tree().root)

# ─── PUBLIC API ───────────────────────────────────────────────────────
func play(key_or_alias: String, volume_offset_db: float = 0.0, pitch_variation: float = 0.08) -> void:
	if not sfx_enabled:
		return

	# Resolve alias → real sfx key
	var key: String = ALIASES.get(key_or_alias, key_or_alias)

	# Dedupe: skip if this exact key played within the last window
	var now: float = Time.get_ticks_msec() / 1000.0
	if _last_played.has(key) and now - _last_played[key] < DEDUPE_WINDOW:
		return
	_last_played[key] = now

	var stream: AudioStream = _sfx_cache.get(key)
	if stream == null:
		return

	var player: AudioStreamPlayer = _sfx_players[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = sfx_volume_db + volume_offset_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()

func play_music() -> void:
	music_enabled = true
	if _music_player and not _music_player.playing and _music_player.stream:
		_music_player.play()

func stop_music(fade_time: float = 0.5) -> void:
	music_enabled = false
	if _music_player and _music_player.playing:
		if fade_time > 0.0:
			var t := create_tween()
			t.tween_property(_music_player, "volume_db", -80.0, fade_time)
			await t.finished
			_music_player.stop()
			_music_player.volume_db = music_volume_db
		else:
			_music_player.stop()

func set_music_volume(db: float) -> void:
	music_volume_db = db
	if _music_player:
		_music_player.volume_db = db

func set_sfx_volume(db: float) -> void:
	sfx_volume_db = db
	for p in _sfx_players:
		p.volume_db = db

# ─── AUTO-WIRING BUTTONS ──────────────────────────────────────────────
func _sweep_for_buttons(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_sweep_for_buttons(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var b: BaseButton = node
		if not b.is_connected("pressed", _on_button_pressed):
			b.pressed.connect(_on_button_pressed)
		if not b.is_connected("mouse_entered", _on_button_hover):
			b.mouse_entered.connect(_on_button_hover)

func _on_button_pressed() -> void:
	play("button_click")

func _on_button_hover() -> void:
	play("button_hover", -6.0, 0.12)
