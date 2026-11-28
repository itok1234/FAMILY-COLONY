extends Node3D
## FAMILY COLONY — native spatial 3D member hub.
## Instantiated by world_controller after Supabase session verification.
## Art is currently procedural blockout geometry; production asset integration remains.

signal destination_requested(destination_id: String)
signal developer_login_requested()
signal developer_authenticated(member: Dictionary, access_token: String, anon_key: String)
signal minigame_requested(game_id: String)
signal developer_center_action_requested(action_id: String)
signal settings_action_requested(action_id: String)
signal room_action_requested(action_id: String)
signal avatar_appearance_changed(appearance: Dictionary)

const FC_AUTH_URL := "https://irwtnqekrwhgompulach.supabase.co/functions/v1/fc-member-auth"
const FINAL_MINIGAMES := ["guess_who", "royal_bomb", "royal_murder_mystery", "royal_dice"]

const HUB_ITEMS := [
	{"id":"profile","title":"PROFIL ANGGOTA","subtitle":"Identitas • Avatar • Koleksi","position":Vector3(-6.0,1.35,-2.0),"color":Color("#4b7891")},
	{"id":"chat","title":"ALUN-ALUN CHAT","subtitle":"Bertemu • Mengobrol • Room","position":Vector3(-2.0,1.35,-4.0),"color":Color("#397b70")},
	{"id":"games","title":"ROYAL GAME CENTER","subtitle":"Semua mini game 3D","position":Vector3(2.0,1.35,-4.0),"color":Color("#8a6334")},
	{"id":"settings","title":"PENGATURAN","subtitle":"Audio • Kontrol • Tampilan","position":Vector3(6.0,1.35,-2.0),"color":Color("#65568d")},
	{"id":"world","title":"DUNIA KOLONI","subtitle":"Jelajahi dunia bersama","position":Vector3(0.0,1.35,1.0),"color":Color("#527d43")}
]

var _hub_orbit_yaw := 0.0
var _hub_orbit_pitch := 0.42
var _hub_orbit_distance := 22.0
var _hub_drag_last := Vector2.ZERO
var _hub_drag_active := false
var _camera: Camera3D
var _animated_shrubs: Array[MeshInstance3D] = []
var _animated_lamp_lights: Array[OmniLight3D] = []
var _animated_station_badges: Array[MeshInstance3D] = []
var _animated_station_portal_rings: Array[MeshInstance3D] = []
var _animated_station_lights: Array[OmniLight3D] = []
var _animated_beacon_halos: Array[MeshInstance3D] = []
var _animated_beacon_light: OmniLight3D
var _hint: Label3D
var _member_board_label: Label3D
var _ray_length := 40.0
var _touch_start := Vector2.ZERO
var _tap_candidate := false
var _bee_tap_count := 0
var _bee_last_tap_ms := 0
var _developer_panel: Node3D
var _developer_pin := ""
var _developer_pin_status: Label3D
var _developer_pin_display: Label3D
var _developer_auth_request: HTTPRequest
var _developer_login_busy := false
var _destination_panel: Node3D
var _panel_title: Label3D
var _panel_body: Label3D
var _member_profile: Dictionary = {}
var _room_snapshot_root: Node3D
var _room_snapshot_data: Array = []
var _room_snapshot_page: int = 0
const ROOM_SNAPSHOT_PAGE_SIZE: int = 2
var _room_status_label: Label3D
var _room_connection_detail := "Belum terhubung ke jaringan LAN."
var _room_lan_state := "offline"
var _room_current_id := ""
var _room_current_members: Array[int] = []
var _cloud_matchmaking_state := "BELUM DIMINTA"
var _cloud_matchmaking_detail := "Server cloud belum diperiksa."
var _profile_avatar_body: MeshInstance3D
var _profile_avatar_halo: MeshInstance3D
var _profile_style_index := 0
const PROFILE_STYLES := [
	{"name":"OCEAN","body":Color("#456d83"),"halo":Color("#9bd4e4")},
	{"name":"EMERALD","body":Color("#397b70"),"halo":Color("#a7dfbd")},
	{"name":"ROYAL","body":Color("#65568d"),"halo":Color("#c6b1f0")},
	{"name":"GOLD","body":Color("#92713d"),"halo":Color("#f0d18b")},
	{"name":"SLATE","body":Color("#596674"),"halo":Color("#c4d0dc")}
]


func set_member_profile(member: Dictionary) -> void:
	# Identity comes only from the verified world-session response.
	_member_profile = member.duplicate(true)
	_refresh_member_board()


func _process(delta: float) -> void:
	# Low-cost ambience: rotating/pulsing beacon and gentle garden breeze.
	var elapsed := float(Time.get_ticks_msec()) / 1000.0
	for index in range(_animated_beacon_halos.size()):
		var halo := _animated_beacon_halos[index]
		halo.rotation_degrees.y += delta * (12.0 + index * 7.0) * (1.0 if index % 2 == 0 else -1.0)
		halo.scale = Vector3.ONE * (1.0 + sin(elapsed * 1.3 + index) * 0.035)
	if is_instance_valid(_animated_beacon_light):
		_animated_beacon_light.light_energy = 0.58 + sin(elapsed * 1.4) * 0.08
	for shrub_index in range(_animated_shrubs.size()):
		var shrub := _animated_shrubs[shrub_index]
		shrub.rotation.z = sin(elapsed * 0.7 + shrub_index * 0.8) * 0.025
		shrub.rotation.x = cos(elapsed * 0.6 + shrub_index * 0.6) * 0.018
	for lamp_index in range(_animated_lamp_lights.size()):
		var lamp_light := _animated_lamp_lights[lamp_index]
		lamp_light.light_energy = 0.24 + sin(elapsed * 1.8 + lamp_index * 0.5) * 0.025
	for station_index in range(_animated_station_badges.size()):
		var badge := _animated_station_badges[station_index]
		badge.rotation_degrees.y += delta * (18.0 + station_index * 3.0)
		badge.scale = Vector3.ONE * (1.0 + sin(elapsed * 1.25 + station_index) * 0.045)
	for portal_index in range(_animated_station_portal_rings.size()):
		var portal := _animated_station_portal_rings[portal_index]
		portal.rotation_degrees.y += delta * (9.0 if portal_index % 2 == 0 else -9.0)
		portal.scale = Vector3.ONE * (1.0 + sin(elapsed * 1.1 + portal_index) * 0.025)
	for station_index in range(_animated_station_lights.size()):
		var station_light := _animated_station_lights[station_index]
		station_light.light_energy = 0.42 + sin(elapsed * 1.5 + station_index * 0.7) * 0.05


func _cache_animated_nodes() -> void:
	# Resolve node references once after hub construction instead of repeated
	# string-based scene lookups each frame; keeps the mobile hub loop lean.
	_animated_shrubs.clear()
	_animated_lamp_lights.clear()
	_animated_station_badges.clear()
	_animated_station_portal_rings.clear()
	_animated_station_lights.clear()
	_animated_beacon_halos.clear()
	_animated_beacon_light = null
	var beacon := get_node_or_null("PlazaBeacon")
	if beacon != null:
		for index in range(3):
			var halo := beacon.get_node_or_null("BeaconHalo_%d" % index) as MeshInstance3D
			if halo != null:
				_animated_beacon_halos.append(halo)
		_animated_beacon_light = beacon.get_node_or_null("BeaconAccentLight") as OmniLight3D
	for shrub_index in range(16):
		var shrub := get_node_or_null("PlazaShrub_%02d" % shrub_index) as MeshInstance3D
		if shrub != null:
			_animated_shrubs.append(shrub)
	for lamp_index in range(8):
		var lamp := get_node_or_null("PlazaLamp_%02d" % lamp_index)
		if lamp != null:
			var light := lamp.get_node_or_null("PlazaLampLight_%02d" % lamp_index) as OmniLight3D
			if light != null:
				_animated_lamp_lights.append(light)
	for item in HUB_ITEMS:
		var station := get_node_or_null("Kiosk_" + str(item.id))
		if station == null:
			continue
		var badge := station.get_node_or_null("StationBadgeRing") as MeshInstance3D
		var portal := station.get_node_or_null("StationPortalRing") as MeshInstance3D
		var light := station.get_node_or_null("StationAccentLight") as OmniLight3D
		if badge != null:
			_animated_station_badges.append(badge)
		if portal != null:
			_animated_station_portal_rings.append(portal)
		if light != null:
			_animated_station_lights.append(light)


