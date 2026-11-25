extends Node3D
## Spatial 3D audio controls and studio credits. Preferences remain local and persistent.

const SETTINGS_PATH := "user://family_colony_settings.cfg"
const MASTER_BUS := "Master"
const MUSIC_SAMPLE_RATE := 22050.0
const MUSIC_GAIN := 0.075
const PICK_LAYER := 16

var _muted := true
var _saved_linear_volume := 0.8
var _music_player: AudioStreamPlayer
var _music_playback: AudioStreamGeneratorPlayback
var _music_sample_cursor: int = 0
var _panel: Node3D
var _credits_label: Label3D
var _camera: Camera3D


func _ready() -> void:
	_load_preferences()
	_apply_audio()
	_build_ambient_music()
	_build_spatial_panel()


func _process(_delta: float) -> void:
	_fill_ambient_music_buffer()


func open_settings_panel() -> void:
	if is_instance_valid(_panel):
		_panel.visible = true
		_update_audio_labels()


func open_credits_panel() -> void:
	if is_instance_valid(_panel):
		_panel.visible = true
		if is_instance_valid(_credits_label):
			_credits_label.visible = true
		_update_audio_labels()


func close_settings_panel() -> void:
	if is_instance_valid(_panel):
		_panel.visible = false


func _build_ambient_music() -> void:
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
	for frame_index in range(mini(frames_available, 2048)):
		var time_seconds := float(_music_sample_cursor) / MUSIC_SAMPLE_RATE
		var chord_index := int(floor(time_seconds / 8.0)) % chord_roots.size()
		var chord_phase := fmod(time_seconds, 8.0) / 8.0
		var root := lerpf(chord_roots[chord_index], chord_roots[(chord_index + 1) % chord_roots.size()], smoothstep(0.82, 1.0, chord_phase))
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


func _build_spatial_panel() -> void:
	_camera = get_viewport().get_camera_3d()
	if _camera == null:
		call_deferred("_build_spatial_panel")
		return
	_panel = Node3D.new()
	_panel.name = "SpatialAudioSettingsPanel"
	_panel.position = Vector3(0.0, 0.0, -3.6)
	_camera.add_child(_panel)
	var backing := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(4.4, 3.15, 0.12)
	backing.mesh = plate
	backing.material_override = _material(Color("#14283d"))
	_panel.add_child(backing)
	_add_label("PENGATURAN KOLONI", Vector3(0, 1.22, -0.09), 30, Color("#f3d99a"))
	_add_label("SUARA & VOLUME", Vector3(0, 0.62, -0.09), 21, Color("#e5edf4"))
	_add_button("TOGGLE_AUDIO", "SUARA: MATI", Vector3(-1.0, 0.05, -0.18), Vector3(1.8, 0.48, 0.16))
	_add_label("VOLUME MASTER", Vector3(0, -0.52, -0.09), 17, Color("#d5e0e9"))
	for step in range(11):
		_add_button("VOLUME_" + str(step), str(step * 10), Vector3(-1.5 + float(step) * 0.3, -0.98, -0.18), Vector3(0.25, 0.36, 0.16), Color("#527d8c"))
	_add_button("CREDITS", "TENTANG STUDIO", Vector3(0.95, 0.05, -0.18), Vector3(1.8, 0.48, 0.16))
	_add_button("CLOSE", "TUTUP", Vector3(0, -1.42, -0.18), Vector3(1.4, 0.4, 0.16), Color("#315b70"))
	_credits_label = Label3D.new()
	_credits_label.text = "CDL PROJECT STUDIO\\nWorld • Community • Stories\\nFAMILY COLONY"
	_credits_label.font_size = 19
	_credits_label.pixel_size = 0.0035
	_credits_label.position = Vector3(0, 0.0, -0.24)
	_credits_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_credits_label.modulate = Color("#f3d99a")
	_credits_label.visible = false
	_panel.add_child(_credits_label)
	_panel.visible = false
	_update_audio_labels()


func _add_label(value: String, local_position: Vector3, font_size: int, tint: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.font_size = font_size
	label.pixel_size = 0.004
	label.position = local_position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint
	label.outline_size = 7
	label.outline_modulate = Color("#101b2b")
	_panel.add_child(label)


func _add_button(action: String, caption: String, local_position: Vector3, dimensions: Vector3, tint: Color = Color("#315b70")) -> void:
	var area := Area3D.new()
	area.name = "Settings_" + action
	area.position = local_position
	area.input_ray_pickable = true
	area.collision_layer = PICK_LAYER
	area.collision_mask = 0
	area.set_meta("settings_action", action)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions + Vector3(0.08, 0.08, 0.08)
	collision.shape = shape
	area.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.material_override = _material(tint)
	area.add_child(mesh)
	var label := Label3D.new()
	label.text = caption
	label.font_size = 16
	label.pixel_size = 0.0035
	label.position.z = -dimensions.z * 0.55
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	area.add_child(label)
	_panel.add_child(area)


func _input(event: InputEvent) -> void:
	if not is_instance_valid(_panel) or not _panel.visible:
		return
	var screen_position := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		screen_position = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		screen_position = event.position
		pressed = event.pressed
	if not pressed:
		return
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 12.0)
	query.collide_with_areas = true
	query.collision_mask = PICK_LAYER
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is Area3D and collider.has_meta("settings_action"):
		_handle_action(str(collider.get_meta("settings_action")))
		get_viewport().set_input_as_handled()


func _handle_action(action: String) -> void:
	if action == "TOGGLE_AUDIO":
		_muted = not _muted
		_apply_audio()
		_save_preferences()
	elif action.begins_with("VOLUME_"):
		_saved_linear_volume = float(action.trim_prefix("VOLUME_")) / 10.0
		_apply_audio()
		_save_preferences()
	elif action == "CREDITS":
		if is_instance_valid(_credits_label):
			_credits_label.visible = not _credits_label.visible
	elif action == "CLOSE":
		close_settings_panel()
	_update_audio_labels()


func _update_audio_labels() -> void:
	if not is_instance_valid(_panel):
		return
	var toggle := _panel.get_node_or_null("Settings_TOGGLE_AUDIO/Label3D") as Label3D
	if toggle != null:
		toggle.text = "SUARA: " + ("MATI" if _muted else "HIDUP")
	for step in range(11):
		var label := _panel.get_node_or_null("Settings_VOLUME_" + str(step) + "/Label3D") as Label3D
		if label != null:
			label.modulate = Color("#f3d99a") if absf(_saved_linear_volume - float(step) / 10.0) < 0.051 else Color.WHITE


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.32
	material.roughness = 0.28
	material.emission_enabled = true
	material.emission = color.darkened(0.25)
	material.emission_energy_multiplier = 0.22
	return material
