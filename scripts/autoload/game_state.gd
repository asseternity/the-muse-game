# res://scripts/autoload/game_state.gd
extends Node

signal stat_changed(character_id: String, stat: String, old_value: int, new_value: int)
signal player_name_changed(new_name: String)

const STAT_MIN := 0
const STAT_MAX := 100

# Every emotion any timeline might ask for. If a character lacks one,
# we fall back to "neutral".
const KNOWN_EMOTIONS := ["neutral", "happy", "sad", "angry", "surprised"]

var player_name: String = "Player"

# character_id -> data. `available_portraits` is the whitelist for fallback.
var characters := {}

func set_player_name(new_name: String) -> void:
	player_name = new_name
	player_name_changed.emit(new_name)
	if Dialogic:
		Dialogic.VAR.set_variable("PlayerName", new_name)

func get_stat(character_id: String, stat: String) -> int:
	if not characters.has(character_id): return 0
	return characters[character_id].get(stat, 0)

func set_stat(character_id: String, stat: String, value: int) -> void:
	if not characters.has(character_id): return
	var clamped: int = clamp(value, STAT_MIN, STAT_MAX)
	var old: int = characters[character_id].get(stat, 0)
	if old == clamped: return
	characters[character_id][stat] = clamped
	stat_changed.emit(character_id, stat, old, clamped)

func change_stat(character_id: String, stat: String, delta: int) -> void:
	set_stat(character_id, stat, get_stat(character_id, stat) + delta)

func apply_change_string(payload: String) -> void:
	var parts := payload.split(":")
	if parts.size() != 3: return
	change_stat(parts[0], parts[1], int(parts[2]))

# ─── Portrait fallback helper ─────────────────────────────────────────
# Returns the requested emotion if the character has it; otherwise "neutral".
func resolve_portrait(character_id: String, requested: String) -> String:
	if not characters.has(character_id):
		return "neutral"
	var available: Array = characters[character_id].get("available_portraits", ["neutral"])
	if requested in available:
		return requested
	return "neutral"

# Safe portrait change from code — use this instead of calling Dialogic directly
# when you don't know if the character supports the requested emotion.
func safe_change_portrait(character_id: String, requested: String) -> void:
	var dch_path := "res://dialogic/characters/%s.dch" % character_id
	if not ResourceLoader.exists(dch_path):
		return
	var character: DialogicCharacter = load(dch_path)
	var emotion := resolve_portrait(character_id, requested)
	Dialogic.Portraits.change_character_portrait(character, emotion)
