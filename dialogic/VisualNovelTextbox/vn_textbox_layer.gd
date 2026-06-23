@tool
extends DialogicLayoutLayer

## A layer that allows showing up to 10 choices.
## Choices are positioned in the center of the screen.

@export_group("Text")
@export_subgroup('Font')
@export var font_use_global: bool = true
@export_file('*.ttf', '*.tres') var font_custom: String = ""
@export_subgroup('Size')
@export var font_size_use_global: bool = true
@export var font_size_custom: int = 16
@export_subgroup('Color')
@export var text_color_use_global: bool = true
@export var text_color_custom: Color = Color.WHITE
@export var text_color_pressed: Color = Color.WHITE
@export var text_color_hovered: Color = Color.GRAY
@export var text_color_disabled: Color = Color.DARK_GRAY
@export var text_color_focused: Color = Color.WHITE

@export_group('Boxes')
@export_subgroup('Panels')
@export_file('*.tres') var boxes_stylebox_normal: String = "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_normal.tres"
@export_file('*.tres') var boxes_stylebox_hovered: String = "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_hover.tres"
@export_file('*.tres') var boxes_stylebox_pressed: String = ""
@export_file('*.tres') var boxes_stylebox_disabled: String = ""
@export_file('*.tres') var boxes_stylebox_focused: String = "res://addons/dialogic/Modules/DefaultLayoutParts/Layer_VN_Choices/choice_panel_focus.tres"
@export_subgroup('Size & Position')
@export var boxes_v_separation: int = 10
@export var boxes_fill_width: bool = true
@export var boxes_min_size: Vector2 = Vector2()
@export var boxes_offset: Vector2 = Vector2()

@export_group('Sounds')
@export_range(-80, 24, 0.01) var sounds_volume: float = -10
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_pressed: String = "res://addons/dialogic/Example Assets/sound-effects/typing1.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_hover: String = "res://addons/dialogic/Example Assets/sound-effects/typing2.wav"
@export_file("*.wav", "*.ogg", "*.mp3") var sounds_focus: String = "res://addons/dialogic/Example Assets/sound-effects/typing4.wav"

@export_group('Choices')
@export_subgroup('Behavior')
@export var maximum_choices: int = 10
@export_file('*.tscn') var choices_custom_button: String = ""

func get_choices() -> VBoxContainer:
	return $Choices

func get_button_sound() -> DialogicNode_ButtonSound:
	return %DialogicNode_ButtonSound


func _apply_export_overrides() -> void:
	# ── Task 4: inject our synthwave theme at runtime (not in editor).
	if not Engine.is_editor_hint():
		var ui := get_node_or_null("/root/UITheme")
		if is_instance_valid(ui) and ui.get("global_theme") != null:
			self.set("theme", ui.global_theme)
			_propagate_theme(self, ui.global_theme)

	var choices: Control = get_choices()
	choices.add_theme_constant_override(&"separation", boxes_v_separation)
	self.position = boxes_offset

	# Replace choice buttons.
	for child: Node in choices.get_children():
		if child is DialogicNode_ChoiceButton:
			child.queue_free()

	var choices_button: PackedScene = null
	if not choices_custom_button.is_empty():
		if ResourceLoader.exists(choices_custom_button):
			choices_button = (load(choices_custom_button) as PackedScene)
		else:
			printerr("[Dialogic] Unable to load custom choice button from ", choices_custom_button)

	for i in range(0, maximum_choices):
		var new_choice: DialogicNode_ChoiceButton
		if choices_button != null:
			new_choice = (choices_button.instantiate() as DialogicNode_ChoiceButton)
		else:
			new_choice = DialogicNode_ChoiceButton.new()
		choices.add_child(new_choice)

		if boxes_fill_width:
			new_choice.size_flags_horizontal = Control.SIZE_FILL
		else:
			new_choice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		new_choice.custom_minimum_size = boxes_min_size

		# Apply theme to each freshly created button immediately.
		if not Engine.is_editor_hint():
			var ui := get_node_or_null("/root/UITheme")
			if is_instance_valid(ui) and ui.get("global_theme") != null:
				new_choice.set("theme", ui.global_theme)

	# Apply sound settings.
	var button_sound: DialogicNode_ButtonSound = get_button_sound()
	button_sound.volume_db = sounds_volume
	button_sound.sound_pressed = load(sounds_pressed)
	button_sound.sound_hover   = load(sounds_hover)
	button_sound.sound_focus   = load(sounds_focus)


## Recursively sets our theme on every Control child so no node is missed.
func _propagate_theme(node: Node, t: Theme) -> void:
	if node is Control:
		(node as Control).set("theme", t)
	for child in node.get_children():
		_propagate_theme(child, t)
