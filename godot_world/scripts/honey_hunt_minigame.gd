extends Node3D
## First playable 3D mini-game: Honey Hunt.
## Rewards are local session points only; no wallet or persistent currency is modified.

const PORTAL_SCRIPT: Script = preload("res://scripts/minigame_portal.gd")

var _player: CharacterBody3D
var _return_position := Vector3.ZERO
var _active := false
var _time_left := 45.0
var _score := 0
var _targets: Array[MeshInstance3D] = []
var _target_home_positions: Dictionary = {}
var _elapsed := 0.0
var _arena: Node3D
var _hud: Node3D
var _status: Label3D
var _return_button: Area3D
var _rng := RandomNumberGenerator.new()
const TARGET_COUNT := 12
const ARENA_ORIGIN := Vector3(0, 0, 140)


func _ready() -> void:
	_rng.randomize()
	_build_arena()
	_build_entry_portal()
	_build_hud()


func _unhandled_input(event: InputEvent) -> void:
	# Keep the spatial result screen interactive after a royal mini-game ends:
	# the player must still be able to ray-pick KELUAR and return to Game Center.
	if not _royal_game_id.is_empty() and is_instance_valid(_royal_game_hud):
		_unhandled_royal_game_input(event)
		return
	if not is_instance_valid(_player) or not is_instance_valid(_hud) or not _hud.visible:
		return
	var pressed: bool = event is InputEventScreenTouch and event.pressed
	pressed = pressed or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	var player_camera := _player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if player_camera == null:
		return
	var screen_position: Vector2 = event.position
	var origin := player_camera.project_ray_origin(screen_position)
	var direction := player_camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 10.0)
	query.collide_with_areas = true
	query.collision_mask = 32
	var hit := player_camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider is Area3D and collider.has_meta("exit_honey_hunt"):
			exit_minigame()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _royal_game_active:
		if _royal_game_id == "guess_who" and not _royal_game_state.is_empty() and not bool(_royal_game_state.get("finished", false)):
			_royal_game_state.seconds = maxf(0.0, float(_royal_game_state.seconds) - delta)
			if _royal_game_state.seconds <= 0.0:
				_royal_game_state.wrong += 1
				_guess_who_next()
		return
	if not _active or not is_instance_valid(_player):
		return
	_time_left = maxf(0.0, _time_left - delta)
	_elapsed += delta
	for index in range(_targets.size()):
		var target := _targets[index]
		if not is_instance_valid(target):
			continue
		var home: Vector3 = _target_home_positions.get(target.get_instance_id(), target.position)
		target.position.y = home.y + sin(_elapsed * 2.4 + float(index) * 0.7) * 0.22
		target.rotation.y += delta * 1.8
		if _player.global_position.distance_to(target.global_position) < 1.55:
			_collect_target(target)
	_update_status()
	if _time_left <= 0.0 or _score >= TARGET_COUNT:
		_finish_round()


func start_honey_hunt(actor: Node) -> String:
	if not actor is CharacterBody3D:
		return "Karakter tidak dapat mengikuti permainan."
	_player = actor as CharacterBody3D
	_return_position = _player.global_position
	_score = 0
	_time_left = 45.0
	_elapsed = 0.0
	_active = true
	_reset_targets()
	_arena.visible = true
	_player.velocity = Vector3.ZERO
	_player.global_position = ARENA_ORIGIN + Vector3(0, 1.1, 8)
	var player_camera := _player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if player_camera != null and _hud.get_parent() != player_camera:
		if _hud.get_parent() != null:
			_hud.get_parent().remove_child(_hud)
		player_camera.add_child(_hud)
		_hud.position = Vector3(0, 0, -3.0)
	_hud.visible = true
	_return_button.visible = true
	_update_status()
	return "Mini-game HONEY HUNT dimulai! Kumpulkan madu sebanyak mungkin dalam 45 detik."


func _build_entry_portal() -> void:
	var portal := Area3D.new()
	portal.name = "HoneyHuntPortal"
	portal.position = Vector3(22, 1.0, -14.0)
	portal.collision_layer = 2
	portal.collision_mask = 0
	portal.set_script(PORTAL_SCRIPT)
	portal.set("game_manager", self)
	add_child(portal)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.3
	shape.shape = sphere
	portal.add_child(shape)

	var pedestal := MeshInstance3D.new()
	var base := CylinderMesh.new()
	base.top_radius = 1.25
	base.bottom_radius = 1.55
	base.height = 0.55
	base.radial_segments = 6
	pedestal.mesh = base
	pedestal.position.y = -0.35
	pedestal.material_override = _material(Color(0.34, 0.23, 0.12), 0.45, 0.35)
	portal.add_child(pedestal)

	var crystal := MeshInstance3D.new()
	var crystal_mesh := CylinderMesh.new()
	crystal_mesh.top_radius = 0.0
	crystal_mesh.bottom_radius = 0.72
	crystal_mesh.height = 1.65
	crystal_mesh.radial_segments = 6
	crystal.mesh = crystal_mesh
	crystal.position.y = 0.75
	crystal.material_override = _material(Color(1.0, 0.69, 0.18), 0.28, 0.5)
	portal.add_child(crystal)

	var sign := Label3D.new()
	sign.text = "HONEY HUNT\nMINI GAME"
	sign.position = Vector3(0, 2.0, 0)
	sign.font_size = 32
	sign.pixel_size = 0.012
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = Color(1.0, 0.88, 0.55)
	portal.add_child(sign)


