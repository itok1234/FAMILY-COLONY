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
var _arena: Node3D
var _hud: CanvasLayer
var _status: Label
var _return_button: Button
var _rng := RandomNumberGenerator.new()
const TARGET_COUNT := 12
const ARENA_ORIGIN := Vector3(0, 0, 140)


func _ready() -> void:
	_rng.randomize()
	_build_arena()
	_build_entry_portal()
	_build_hud()


func _process(delta: float) -> void:
	if not _active or not is_instance_valid(_player):
		return
	_time_left = maxf(0.0, _time_left - delta)
	for target in _targets.duplicate():
		if is_instance_valid(target) and _player.global_position.distance_to(target.global_position) < 1.55:
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
	_active = true
	_reset_targets()
	_arena.visible = true
	_player.velocity = Vector3.ZERO
	_player.global_position = ARENA_ORIGIN + Vector3(0, 1.1, 8)
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
	_hud = CanvasLayer.new()
	_hud.name = "HoneyHuntHUD"
	_hud.layer = 25
	add_child(_hud)

	_status = Label.new()
	_status.anchor_left = 0.08
	_status.anchor_right = 0.72
	_status.anchor_top = 0.04
	_status.anchor_bottom = 0.13
	_status.add_theme_font_size_override("font_size", 20)
	_status.add_theme_color_override("font_color", Color(1.0, 0.9, 0.62))
	_status.add_theme_color_override("font_shadow_color", Color(0.05, 0.06, 0.08, 1))
	_status.add_theme_constant_override("shadow_offset_x", 2)
	_status.add_theme_constant_override("shadow_offset_y", 2)
	_status.visible = false
	_hud.add_child(_status)

	_return_button = Button.new()
	_return_button.text = "KELUAR MINI-GAME"
	_return_button.anchor_left = 0.68
	_return_button.anchor_right = 0.96
	_return_button.anchor_top = 0.84
	_return_button.anchor_bottom = 0.94
	_return_button.custom_minimum_size = Vector2(0, 48)
	_return_button.pressed.connect(exit_minigame)
	_return_button.visible = false
	_hud.add_child(_return_button)


func _reset_targets() -> void:
	for target in _targets:
		if is_instance_valid(target):
			target.queue_free()
	_targets.clear()
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
