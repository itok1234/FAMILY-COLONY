extends Node
## Adaptive graphics profiles for a wide range of Android devices.
## Quality changes rendering only; they never disable gameplay or member features.

enum Quality { AUTO, PERFORMANCE, BALANCED, HIGH }

@export var default_quality: Quality = Quality.AUTO
@export var world_environment_path: NodePath = NodePath("../WorldEnvironment")
@export var sun_path: NodePath = NodePath("../Sun")
@export var environment_builder_path: NodePath = NodePath("../EnvironmentBuilder")

@onready var world_environment: WorldEnvironment = get_node_or_null(world_environment_path) as WorldEnvironment
@onready var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
@onready var environment_builder: Node = get_node_or_null(environment_builder_path)

var _selected_quality: Quality = Quality.AUTO
var _quality_panel: Node3D
var _quality_status: Label3D
var _runtime_quality: Quality = Quality.BALANCED
var _fps_sample_timer: float = 0.0
var _low_fps_streak: int = 0
var _healthy_fps_streak: int = 0
var _startup_grace: float = 12.0


func _ready() -> void:
	_load_saved_quality()
	call_deferred("_build_quality_picker")
	# Apply after sibling nodes finish _ready(), so EnvironmentBuilder cannot overwrite the selected density.
	call_deferred("apply_quality", _selected_quality)


func _process(delta: float) -> void:
	if _selected_quality != Quality.AUTO:
		return
	if _startup_grace > 0.0:
		_startup_grace = maxf(0.0, _startup_grace - delta)
		return
	_fps_sample_timer += delta
	if _fps_sample_timer < 4.0:
		return
	_fps_sample_timer = 0.0
	var fps := Engine.get_frames_per_second()
	if fps < 28:
		_low_fps_streak += 1
		_healthy_fps_streak = 0
		if _low_fps_streak >= 2 and _runtime_quality != Quality.PERFORMANCE:
			_apply_resolved_quality(Quality.PERFORMANCE)
	elif fps >= 50:
		_healthy_fps_streak += 1
		_low_fps_streak = 0
		if _healthy_fps_streak >= 3 and _runtime_quality == Quality.PERFORMANCE:
			_apply_resolved_quality(Quality.BALANCED)
	else:
		_low_fps_streak = 0
		_healthy_fps_streak = 0


func _load_saved_quality() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://family_colony_settings.cfg")
	if err == OK:
		_selected_quality = int(config.get_value("graphics", "quality", int(default_quality)))
	else:
		_selected_quality = default_quality
	_selected_quality = clampi(int(_selected_quality), int(Quality.AUTO), int(Quality.HIGH))


func _save_quality() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "quality", int(_selected_quality))
	var err := config.save("user://family_colony_settings.cfg")
	if err != OK:
		push_warning("FAMILY COLONY: Graphics preference could not be saved.")


func _build_quality_picker() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	_quality_panel = Node3D.new()
	_quality_panel.name = "SpatialGraphicsQualityPanel"
	_quality_panel.position = Vector3(-1.05, 0.78, -3.2)
	camera.add_child(_quality_panel)
	var backing := MeshInstance3D.new()
	var backing_mesh := BoxMesh.new()
	backing_mesh.size = Vector3(2.35, 1.12, 0.08)
	backing.mesh = backing_mesh
	backing.material_override = _quality_material(Color("#10263a"), 0.25)
	_quality_panel.add_child(backing)
	var title := Label3D.new()
	title.text = "KUALITAS GRAFIS"
	title.font_size = 22
	title.pixel_size = 0.002
	title.position = Vector3(0, 0.36, -0.06)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color("#f0d59b")
	_quality_panel.add_child(title)
	var labels := ["AUTO", "HEMAT", "SEIMBANG", "TINGGI"]
	for index in range(labels.size()):
		var area := Area3D.new()
		area.name = "QualityOption_%d" % index
		area.position = Vector3(-0.84 + float(index) * 0.56, -0.12, -0.10)
		area.input_ray_pickable = true
		area.collision_layer = 8
		area.collision_mask = 0
		area.set_meta("graphics_quality", index)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.50, 0.42, 0.18)
		collision.shape = shape
		area.add_child(collision)
		var face := MeshInstance3D.new()
		var face_mesh := BoxMesh.new()
		face_mesh.size = Vector3(0.48, 0.40, 0.12)
		face.mesh = face_mesh
		face.material_override = _quality_material(Color("#b58a45") if index == int(_selected_quality) else Color("#31536a"), 0.32)
		area.add_child(face)
		var label := Label3D.new()
		label.text = labels[index]
		label.font_size = 15
		label.pixel_size = 0.002
		label.position.z = -0.075
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color.WHITE
		area.add_child(label)
		_quality_panel.add_child(area)
	_quality_status = Label3D.new()
	_quality_status.text = "PILIHAN: " + labels[int(_selected_quality)]
	_quality_status.font_size = 15
	_quality_status.pixel_size = 0.002
	_quality_status.position = Vector3(0, -0.43, -0.07)
	_quality_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_quality_status.modulate = Color("#c8dce8")
	_quality_panel.add_child(_quality_status)


