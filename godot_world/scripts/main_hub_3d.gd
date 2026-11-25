extends Node3D
## FAMILY COLONY — first native 3D hub slice.
## This scene is intentionally isolated until authentication/session flows are
## migrated; it does not replace the current launcher scene prematurely.

signal destination_requested(destination_id: String)
signal developer_login_requested()
signal developer_authenticated(member: Dictionary, access_token: String, refresh_token: String, anon_key: String)

const FC_AUTH_URL := "https://irwtnqekrwhgompulach.supabase.co/functions/v1/fc-member-auth"

const HUB_ITEMS := [
	{"id":"profile","title":"PROFIL ANGGOTA","subtitle":"Identitas • Avatar • Koleksi","position":Vector3(-6.0,1.35,-2.0),"color":Color("#4b7891")},
	{"id":"chat","title":"ALUN-ALUN CHAT","subtitle":"Bertemu • Mengobrol • Room","position":Vector3(-2.0,1.35,-4.0),"color":Color("#397b70")},
	{"id":"games","title":"ROYAL GAME CENTER","subtitle":"Semua mini game 3D","position":Vector3(2.0,1.35,-4.0),"color":Color("#8a6334")},
	{"id":"settings","title":"PENGATURAN","subtitle":"Audio • Kontrol • Tampilan","position":Vector3(6.0,1.35,-2.0),"color":Color("#65568d")},
	{"id":"world","title":"DUNIA KOLONI","subtitle":"Jelajahi dunia bersama","position":Vector3(0.0,1.35,1.0),"color":Color("#527d43")}
]

var _camera: Camera3D
var _hint: Label3D
var _ray_length := 40.0
var _touch_start := Vector2.ZERO
var _bee_tap_count := 0
var _bee_last_tap_ms := 0
var _developer_panel: Node3D
var _developer_pin := ""
var _developer_pin_status: Label3D
var _developer_pin_display: Label3D
var _developer_auth_request: HTTPRequest
var _developer_login_busy := false


func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_central_hall()
	_build_developer_bee()
	_build_kiosks()
	_build_hud()
	_developer_auth_request = HTTPRequest.new()
	_developer_auth_request.timeout = 18.0
	_developer_auth_request.request_completed.connect(_on_developer_pin_response)
	add_child(_developer_auth_request)
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

func _build_developer_bee() -> void:
	# Five taps reveal the developer login hologram; this is not authentication.
	var bee := Area3D.new()
	bee.name = "DeveloperBeeEmblem"
	bee.position = Vector3(0, 3.15, -0.8)
	bee.input_ray_pickable = true
	bee.collision_layer = 2
	bee.collision_mask = 0
	bee.set_meta("developer_bee", true)
	var hit_shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.95
	hit_shape.shape = sphere_shape
	bee.add_child(hit_shape)
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.58
	body_mesh.height = 0.9
	body.mesh = body_mesh
	body.scale = Vector3(1.25, 0.72, 0.8)
	body.material_override = _material(Color("#e7b94f"), 0.28, 0.28)
	bee.add_child(body)
	for stripe_x in [-0.22, 0.22]:
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(0.12, 0.65, 0.72)
		stripe.mesh = stripe_mesh
		stripe.position.x = stripe_x
		stripe.material_override = _material(Color("#202b36"), 0.4, 0.12)
		bee.add_child(stripe)
	for wing_x in [-0.48, 0.48]:
		var wing := MeshInstance3D.new()
		var wing_mesh := SphereMesh.new()
		wing_mesh.radius = 0.34
		wing_mesh.height = 0.16
		wing.mesh = wing_mesh
		wing.position = Vector3(wing_x, 0.42, 0.08)
		wing.rotation_degrees.z = -24.0 if wing_x < 0.0 else 24.0
		wing.material_override = _material(Color("#c8e0e8"), 0.18, 0.12)
		bee.add_child(wing)
	var label := Label3D.new()
	label.text = "FAMILY COLONY"
	label.font_size = 18
	label.pixel_size = 0.003
	label.position.y = -0.9
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#f6dfa8")
	bee.add_child(label)
	add_child(bee)