func _ready() -> void:
	_build_environment()
	_build_visual_landmark_layer()
	_build_plaza_path_composition()
	_build_hub_focal_lighting()
	_build_distant_colony_silhouette()
	_build_plaza_wayfinding()
	_build_feature_approach_lanes()
	_build_camera()
	_build_central_hall()
	_build_developer_bee()
	_build_kiosks()
	_build_hud()
	_cache_animated_nodes()
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

	# Home-hub benchmark: circular plaza, inset paths and stylized garden landmarks.
	var plaza := MeshInstance3D.new()
	var plaza_mesh := CylinderMesh.new()
	plaza_mesh.top_radius = 10.2
	plaza_mesh.bottom_radius = 10.5
	plaza_mesh.height = 0.22
	plaza.mesh = plaza_mesh
	plaza.position.y = 0.02
	plaza.material_override = _material(Color("#526a68"), 0.78, 0.12)
	add_child(plaza)
	for ring_radius in [5.2, 9.2]:
		var path_ring := MeshInstance3D.new()
		var path_mesh := TorusMesh.new()
		path_mesh.inner_radius = ring_radius - 0.16
		path_mesh.outer_radius = ring_radius + 0.16
		path_ring.mesh = path_mesh
		path_ring.rotation_degrees.x = 90.0
		path_ring.position.y = 0.18
		path_ring.material_override = _material(Color("#d5b879"), 0.52, 0.22)
		add_child(path_ring)
	# Twelve radial inlays connect the central plaza to the outer garden ring.
	for spoke_index in range(12):
		var spoke_angle := TAU * float(spoke_index) / 12.0
		var spoke := MeshInstance3D.new()
		var spoke_mesh := BoxMesh.new()
		spoke_mesh.size = Vector3(0.12, 0.035, 4.0)
		spoke.mesh = spoke_mesh
		spoke.position = Vector3(cos(spoke_angle) * 7.15, 0.16, sin(spoke_angle) * 7.15)
		spoke.rotation.y = -spoke_angle
		spoke.material_override = _material(Color("#b7c6bd"), 0.58, 0.16)
		spoke.name = "PlazaRadialInlay_%02d" % spoke_index
		add_child(spoke)
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var planter := MeshInstance3D.new()
		var planter_mesh := CylinderMesh.new()
		planter_mesh.top_radius = 0.68
		planter_mesh.bottom_radius = 0.82
		planter_mesh.height = 0.42
		planter.mesh = planter_mesh
		planter.position = Vector3(cos(angle) * 11.2, 0.2, sin(angle) * 11.2)
		planter.material_override = _material(Color("#334b50"), 0.75, 0.16)
		add_child(planter)
		var shrub := MeshInstance3D.new()
		var shrub_mesh := SphereMesh.new()
		shrub_mesh.radius = 0.62
		shrub_mesh.height = 1.12
		shrub.mesh = shrub_mesh
		shrub.position = planter.position + Vector3(0, 0.74, 0)
		shrub.material_override = _material(Color("#52866b"), 0.88, 0.04)
		shrub.name = "PlazaShrub_%02d" % i
		add_child(shrub)
	_build_garden_trees()
	_build_outer_garden_composition()
	# Decorative lamp posts establish a recognizable spatial home plaza.
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var lamp := Node3D.new()
		lamp.name = "PlazaLamp_%02d" % i
		lamp.position = Vector3(cos(angle) * 7.6, 0.0, sin(angle) * 7.6)
		add_child(lamp)
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.09
		post_mesh.bottom_radius = 0.13
		post_mesh.height = 2.8
		post.mesh = post_mesh
		post.position.y = 1.4
		post.material_override = _material(Color("#c9ad70"), 0.35, 0.42)
		lamp.add_child(post)
		var lantern := MeshInstance3D.new()
		var lantern_mesh := SphereMesh.new()
		lantern_mesh.radius = 0.28
		lantern_mesh.height = 0.42
		lantern.mesh = lantern_mesh
		lantern.position.y = 2.85
		var lantern_mat := _material(Color("#f3d99a"), 0.2, 0.48)
		lantern_mat.emission_enabled = true
		lantern_mat.emission = Color("#f3d99a")
		lantern_mat.emission_energy_multiplier = 1.2
		lantern.material_override = lantern_mat
		lamp.add_child(lantern)
		var light := OmniLight3D.new()
		light.position.y = 2.8
		light.light_color = Color("#f3d99a")
		light.name = "PlazaLampLight_%02d" % i
		light.light_energy = 0.28
		light.omni_range = 4.0
		lamp.add_child(light)


func _build_visual_landmark_layer() -> void:
	# Art pass: layered entrance arches, reflective trim and sculpted wayfinding.
	# These are production-facing visual additions, not benchmark/test geometry.
	for arch_index in range(5):
		var angle := TAU * float(arch_index) / 5.0
		var arch_root := Node3D.new()
		arch_root.name = "LandmarkArch_%02d" % arch_index
		arch_root.position = Vector3(cos(angle) * 8.35, 0.0, sin(angle) * 8.35)
		arch_root.rotation.y = -angle + PI * 0.5
		add_child(arch_root)
		var stone_color := Color("#536d78") if arch_index % 2 == 0 else Color("#49665f")
		for side in [-1.0, 1.0]:
			var column := MeshInstance3D.new()
			var column_mesh := CylinderMesh.new()
			column_mesh.top_radius = 0.18
			column_mesh.bottom_radius = 0.24
			column_mesh.height = 2.75
			column.mesh = column_mesh
			column.position = Vector3(side * 1.05, 1.38, 0.0)
			column.material_override = _material(stone_color, 0.62, 0.12)
			arch_root.add_child(column)
			var capital := MeshInstance3D.new()
			var capital_mesh := BoxMesh.new()
			capital_mesh.size = Vector3(0.55, 0.16, 0.42)
			capital.mesh = capital_mesh
			capital.position = Vector3(side * 1.05, 2.82, 0.0)
			capital.material_override = _material(Color("#d5b879"), 0.38, 0.22)
			arch_root.add_child(capital)
		var lintel := MeshInstance3D.new()
		var lintel_mesh := BoxMesh.new()
		lintel_mesh.size = Vector3(2.5, 0.24, 0.34)
		lintel.mesh = lintel_mesh
		lintel.position.y = 2.92
		lintel.material_override = _material(Color("#d5b879"), 0.34, 0.28)
		arch_root.add_child(lintel)
		var crest := MeshInstance3D.new()
		var crest_mesh := SphereMesh.new()
		crest_mesh.radius = 0.28
		crest_mesh.height = 0.38
		crest.mesh = crest_mesh
		crest.position = Vector3(0.0, 3.25, 0.0)
		var crest_material := _material(Color("#e6bd70"), 0.28, 0.22)
		crest_material.emission_enabled = true
		crest_material.emission = Color("#e6bd70")
		crest_material.emission_energy_multiplier = 0.22
		crest.material_override = crest_material
		arch_root.add_child(crest)
	# Small raised stepping stones soften the plaza's straight radial inlays.
	for stone_index in range(24):
		var angle := TAU * float(stone_index) / 24.0
		var stone := MeshInstance3D.new()
		var stone_mesh := CylinderMesh.new()
		stone_mesh.top_radius = 0.24
		stone_mesh.bottom_radius = 0.27
		stone_mesh.height = 0.09
		stone.mesh = stone_mesh
		stone.position = Vector3(cos(angle) * 9.8, 0.14, sin(angle) * 9.8)
		stone.material_override = _material(Color("#b7c6bd"), 0.7, 0.06)
		add_child(stone)


