# res://scripts/ui/variable_inspector.gd
# Debug overlay: press V to toggle a window listing every Dialogic.VAR
# variable (including nested folders) and every GameState.characters
# stat. Intended as a dev/test tool, not player-facing UI.
#
# Add this as an autoload (recommended) — Project Settings > Autoload,
# name it "VariableInspector" — or instance it once under your main
# scene's UI layer. It builds its own UI in code, no .tscn needed.
extends Control

const TOGGLE_ACTION_KEY := KEY_V

var _panel: PanelContainer
var _content_box: VBoxContainer
var _visible_state: bool = false

func _ready() -> void:
	# Sits above everything else, ignores layout from parents.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	# So this works no matter what scene is active.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.position = Vector2(-420, 16)
	_panel.offset_left = -420
	_panel.offset_top = 16
	_panel.custom_minimum_size = Vector2(400, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.02, 0.09, 0.92)
	sb.border_color = Color("#ff2a7a")
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", sb)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 0)
	# Cap height so it doesn't run off-screen on long variable lists.
	scroll.set("custom_minimum_size", Vector2(372, 0))
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var outer_box := VBoxContainer.new()
	outer_box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "VARIABLE INSPECTOR  (V to close)"
	title.add_theme_color_override("font_color", Color("#ffde00"))
	title.add_theme_font_size_override("font_size", 14)
	outer_box.add_child(title)

	var sep := HSeparator.new()
	outer_box.add_child(sep)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", 4)
	outer_box.add_child(_content_box)

	scroll.add_child(outer_box)
	_panel.add_child(scroll)
	add_child(_panel)

	# Cap the panel's overall height relative to viewport so it never
	# overflows on small windows.
	_panel.custom_minimum_size.y = 0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == TOGGLE_ACTION_KEY:
			# Don't toggle while the player is typing into a text field
			# (e.g. the Dialogic text-input box) — check for a focused
			# LineEdit/TextEdit anywhere in the tree first.
			if _is_text_field_focused():
				return
			toggle()

func _is_text_field_focused() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

func toggle() -> void:
	_visible_state = not _visible_state
	visible = _visible_state
	if _visible_state:
		_refresh()

func _refresh() -> void:
	for child in _content_box.get_children():
		child.queue_free()

	_add_section_header("DIALOGIC VARIABLES")
	_add_dialogic_variables()

	_add_section_header("GAME STATE — CHARACTERS")
	_add_game_state_stats()

func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color("#00f0ff"))
	lbl.add_theme_font_size_override("font_size", 13)
	_content_box.add_child(lbl)

func _add_row(key: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.custom_minimum_size = Vector2(180, 0)
	key_lbl.add_theme_color_override("font_color", Color("#a390d4"))
	key_lbl.add_theme_font_size_override("font_size", 13)
	key_lbl.clip_text = true
	row.add_child(key_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_color_override("font_color", Color("#ffffff"))
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(val_lbl)

	_content_box.add_child(row)

# ─── DIALOGIC VARIABLES ────────────────────────────────────────────────
func _add_dialogic_variables() -> void:
	if not Engine.has_singleton("Dialogic") and not (Engine.get_main_loop() as SceneTree).root.has_node("Dialogic"):
		# Dialogic autoload not present at all — extremely unlikely, but
		# guard anyway so this never hard-crashes the inspector.
		pass

	var dialogic := _get_dialogic()
	if dialogic == null or not ("VAR" in dialogic):
		_add_row("(unavailable)", "Dialogic.VAR not found")
		return

	var var_root = dialogic.VAR
	if var_root == null:
		_add_row("(unavailable)", "Dialogic.VAR is null")
		return

	var found_any := _walk_variable_folder(var_root, "")
	if not found_any:
		_add_row("(none)", "no variables defined yet")

# Recursively walks a Dialogic variable folder, printing every variable
# and descending into sub-folders with dotted prefixes (matches the
# {Folder.subfolder.var} syntax used in timelines).
# Returns true if at least one variable was printed.
func _walk_variable_folder(folder, prefix: String) -> bool:
	var any_found := false

	if folder.has_method("variables"):
		var var_names: Array = folder.variables(false)
		for var_name in var_names:
			var full_name: String = (prefix + "." + str(var_name)) if prefix != "" else str(var_name)
			var value = folder.get(var_name) if folder.has_method("get") else null
			_add_row(full_name, str(value))
			any_found = true

	if folder.has_method("folders"):
		var sub_folders: Array = folder.folders()
		for sub in sub_folders:
			var sub_name: String = str(sub.name) if "name" in sub else "?"
			var new_prefix: String = (prefix + "." + sub_name) if prefix != "" else sub_name
			if _walk_variable_folder(sub, new_prefix):
				any_found = true

	return any_found

func _get_dialogic() -> Object:
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.root
	if root.has_node("Dialogic"):
		return root.get_node("Dialogic")
	return null

# ─── GAME STATE STATS ──────────────────────────────────────────────────
func _add_game_state_stats() -> void:
	if not Engine.get_main_loop():
		return
	var tree := get_tree()
	if tree == null or not tree.root.has_node("GameState"):
		_add_row("(unavailable)", "GameState autoload not found")
		return

	var game_state = tree.root.get_node("GameState")
	if not ("characters" in game_state):
		_add_row("(unavailable)", "GameState.characters not found")
		return

	var characters: Dictionary = game_state.characters
	if characters.is_empty():
		_add_row("(none)", "no characters registered yet")
		return

	for cid in characters.keys():
		var data: Dictionary = characters[cid]
		var display: String = str(data.get("display_name", cid))
		_add_row("— %s —" % display, "")
		for stat_key in data.keys():
			if stat_key == "display_name" or stat_key == "available_portraits":
				continue
			_add_row("    " + str(stat_key), str(data[stat_key]))

	if "player_name" in game_state:
		_add_row("player_name", str(game_state.player_name))
