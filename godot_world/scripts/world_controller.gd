extends Node3D

const MAIN_HUB_SCENE: PackedScene = preload("res://scenes/main_hub_3d.tscn")
## FAMILY COLONY world scene controller.
## Android gameplay is locked until the existing app session is verified by Supabase.

@export var player_path: NodePath = NodePath("Player")
@onready var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
@onready var session_client: Node = get_node_or_null("WorldSessionClient")

var _android_session_required := false
var _gate_layer: Node3D
var _gate_status: Label3D
var _world_exit_layer: Node3D
var _is_exiting := false
var _main_hub: Node3D


func _ready() -> void:
	if player == null:
		push_warning("FAMILY COLONY: Player node is not assigned.")
		return

	_android_session_required = OS.has_feature("android")
	if not _android_session_required:
		return

	_set_player_enabled(false)
	_build_session_gate()

	if session_client == null:
		_set_gate_status("Penghubung sesi belum tersedia. Silakan kembali ke aplikasi.")
		return

	session_client.session_verified.connect(_on_session_verified)
	session_client.session_rejected.connect(_on_session_rejected)

	if not bool(session_client.call("has_native_bridge")):
		_on_session_rejected("native_session_bridge_missing")
		return

	var previous_error := str(session_client.call("get_last_error_code"))
	if not previous_error.is_empty():
		_on_session_rejected(previous_error)
	else:
		_set_gate_status("Memverifikasi akun FAMILY COLONY...")


func _process(_delta: float) -> void:
	if is_instance_valid(_world_exit_layer) and player != null:
		var forward := -player.global_transform.basis.z
		_world_exit_layer.global_position = player.global_position + Vector3.UP * 1.8 + forward * 2.6