func _build_arena() -> void:
	_arena = Node3D.new()
	_arena.name = "HoneyHunt3DArena"
	_arena.position = ARENA_ORIGIN
	_arena.visible = false
	add_child(_arena)

	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 19.0
	floor_mesh.bottom_radius = 19.0
	floor_mesh.height = 0.5
	floor_mesh.radial_segments = 48
	floor.mesh = floor_mesh
	floor.position.y = -0.55
	floor.material_override = _material(Color(0.22, 0.38, 0.31), 0.95)
	_arena.add_child(floor)

	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloorCollision"
	_arena.add_child(floor_body)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := CylinderShape3D.new()
	floor_shape.radius = 19.0
	floor_shape.height = 0.5
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.55
	floor_body.add_child(floor_collision)

	for index in range(18):
		var angle := TAU * float(index) / 18.0
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.55
		pillar_mesh.bottom_radius = 0.8
		pillar_mesh.height = 3.2
		pillar_mesh.radial_segments = 6
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 17.0, 1.05, sin(angle) * 17.0)
		pillar.material_override = _material(Color(0.58, 0.43, 0.25), 0.7)
		_arena.add_child(pillar)

	var title := Label3D.new()
	title.text = "TAMAN MADU"
	title.position = Vector3(0, 5.0, -12.0)
	title.font_size = 52
	title.pixel_size = 0.012
	title.modulate = Color(1.0, 0.84, 0.42)
	title.outline_size = 8
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_arena.add_child(title)

	var light := OmniLight3D.new()
	light.position = Vector3(0, 8, 0)
	light.light_color = Color(1.0, 0.78, 0.42)
	light.light_energy = 1.8
	light.omni_range = 32.0
	_arena.add_child(light)


func _build_hud() -> void:
	# In-world camera-mounted 3D score display and ray-pickable exit control.
	_hud = Node3D.new()
	_hud.name = "HoneyHuntSpatialHUD"
	_hud.visible = false
	_status = Label3D.new()
	_status.name = "HoneyHuntScoreboard"
	_status.font_size = 28
	_status.pixel_size = 0.0035
	_status.position = Vector3(-0.95, 0.82, 0)
	_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status.modulate = Color("#ffe3a3")
	_status.outline_size = 7
	_status.outline_modulate = Color("#172331")
	_status.visible = false
	_hud.add_child(_status)

	_return_button = Area3D.new()
	_return_button.name = "HoneyHuntSpatialExit"
	_return_button.position = Vector3(1.2, 0.68, 0)
	_return_button.input_ray_pickable = true
	_return_button.collision_layer = 32
	_return_button.collision_mask = 0
	_return_button.set_meta("exit_honey_hunt", true)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.35, 0.48, 0.3)
	collision.shape = shape
	_return_button.add_child(collision)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.3, 0.44, 0.18)
	body.mesh = box
	body.material_override = _material(Color("#a77a36"), 0.35, 0.2)
	_return_button.add_child(body)
	var label := Label3D.new()
	label.text = "KELUAR"
	label.font_size = 20
	label.pixel_size = 0.0035
	label.position.z = -0.12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffffff")
	_return_button.add_child(label)
	_hud.add_child(_return_button)


func _reset_targets() -> void:
	for target in _targets:
		if is_instance_valid(target):
			target.queue_free()
	_targets.clear()
	_target_home_positions.clear()
	for index in range(TARGET_COUNT):
		var token := MeshInstance3D.new()
		token.name = "HoneyToken_%02d" % index
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.62
		mesh.bottom_radius = 0.62
		mesh.height = 0.22
		mesh.radial_segments = 6
		token.mesh = mesh
		token.rotation.x = PI * 0.5
		token.position = Vector3(_rng.randf_range(-13.0, 13.0), _rng.randf_range(0.8, 2.8), _rng.randf_range(-12.0, 12.0))
		token.material_override = _material(Color(1.0, 0.67, 0.12), 0.28, 0.45)
		_arena.add_child(token)
		_target_home_positions[token.get_instance_id()] = token.position
		var halo := MeshInstance3D.new()
		var halo_mesh := TorusMesh.new()
		halo_mesh.inner_radius = 0.72
		halo_mesh.outer_radius = 0.82
		halo.mesh = halo_mesh
		halo.rotation.x = PI * 0.5
		halo.material_override = _material(Color(1.0, 0.88, 0.48), 0.25, 0.2)
		token.add_child(halo)
		_targets.append(token)


func _collect_target(target: MeshInstance3D) -> void:
	_targets.erase(target)
	_target_home_positions.erase(target.get_instance_id())
	target.queue_free()
	_score += 1
	_update_status()


func _finish_round() -> void:
	_active = false
	_status.text = "HONEY HUNT SELESAI\nMadu terkumpul: %d / %d\nTekan KELUAR untuk kembali." % [_score, TARGET_COUNT]
	_status.visible = true


func exit_minigame() -> void:
	if is_instance_valid(_player):
		_player.velocity = Vector3.ZERO
		_player.global_position = _return_position
	_arena.visible = false
	_active = false
	_status.visible = false
	_return_button.visible = false
	if is_instance_valid(_hud) and _hud.get_parent() != self:
		if _hud.get_parent() != null:
			_hud.get_parent().remove_child(_hud)
		add_child(_hud)
	_hud.visible = false
	_player = null