func _register_bee_tap() -> void:
	var now := Time.get_ticks_msec()
	if now - _bee_last_tap_ms > 3500:
		_bee_tap_count = 0
	_bee_tap_count += 1
	_bee_last_tap_ms = now
	if _bee_tap_count >= 5:
		_bee_tap_count = 0
		_show_developer_hologram()
		developer_login_requested.emit()
		_hint.text = "AKSES DEVELOPER • Panel login rahasia terbuka."


func _show_developer_hologram() -> void:
	if is_instance_valid(_developer_panel):
		_developer_panel.queue_free()
	_developer_pin = ""
	_developer_login_busy = false
	_developer_panel = Node3D.new()
	_developer_panel.name = "DeveloperLoginHologram"
	_developer_panel.position = Vector3(0, 2.9, 3.0)
	var panel_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(4.8, 5.2, 0.12)
	panel_mesh.mesh = plane
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.035, 0.12, 0.19, 0.94)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.35
	glass.roughness = 0.22
	glass.emission_enabled = true
	glass.emission = Color("#287b9b")
	glass.emission_energy_multiplier = 0.35
	panel_mesh.material_override = glass
	_developer_panel.add_child(panel_mesh)
	var heading := Label3D.new()
	heading.text = "DEVELOPER ACCESS"
	heading.font_size = 44
	heading.pixel_size = 0.004
	heading.position = Vector3(0, 2.12, -0.09)
	heading.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	heading.modulate = Color("#f5d994")
	_developer_panel.add_child(heading)
	_developer_pin_display = Label3D.new()
	_developer_pin_display.text = "•  •  •  •  •  •"
	_developer_pin_display.font_size = 34
	_developer_pin_display.pixel_size = 0.004
	_developer_pin_display.position = Vector3(0, 1.48, -0.09)
	_developer_pin_display.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_developer_pin_display.modulate = Color("#e5f4ff")
	_developer_panel.add_child(_developer_pin_display)
	_developer_pin_status = Label3D.new()
	_developer_pin_status.text = "Masukkan PIN Developer 6 digit"
	_developer_pin_status.font_size = 18
	_developer_pin_status.pixel_size = 0.004
	_developer_pin_status.position = Vector3(0, 1.08, -0.09)
	_developer_pin_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_developer_pin_status.modulate = Color("#b9d7e8")
	_developer_panel.add_child(_developer_pin_status)
	var keys := [
		["1", -1.15, 0.36], ["2", 0.0, 0.36], ["3", 1.15, 0.36],
		["4", -1.15, -0.30], ["5", 0.0, -0.30], ["6", 1.15, -0.30],
		["7", -1.15, -0.96], ["8", 0.0, -0.96], ["9", 1.15, -0.96],
		["HAPUS", -1.15, -1.62], ["0", 0.0, -1.62], ["MASUK", 1.15, -1.62]
	]
	for key_data in keys:
		_create_developer_key(str(key_data[0]), Vector3(float(key_data[1]), float(key_data[2]), -0.22))
	add_child(_developer_panel)


func _create_developer_key(key_value: String, local_position: Vector3) -> void:
	var key_area := Area3D.new()
	key_area.name = "DeveloperKey_" + key_value
	key_area.position = local_position
	key_area.input_ray_pickable = true
	key_area.collision_layer = 4
	key_area.collision_mask = 0
	key_area.set_meta("developer_key", key_value)
	var hit := CollisionShape3D.new()
	var hit_shape := BoxShape3D.new()
	hit_shape.size = Vector3(0.92, 0.5, 0.32)
	hit.shape = hit_shape
	key_area.add_child(hit)
	var key_mesh := MeshInstance3D.new()
	var key_box := BoxMesh.new()
	key_box.size = Vector3(0.88, 0.46, 0.16)
	key_mesh.mesh = key_box
	key_mesh.material_override = _material(Color("#315b70") if key_value != "MASUK" else Color("#a77a36"), 0.3, 0.24)
	key_area.add_child(key_mesh)
	var label := Label3D.new()
	label.text = key_value
	label.font_size = 25 if key_value.length() <= 2 else 15
	label.pixel_size = 0.004
	label.position.z = -0.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffffff")
	key_area.add_child(label)
	_developer_panel.add_child(key_area)


