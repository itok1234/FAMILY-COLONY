extends Node
## In-world audio preferences and studio credits.
## Audio is muted on first launch; the member may enable it explicitly.

const SETTINGS_PATH := "user://family_colony_settings.cfg"
const MASTER_BUS := "Master"

var _master_slider: HSlider
var _mute_button: Button
var _credits_panel: PanelContainer
var _muted := true
var _saved_linear_volume := 0.8
var _settings_layer: CanvasLayer

func _ready() -> void:
	_load_preferences()
	_apply_audio()
	_build_settings_ui()

func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		_muted = bool(config.get_value("audio", "muted", true))
		_saved_linear_volume = clampf(float(config.get_value("audio", "volume", 0.8)), 0.0, 1.0)
	else:
		_muted = true
		_saved_linear_volume = 0.8

func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "muted", _muted)
	config.set_value("audio", "volume", _saved_linear_volume)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("FAMILY COLONY: Audio preferences could not be saved.")

func _apply_audio() -> void:
	var bus := AudioServer.get_bus_index(MASTER_BUS)
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, _muted)
	AudioServer.set_bus_volume_linear(bus, _saved_linear_volume)

func _build_settings_ui() -> void:
	_settings_layer = CanvasLayer.new()
	_settings_layer.name = "AudioAndStudioSettings"
	_settings_layer.layer = 24
	add_child(_settings_layer)

	var toggle := Button.new()
	toggle.name = "AudioSettingsButton"
	toggle.text = "SUARA: " + ("MATI" if _muted else "HIDUP")
	toggle.anchor_left = 0.035
	toggle.anchor_right = 0.24
	toggle.anchor_top = 0.045
	toggle.anchor_bottom = 0.11
	toggle.custom_minimum_size = Vector2(150, 42)
	toggle.pressed.connect(_toggle_audio)
	_settings_layer.add_child(toggle)
	_mute_button = toggle

	var credits_button := Button.new()
	credits_button.name = "StudioCreditsButton"
	credits_button.text = "TENTANG STUDIO"
	credits_button.anchor_left = 0.035
	credits_button.anchor_right = 0.24
	credits_button.anchor_top = 0.12
	credits_button.anchor_bottom = 0.185
	credits_button.custom_minimum_size = Vector2(150, 42)
	credits_button.pressed.connect(_toggle_credits)
	_settings_layer.add_child(credits_button)

	var panel := PanelContainer.new()
	panel.name = "StudioCreditsPanel"
	panel.anchor_left = 0.22
	panel.anchor_right = 0.78
	panel.anchor_top = 0.28
	panel.anchor_bottom = 0.72
	panel.visible = false
	_settings_layer.add_child(panel)
	_credits_panel = panel

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Label.new()
	title.text = "FAMILY COLONY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	column.add_child(title)

	var studio := Label.new()
	studio.text = "Dikembangkan oleh CDL PROJECT STUDIO"
	studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	studio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	studio.add_theme_font_size_override("font_size", 17)
	column.add_child(studio)

	var subtitle := Label.new()
	subtitle.text = "World • Community • Stories"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.84, 0.91))
	column.add_child(subtitle)

	var close := Button.new()
	close.text = "TUTUP"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(func(): _credits_panel.visible = false)
	column.add_child(close)

func _toggle_audio() -> void:
	if _muted:
		_muted = false
	else:
		_muted = true
	_apply_audio()
	_save_preferences()
	if is_instance_valid(_mute_button):
		_mute_button.text = "SUARA: " + ("MATI" if _muted else "HIDUP")

func _toggle_credits() -> void:
	if is_instance_valid(_credits_panel):
		_credits_panel.visible = not _credits_panel.visible