func _update_status() -> void:
	if is_instance_valid(_status):
		_status.text = "HONEY HUNT   •   MADU %02d/%02d   •   WAKTU %02d" % [_score, TARGET_COUNT, ceili(_time_left)]
		_status.visible = _active


func _material(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


# ---------------------------------------------------------------------------
# ROYAL GAME CENTER — 4 additional native 3D mini-games.
# All menus, controls and feedback are spatial 3D objects (no CanvasLayer).
# ---------------------------------------------------------------------------
var _royal_game_id := ""
var _royal_game_state: Dictionary = {}
var _royal_game_hud: Node3D
var _royal_game_panel: Node3D
var _royal_game_status: Label3D
var _royal_game_clock := 0.0
var _royal_game_active := false
var _royal_game_return_position := Vector3.ZERO
var _royal_game_rng := RandomNumberGenerator.new()

const ROYAL_GAME_ORIGIN := Vector3(0, 0, 205)
const GUESS_WHO_ROSTER := [
	{"name":"Luna Bee","category":"Member Fiktif","clues":["Selalu hadir membawa semangat positif.","Suka mengoleksi avatar bertema bunga.","Warna favoritnya ungu."],"options":["Luna Bee","Raja Madu","Bintang Hive","Milo Honey"]},
	{"name":"Raja Madu","category":"Member Fiktif","clues":["Sering mengingatkan anggota untuk kompak.","Identik dengan simbol mahkota.","Julukannya terinspirasi dari hasil kerja lebah."],"options":["Luna Bee","Raja Madu","Bintang Hive","Milo Honey"]},
	{"name":"Bintang Hive","category":"Member Fiktif","clues":["Suka membuat suasana room menjadi ramai.","Nama panggilannya berkaitan dengan cahaya malam.","Sering memakai emoji bintang."],"options":["Luna Bee","Raja Madu","Bintang Hive","Milo Honey"]},
	{"name":"Milo Honey","category":"Member Fiktif","clues":["Nama panggilannya terdengar manis.","Suka membantu anggota baru mengenal koloni.","Identik dengan warna keemasan."],"options":["Luna Bee","Raja Madu","Bintang Hive","Milo Honey"]},
	{"name":"Awan Ceria","category":"Member Fiktif","clues":["Suka suasana tenang dan santai.","Nama panggilannya terinspirasi dari langit.","Sering mengirim emoji awan."],"options":["Awan Ceria","Raja Madu","Bintang Hive","Milo Honey"]}
]
const MURDER_CASES := [
	{"title":"MISTERI MENARA MADU","clue":"Penjaga melihat sosok membawa kunci istana. Jejak lilin ditemukan di dekat ruang harta.","answer":"The Alchemist","options":["The Alchemist","The Shadow","The Royal Guard"]},
	{"title":"RAHASIA TAMAN KACA","clue":"Korban terakhir terlihat menerima pesan rahasia. Saksi mendengar langkah cepat menuju lorong utara.","answer":"The Shadow","options":["The Royal Guard","The Shadow","The Alchemist"]},
	{"title":"MALAM DI AULA KERAJAAN","clue":"Pintu aula terkunci dari dalam. Hanya pemegang lencana kerajaan yang dapat membuka segelnya.","answer":"The Royal Guard","options":["The Shadow","The Alchemist","The Royal Guard"]}
]


func start_royal_game(game_id: String, actor: Node) -> String:
	if not actor is CharacterBody3D:
		return "Karakter tidak dapat mengikuti permainan."
	if not ["guess_who", "royal_bomb", "royal_murder_mystery", "royal_dice"].has(game_id):
		return "Mini-game tidak dikenal."
	if _active or _royal_game_active:
		return "Selesaikan permainan yang sedang aktif terlebih dahulu."
	_player = actor as CharacterBody3D
	_royal_game_id = game_id
	_royal_game_return_position = _player.global_position
	_player.velocity = Vector3.ZERO
	_player.set_physics_process(false)
	_player.global_position = ROYAL_GAME_ORIGIN + Vector3(0, 1.1, 4)
	_royal_game_rng.randomize()
	_royal_game_active = true
	_royal_game_clock = 0.0
	_build_royal_game_arena()
	_attach_royal_game_hud()
	match game_id:
		"guess_who":
			_start_guess_who()
		"royal_bomb":
			_start_royal_bomb()
		"royal_murder_mystery":
			_start_murder_mystery()
		"royal_dice":
			_start_royal_dice()
	return "Mini-game " + game_id.to_upper().replace("_", " ") + " dimulai dalam arena 3D."


func _build_royal_game_arena() -> void:
	var arena := Node3D.new()
	arena.name = "RoyalGameArena_" + _royal_game_id
	arena.position = ROYAL_GAME_ORIGIN
	add_child(arena)
	var theme_color := Color("#65c8d0")
	var theme_title := "GUESS WHO"
	match _royal_game_id:
		"royal_bomb":
			theme_color = Color("#e56b62")
			theme_title = "ROYAL BOMB"
		"royal_murder_mystery":
			theme_color = Color("#9a82d8")
			theme_title = "MURDER MYSTERY"
		"royal_dice":
			theme_color = Color("#72bd91")
			theme_title = "ROYAL DICE"
		"guess_who":
			theme_color = Color("#65c8d0")
			theme_title = "GUESS WHO"
	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 15.0
	floor_mesh.bottom_radius = 15.0
	floor_mesh.height = 0.5
	floor_mesh.radial_segments = 48
	floor.mesh = floor_mesh
	floor.position.y = -0.6
	floor.material_override = _material(Color("#263c4b").lerp(theme_color, 0.10), 0.78, 0.18)
	arena.add_child(floor)
	var floor_body := StaticBody3D.new()
	var floor_hit := CollisionShape3D.new()
	var floor_shape := CylinderShape3D.new()
	floor_shape.radius = 15.0
	floor_shape.height = 0.5
	floor_hit.shape = floor_shape
	floor_hit.position.y = -0.6
	floor_body.add_child(floor_hit)
	arena.add_child(floor_body)
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.35
		pillar_mesh.bottom_radius = 0.65
		pillar_mesh.height = 4.0
		pillar_mesh.radial_segments = 8
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 13.0, 1.4, sin(angle) * 13.0)
		pillar.material_override = _material(Color("#8b7048"), 0.38, 0.32)
		arena.add_child(pillar)
	# Reference-driven arena dressing: layered floor inlays and distinct themed centerpiece props.
	var inner_ring := MeshInstance3D.new()
	var inner_ring_mesh := TorusMesh.new()
	inner_ring_mesh.inner_radius = 8.6
	inner_ring_mesh.outer_radius = 9.15
	inner_ring.mesh = inner_ring_mesh
	inner_ring.position.y = -0.22
	inner_ring.rotation_degrees.x = 90.0
	inner_ring.material_override = _material(theme_color.lightened(0.18), 0.22, 0.48)
	arena.add_child(inner_ring)
	var outer_ring := MeshInstance3D.new()
	var outer_ring_mesh := TorusMesh.new()
	outer_ring_mesh.inner_radius = 11.8
	outer_ring_mesh.outer_radius = 12.15
	outer_ring.mesh = outer_ring_mesh
	outer_ring.position.y = -0.18
	outer_ring.rotation_degrees.x = 90.0
	outer_ring.material_override = _material(Color("#d6b66c"), 0.3, 0.62)
	arena.add_child(outer_ring)
	# Four low display pylons with game-specific sculptural accents.
	for prop_index in range(4):
		var prop_angle := TAU * float(prop_index) / 4.0
		var prop := Node3D.new()
		prop.position = Vector3(cos(prop_angle) * 8.2, 0.0, sin(prop_angle) * 8.2)
		prop.rotation.y = -prop_angle
		arena.add_child(prop)
		var base_prop := MeshInstance3D.new()
		var base_prop_mesh := CylinderMesh.new()
		base_prop_mesh.top_radius = 0.46
		base_prop_mesh.bottom_radius = 0.62
		base_prop_mesh.height = 0.65
		base_prop_mesh.radial_segments = 10
		base_prop.mesh = base_prop_mesh
		base_prop.position.y = 0.32
		base_prop.material_override = _material(Color("#d6b66c"), 0.32, 0.55)
		prop.add_child(base_prop)
		var prop_shape := MeshInstance3D.new()
		if _royal_game_id == "royal_dice":
			var die_mesh := BoxMesh.new()
			die_mesh.size = Vector3(0.58, 0.58, 0.58)
			prop_shape.mesh = die_mesh
		elif _royal_game_id == "royal_murder_mystery":
			var book_mesh := BoxMesh.new()
			book_mesh.size = Vector3(0.55, 0.75, 0.18)
			prop_shape.mesh = book_mesh
		elif _royal_game_id == "royal_bomb":
			var orb_mesh := SphereMesh.new()
			orb_mesh.radius = 0.4
			orb_mesh.height = 0.8
			prop_shape.mesh = orb_mesh
		else:
			var bust_mesh := SphereMesh.new()
			bust_mesh.radius = 0.42
			bust_mesh.height = 0.84
			prop_shape.mesh = bust_mesh
		prop_shape.position.y = 1.0
		prop_shape.material_override = _material(theme_color.lightened(0.32), 0.22, 0.35)
		prop.add_child(prop_shape)
	# A tall, game-specific landmark makes each arena readable at a distance.
	var landmark := MeshInstance3D.new()
	if _royal_game_id == "royal_dice":
		var landmark_mesh := BoxMesh.new()
		landmark_mesh.size = Vector3(1.15, 3.2, 1.15)
		landmark.mesh = landmark_mesh
	elif _royal_game_id == "royal_murder_mystery":
		var landmark_mesh := CylinderMesh.new()
		landmark_mesh.top_radius = 0.0
		landmark_mesh.bottom_radius = 1.0
		landmark_mesh.height = 3.2
		landmark.mesh = landmark_mesh
	elif _royal_game_id == "royal_bomb":
		var landmark_mesh := SphereMesh.new()
		landmark_mesh.radius = 1.15
		landmark_mesh.height = 2.3
		landmark.mesh = landmark_mesh
	else:
		var landmark_mesh := PrismMesh.new()
		landmark_mesh.size = Vector3(2.0, 3.0, 2.0)
		landmark.mesh = landmark_mesh
	landmark.position = Vector3(0.0, 2.5, 0.0)
	landmark.material_override = _material(theme_color, 0.22, 0.5)
	arena.add_child(landmark)
	var landmark_glow := OmniLight3D.new()
	landmark_glow.position = Vector3(0.0, 3.2, 0.0)
	landmark_glow.light_color = theme_color
	landmark_glow.light_energy = 1.1
	landmark_glow.omni_range = 9.0
	arena.add_child(landmark_glow)

	var centerpiece := MeshInstance3D.new()
	var center_mesh := TorusMesh.new()
	center_mesh.inner_radius = 3.4
	center_mesh.outer_radius = 3.7
	centerpiece.mesh = center_mesh
	centerpiece.position.y = 0.1
	centerpiece.rotation_degrees.x = 90
	centerpiece.material_override = _material(theme_color, 0.24, 0.42)
	arena.add_child(centerpiece)
	var crest := Label3D.new()
	crest.text = theme_title
	crest.font_size = 48
	crest.pixel_size = 0.006
	crest.position = Vector3(0, 2.8, -5.4)
	crest.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	crest.modulate = theme_color.lightened(0.45)
	crest.outline_size = 8
	crest.outline_modulate = Color("#101d2b")
	arena.add_child(crest)
	# Four themed beacon plinths visually distinguish each royal arena.
	for beacon_index in range(4):
		var beacon_angle := TAU * float(beacon_index) / 4.0 + PI * 0.25
		var beacon := Node3D.new()
		beacon.position = Vector3(cos(beacon_angle) * 5.4, 0.0, sin(beacon_angle) * 5.4)
		arena.add_child(beacon)
		var plinth := MeshInstance3D.new()
		var plinth_mesh := CylinderMesh.new()
		plinth_mesh.top_radius = 0.58
		plinth_mesh.bottom_radius = 0.78
		plinth_mesh.height = 0.52
		plinth.mesh = plinth_mesh
		plinth.material_override = _material(Color("#8b7048"), 0.35, 0.38)
		beacon.add_child(plinth)
		var beacon_ring := MeshInstance3D.new()
		var beacon_ring_mesh := TorusMesh.new()
		beacon_ring_mesh.inner_radius = 0.40
		beacon_ring_mesh.outer_radius = 0.48
		beacon_ring.mesh = beacon_ring_mesh
		beacon_ring.position.y = 0.36
		beacon_ring.material_override = _material(theme_color, 0.25, 0.32)
		beacon.add_child(beacon_ring)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 8, 0)
	light.light_color = theme_color
	light.light_energy = 1.5
	light.omni_range = 28.0
	arena.add_child(light)