func _update_developer_pin_display() -> void:
	if not is_instance_valid(_developer_pin_display):
		return
	var masked := ""
	for i in range(6):
		masked += "●  " if i < _developer_pin.length() else "○  "
	_developer_pin_display.text = masked.strip_edges()


func _handle_developer_key(key_value: String) -> void:
	if _developer_login_busy:
		return
	if key_value == "HAPUS":
		_developer_pin = _developer_pin.left(maxi(0, _developer_pin.length() - 1))
		_update_developer_pin_display()
		return
	if key_value == "MASUK":
		_submit_developer_pin()
		return
	if key_value.is_valid_int() and _developer_pin.length() < 6:
		_developer_pin += key_value
		_update_developer_pin_display()
		if _developer_pin.length() == 6 and is_instance_valid(_developer_pin_status):
			_developer_pin_status.text = "PIN lengkap • tekan MASUK untuk verifikasi"


func _submit_developer_pin() -> void:
	if _developer_pin.length() != 6:
		_developer_pin_status.text = "PIN harus tepat 6 angka."
		return
	if _developer_auth_request == null or _developer_auth_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_developer_pin_status.text = "Permintaan sebelumnya masih diproses."
		return
	var payload := JSON.stringify({"action": "developer_pin_login", "pin": _developer_pin})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var error := _developer_auth_request.request(FC_AUTH_URL, headers, HTTPClient.METHOD_POST, payload)
	if error != OK:
		_developer_pin_status.text = "Tidak dapat menghubungi server. Coba lagi."
		return
	_developer_login_busy = true
	_developer_pin_status.text = "Memverifikasi PIN melalui server aman..."


func _on_developer_pin_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_developer_login_busy = false
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or not (parsed is Dictionary):
		_developer_pin_status.text = "Koneksi gagal (" + str(response_code) + "). Periksa internet."
		return
	if parsed.get("ok") != true or not parsed.has("access_token") or not (parsed.get("member") is Dictionary):
		_developer_pin_status.text = "Akses ditolak. PIN salah atau akun belum tersedia."
		_developer_pin = ""
		_update_developer_pin_display()
		return
	var member: Dictionary = parsed.get("member", {})
	if str(member.get("role", "")).to_lower() != "developer" or str(member.get("username", "")).to_lower() != "edrick":
		_developer_pin_status.text = "Server tidak mengembalikan identitas Developer yang valid."
		_developer_pin = ""
		_update_developer_pin_display()
		return
	var access_token := str(parsed.get("access_token", ""))
	var refresh_token := str(parsed.get("refresh_token", ""))
	var anon_key := str(parsed.get("anon_key", ""))
	_developer_pin = ""
	_developer_pin_status.text = "Verifikasi berhasil • sesi Developer aktif"
	developer_authenticated.emit(member, access_token, refresh_token, anon_key)
	_hint.text = "Developer terverifikasi oleh server. Sesi siap diteruskan ke pusat aplikasi."

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
	# Diegetic information board: no CanvasLayer or flat 2D panel in the 3D hub.
	var board := Node3D.new()
	board.name = "SpatialInformationBoard"
	board.position = Vector3(-8.2, 5.2, 5.2)
	var backing := MeshInstance3D.new()
	var backing_mesh := BoxMesh.new()
	backing_mesh.size = Vector3(5.6, 1.75, 0.16)
	backing.mesh = backing_mesh
	backing.material_override = _material(Color("#14283d"), 0.32, 0.22)
	board.add_child(backing)
	var heading := Label3D.new()
	heading.text = "FAMILY COLONY  •  3D HUB"
	heading.font_size = 30
	heading.pixel_size = 0.004
	heading.position = Vector3(0, 0.43, -0.1)
	heading.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	heading.modulate = Color("#f3d99a")
	board.add_child(heading)
	_hint = Label3D.new()
	_hint.text = "Pilih bangunan 3D untuk membuka fitur."
	_hint.font_size = 20
	_hint.pixel_size = 0.004
	_hint.position = Vector3(0, -0.28, -0.1)
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.modulate = Color("#e5edf4")
	board.add_child(_hint)
	add_child(board)


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
	if collider is Area3D and collider.has_meta("developer_bee"):
		_register_bee_tap()
		return
	if collider is Area3D and collider.has_meta("developer_key"):
		_handle_developer_key(str(collider.get_meta("developer_key")))
		return
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
