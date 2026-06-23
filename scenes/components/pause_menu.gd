# res://scenes/components/pause_menu.gd
extends CanvasLayer

@onready var panel: PanelContainer = $Center/MenuPanel
@onready var dimmer: ColorRect = $Dimmer
@onready var sld_music: HSlider = $Center/MenuPanel/Margin/VBox/Grid/SldMusic
@onready var sld_sfx: HSlider = $Center/MenuPanel/Margin/VBox/Grid/SldSFX
@onready var sld_voice: HSlider = $Center/MenuPanel/Margin/VBox/Grid/SldVoice
@onready var btn_resume: Button = $Center/MenuPanel/Margin/VBox/BtnResume
@onready var btn_quit: Button = $Center/MenuPanel/Margin/VBox/BtnQuit

# Fetch the Godot internal IDs for our custom audio buses
var _music_bus := AudioServer.get_bus_index("Music")
var _sfx_bus   := AudioServer.get_bus_index("SFX")
var _voice_bus := AudioServer.get_bus_index("Voice")

func _ready() -> void:
	hide()
	
	# Apply your juicy UI theme
	panel.theme = UITheme.global_theme
	UITheme.attach_fx(panel)
	
	btn_resume.pressed.connect(_resume)
	btn_quit.pressed.connect(func(): get_tree().quit())
	
	# Wire up the sliders to change volume instantly
	sld_music.value_changed.connect(_on_vol_changed.bind(_music_bus))
	sld_sfx.value_changed.connect(_on_vol_changed.bind(_sfx_bus))
	sld_voice.value_changed.connect(_on_vol_changed.bind(_voice_bus))
	
	# Read current volume levels on boot so sliders match the actual audio
	_init_slider(sld_music, _music_bus)
	_init_slider(sld_sfx, _sfx_bus)
	_init_slider(sld_voice, _voice_bus)

func _init_slider(slider: HSlider, bus_idx: int) -> void:
	if bus_idx >= 0:
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

# Listen for the escape key
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if get_tree().paused:
			_resume()
		else:
			_pause()

func _pause() -> void:
	# Freeze the game
	get_tree().paused = true
	show()
	
	# Juice entrance
	dimmer.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(dimmer, "modulate:a", 1.0, 0.2)
	UITheme.pop_in(panel)

func _resume() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(dimmer, "modulate:a", 0.0, 0.2)
	t.tween_property(panel, "scale", Vector2.ZERO, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await t.finished
	hide()
	# Unfreeze the game
	get_tree().paused = false

func _on_vol_changed(value: float, bus_idx: int) -> void:
	# Convert linear slider (0.0 to 1.0) back to logarithmic Decibels 
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