func _build_outer_garden_composition() -> void:
	# Sculpted garden edge, low layered beds and curved walkways frame the plaza.
	for bed_index in range(12):
		var angle := TAU * float(bed_index) / 12.0
		var bed_root := Node3D.new()
		bed_root.name = "GardenBed_%02d" % bed_index
		bed_root.position = Vector3(cos(angle) * 13.15, 0.0, sin(angle) * 13.15)
		bed_root.rotation.y = angle
		add_child(bed_root)
		var bed := MeshInstance3D.new()
		var bed_mesh := CylinderMesh.new()
		bed_mesh.top_radius = 1.25
		bed_mesh.bottom_radius = 1.38
		bed_mesh.height = 0.24
		bed.mesh = bed_mesh
		bed.position.y = 0.12
		bed.material_override = _material(Color("#344e4b"), 0.92, 0.0)
		bed_root.add_child(bed)
		for bloom_index in range(5):
			var bloom_angle := TAU * float(bloom_index) / 5.0
			var bloom := MeshInstance3D.new()
			var bloom_mesh := SphereMesh.new()
			bloom_mesh.radius = 0.17
			bloom_mesh.height = 0.28
			bloom.mesh = bloom_mesh
			bloom.position = Vector3(cos(bloom_angle) * 0.72, 0.42, sin(bloom_angle) * 0.72)
			bloom.material_override = _material(Color("#c9bfa7") if bloom_index % 2 == 0 else Color("#87b9ad"), 0.78, 0.0)
			bed_root.add_child(bloom)
	# Outer paving segments and subtle border markers reinforce navigable scale.
	for tile_index in range(32):
		var angle := TAU * float(tile_index) / 32.0
		var tile := MeshInstance3D.new()
		var tile_mesh := BoxMesh.new()
		tile_mesh.size = Vector3(1.35, 0.08, 0.34)
		tile.mesh = tile_mesh
		tile.position = Vector3(cos(angle) * 15.1, 0.03, sin(angle) * 15.1)
		tile.rotation.y = -angle
		tile.material_override = _material(Color("#91a6a4") if tile_index % 2 == 0 else Color("#536d78"), 0.68, 0.08)
		add_child(tile)
	for marker_index in range(8):
		var angle := TAU * float(marker_index) / 8.0 + PI / 8.0
		var marker := MeshInstance3D.new()
		var marker_mesh := CylinderMesh.new()
		marker_mesh.top_radius = 0.16
		marker_mesh.bottom_radius = 0.24
		marker_mesh.height = 0.62
		marker.mesh = marker_mesh
		marker.position = Vector3(cos(angle) * 14.0, 0.31, sin(angle) * 14.0)
		marker.material_override = _material(Color("#d5b879"), 0.38, 0.24)
		add_child(marker)


func _build_garden_trees() -> void:
	# Lightweight layered ornamental trees: silhouettes and leaf volumes improve
	# the plaza's scale/depth without relying on external assets or heavy shaders.
	for tree_index in range(10):
		var angle := TAU * float(tree_index) / 10.0
		var tree_root := Node3D.new()
		tree_root.name = "PlazaTree_%02d" % tree_index
		tree_root.position = Vector3(cos(angle) * 12.35, 0.0, sin(angle) * 12.35)
		tree_root.rotation.y = angle
		add_child(tree_root)
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.18
		trunk_mesh.bottom_radius = 0.28
		trunk_mesh.height = 2.35
		trunk.mesh = trunk_mesh
		trunk.position.y = 1.18
		trunk.material_override = _material(Color("#71513a"), 0.88, 0.0)
		tree_root.add_child(trunk)
		for crown_index in range(3):
			var crown := MeshInstance3D.new()
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 1.0 - crown_index * 0.12
			crown_mesh.height = 1.65 - crown_index * 0.12
			crown.mesh = crown_mesh
			crown.position = Vector3(0.0, 2.25 + crown_index * 0.72, 0.0)
			crown.material_override = _material(Color("#4f896c") if crown_index != 1 else Color("#629a79"), 0.92, 0.0)
			tree_root.add_child(crown)
		var accent := MeshInstance3D.new()
		var accent_mesh := SphereMesh.new()
		accent_mesh.radius = 0.13
		accent_mesh.height = 0.18
		accent.mesh = accent_mesh
		accent.position = Vector3(0.32, 3.55, 0.16)
		var accent_material := _material(Color("#d5b879"), 0.4, 0.08)
		accent_material.emission_enabled = true
		accent_material.emission = Color("#d5b879")
		accent_material.emission_energy_multiplier = 0.25
		accent.material_override = accent_material
		tree_root.add_child(accent)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "HubCamera"
	_camera.fov = 58.0
	add_child(_camera)
	_camera.current = true
	_update_hub_camera_framing()
	get_viewport().size_changed.connect(_update_hub_camera_framing)