func _attach_royal_game_hud() -> void:
	var camera := _player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if camera == null:
		return
	_royal_game_hud = Node3D.new()
	_royal_game_hud.name = "RoyalGameSpatialHUD"
	camera.add_child(_royal_game_hud)
	_royal_game_hud.position = Vector3(0, 0, -4.2)


func _clear_royal_game_panel() -> void:
	if is_instance_valid(_royal_game_panel):
		_royal_game_panel.queue_free()
	_royal_game_panel = Node3D.new()
	_royal_game_panel.name = "RoyalGamePanel3D"
	_royal_game_hud.add_child(_royal_game_panel)
	var backing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(6.4, 5.3, 0.18)
	backing.mesh = box
	backing.material_override = _material(Color("#10243a"), 0.25, 0.34)
	_royal_game_panel.add_child(backing)

	# Premium royal frame: layered brass rails and a soft cyan inner accent.
	for edge in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(6.42, 0.075, 0.12) if edge > 0.0 else Vector3(0.075, 5.32, 0.12)
		rail.mesh = rail_mesh
		rail.position = Vector3(0, edge * 2.62, -0.14) if edge > 0.0 else Vector3(edge * 3.16, 0, -0.14)
		rail.material_override = _material(Color("#d7b36c"), 0.28, 0.58)
		_royal_game_panel.add_child(rail)

	var accent := MeshInstance3D.new()
	var accent_mesh := BoxMesh.new()
	accent_mesh.size = Vector3(3.0, 0.035, 0.08)
	accent.mesh = accent_mesh
	accent.position = Vector3(0, 1.88, -0.15)
	var accent_material := _material(Color("#6cb5bd"), 0.25, 0.35)
	accent_material.emission_enabled = true
	accent_material.emission = Color("#6cb5bd")
	accent_material.emission_energy_multiplier = 0.45
	accent.material_override = accent_material
	_royal_game_panel.add_child(accent)

	var title := Label3D.new()
	title.text = _royal_game_title()
	title.font_size = 38
	title.pixel_size = 0.0034
	title.position = Vector3(0, 2.18, -0.12)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color("#f3d99a")
	_royal_game_panel.add_child(title)
	_royal_game_status = Label3D.new()
	_royal_game_status.font_size = 19
	_royal_game_status.pixel_size = 0.0032
	_royal_game_status.position = Vector3(0, 1.45, -0.12)
	_royal_game_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_royal_game_status.modulate = Color("#e5edf4")
	_royal_game_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_royal_game_panel.add_child(_royal_game_status)
	_add_royal_button("KELUAR", Vector3(0, -2.28, -0.24), "exit", Vector3(2.0, 0.48, 0.16), Color("#7d493d"))


