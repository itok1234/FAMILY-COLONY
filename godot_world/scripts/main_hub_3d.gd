extends Node3D
## FAMILY COLONY — first native 3D hub slice.
## This scene is intentionally isolated until authentication/session flows are
## migrated; it does not replace the current launcher scene prematurely.

signal destination_requested(destination_id: String)

const HUB_ITEMS := [
	{"id":"profile","title":"PROFIL ANGGOTA","subtitle":"Identitas • Avatar • Koleksi","position":Vector3(-6.0,1.35,-2.0),"color":Color("#4b7891")},
	{"id":"chat","title":"ALUN-ALUN CHAT","subtitle":"Bertemu • Mengobrol • Room","position":Vector3(-2.0,1.35,-4.0),"color":Color("#397b70")},
	{"id":"games","title":"ROYAL GAME CENTER","subtitle":"Semua mini game 3D","position":Vector3(2.0,1.35,-4.0),"color":Color("#8a6334")},
	{"id":"settings","title":"PENGATURAN","subtitle":"Audio • Kontrol • Tampilan","position":Vector3(6.0,1.35,-2.0),"color":Color("#65568d")},
	{"id":"world","title":"DUNIA KOLONI","subtitle":"Jelajahi dunia bersama","position":Vector3(0.0,1.35,1.0),"color":Color("#527d43")}
]

var _camera: Camera3D
var _hint: Label
var _ray_length := 40.0
var _touch_start := Vector2.ZERO


func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_central_hall()
	_build_kiosks()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#172d49")
	sky_material.sky_horizon_color = Color("#a9bdc8")
	sky_material.ground_bottom_color = Color("#172331")
	sky_material.ground_horizon_color = Color("#657c82")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c7d8e5")
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(42, 42)
	ground.mesh = ground_mesh
	ground.material_override = _material(Color("#243a3d"), 0.92)
	add_child(ground)

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 15.5
	base_mesh.bottom_radius = 16.0
	base_mesh.height = 0.32
	base.mesh = base_mesh
	base.position.y = -0.18
	base.material_override = _material(Color("#344b52"), 0.75)
	add_child(base)

	for i in range(24):
		var angle := TAU * float(i) / 24.0
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.16
		pillar_mesh.bottom_radius = 0.24
		pillar_mesh.height = 2.8
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 13.5, 1.4, sin(angle) * 13.5)
		pillar.material_override = _material(Color("#8da2a0"), 0.65)
		add_child(pillar)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "HubCamera"
	_camera.position = Vector3(0, 11.5, 19.0)
	_camera.fov = 58.0
	add_child(_camera)
	_camera.look_at(Vector3(0, 1.0, -1.0), Vector3.UP)
	_camera.current = true


func _build_central_hall() -> void:
	var platform := MeshInstance3D.new()
	var platform_mesh := CylinderMesh.new()
	platform_mesh.top_radius = 3.3
	platform_mesh.bottom_radius = 3.6
	platform_mesh.height = 0.55
	platform.mesh = platform_mesh
	platform.position = Vector3(0, 0.15, -0.8)
	platform.material_override = _material(Color("#b58a45"), 0.42, 0.18)
	add_child(platform)

	var emblem := Label3D.new()
	emblem.text = "FAMILY\nCOLONY"
	emblem.font_size = 72
	emblem.pixel_size = 0.004
	emblem.position = Vector3(0, 2.15, -0.8)
	emblem.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	emblem.modulate = Color("#f3d99a")
	emblem.outline_size = 10
	emblem.outline_modulate = Color("#142235")
	add_child(emblem)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 2.6
	ring_mesh.outer_radius = 2.78
	ring.mesh = ring_mesh
	ring.position = Vector3(0, 0.55, -0.8)
	ring.rotation_degrees.x = 90
	ring.material_override = _material(Color("#e3bd70"), 0.3, 0.3)
	add_child(ring)


func _build_kiosks() -> void:
	for item in HUB_ITEMS:
		_create_kiosk(item)


func _create_kiosk(item: Dictionary) -> void:
	var root := Area3D.new()
	root.name = "Kiosk_" + str(item.id)
	root.position = item.position
	root.set_meta("destination_id", str(item.id))
	root.input_ray_pickable = true
	root.collision_layer = 2
	root.collision_mask = 0

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.1, 2.5, 0.65)
	collision.shape = shape
	collision.position.y = 0.95
	root.add_child(collision)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(3.1, 2.5, 0.48)
	body.mesh = body_mesh
	body.position.y = 0.95
	body.material_override = _material(item.color, 0.48, 0.08)
	root.add_child(body)

	var trim := MeshInstance3D.new()
	var trim_mesh := BoxMesh.new()
	trim_mesh.size = Vector3(3.18, 0.09, 0.56)
	trim.mesh = trim_mesh
	trim.position.y = 2.18
	trim.material_override = _material(Color("#e5c27b"), 0.28, 0.32)
	root.add_child(trim)

	var title := Label3D.new()
	title.text = str(item.title)
	title.font_size =  thirty_two()
	title.pixel_size = 0.0035
	title.position = Vector3(0, 1.22, -0.27)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color("#fff1cc")
	title.outline_size = 8
	title.outline_modulate = Color("#17263a")
	root.add_child(title)

	var subtitle := Label3D.new()
	subtitle.text = str(item.subtitle)
	subtitle.font_size =  twenty()
	subtitle.pixel_size = 0.003
	subtitle.position = Vector3(0, 0.72, -0.28)
	subtitle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	subtitle.modulate = Color("#e0e8ed")
	subtitle.outline_size = 6
	subtitle.outline_modulate = Color("#17263a")
	root.add_child(subtitle)

	var marker := MeshInstance3D.new()
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.18
	marker_mesh.height = 0.36
	marker.mesh = marker_mesh
	marker.position = Vector3(0, 1.88, -0.31)
	marker.material_override = _material(Color("#f2d38b"), 0.22, 0.45)
	root.add_child(marker)

	add_child(root)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Accessible3DControls"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.025
	panel.anchor_top = 0.025
	panel.anchor_right = 0.43
	panel.anchor_bottom = 0.14
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "FAMILY COLONY  •  3D HUB"
	heading.add_theme_font_size_override("font_size", 18)
	column.add_child(heading)
	_hint = Label.new()
	_hint.text = "Pilih salah satu bangunan 3D untuk membuka fitur."
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_hint)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_pick_destination(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_destination(event.position)


func _pick_destination(screen_position: Vector2) -> void:
	if _camera == null:
		return
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * _ray_length)
	query.collide_with_areas = true
	query.collision_mask = 2
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is Area3D and collider.has_meta("destination_id"):
		var destination := str(collider.get_meta("destination_id"))
		_hint.text = "Dipilih: " + destination.to_upper() + " • integrasi fitur sedang dimigrasikan."
		destination_requested.emit(destination)


func _material(color: Color, roughness: float = 0.65, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func thirty_two() -> int:
	return 32


func twenty() -> int:
	return 20