func _update_hub_camera_framing() -> void:
	if not is_instance_valid(_camera):
		return
	# Landscape/portrait framing is responsive; orbit values remain user-adjustable.
	var viewport_size := get_viewport().get_visible_rect().size
	var is_portrait := viewport_size.x < viewport_size.y
	_camera.fov = 68.0 if is_portrait else 56.0
	_hub_orbit_distance = clampf(_hub_orbit_distance, 14.0, 30.0)
	_hub_orbit_pitch = clampf(_hub_orbit_pitch, 0.22, 0.72)
	var target := Vector3(0.0, 1.1, -1.0)
	var horizontal := _hub_orbit_distance * cos(_hub_orbit_pitch)
	_camera.position = target + Vector3(sin(_hub_orbit_yaw) * horizontal, _hub_orbit_distance * sin(_hub_orbit_pitch), cos(_hub_orbit_yaw) * horizontal)
	_camera.look_at(target, Vector3.UP)


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

	# Add a stepped dais and fine concentric trim to give the hall a grounded silhouette.
	for tier_index in range(2):
		var tier := MeshInstance3D.new()
		var tier_mesh := CylinderMesh.new()
		tier_mesh.top_radius = 3.55 + tier_index * 0.22
		tier_mesh.bottom_radius = 3.72 + tier_index * 0.22
		tier_mesh.height = 0.16
		tier.mesh = tier_mesh
		tier.position = Vector3(0.0, -0.16 - tier_index * 0.12, -0.8)
		tier.material_override = _material(Color("#526a68") if tier_index == 0 else Color("#d5b879"), 0.48, 0.2)
		add_child(tier)
	var hall_trim := MeshInstance3D.new()
	var hall_trim_mesh := TorusMesh.new()
	hall_trim_mesh.inner_radius = 2.9
	hall_trim_mesh.outer_radius = 3.02
	hall_trim.mesh = hall_trim_mesh
	hall_trim.rotation_degrees.x = 90.0
	hall_trim.position = Vector3(0.0, 0.46, -0.8)
	hall_trim.material_override = _material(Color("#e6bd70"), 0.3, 0.42)
	add_child(hall_trim)

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

	# Additional low-cost architectural accents give the central landmark depth
	# and a clearer premium plaza silhouette without imported asset dependencies.
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var accent := MeshInstance3D.new()
		var accent_mesh := BoxMesh.new()
		accent_mesh.size = Vector3(0.18, 0.12, 1.25)
		accent.mesh = accent_mesh
		accent.position = Vector3(cos(angle) * 4.35, 0.18, sin(angle) * 4.35 - 0.8)
		accent.rotation.y = -angle
		accent.material_override = _material(Color("#d5b879"), 0.42, 0.24)
		add_child(accent)
	var beacon := Node3D.new()
	beacon.name = "PlazaBeacon"
	beacon.position = Vector3(0.0, 0.55, -0.8)
	add_child(beacon)
	var beacon_core := MeshInstance3D.new()
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.18
	core_mesh.bottom_radius = 0.32
	core_mesh.height = 1.35
	beacon_core.mesh = core_mesh
	beacon_core.material_override = _material(Color("#e5c477"), 0.32, 0.38)
	beacon.add_child(beacon_core)
	var beacon_cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.36
	cap_mesh.height = 0.48
	beacon_cap.mesh = cap_mesh
	beacon_cap.position.y = 0.84
	var cap_mat := _material(Color("#f3d99a"), 0.24, 0.18)
	cap_mat.emission_enabled = true
	cap_mat.emission = Color("#e6bd70")
	cap_mat.emission_energy_multiplier = 0.65
	beacon_cap.material_override = cap_mat
	beacon.add_child(beacon_cap)

	# Layered halo rings and light volume make the central beacon read as a landmark.
	for ring_index in range(3):
		var halo := MeshInstance3D.new()
		halo.name = "BeaconHalo_%d" % ring_index
		var halo_mesh := TorusMesh.new()
		halo_mesh.inner_radius = 0.62 + ring_index * 0.22
		halo_mesh.outer_radius = 0.68 + ring_index * 0.22
		halo.mesh = halo_mesh
		halo.position.y = 0.28 + ring_index * 0.36
		halo.rotation_degrees.x = 90.0
		halo.material_override = _material(Color("#e6bd70") if ring_index == 0 else Color("#8bc8e4"), 0.22, 0.48)
		beacon.add_child(halo)
	var beacon_light := OmniLight3D.new()
	beacon_light.name = "BeaconAccentLight"
	beacon_light.position.y = 1.15
	beacon_light.light_color = Color("#e6bd70")
	beacon_light.light_energy = 0.65
	beacon_light.omni_range = 5.5
	beacon_light.shadow_enabled = false
	beacon.add_child(beacon_light)

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
	var anon_key := str(parsed.get("anon_key", ""))
	_developer_pin = ""
	_developer_pin_status.text = "Verifikasi berhasil • sesi Developer aktif"
	developer_authenticated.emit(member, access_token, anon_key)
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
	# Broad, forgiving interaction volume for touch-first navigation; it spans
	# the doorway frame without forcing precise taps on a phone screen.
	shape.size = Vector3(3.55, 2.85, 1.05)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.15, 0.0)
	root.add_child(collision)

	# Portal-style station frame: recognizable spatial doorway instead of flat UI slab.
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.65, 2.05, 0.24)
	body.mesh = body_mesh
	body.position.y = 1.18
	body.material_override = _material(item.color.darkened(0.12), 0.42, 0.18)
	root.add_child(body)
	var portal_ring := MeshInstance3D.new()
	var portal_mesh := TorusMesh.new()
	portal_mesh.inner_radius = 1.18
	portal_mesh.outer_radius = 1.34
	portal_ring.name = "StationPortalRing"
	portal_ring.mesh = portal_mesh
	portal_ring.position = Vector3(0, 1.18, -0.18)
	portal_ring.rotation_degrees.x = 90.0
	portal_ring.scale = Vector3(1.12, 1.12, 1.12)
	portal_ring.material_override = _material(item.color.lightened(0.42), 0.28, 0.42)
	root.add_child(portal_ring)

	var trim := MeshInstance3D.new()
	var trim_mesh := BoxMesh.new()
	trim_mesh.size = Vector3(3.18, 0.09, 0.56)
	trim.mesh = trim_mesh
	trim.position.y = 2.18
	trim.material_override = _material(Color("#e5c27b"), 0.28, 0.32)
	root.add_child(trim)

	# Layered stone-and-brass plinth gives every feature station a grounded,
	# readable silhouette instead of a floating rectangular menu block.
	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 1.78
	pedestal_mesh.bottom_radius = 1.92
	pedestal_mesh.height = 0.34
	pedestal.mesh = pedestal_mesh
	pedestal.position.y = -0.48
	pedestal.material_override = _material(Color("#263b49"), 0.62, 0.28)
	root.add_child(pedestal)

	var pedestal_rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 1.68
	rim_mesh.outer_radius = 1.78
	pedestal_rim.mesh = rim_mesh
	pedestal_rim.rotation_degrees.x = 90.0
	pedestal_rim.position.y = -0.28
	pedestal_rim.material_override = _material(Color("#d7b36c"), 0.3, 0.5)
	root.add_child(pedestal_rim)

	var station_light := OmniLight3D.new()
	station_light.name = "StationAccentLight"
	station_light.position = Vector3(0, 2.85, 0.0)
	station_light.light_color = item.color.lightened(0.35)
	station_light.light_energy = 0.48
	station_light.omni_range = 5.5
	station_light.shadow_enabled = false
	root.add_child(station_light)

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
	marker.scale = Vector3(1.18, 1.18, 1.18)
	var marker_material := _material(Color("#f2d38b"), 0.22, 0.45)
	marker_material.emission_enabled = true
	marker_material.emission = Color("#f2d38b")
	marker_material.emission_energy_multiplier = 0.7
	marker.material_override = marker_material
	root.add_child(marker)

	# Small luminous badge ring gives each station a clearer focal point.
	var badge_ring := MeshInstance3D.new()
	var badge_ring_mesh := TorusMesh.new()
	badge_ring_mesh.inner_radius = 0.24
	badge_ring_mesh.outer_radius = 0.31
	badge_ring.name = "StationBadgeRing"
	badge_ring.mesh = badge_ring_mesh
	badge_ring.position = Vector3(0, 1.88, -0.34)
	badge_ring.rotation_degrees.x = 90.0
	var badge_ring_material := _material(item.color.lightened(0.48), 0.24, 0.42)
	badge_ring_material.emission_enabled = true
	badge_ring_material.emission = item.color.lightened(0.38)
	badge_ring_material.emission_energy_multiplier = 0.65
	badge_ring.material_override = badge_ring_material
	root.add_child(badge_ring)

	# Slim side columns and inset face strips add depth while keeping the
	# title and touch target unobstructed on phone-sized screens.
	for side_x in [-1.42, 1.42]:
		var side_trim := MeshInstance3D.new()
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.055, 1.92, 0.06)
		side_trim.mesh = side_mesh
		side_trim.position = Vector3(side_x, 0.95, -0.255)
		side_trim.material_override = _material(Color("#d6b16c"), 0.32, 0.42)
		root.add_child(side_trim)

	# New visual pass: sculpted station shoulders, inset jewel and floor approach.
	for side in [-1.0, 1.0]:
		var shoulder := MeshInstance3D.new()
		var shoulder_mesh := BoxMesh.new()
		shoulder_mesh.size = Vector3(0.42, 2.18, 0.38)
		shoulder.mesh = shoulder_mesh
		shoulder.position = Vector3(side * 1.58, 1.12, 0.02)
		shoulder.material_override = _material(item.color.darkened(0.32), 0.48, 0.24)
		root.add_child(shoulder)
		var shoulder_cap := MeshInstance3D.new()
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = Vector3(0.5, 0.12, 0.46)
		shoulder_cap.mesh = cap_mesh
		shoulder_cap.position = Vector3(side * 1.58, 2.25, 0.02)
		shoulder_cap.material_override = _material(Color("#d5b879"), 0.32, 0.34)
		root.add_child(shoulder_cap)
	# Floating jewel-like station crest, emissive but inexpensive on mobile.
	var crest := MeshInstance3D.new()
	var crest_mesh := SphereMesh.new()
	crest_mesh.radius = 0.23
	crest_mesh.height = 0.42
	crest.mesh = crest_mesh
	crest.position = Vector3(0, 2.52, -0.06)
	crest.scale = Vector3(1.0, 1.35, 0.72)
	var crest_mat := _material(item.color.lightened(0.48), 0.22, 0.36)
	crest_mat.emission_enabled = true
	crest_mat.emission = item.color.lightened(0.3)
	crest_mat.emission_energy_multiplier = 0.45
	crest.material_override = crest_mat
	root.add_child(crest)
	# Three shallow approach slabs visibly anchor each kiosk into the plaza.
	for step_index in range(3):
		var step := MeshInstance3D.new()
		var step_mesh := BoxMesh.new()
		step_mesh.size = Vector3(2.5 - step_index * 0.18, 0.12, 0.46)
		step.mesh = step_mesh
		step.position = Vector3(0, -0.31 - step_index * 0.08, 0.55 + step_index * 0.34)
		step.material_override = _material(Color("#415b68"), 0.58, 0.16)
		root.add_child(step)

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
	_member_board_label = Label3D.new()
	_member_board_label.name = "MemberWelcomeLabel"
	_member_board_label.text = "SELAMAT DATANG, COLONY MEMBER"
	_member_board_label.font_size = 17
	_member_board_label.pixel_size = 0.0038
	_member_board_label.position = Vector3(0, -0.68, -0.1)
	_member_board_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_member_board_label.modulate = Color("#a9d6e7")
	board.add_child(_member_board_label)
	_refresh_member_board()
	add_child(board)


func _refresh_member_board() -> void:
	if not is_instance_valid(_member_board_label):
		return
	var name_value := str(_member_profile.get("name", _member_profile.get("username", "COLONY MEMBER"))).strip_edges()
	if name_value.is_empty():
		name_value = "COLONY MEMBER"
	_member_board_label.text = "SELAMAT DATANG, " + name_value.left(24).to_upper()


func _input(event: InputEvent) -> void:
	# Resolve on release to avoid activating stations during swipe/drag gestures.
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_tap_candidate = true
		else:
			if _tap_candidate and _touch_start.distance_to(event.position) <= 24.0:
				_pick_destination(event.position)
			_tap_candidate = false
	elif event is InputEventScreenDrag:
		if _tap_candidate and _touch_start.distance_to(event.position) > 24.0:
			_tap_candidate = false
		if _touch_candidate_for_orbit(event):
			_hub_drag_active = true
			_hub_orbit_yaw -= event.relative.x * 0.004
			_hub_orbit_pitch = clampf(_hub_orbit_pitch + event.relative.y * 0.003, 0.22, 0.72)
			_update_hub_camera_framing()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_start = event.position
			_tap_candidate = true
		else:
			if _tap_candidate and _touch_start.distance_to(event.position) <= 8.0:
				_pick_destination(event.position)
			_tap_candidate = false
	elif event is InputEventMouseMotion:
		if _tap_candidate and _touch_start.distance_to(event.position) > 8.0:
			_tap_candidate = false
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_hub_orbit_yaw -= event.relative.x * 0.004
			_hub_orbit_pitch = clampf(_hub_orbit_pitch + event.relative.y * 0.003, 0.22, 0.72)
			_update_hub_camera_framing()