func _royal_game_title() -> String:
	match _royal_game_id:
		"guess_who": return "GUESS WHO? • MYSTERY MEMBER"
		"royal_bomb": return "ROYAL BOMB • HONEY BLAST"
		"royal_murder_mystery": return "ROYAL MURDER MYSTERY"
		"royal_dice": return "ROYAL DICE • KINGDOM OF FORTUNE"
	return "ROYAL GAME"


func _add_royal_button(label_text: String, pos: Vector3, action: String, size: Vector3 = Vector3(2.4, 0.52, 0.16), tint: Color = Color("#315b70")) -> void:
	var area := Area3D.new()
	area.name = "RoyalAction_" + str(_royal_game_panel.get_child_count())
	area.position = pos
	area.input_ray_pickable = true
	area.collision_layer = 64
	area.collision_mask = 0
	area.set_meta("royal_action", action)
	var hit := CollisionShape3D.new()
	var hit_shape := BoxShape3D.new()
	hit_shape.size = Vector3(size.x, size.y, 0.42)
	hit.shape = hit_shape
	area.add_child(hit)
	var rim := MeshInstance3D.new()
	var rim_box := BoxMesh.new()
	rim_box.size = Vector3(size.x + 0.075, size.y + 0.075, size.z * 0.72)
	rim.mesh = rim_box
	rim.material_override = _material(Color("#b9904e"), 0.3, 0.52)
	area.add_child(rim)

	var mesh := MeshInstance3D.new()
	var visual := BoxMesh.new()
	visual.size = Vector3(size.x - 0.035, size.y - 0.035, size.z)
	mesh.mesh = visual
	mesh.material_override = _material(tint, 0.28, 0.2)
	mesh.position.z = -0.035
	area.add_child(mesh)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 19 if label_text.length() < 18 else 15
	label.pixel_size = 0.003
	label.position.z = -0.12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	area.add_child(label)
	_royal_game_panel.add_child(area)


