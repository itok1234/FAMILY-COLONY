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
var _music_player: AudioStreamPlayer
var _music_playback: AudioStreamGeneratorPlayback
var _music_sample_cursor: int = 0
const MUSIC_SAMPLE_RATE := 22050.0
const MUSIC_GAIN := 0.075

func _ready() -> void:
	_load_preferences()
	_apply_audio()
	_build_ambient_music()
	_build_settings_ui()

func _process(_delta: float) -> void:
	_fill_ambient_music_buffer()

func _build_ambient_music() -> void:
	# Original, royalty-free procedural ambient score; no external audio asset required.
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MUSIC_SAMPLE_RATE
	generator.buffer_length = 0.8
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ColonyAmbientMusic"
	_music_player.stream = generator
	_music_player.volume_db = -3.0
	add_child(_music_player)
	_music_player.play()
	_music_playback = _music_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _fill_ambient_music_buffer() -> void:
	if not is_instance_valid(_music_playback):
		return
	var frames_available := _music_playback.get_frames_available()
	if frames_available <= 0:
		return
	var chord_roots: Array[float] = [110.0, 82.41, 98.0, 73.42]
	var melody_notes: Array[float] = [440.0, 392.0, 329.63, 392.0, 493.88, 440.0, 392.0, 329.63]
	for frame_index in range(frames_available):
		var time_seconds := float(_music_sample_cursor) / MUSIC_SAMPLE_RATE
		var chord_index := int(floor(time_seconds / 8.0)) % chord_roots.size()
		var chord_phase := fmod(time_seconds, 8.0) / 8.0
		var root := chord_roots[chord_index]
		var next_root := chord_roots[(chord_index + 1) % chord_roots.size()]
		var blend := smoothstep(0.82, 1.0, chord_phase)
		root = lerpf(root, next_root, blend)
		var slow_breath := 0.78 + 0.22 * sin(TAU * time_seconds / 11.0)
		var pad := sin(TAU * root * time_seconds) * 0.42
		pad += sin(TAU * root * 1.5 * time_seconds + 0.4) * 0.24
		pad += sin(TAU * root * 2.0 * time_seconds + 0.8) * 0.12
		pad += sin(TAU * root * 2.01 * time_seconds) * 0.08
		var note_index := int(floor(time_seconds / 2.0)) % melody_notes.size()
		var note_phase := fmod(time_seconds, 2.0)
		var bell_envelope := exp(-note_phase * 2.8) * minf(note_phase * 5.0, 1.0)
		var bell := sin(TAU * melody_notes[note_index] * time_seconds) * bell_envelope * 0.12
		var sample := clampf((pad * slow_breath + bell) * MUSIC_GAIN, -0.8, 0.8)
		_music_playback.push_frame(Vector2(sample, sample))
		_music_sample_cursor += 1

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

	var volume_slider := HSlider.new()
	volume_slider.name = "MasterVolumeSlider"
	volume_slider.anchor_left = 0.035
	volume_slider.anchor_right = 0.24
	volume_slider.anchor_top = 0.195
	volume_slider.anchor_bottom = 0.255
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = _saved_linear_volume
	volume_slider.custom_minimum_size = Vector2(150, 32)
	volume_slider.value_changed.connect(_on_volume_changed)
	_settings_layer.add_child(volume_slider)
	_master_slider = volume_slider

	var volume_label := Label.new()
	volume_label.text = "VOLUME"
	volume_label.anchor_left = 0.035
	volume_label.anchor_right = 0.24
	volume_label.anchor_top = 0.255
	volume_label.anchor_bottom = 0.30
	volume_label.add_theme_font_size_override("font_size", 12)
	_settings_layer.add_child(volume_label)

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

func _on_volume_changed(value: float) -> void:
	_saved_linear_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	_save_preferences()


func _toggle_credits() -> void:
	if is_instance_valid(_credits_panel):
		_credits_panel.visible = not _credits_panel.visible