func _touch_candidate_for_orbit(_event: InputEventScreenDrag) -> bool:
	return not _tap_candidate


func _pick_destination(screen_position: Vector2) -> void:
	if _camera == null:
		return
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * _ray_length)
	query.collide_with_areas = true
	query.collision_mask = 6
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
	if collider is Area3D and collider.has_meta("hub_panel_action"):
		_handle_hub_panel_action(str(collider.get_meta("hub_panel_action")))
		return
	if collider is Area3D and collider.has_meta("destination_id"):
		var destination := str(collider.get_meta("destination_id"))
		_open_destination_panel(destination)


func _open_destination_panel(destination_id: String) -> void:
	if is_instance_valid(_destination_panel):
		_destination_panel.queue_free()
	_destination_panel = Node3D.new()
	_destination_panel.name = "SpatialFeaturePanel"
	_destination_panel.position = Vector3(0, 2.9, 5.0)
	var panel_mesh := MeshInstance3D.new()
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(7.2, 5.7, 0.18)
	panel_mesh.mesh = panel_box
	panel_mesh.material_override = _material(Color("#10263b"), 0.28, 0.28)
	_destination_panel.add_child(panel_mesh)

	_panel_title = Label3D.new()
	_panel_title.text = _destination_title(destination_id)
	_panel_title.font_size = 42
	_panel_title.pixel_size = 0.004
	_panel_title.position = Vector3(0, 2.15, -0.12)
	_panel_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_panel_title.modulate = Color("#f3d99a")
	_destination_panel.add_child(_panel_title)

	_panel_body = Label3D.new()
	_panel_body.text = _destination_description(destination_id)
	_panel_body.font_size = 21
	_panel_body.pixel_size = 0.004
	_panel_body.position = Vector3(0, 1.28, -0.12)
	_panel_body.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_panel_body.modulate = Color("#e5edf4")
	_destination_panel.add_child(_panel_body)

	if destination_id == "profile":
		_build_profile_card()
	if destination_id == "world":
		_create_hub_panel_button("MASUK KE DUNIA", Vector3(0, 0.0, -0.24), "enter_world", Vector3(2.8, 0.68, 0.16), Color("#a77a36"))
	if destination_id == "settings":
		_create_hub_panel_button("SUARA & VOLUME", Vector3(0, 0.78, -0.24), "settings:audio", Vector3(2.8, 0.52, 0.16), Color("#a77a36"))
		_create_hub_panel_button("HEMAT", Vector3(-1.5, 0.02, -0.24), "settings:quality:1", Vector3(1.35, 0.5, 0.16))
		_create_hub_panel_button("SEIMBANG", Vector3(0, 0.02, -0.24), "settings:quality:2", Vector3(1.35, 0.5, 0.16))
		_create_hub_panel_button("TINGGI", Vector3(1.5, 0.02, -0.24), "settings:quality:3", Vector3(1.35, 0.5, 0.16))
		_create_hub_panel_button("AUTO", Vector3(0, -0.66, -0.24), "settings:quality:0", Vector3(1.35, 0.5, 0.16))
		_create_hub_panel_button("TENTANG STUDIO", Vector3(0, -1.3, -0.24), "settings:credits", Vector3(2.8, 0.5, 0.16))
	if destination_id == "chat":
		_create_hub_panel_button("BUKA CHAT 3D", Vector3(0, 0.62, -0.24), "open_chat", Vector3(2.8, 0.56, 0.16), Color("#397b70"))
		_create_hub_panel_button("HOST LAN", Vector3(-1.62, -0.12, -0.24), "room:host", Vector3(2.55, 0.5, 0.16), Color("#315b70"))
		_create_hub_panel_button("BUAT ROOM", Vector3(1.62, -0.12, -0.24), "room:create", Vector3(2.55, 0.5, 0.16), Color("#a77a36"))
		_create_hub_panel_button("MASUK LOBBY", Vector3(-1.62, -0.78, -0.24), "room:lobby", Vector3(2.55, 0.5, 0.16), Color("#397b70"))
		_create_hub_panel_button("KELUAR ROOM", Vector3(1.62, -0.78, -0.24), "room:leave", Vector3(2.55, 0.5, 0.16), Color("#65568d"))
		_room_status_label = Label3D.new()
		_room_status_label.name = "RoomStatus3D"
		_room_status_label.text = "LAN: OFFLINE • Room: —"
		_room_status_label.font_size = 15
		_room_status_label.pixel_size = 0.0032
		_room_status_label.position = Vector3(-2.7, -1.38, -0.24)
		_room_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_room_status_label.modulate = Color("#c9d9e5")
		_destination_panel.add_child(_room_status_label)
		_room_snapshot_root = Node3D.new()
		_room_snapshot_root.name = "RoomList3D"
		_room_snapshot_root.position = Vector3(1.45, -1.28, -0.25)
		_destination_panel.add_child(_room_snapshot_root)
		# Restore the most recent network snapshot immediately when the panel opens;
		# don't wait for another broadcast to repopulate the visible room list.
		_refresh_room_status_label()
		_render_room_snapshot_page()
		_create_hub_panel_button("SEBELUM", Vector3(0.72, -2.18, -0.24), "room:page:prev", Vector3(1.12, 0.34, 0.16), Color("#315b70"))
		_create_hub_panel_button("LANJUT", Vector3(2.18, -2.18, -0.24), "room:page:next", Vector3(1.12, 0.34, 0.16), Color("#397b70"))
		_create_hub_panel_button("KEMBALI KE HUB", Vector3(0, -2.62, -0.24), "back", Vector3(2.6, 0.36, 0.16), Color("#315b70"))
		# Keep the latest RoomManager snapshot received before this panel opens.
		# Resetting it here hid existing rooms until the next network broadcast.
	if destination_id == "games":
		_create_hub_panel_button("GUESS WHO?", Vector3(-1.15, 0.15, -0.24), "game:guess_who", Vector3(2.25, 0.58, 0.16))
		_create_hub_panel_button("ROYAL BOMB", Vector3(1.15, 0.15, -0.24), "game:royal_bomb", Vector3(2.25, 0.58, 0.16))
		_create_hub_panel_button("MURDER MYSTERY", Vector3(-1.15, -0.72, -0.24), "game:royal_murder_mystery", Vector3(2.25, 0.58, 0.16))
		_create_hub_panel_button("ROYAL DICE", Vector3(1.15, -0.72, -0.24), "game:royal_dice", Vector3(2.25, 0.58, 0.16))
	if destination_id != "chat":
		_create_hub_panel_button("KEMBALI KE HUB", Vector3(0, -2.05, -0.24), "back", Vector3(2.6, 0.62, 0.16), Color("#315b70"))
	add_child(_destination_panel)
	_hint.text = "Panel 3D terbuka: " + destination_id.to_upper()