func set_picker_visible(visible: bool) -> void:
	if is_instance_valid(_quality_panel):
		_quality_panel.visible = visible


func select_quality(index: int) -> void:
	_on_quality_selected(index)


func _quality_material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = 0.22
	return material


func _unhandled_input(event: InputEvent) -> void:
	var screen_position := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		screen_position = event.position
		pressed = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		screen_position = event.position
		pressed = true
	if not pressed:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 12.0)
	query.collision_mask = 8
	query.collide_with_areas = true
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is Area3D and collider.has_meta("graphics_quality"):
		_on_quality_selected(int(collider.get_meta("graphics_quality")))
		get_viewport().set_input_as_handled()


func _on_quality_selected(index: int) -> void:
	_selected_quality = clampi(index, int(Quality.AUTO), int(Quality.HIGH))
	_save_quality()
	apply_quality(_selected_quality)
	if is_instance_valid(_quality_status):
		var labels := ["AUTO", "HEMAT", "SEIMBANG", "TINGGI"]
		_quality_status.text = "PILIHAN: " + labels[int(_selected_quality)]
		for option in _quality_panel.get_children():
			if option is Area3D and option.has_meta("graphics_quality"):
				var face := option.get_child(1) as MeshInstance3D
				if face != null:
					face.material_override = _quality_material(Color("#b58a45") if int(option.get_meta("graphics_quality")) == int(_selected_quality) else Color("#31536a"), 0.32)


func _resolve_auto_quality() -> Quality:
	# AUTO starts with the high-fidelity profile to avoid a visibly reduced
	# first impression. Sustained low FPS still triggers PERFORMANCE fallback.
	return Quality.HIGH


func apply_quality(level: Quality) -> void:
	var resolved: Quality = _resolve_auto_quality() if level == Quality.AUTO else level
	_apply_resolved_quality(resolved)


func _apply_resolved_quality(resolved: Quality) -> void:
	_runtime_quality = resolved
	var viewport := get_viewport()

	match resolved:
		Quality.PERFORMANCE:
			viewport.scaling_3d_scale = 0.70
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			_set_scene_density(10, 4, 3)
			_set_effects(false, false)
		Quality.BALANCED:
			viewport.scaling_3d_scale = 0.90
			viewport.msaa_3d = Viewport.MSAA_2X
			_set_scene_density(22, 8, 4)
			_set_effects(true, true)
		Quality.HIGH:
			# High mode prioritizes visible scene fidelity: native render scale,
			# stronger edge smoothing, and fuller landscaping density.
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_4X
			_set_scene_density(34, 12, 5)
			_set_effects(true, true)


func _set_scene_density(trees: int, lamps: int, buildings: int) -> void:
	if environment_builder == null:
		return
	if environment_builder.has_method("apply_quality_density"):
		environment_builder.call("apply_quality_density", trees, lamps, buildings)
	else:
		environment_builder.set("tree_count", trees)
		environment_builder.set("lamp_count", lamps)
		environment_builder.set("building_count", buildings)


func _set_effects(shadows: bool, glow: bool) -> void:
	if sun != null:
		sun.shadow_enabled = shadows
	if world_environment == null or world_environment.environment == null:
		return
	world_environment.environment.glow_enabled = glow
	world_environment.environment.ssr_enabled = false