func _unhandled_royal_game_input(event: InputEvent) -> void:
	if _royal_game_id.is_empty() or not is_instance_valid(_royal_game_hud):
		return
	var pressed: bool = event is InputEventScreenTouch and event.pressed
	pressed = pressed or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	var camera := _player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if camera == null:
		return
	var origin := camera.project_ray_origin(event.position)
	var direction := camera.project_ray_normal(event.position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 12.0)
	query.collide_with_areas = true
	query.collision_mask = 64
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is Area3D and collider.has_meta("royal_action"):
		_handle_royal_action(str(collider.get_meta("royal_action")))
		get_viewport().set_input_as_handled()


func _handle_royal_action(action: String) -> void:
	if not _royal_game_active and action != "exit":
		return
	if action == "exit":
		exit_royal_game()
		return
	match _royal_game_id:
		"guess_who": _guess_who_action(action)
		"royal_bomb": _royal_bomb_action(action)
		"royal_murder_mystery": _murder_action(action)
		"royal_dice": _dice_action(action)


func _start_guess_who() -> void:
	var pool := GUESS_WHO_ROSTER.duplicate(true)
	pool.shuffle()
	_royal_game_state = {"pool":pool,"index":0,"score":0,"correct":0,"wrong":0,"hints":0,"clue":2,"seconds":25,"finished":false}
	_show_guess_who_question()


func _show_guess_who_question() -> void:
	_clear_royal_game_panel()
	var q: Dictionary = _royal_game_state.pool[_royal_game_state.index]
	_royal_game_state.seconds = 25
	_royal_game_state.clue = 2
	_royal_game_status.text = "SOAL %d/%d   •   SKOR %d   •   25 DETIK\nKategori: %s\nPetunjuk 1: %s\nPetunjuk 2: %s" % [_royal_game_state.index + 1, _royal_game_state.pool.size(), _royal_game_state.score, q.category, q.clues[0], q.clues[1]]
	var opts: Array = q.options.duplicate()
	opts.shuffle()
	for i in range(opts.size()):
		_add_royal_button(str(opts[i]), Vector3(-1.55 + float(i % 2) * 3.1, 0.15 - float(i / 2) * 0.72, -0.24), "guess:" + str(opts[i]), Vector3(2.7, 0.48, 0.16))
	_add_royal_button("BUKA PETUNJUK (-5)", Vector3(0, -1.45, -0.24), "hint", Vector3(2.7, 0.46, 0.16), Color("#8a6334"))
	_add_royal_button("LEWATI SOAL", Vector3(0, -1.92, -0.24), "skip", Vector3(2.3, 0.42, 0.16))


func _guess_who_action(action: String) -> void:
	if action == "hint":
		var q: Dictionary = _royal_game_state.pool[_royal_game_state.index]
		var clue_index: int = int(_royal_game_state.clue)
		# Only charge for an actual clue; repeated taps after the clue limit
		# must not drain points or inflate the hint counter.
		if clue_index >= q.clues.size():
			_royal_game_status.text += "\nSem petunjuk tambahan."
			return
		_royal_game_state.clue = clue_index + 1
		_royal_game_state.hints += 1
		_royal_game_state.score = maxi(0, int(_royal_game_state.score) - 5)
		_royal_game_status.text += "\nPetunjuk %d: %s" % [clue_index + 1, q.clues[clue_index]]
		return
	if action == "skip":
		_royal_game_state.wrong += 1
		_guess_who_next()
		return
	if action.begins_with("guess:"):
		var q: Dictionary = _royal_game_state.pool[_royal_game_state.index]
		if action.trim_prefix("guess:") == str(q.name):
			_royal_game_state.correct += 1
			_royal_game_state.score += maxi(5, 10 + int(_royal_game_state.seconds) / 3)
			_royal_game_status.text += "\n✓ JAWABAN TEPAT: " + str(q.name)
		else:
			_royal_game_state.wrong += 1
			_royal_game_status.text += "\n✕ Jawaban benar: " + str(q.name)
		_guess_who_next()