func _build_profile_card() -> void:
	_load_profile_style()
	var display_name := str(_member_profile.get("name", "Anggota Colony")).strip_edges()
	var username := str(_member_profile.get("username", "")).strip_edges()
	var role := str(_member_profile.get("role", "member")).strip_edges()
	var status := str(_member_profile.get("status", "Aktif")).strip_edges()
	var avatar_root := Node3D.new()
	avatar_root.name = "ProfileAvatarPreview3D"
	avatar_root.position = Vector3(-2.15, -0.05, -0.28)
	var avatar_preview_script: Script = preload("res://scripts/avatar_visual.gd")
	var avatar_preview := avatar_preview_script.new() as Node3D
	avatar_preview.name = "VerifiedAvatarVisual"
	avatar_preview.scale = Vector3.ONE * 0.78
	avatar_root.add_child(avatar_preview)
	_profile_avatar_body = null
	var halo := MeshInstance3D.new()
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 0.52
	halo_mesh.outer_radius = 0.59
	halo.mesh = halo_mesh
	halo.position.y = 1.88
	halo.rotation_degrees.x = 90.0
	halo.material_override = _material(PROFILE_STYLES[_profile_style_index].halo, 0.28, 0.35)
	_profile_avatar_halo = halo
	avatar_root.add_child(halo)
	_destination_panel.add_child(avatar_root)
	# Apply only after entering the scene tree so AvatarVisual._ready()
	# has created its appearance materials and name label.
	avatar_preview.call("set_display_name", display_name)
	avatar_preview.call("apply_appearance", get_profile_appearance())
	var details := Label3D.new()
	details.text = "IDENTITAS TERVERIFIKASI\n%s\n@%s\nPERAN: %s\nSTATUS: %s\n\nData identitas berasal dari server sesi.\nPerubahan data akun dilakukan melalui layanan akun." % [display_name, username if not username.is_empty() else "—", role.to_upper(), status.to_upper()]
	details.font_size = 19
	details.pixel_size = 0.0038
	details.position = Vector3(0.55, 0.55, -0.24)
	details.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	details.modulate = Color("#e5edf4")
	_destination_panel.add_child(details)
	var verified := Label3D.new()
	verified.text = "●  SESI AKUN TERVERIFIKASI"
	verified.font_size = 15
	verified.pixel_size = 0.0035
	verified.position = Vector3(0, -2.12, -0.24)
	verified.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	verified.modulate = Color("#9ed6b2")
	_destination_panel.add_child(verified)
	var wardrobe_title := Label3D.new()
	wardrobe_title.text = "GAYA AVATAR • PILIH TAMPILAN"
	wardrobe_title.font_size = 15
	wardrobe_title.pixel_size = 0.0035
	wardrobe_title.position = Vector3(0, -1.25, -0.24)
	wardrobe_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	wardrobe_title.modulate = Color("#f3d99a")
	_destination_panel.add_child(wardrobe_title)
	for i in range(PROFILE_STYLES.size()):
		_create_profile_style_button(i, Vector3(-2.45 + float(i) * 1.22, -1.68, -0.28))


func _load_profile_style() -> void:
	var config := ConfigFile.new()
	if config.load("user://family_colony_profile.cfg") == OK:
		_profile_style_index = clampi(int(config.get_value("avatar", "style_index", 0)), 0, PROFILE_STYLES.size() - 1)
	else:
		_profile_style_index = 0


func get_profile_appearance() -> Dictionary:
	var outfit: Color = PROFILE_STYLES[_profile_style_index].body
	return {
		"top": outfit.to_html(true),
		"trousers": outfit.darkened(0.48).to_html(true),
		"shoes": outfit.darkened(0.72).to_html(true)
	}


func _save_profile_style() -> void:
	var config := ConfigFile.new()
	config.set_value("avatar", "style_index", _profile_style_index)
	var error := config.save("user://family_colony_profile.cfg")
	if error != OK:
		push_warning("FAMILY COLONY: Avatar style could not be saved locally. Error: %s" % error)


func _create_profile_style_button(style_index: int, local_position: Vector3) -> void:
	var style: Dictionary = PROFILE_STYLES[style_index]
	var area := Area3D.new()
	area.name = "ProfileStyle_" + str(style_index)
	area.position = local_position
	area.input_ray_pickable = true
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("hub_panel_action", "avatar_style:" + str(style_index))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.08, 0.5, 0.2)
	collision.shape = shape
	area.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.02, 0.44, 0.14)
	mesh.mesh = box
	mesh.material_override = _material(style.body, 0.34, 0.22)
	area.add_child(mesh)
	var label := Label3D.new()
	label.text = str(style.name) + (" ✓" if style_index == _profile_style_index else "")
	label.font_size = 13
	label.pixel_size = 0.003
	label.position.z = -0.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffffff")
	area.add_child(label)
	_destination_panel.add_child(area)


func _apply_profile_style(style_index: int) -> void:
	if style_index < 0 or style_index >= PROFILE_STYLES.size():
		return
	_profile_style_index = style_index
	if is_instance_valid(_profile_avatar_body):
		var body_material := _material(PROFILE_STYLES[style_index].body, 0.42, 0.18)
		_profile_avatar_body.material_override = body_material
	if is_instance_valid(_destination_panel):
		var preview := _destination_panel.find_child("VerifiedAvatarVisual", true, false)
		if preview != null and preview.has_method("apply_appearance"):
			preview.call("apply_appearance", get_profile_appearance())
	if is_instance_valid(_profile_avatar_halo):
		var halo_material := _material(PROFILE_STYLES[style_index].halo, 0.28, 0.35)
		_profile_avatar_halo.material_override = halo_material
	_save_profile_style()
	avatar_appearance_changed.emit(get_profile_appearance())
	_hint.text = "Tampilan avatar disimpan dan diterapkan: " + str(PROFILE_STYLES[style_index].name)
	if is_instance_valid(_destination_panel):
		_destination_panel.queue_free()
	_destination_panel = null
	_open_destination_panel("profile")


func show_developer_center(member: Dictionary) -> void:
	# Defense in depth: the world controller already verifies the token with the
	# server, but this scene also refuses to render the privileged dashboard for
	# any other identity.
	if str(member.get("role", "")).to_lower() != "developer" or str(member.get("username", "")).to_lower() != "edrick":
		set_developer_status("Akses ditolak • identitas Developer tidak valid.")
		return
	if is_instance_valid(_developer_panel):
		_developer_panel.queue_free()
		_developer_panel = null
	if is_instance_valid(_destination_panel):
		_destination_panel.queue_free()
	_destination_panel = Node3D.new()
	_destination_panel.name = "DeveloperCenter3D"
	_destination_panel.position = Vector3(0, 2.9, 5.0)
	var backing := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(8.0, 5.8, 0.18)
	backing.mesh = panel_mesh
	backing.material_override = _material(Color("#101e31"), 0.26, 0.34)
	_destination_panel.add_child(backing)
	var heading := Label3D.new()
	heading.text = "DEVELOPER CENTER"
	heading.font_size = 46
	heading.pixel_size = 0.004
	heading.position = Vector3(0, 2.12, -0.12)
	heading.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	heading.modulate = Color("#f3d99a")
	_destination_panel.add_child(heading)
	var identity := Label3D.new()
	identity.text = "SERVER VERIFIED • " + str(member.get("name", "Developer")) + " • " + str(member.get("role", "Developer")).to_upper()
	identity.font_size = 18
	identity.pixel_size = 0.0035
	identity.position = Vector3(0, 1.48, -0.12)
	identity.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	identity.modulate = Color("#b9d7e8")
	_destination_panel.add_child(identity)
	var actions := [
		["MANAJEMEN ANGGOTA", "members"],
		["PENGATURAN DUNIA", "world_settings"],
		["MANAJEMEN MINI GAME", "minigames"],
		["MONITOR SERVER", "server_monitor"],
		["LAPORAN & AKTIVITAS", "reports"],
		["KONFIGURASI APLIKASI", "app_config"]
	]
	for i in range(actions.size()):
		var row := i / 3
		var col := i % 3
		var x := -2.45 + float(col) * 2.45
		var y := 0.48 if row == 0 else -0.42
		_create_developer_center_button(str(actions[i][0]), Vector3(x, y, -0.24), str(actions[i][1]))
	_create_developer_center_button("KEMBALI KE HUB", Vector3(0, -1.78, -0.24), "back")
	add_child(_destination_panel)
	_hint.text = "Developer Center aktif • role diverifikasi server."


func _create_developer_center_button(label_text: String, local_position: Vector3, action_id: String) -> void:
	var area := Area3D.new()
	area.name = "DeveloperCenter_" + action_id
	area.position = local_position
	area.input_ray_pickable = true
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("hub_panel_action", "developer:" + action_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.15, 0.62, 0.18)
	collision.shape = shape
	area.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.08, 0.58, 0.14)
	mesh.mesh = box
	mesh.material_override = _material(Color("#315b70") if action_id != "back" else Color("#a77a36"), 0.3, 0.22)
	area.add_child(mesh)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 16
	label.pixel_size = 0.0035
	label.position.z = -0.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffffff")
	area.add_child(label)
	_destination_panel.add_child(area)


func set_developer_status(message: String) -> void:
	if is_instance_valid(_developer_pin_status):
		_developer_pin_status.text = message
	if is_instance_valid(_hint):
		_hint.text = message


func _destination_title(destination_id: String) -> String:
	match destination_id:
		"profile": return "PROFIL ANGGOTA"
		"chat": return "ALUN-ALUN CHAT"
		"games": return "ROYAL GAME CENTER"
		"settings": return "PENGATURAN KOLONI"
		"world": return "DUNIA KOLONI"
		_: return "FAMILY COLONY"