func _unhandled_input(event: InputEvent) -> void:
	if _android_session_required and event.is_action_pressed("ui_cancel"):
		_return_to_app()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.pressed:
		_pick_spatial_action(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_spatial_action(event.position)


func _pick_spatial_action(screen_position: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 30.0)
	query.collide_with_areas = true
	query.collision_mask = 8
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is Area3D and collider.has_meta("return_to_app"):
		_return_to_app()


func _build_session_gate() -> void:
	# Session status and return action are spatial 3D objects, not a flat overlay.
	_gate_layer = Node3D.new()
	_gate_layer.name = "SpatialSessionVerificationGate"
	_gate_layer.position = Vector3(0, 3.0, -4.0)
	add_child(_gate_layer)
	var backing := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(5.2, 2.8, 0.16)
	backing.mesh = panel_mesh
	var panel_material := StandardMaterial3D.new()
	panel_material.albedo_color = Color(0.025, 0.06, 0.11, 0.94)
	panel_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_material.metallic = 0.28
	panel_material.roughness = 0.3
	panel_material.emission_enabled = true
	panel_material.emission = Color("#1d526e")
	panel_material.emission_energy_multiplier = 0.25
	backing.material_override = panel_material
	_gate_layer.add_child(backing)
	var title := Label3D.new()
	title.text = "FAMILY COLONY"
	title.font_size = 48
	title.pixel_size = 0.004
	title.position = Vector3(0, 0.82, -0.11)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color("#f3d99a")
	_gate_layer.add_child(title)
	_gate_status = Label3D.new()
	_gate_status.text = "Memverifikasi akun anggota..."
	_gate_status.font_size = 23
	_gate_status.pixel_size = 0.004
	_gate_status.position = Vector3(0, 0.12, -0.11)
	_gate_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_gate_status.modulate = Color("#e5edf4")
	_gate_layer.add_child(_gate_status)
	var return_area := Area3D.new()
	return_area.name = "ReturnToAppSpatialAction"
	return_area.position = Vector3(0, -0.82, -0.18)
	return_area.input_ray_pickable = true
	return_area.collision_layer = 8
	return_area.collision_mask = 0
	return_area.set_meta("return_to_app", true)
	var return_collision := CollisionShape3D.new()
	var return_shape := BoxShape3D.new()
	return_shape.size = Vector3(2.6, 0.55, 0.4)
	return_collision.shape = return_shape
	return_area.add_child(return_collision)
	var return_mesh := MeshInstance3D.new()
	var return_box := BoxMesh.new()
	return_box.size = Vector3(2.55, 0.5, 0.2)
	return_mesh.mesh = return_box
	return_mesh.material_override = _spatial_material(Color("#a77a36"))
	return_area.add_child(return_mesh)
	var return_label := Label3D.new()
	return_label.text = "KEMBALI KE APLIKASI"
	return_label.font_size = 20
	return_label.pixel_size = 0.004
	return_label.position.z = -0.13
	return_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return_label.modulate = Color("#ffffff")
	return_area.add_child(return_label)
	_gate_layer.add_child(return_area)


func _set_gate_status(message: String) -> void:
	if is_instance_valid(_gate_status):
		_gate_status.text = message


func _on_session_verified(_member: Dictionary, permissions: Dictionary) -> void:
	if not bool(permissions.get("can_enter_world", false)):
		_on_session_rejected("world_access_denied")
		return
	var avatar := player.get_node_or_null("AvatarVisual")
	if avatar != null and avatar.has_method("set_display_name"):
		avatar.call("set_display_name", str(_member.get("name", "Colony Member")))
	# After server verification, enter the native spatial 3D hub first.
	# The existing WebView login/session remains the source of member identity.
	_set_player_enabled(false)
	var mobile_hud := get_node_or_null("MobileHUD")
	if mobile_hud != null:
		mobile_hud.visible = false
	_main_hub = MAIN_HUB_SCENE.instantiate() as Node3D
	if _main_hub != null:
		_main_hub.name = "MainHub3D"
		_main_hub.destination_requested.connect(_on_hub_destination_requested)
		add_child(_main_hub)
	if is_instance_valid(_gate_layer):
		_gate_layer.queue_free()
	_gate_layer = null


func _on_hub_destination_requested(destination_id: String) -> void:
	if destination_id != "world":
		return
	if is_instance_valid(_main_hub):
		_main_hub.queue_free()
	_main_hub = null
	var mobile_hud := get_node_or_null("MobileHUD")
	if mobile_hud != null:
		mobile_hud.visible = true
	_set_player_enabled(true)
	var player_camera := player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if player_camera != null:
		player_camera.current = true
	_build_world_exit_button()


func _on_session_rejected(error_code: String) -> void:
	_set_player_enabled(false)
	_set_gate_status(
		"Sesi belum dapat diverifikasi. "
		+ error_code.replace("_", " ")
		+ ". Silakan kembali ke aplikasi dan masuk lagi."
	)


func _build_world_exit_button() -> void:
	if is_instance_valid(_world_exit_layer):
		return
	_world_exit_layer = Node3D.new()
	_world_exit_layer.name = "SpatialWorldExitAction"
	var action := Area3D.new()
	action.name = "ReturnToAppSpatialAction"
	action.input_ray_pickable = true
	action.collision_layer = 8
	action.collision_mask = 0
	action.set_meta("return_to_app", true)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.85
	collision.shape = shape
	action.add_child(collision)
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.72
	orb_mesh.height = 1.44
	orb.mesh = orb_mesh
	orb.material_override = _spatial_material(Color("#b58a45"))
	action.add_child(orb)
	var label := Label3D.new()
	label.text = "KEMBALI"
	label.font_size = 22
	label.pixel_size = 0.004
	label.position.y = 0.95
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#fff1cc")
	action.add_child(label)
	_world_exit_layer.add_child(action)
	add_child(_world_exit_layer)


func _spatial_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.25
	material.roughness = 0.32
	material.emission_enabled = true
	material.emission = color.darkened(0.28)
	material.emission_energy_multiplier = 0.22
	return material


func _set_player_enabled(enabled: bool) -> void:
	if player == null:
		return
	player.set_physics_process(enabled)
	player.set_process_input(enabled)
	player.set_process_unhandled_input(enabled)

	var camera_pivot := player.get_node_or_null("CameraPivot")
	if camera_pivot != null:
		camera_pivot.set_process(enabled)
		camera_pivot.set_process_input(enabled)

	var interaction := player.get_node_or_null("InteractionController")
	if interaction != null:
		interaction.set_process(enabled)
		interaction.set_process_input(enabled)
		interaction.set_process_unhandled_input(enabled)


func _return_to_app() -> void:
	if _is_exiting:
		return
	_is_exiting = true
	_set_player_enabled(false)
	# Release world resources before handing control back to the Android home UI.
	var multiplayer_manager := get_node_or_null("MultiplayerManager")
	if multiplayer_manager != null and multiplayer_manager.has_method("leave_game"):
		multiplayer_manager.call("leave_game")
	var session := get_node_or_null("WorldSessionClient")
	if session != null and session.has_method("clear_session"):
		session.call("clear_session")
	var audio_settings := get_node_or_null("AudioStudioSettings")
	if audio_settings != null:
		_stop_audio_players(audio_settings)
	if Engine.has_singleton("FamilyColonyBridge"):
		var bridge: Object = Engine.get_singleton("FamilyColonyBridge")
		# Android JNISingleton does not expose Java plugin methods through has_method().
		bridge.call("requestExitToApp")
		return
	get_tree().quit()


func _stop_audio_players(node: Node) -> void:
	for child in node.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
			child.stop()
		_stop_audio_players(child)