func _guess_who_next() -> void:
	_royal_game_state.index += 1
	if _royal_game_state.index >= _royal_game_state.pool.size():
		_finish_royal_game("GUESS WHO SELESAI\nSkor: %d\nBenar: %d   Salah: %d\nPetunjuk dipakai: %d" % [_royal_game_state.score, _royal_game_state.correct, _royal_game_state.wrong, _royal_game_state.hints])
	else:
		_show_guess_who_question()


func _start_royal_bomb() -> void:
	_royal_game_state = {"round":1,"score":0,"defuse":2,"armed_defuse":false,"bombs":3,"alive":true,"draws":0,"deck":_royal_game_rng.randi_range(1, 100)}
	_show_royal_bomb()


func _show_royal_bomb() -> void:
	_clear_royal_game_panel()
	_royal_game_status.text = "BERTAHAN DARI ROYAL BOMB!\nGiliran: %d/12   •   Skor: %d\nHoney Defuse: %d   •   Aktif: %s   •   Bom tersisa: %d\nAmbil kartu, siapkan Defuse, atau lewati giliran." % [_royal_game_state.round, _royal_game_state.score, _royal_game_state.defuse, ("YA" if bool(_royal_game_state.armed_defuse) else "TIDAK"), _royal_game_state.bombs]
	_add_royal_button("AMBIL KARTU", Vector3(-1.55, 0.05, -0.24), "draw", Vector3(2.5, 0.62, 0.16), Color("#a77a36"))
	_add_royal_button("PAKAI HONEY DEFUSE", Vector3(1.55, 0.05, -0.24), "defuse", Vector3(2.5, 0.62, 0.16))
	_add_royal_button("SKIP GILIRAN", Vector3(0, -0.82, -0.24), "skip", Vector3(2.5, 0.56, 0.16))


func _royal_bomb_action(action: String) -> void:
	if action == "defuse":
		if int(_royal_game_state.defuse) > 0 and not bool(_royal_game_state.armed_defuse):
			_royal_game_state.defuse -= 1
			_royal_game_state.armed_defuse = true
			_royal_game_status.text = "HONEY DEFUSE aktif. Bom berikutnya akan dinetralkan."
		else:
			_royal_game_status.text = "Tidak ada Honey Defuse tersisa."
		return
	if action == "skip":
		# Skipping a turn still advances the simulated table, preventing a
		# player from indefinitely bypassing the round's bot progression.
		if _royal_game_rng.randf() > 0.38:
			_royal_game_state.score += 1
			_royal_game_status.text = "Giliran dilewati. Bot lawan bertahan; +1 bonus simulasi."
		else:
			_royal_game_state.bombs = maxi(0, int(_royal_game_state.bombs) - 1)
			_royal_game_status.text = "Giliran dilewati. Satu bot lawan tereliminasi."
		_royal_game_state.round += 1
	elif action == "draw":
		_royal_game_state.draws += 1
		var card_roll := _royal_game_rng.randi_range(1, 100)
		if card_roll <= 24:
			if bool(_royal_game_state.armed_defuse):
				_royal_game_state.armed_defuse = false
				_royal_game_state.score += 3
				_royal_game_status.text = "💣 ROYAL BOMB! Honey Defuse yang kamu siapkan berhasil menetralkan bom."
			else:
				_royal_game_state.alive = false
				_finish_royal_game("TERELIMINASI OLEH ROYAL BOMB\nSkor akhir: %d" % _royal_game_state.score)
				return
		else:
			_royal_game_state.score += 1
			_royal_game_status.text = "🍯 HONEY DROP! Kamu mendapat 1 poin."
		# Simulated bot table resolves its turn after each player draw.
		if _royal_game_rng.randf() > 0.38:
			_royal_game_state.score += 1
			_royal_game_status.text += "\nBot lawan terkena kartu aman. +1 bonus bertahan."
		else:
			_royal_game_status.text += "\nSatu bot lawan tereliminasi!"
			_royal_game_state.bombs = maxi(0, int(_royal_game_state.bombs) - 1)
		_royal_game_state.round += 1
	if int(_royal_game_state.round) > 12 or int(_royal_game_state.bombs) <= 0:
		_finish_royal_game("ROYAL BOMB BERAKHIR\nSkor bertahan: %d\nKartu diambil: %d" % [_royal_game_state.score, _royal_game_state.draws])
	else:
		_show_royal_bomb()


func _start_murder_mystery() -> void:
	var cases := MURDER_CASES.duplicate(true)
	cases.shuffle()
	_royal_game_state = {"cases":cases,"index":0,"score":0,"correct":0,"wrong":0}
	_show_murder_case()


func _show_murder_case() -> void:
	_clear_royal_game_panel()
	var c: Dictionary = _royal_game_state.cases[_royal_game_state.index]
	_royal_game_status.text = "KASUS %d/3  •  DETEKTIF KERAJAAN\n%s\n\nBUKTI: %s\n\nPilih tersangka yang paling mungkin." % [_royal_game_state.index + 1, c.title, c.clue]
	var opts: Array = c.options.duplicate()
	opts.shuffle()
	for i in range(opts.size()):
		# Compact 2-column answer layout keeps case choices reachable in the mobile HUD.
		var column := i % 2
		var row := int(i / 2)
		var x := -1.35 if column == 0 else 1.35
		var y := 0.12 - float(row) * 0.72
		_add_royal_button(str(opts[i]), Vector3(x, y, -0.24), "suspect:" + str(opts[i]), Vector3(2.55, 0.5, 0.16))