func _destination_description(destination_id: String) -> String:
	match destination_id:
		"profile":
			var display_name := str(_member_profile.get("name", "Anggota Colony")).strip_edges()
			var username := str(_member_profile.get("username", "")).strip_edges()
			var role := str(_member_profile.get("role", "member")).strip_edges()
			if username.is_empty():
				return "PROFIL ANGGOTA\n" + display_name + "\nPeran: " + role + "\nData profil berasal dari sesi akun terverifikasi."
			return "PROFIL ANGGOTA\n" + display_name + "\n@" + username + "  •  " + role + "\nData profil berasal dari sesi akun terverifikasi."
		"chat": return "Bertemu • mengobrol • room\nLayanan chat lintas jaringan dan panel 3D sedang dimigrasikan."
		"games": return "Pilih satu dari empat mini-game: Guess Who, Royal Bomb, Royal Murder Mystery, Royal Dice.\nIntegrasi arena dan gameplay final masih dalam pengerjaan."
		"settings": return "Atur audio dan kualitas grafis langsung di dunia 3D.\nHEMAT • SEIMBANG • TINGGI • AUTO"
		"world": return "Masuk ke dunia 3D dan jelajahi Bee Kingdom.\nBerjalan, berinteraksi, dan bermain bersama."
		_: return "Fitur sedang disiapkan."


func _create_hub_panel_button(label_text: String, local_position: Vector3, action_id: String, dimensions: Vector3, color: Color = Color("#315b70")) -> void:
	var area := Area3D.new()
	area.name = "HubPanelAction_" + action_id.replace(":", "_")
	area.position = local_position
	area.input_ray_pickable = true
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("hub_panel_action", action_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	area.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions * Vector3(0.96, 0.94, 0.72)
	mesh.mesh = box
	mesh.material_override = _material(color, 0.32, 0.2)
	area.add_child(mesh)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 18 if label_text.length() > 10 else 23
	label.pixel_size = 0.0035
	label.position.z = -dimensions.z * 0.42
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffffff")
	area.add_child(label)
	_destination_panel.add_child(area)


func _handle_hub_panel_action(action_id: String) -> void:
	if action_id.begins_with("avatar_style:"):
		_apply_profile_style(int(action_id.trim_prefix("avatar_style:")))
		return
	if action_id.begins_with("developer:"):
		var developer_action := action_id.trim_prefix("developer:")
		if developer_action == "back":
			if is_instance_valid(_destination_panel):
				_destination_panel.queue_free()
			_destination_panel = null
			_hint.text = "Developer Center ditutup. Pilih bangunan 3D."
		else:
			developer_center_action_requested.emit(developer_action)
			_hint.text = "Developer Center: " + developer_action.replace("_", " ").to_upper() + " • menunggu integrasi operasi server."
		return
	if action_id.begins_with("settings:"):
		settings_action_requested.emit(action_id.trim_prefix("settings:"))
		_hint.text = "Pengaturan 3D diperbarui: " + action_id.trim_prefix("settings:").replace(":", " ").to_upper()
		return
	if action_id == "open_chat":
		destination_requested.emit("chat_open")
		return
	if action_id.begins_with("room:"):
		room_action_requested.emit(action_id.trim_prefix("room:"))
		return
	if action_id == "enter_world":
		if is_instance_valid(_destination_panel):
			_destination_panel.queue_free()
		_destination_panel = null
		destination_requested.emit("world")
		return
	if action_id == "back":
		if is_instance_valid(_destination_panel):
			_destination_panel.queue_free()
		_destination_panel = null
		_hint.text = "Pilih bangunan 3D untuk membuka fitur."
		return
	if action_id.begins_with("game:"):
		var game_id := action_id.trim_prefix("game:")
		if FINAL_MINIGAMES.has(game_id):
			if is_instance_valid(_destination_panel):
				_destination_panel.queue_free()
			_destination_panel = null
			destination_requested.emit("world")
			minigame_requested.emit(game_id)
			return
		_hint.text = "Mini-game tidak dikenali: " + game_id


func set_room_network_state(state: String, detail: String) -> void:
	_room_lan_state = state.to_upper()
	_room_connection_detail = detail
	_refresh_room_status_label()


func set_cloud_matchmaking_state(state: String, detail: String) -> void:
	_cloud_matchmaking_state = state.to_upper()
	_cloud_matchmaking_detail = detail
	_refresh_room_status_label()


func _refresh_room_status_label() -> void:
	if not is_instance_valid(_room_status_label):
		return
	var room_status := "—"
	if not _room_current_id.is_empty():
		room_status = "%s • %d anggota" % [_room_current_id, _room_current_members.size()]
	_room_status_label.text = "LAN: %s\n%s\nCLOUD: %s\n%s\nROOM: %s" % [_room_lan_state, _room_connection_detail, _cloud_matchmaking_state, _cloud_matchmaking_detail, room_status]


func set_current_room(room_id: String, members: Array[int]) -> void:
	_room_current_id = room_id
	_room_current_members = members.duplicate()
	set_room_network_state("aktif" if not room_id.is_empty() else "offline", _room_connection_detail)


func set_room_snapshot(rooms: Array) -> void:
	_room_snapshot_data = rooms.duplicate(true)
	var page_count := maxi(1, ceili(float(_room_snapshot_data.size()) / float(ROOM_SNAPSHOT_PAGE_SIZE)))
	_room_snapshot_page = clampi(_room_snapshot_page, 0, page_count - 1)
	_render_room_snapshot_page()


func change_room_snapshot_page(direction: int) -> void:
	var page_count := maxi(1, ceili(float(_room_snapshot_data.size()) / float(ROOM_SNAPSHOT_PAGE_SIZE)))
	var next_page := clampi(_room_snapshot_page + signi(direction), 0, page_count - 1)
	if next_page == _room_snapshot_page:
		return
	_room_snapshot_page = next_page
	_render_room_snapshot_page()


func _render_room_snapshot_page() -> void:
	if not is_instance_valid(_room_snapshot_root):
		return
	for child in _room_snapshot_root.get_children():
		# Remove synchronously so freshly rendered page children keep stable names.
		_room_snapshot_root.remove_child(child)
		child.free()
	var start_index := _room_snapshot_page * ROOM_SNAPSHOT_PAGE_SIZE
	var end_index := mini(start_index + ROOM_SNAPSHOT_PAGE_SIZE, _room_snapshot_data.size())
	var shown := 0
	for index in range(start_index, end_index):
		var room_variant = _room_snapshot_data[index]
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		var room_id := str(room.get("id", ""))
		var room_name := str(room.get("name", "Room"))
		var member_count := int(room.get("member_count", 0))
		var capacity := int(room.get("capacity", 0))
		var row := Node3D.new()
		row.position.y = -float(shown) * 0.56
		var label := Label3D.new()
		label.text = "%s  %d/%d" % [room_name.left(13), member_count, capacity]
		label.font_size = 13
		label.pixel_size = 0.003
		label.position = Vector3(-1.35, 0, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("#e5edf4")
		row.add_child(label)
		_room_snapshot_root.add_child(row)
		_create_room_join_button(room_id, shown)
		shown += 1
	var page_count := maxi(1, ceili(float(_room_snapshot_data.size()) / float(ROOM_SNAPSHOT_PAGE_SIZE)))
	var page_label := Label3D.new()
	page_label.text = "Halaman %d/%d" % [_room_snapshot_page + 1, page_count]
	page_label.font_size = 12
	page_label.pixel_size = 0.0028
	page_label.position = Vector3(-1.35, -0.72, 0)
	page_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	page_label.modulate = Color("#c9d9e5")
	_room_snapshot_root.add_child(page_label)
	if shown == 0:
		var empty_label := Label3D.new()
		empty_label.text = "Belum ada room terdaftar."
		empty_label.font_size = 13
		empty_label.pixel_size = 0.003
		empty_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		empty_label.modulate = Color("#c9d9e5")
		_room_snapshot_root.add_child(empty_label)


func _create_room_join_button(room_id: String, index: int) -> void:
	var area := Area3D.new()
	area.name = "JoinRoom_" + str(index)
	area.position = Vector3(1.15, -float(index) * 0.48, 0)
	area.input_ray_pickable = true
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("hub_panel_action", "room:join:" + room_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.72, 0.32, 0.14)
	collision.shape = shape
	area.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.68, 0.29, 0.1)
	mesh.mesh = box
	mesh.material_override = _material(Color("#397b70"), 0.35, 0.12)
	area.add_child(mesh)
	var label := Label3D.new()
	label.text = "GABUNG"
	label.font_size = 12
	label.pixel_size = 0.003
	label.position.z = -0.06
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	area.add_child(label)
	_room_snapshot_root.add_child(area)


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

func _build_plaza_path_composition() -> void:
	# Cohesive approach paths: curved-feeling layered stone strips, edge borders
	# and small planted pockets, composed to read as a connected plaza.
	for path_index in range(5):
		var target: Vector3 = HUB_ITEMS[path_index].position
		var start := Vector3(0.0, 0.0, 2.8)
		var direction := Vector2(target.x, target.z + 1.0)
		if direction.length() < 0.1:
			continue
		direction = direction.normalized()
		var perpendicular := Vector3(-direction.y, 0.0, direction.x)
		var center := Vector3(direction.x * 5.8, 0.0, direction.y * 5.8)
		for side in [-1.0, 1.0]:
			var curb := MeshInstance3D.new()
			var curb_mesh := BoxMesh.new()
			curb_mesh.size = Vector3(0.18, 0.12, 4.3)
			curb.mesh = curb_mesh
			curb.position = center + perpendicular * side * 0.95 + Vector3(0.0, 0.09, 0.0)
			curb.rotation.y = atan2(direction.x, direction.y)
			curb.material_override = _material(Color("#9aaba8"), 0.58, 0.12)
			add_child(curb)
		for slab_index in range(4):
			var slab := MeshInstance3D.new()
			var slab_mesh := BoxMesh.new()
			slab_mesh.size = Vector3(1.35, 0.1, 0.88)
			slab.mesh = slab_mesh
			slab.position = center + direction * (float(slab_index) * 1.0 - 1.5) + Vector3(0.0, 0.11, 0.0)
			slab.rotation.y = atan2(direction.x, direction.y)
			slab.material_override = _material(Color("#718783") if slab_index % 2 == 0 else Color("#849a95"), 0.72, 0.06)
			add_child(slab)
		for side in [-1.0, 1.0]:
			var pocket := Node3D.new()
			pocket.position = center + perpendicular * side * 1.65
			add_child(pocket)
			var bed := MeshInstance3D.new()
			var bed_mesh := CylinderMesh.new()
			bed_mesh.top_radius = 0.42
			bed_mesh.bottom_radius = 0.52
			bed_mesh.height = 0.2
			bed.mesh = bed_mesh
			bed.position.y = 0.1
			bed.material_override = _material(Color("#405a55"), 0.88, 0.0)
			pocket.add_child(bed)
			for bloom_index in range(3):
				var bloom := MeshInstance3D.new()
				var bloom_mesh := SphereMesh.new()
				bloom_mesh.radius = 0.18
				bloom_mesh.height = 0.3
				bloom.mesh = bloom_mesh
				bloom.position = Vector3((float(bloom_index) - 1.0) * 0.22, 0.3, 0.06)
				bloom.material_override = _material(Color("#c9bfa7") if bloom_index % 2 == 0 else Color("#87b9ad"), 0.76, 0.0)
				pocket.add_child(bloom)


func _build_hub_focal_lighting() -> void:
	# Mobile-friendly focal lighting to help the plaza landmarks read as one scene.
	var beacon_fill := OmniLight3D.new()
	beacon_fill.name = "PlazaBeaconFill"
	beacon_fill.position = Vector3(0.0, 4.5, -0.8)
	beacon_fill.light_color = Color("#b8d9e7")
	beacon_fill.light_energy = 0.6
	beacon_fill.omni_range = 10.0
	beacon_fill.shadow_enabled = false
	add_child(beacon_fill)
	for index in range(5):
		var angle := TAU * float(index) / 5.0
		var light := OmniLight3D.new()
		light.name = "LandmarkAccent_%02d" % index
		light.position = Vector3(cos(angle) * 8.0, 2.8, sin(angle) * 8.0)
		light.light_color = Color("#d5b879") if index % 2 == 0 else Color("#9bcbd6")
		light.light_energy = 0.34
		light.omni_range = 5.2
		light.shadow_enabled = false
		add_child(light)

func _build_distant_colony_silhouette() -> void:
	# Low-poly distant skyline framing the hub; silhouettes create depth without
	# heavy assets or collision bodies.
	for cluster_index in range(9):
		var angle := TAU * float(cluster_index) / 9.0
		var cluster := Node3D.new()
		cluster.name = "ColonySkyline_%02d" % cluster_index
		cluster.position = Vector3(cos(angle) * 19.0, 0.0, sin(angle) * 19.0)
		cluster.rotation.y = angle
		add_child(cluster)
		for tower_index in range(2):
			var tower := MeshInstance3D.new()
			var tower_mesh := CylinderMesh.new()
			var height := 3.6 + float((cluster_index + tower_index * 3) % 4) * 1.15
			tower_mesh.top_radius = 0.22
			tower_mesh.bottom_radius = 0.62
			tower_mesh.height = height
			tower.mesh = tower_mesh
			tower.position = Vector3((tower_index - 0.5) * 1.6, height * 0.5 - 0.12, -1.0)
			tower.material_override = _material(Color("#344b60") if cluster_index % 2 == 0 else Color("#405b60"), 0.82, 0.08)
			cluster.add_child(tower)
			var cap := MeshInstance3D.new()
			var cap_mesh := SphereMesh.new()
			cap_mesh.radius = 0.42
			cap_mesh.height = 0.62
			cap.mesh = cap_mesh
			cap.position = tower.position + Vector3(0.0, height * 0.5 + 0.08, 0.0)
			cap.material_override = _material(Color("#526d78"), 0.62, 0.18)
			cluster.add_child(cap)

func _build_plaza_wayfinding() -> void:
	# Radial direction markers and illuminated inset plates guide members between
	# the central hall and feature stations without cluttering the touch surfaces.
	for index in range(5):
		var item: Dictionary = HUB_ITEMS[index]
		var direction := Vector2(float(item.position.x), float(item.position.z)).normalized()
		var marker_root := Node3D.new()
		marker_root.name = "Wayfinding_%s" % str(item.id)
		marker_root.position = Vector3(direction.x * 4.15, 0.0, direction.y * 4.15)
		marker_root.rotation.y = atan2(direction.x, direction.y)
		add_child(marker_root)
		var plate := MeshInstance3D.new()
		var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(0.72, 0.045, 1.25)
		plate.mesh = plate_mesh
		plate.position.y = 0.19
		plate.material_override = _material(Color("#263b49"), 0.42, 0.3)
		marker_root.add_child(plate)
		for stripe_index in range(3):
			var stripe := MeshInstance3D.new()
			var stripe_mesh := BoxMesh.new()
			stripe_mesh.size = Vector3(0.12, 0.025, 0.26)
			stripe.mesh = stripe_mesh
			stripe.position = Vector3(0.0, 0.23, -0.34 + float(stripe_index) * 0.32)
			var stripe_material := _material(item.color.lightened(0.28), 0.25, 0.35)
			stripe_material.emission_enabled = true
			stripe_material.emission = item.color.lightened(0.2)
			stripe_material.emission_energy_multiplier = 0.3
			stripe.material_override = stripe_material
			marker_root.add_child(stripe)


func _build_feature_approach_lanes() -> void:
	# Subtle segmented inlays connect the central landmark to each feature kiosk.
	# They are static mesh accents (no per-frame processing) to keep mobile cost low.
	for item in HUB_ITEMS:
		var direction := Vector2(float(item.position.x), float(item.position.z) - -0.8).normalized()
		var lane_root := Node3D.new()
		lane_root.name = "ApproachLane_%s" % str(item.id)
		lane_root.position = Vector3(0.0, 0.0, -0.8)
		lane_root.rotation.y = atan2(direction.x, direction.y)
		add_child(lane_root)
		for segment_index in range(4):
			var segment := MeshInstance3D.new()
			var segment_mesh := BoxMesh.new()
			segment_mesh.size = Vector3(0.22, 0.035, 0.62)
			segment.mesh = segment_mesh
			segment.position = Vector3(0.0, 0.17, -4.25 - float(segment_index) * 1.0)
			var segment_material := _material(item.color.lightened(0.18), 0.42, 0.22)
			segment_material.emission_enabled = true
			segment_material.emission = item.color.darkened(0.12)
			segment_material.emission_energy_multiplier = 0.16
			segment.material_override = segment_material
			lane_root.add_child(segment)