func _murder_action(action: String) -> void:
	if not action.begins_with("suspect:"):
		return
	var c: Dictionary = _royal_game_state.cases[_royal_game_state.index]
	if action.trim_prefix("suspect:") == str(c.answer):
		_royal_game_state.correct += 1
		_royal_game_state.score += 100
		_royal_game_status.text += "\n✓ KASUS TERPECAHKAN! +100"
	else:
		_royal_game_state.wrong += 1
		_royal_game_status.text += "\n✕ BUKTI TIDAK COCOK. Pelaku: " + str(c.answer)
	_royal_game_state.index += 1
	if _royal_game_state.index >= _royal_game_state.cases.size():
		_finish_royal_game("HASIL PENYELIDIKAN\nSkor: %d\nKasus terpecahkan: %d/3\nKesalahan: %d" % [_royal_game_state.score, _royal_game_state.correct, _royal_game_state.wrong])
	else:
		_show_murder_case()


func _start_royal_dice() -> void:
	_royal_game_state = {"round":1,"rounds":5,"score":0,"bot_score":0,"last_roll":0,"card":"ROYAL BOOST"}
	_show_royal_dice()


func _show_royal_dice() -> void:
	_clear_royal_game_panel()
	_royal_game_status.text = "RONDE %d/5\nKamu: %d poin   •   Royal Bot: %d poin\nKartu aktif: %s\nLempar dadu untuk menentukan hasil ronde." % [_royal_game_state.round, _royal_game_state.score, _royal_game_state.bot_score, _royal_game_state.card]
	_add_royal_button("LEMPAR DADU", Vector3(0, 0.1, -0.24), "roll", Vector3(3.0, 0.72, 0.16), Color("#a77a36"))
	var cards := ["ROYAL BOOST","HONEY SHIELD","SHADOW TRAP","LUCKY CROWN"]
	# Use a 2x2 grid instead of a single horizontal strip: the previous
	# arrangement pushed the fourth choice beyond the panel's visible bounds.
	for i in range(cards.size()):
		var column := i % 2
		var row := int(i / 2)
		var x := -1.35 if column == 0 else 1.35
		var y := -0.92 if row == 0 else -1.48
		_add_royal_button(cards[i], Vector3(x, y, -0.24), "card:" + cards[i], Vector3(2.45, 0.46, 0.16))


func _dice_action(action: String) -> void:
	if action.begins_with("card:"):
		_royal_game_state.card = action.trim_prefix("card:")
		_royal_game_status.text = "Kartu dipilih: " + str(_royal_game_state.card) + "\nLempar dadu untuk memakai efek kartu."
		return
	if action != "roll":
		return
	var roll := _royal_game_rng.randi_range(1, 6)
	var bot_roll := _royal_game_rng.randi_range(1, 6)
	var card := str(_royal_game_state.card)
	var bonus := 0
	if card == "ROYAL BOOST": bonus = 2
	elif card == "HONEY SHIELD": bonus = 1
	elif card == "SHADOW TRAP": bot_roll = maxi(1, bot_roll - 2)
	elif card == "LUCKY CROWN": roll = mini(6, roll + 1)
	var total := roll + bonus
	if total > bot_roll:
		_royal_game_state.score += 2
	elif total == bot_roll:
		_royal_game_state.score += 1
	else:
		_royal_game_state.bot_score += 2
	_royal_game_status.text = "🎲 DADU KAMU: %d (+%d)  •  BOT: %d\nKartu: %s\nSkor: %d — %d" % [roll, bonus, bot_roll, card, _royal_game_state.score, _royal_game_state.bot_score]
	_royal_game_state.round += 1
	_royal_game_state.card = "ROYAL BOOST"
	if int(_royal_game_state.round) > 5:
		var outcome := "KAMU MENANG!" if int(_royal_game_state.score) > int(_royal_game_state.bot_score) else ("SERI!" if int(_royal_game_state.score) == int(_royal_game_state.bot_score) else "ROYAL BOT MENANG!")
		_finish_royal_game("ROYAL DICE SELESAI\n%s\nSkor akhir: %d — %d" % [outcome, _royal_game_state.score, _royal_game_state.bot_score])
	else:
		_show_royal_dice()


func _finish_royal_game(summary: String) -> void:
	_clear_royal_game_panel()
	_royal_game_status.text = summary + "\n\nTekan KELUAR untuk kembali ke Game Center."
	_royal_game_active = false


func exit_royal_game() -> void:
	if is_instance_valid(_player):
		_player.velocity = Vector3.ZERO
		_player.global_position = _royal_game_return_position
		_player.set_physics_process(true)
	if is_instance_valid(_royal_game_hud):
		_royal_game_hud.queue_free()
	_royal_game_hud = null
	var arena := get_node_or_null("RoyalGameArena_" + _royal_game_id)
	if arena != null:
		arena.queue_free()
	_royal_game_active = false
	_royal_game_id = ""
	_royal_game_state.clear()
	_player = null
