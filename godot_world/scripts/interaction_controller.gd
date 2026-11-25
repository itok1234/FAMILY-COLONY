extends Node
## Contextual interaction controller with compact radial-style action menu.
## This is local presentation/gameplay scaffolding; authoritative multiplayer checks are not implemented.

@export var camera_path: NodePath = NodePath("../CameraPivot/Camera3D")
@export var interaction_distance: float = 5.0
@onready var camera: Camera3D = get_node_or_null(camera_path) as Camera3D

var _target: Node
var _prompt: Label3D
var _result: Label3D
var _action_button: Area3D
var _menu: Node3D
var _menu_buttons: Array[Area3D] = []
var _hud_root: Node3D
var _menu_button_by_action: Dictionary = {}
var _refresh_timer := 0.0
var _result_generation := 0

func _ready() -> void:
	_build_hud()
	if camera == null:
		push_warning("FAMILY COLONY: Interaction camera is not assigned.")

func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.08
		_refresh_target()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		var player := get_parent()
		if player.has_method("is_seated") and player.call("is_seated"):
			player.call("set_seated", false)
			_broadcast_social_action("stand")
			_show_result("Kamu berdiri kembali.")
		else:
			_open_action_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and _menu.visible:
		_menu.visible = false
		_action_button.visible = true
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.pressed:
		_pick_spatial_control(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_spatial_control(event.position)


func _pick_spatial_control(screen_position: Vector2) -> void:
	if camera == null:
		return
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 12.0)
	query.collide_with_areas = true
	query.collision_mask = 16
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if not (collider is Area3D) or not collider.has_meta("spatial_action"):
		return
	var action := str(collider.get_meta("spatial_action"))
	match action:
		"open":
			_open_action_menu()
		"cancel":
			_menu.visible = false
			_action_button.visible = true
		_:
			_choose_action(action)
	get_viewport().set_input_as_handled()

func _refresh_target() -> void:
	if _menu.visible:
		return
	_target = null
	if camera == null or not is_instance_valid(camera):
		_set_prompt("")
		return
	var origin := camera.global_position
	var endpoint := origin + (-camera.global_basis.z * interaction_distance)
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.collision_mask = 2
	query.collide_with_areas = true
	var player := get_parent()
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider is Node and collider.is_in_group("world_interactable"):
			_target = collider
			var label := "Interaksi"
			if collider.has_method("get_interaction_label"):
				label = str(collider.call("get_interaction_label"))
			_set_prompt(label)
			return
	_set_prompt("")

func _set_prompt(value: String) -> void:
	_prompt.text = value
	_prompt.visible = not value.is_empty()
	_action_button.visible = true

func _open_action_menu() -> void:
	var has_target := _is_target_interactable_and_in_range()
	var available_actions: Array = []
	if has_target:
		available_actions = ["use", "greet", "sit"]
		if _target.has_method("get_available_actions"):
			var configured_actions: Variant = _target.call("get_available_actions")
			if configured_actions is Array:
				available_actions = configured_actions
	else:
		_target = null
		available_actions = ["greet", "sit"]
		var player := get_parent()
		if player.has_method("is_seated") and player.call("is_seated"):
			available_actions.append("stand")
	for action_id in _menu_button_by_action:
		var action_button: Button = _menu_button_by_action[action_id]
		action_button.visible = available_actions.has(action_id)
	if available_actions.is_empty():
		_show_result("Tidak ada aksi yang tersedia.")
		return
	_menu.visible = true
	_prompt.visible = false
	_action_button.visible = false

func _choose_action(action_id: String) -> void:
	_menu.visible = false
	var has_target := _is_target_interactable_and_in_range()
	if not has_target:
		_target = null
		var player := get_parent()
		match action_id:
			"greet":
				var avatar := player.get_node_or_null("AvatarVisual")
				if avatar != null and avatar.has_method("play_action"):
					avatar.call("play_action", "wave")
					_broadcast_social_action("wave")
					_show_result("Kamu melambaikan tangan.")
				else:
					_show_result("Animasi avatar belum tersedia.")
			"sit":
				if player.has_method("set_seated"):
					player.call("set_seated", true)
					_broadcast_social_action("sit")
					_show_result("Kamu duduk.")
			"stand":
				if player.has_method("set_seated"):
					player.call("set_seated", false)
					_broadcast_social_action("stand")
					_show_result("Kamu berdiri kembali.")
			_:
				_show_result("Arahkan kamera ke objek untuk menggunakan interaksi.")
		_action_button.visible = true
		return
	if _target.has_method("get_available_actions"):
		var allowed_actions: Variant = _target.call("get_available_actions")
		if allowed_actions is Array and not allowed_actions.has(action_id):
			_show_result("Aksi tersebut tidak tersedia untuk objek ini.")
			return
	var message := "Aksi selesai."
	if _target.has_method("interact"):
		message = str(_target.call("interact", get_parent(), action_id))
	var avatar := get_parent().get_node_or_null("AvatarVisual")
	if avatar != null and avatar.has_method("play_action"):
		if action_id == "greet":
			avatar.call("play_action", "wave")
			_broadcast_social_action("wave")
		elif action_id == "sit":
			var player := get_parent()
			if player.has_method("set_seated"):
				player.call("set_seated", true)
			else:
				avatar.call("play_action", "sit")
			_broadcast_social_action("sit")
	_show_result(message)
	_target = null
	_set_prompt("")
	_action_button.visible = true

func _build_hud() -> void:
	# Camera-mounted 3D action console; no CanvasLayer, Control or Button nodes.
	if camera == null:
		return
	_hud_root = Node3D.new()
	_hud_root.name = "SpatialInteractionConsole"
	camera.add_child(_hud_root)

	_prompt = Label3D.new()
	_prompt.name = "ContextPrompt3D"
	_prompt.text = ""
	_prompt.font_size = 23
	_prompt.pixel_size = 0.0035
	_prompt.position = Vector3(0, -0.32, -3.0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.modulate = Color("#fff1cc")
	_prompt.outline_size = 7
	_prompt.outline_modulate = Color("#142235")
	_prompt.visible = false
	_hud_root.add_child(_prompt)

	_result = Label3D.new()
	_result.name = "InteractionResult3D"
	_result.font_size = 22
	_result.pixel_size = 0.0035
	_result.position = Vector3(0, 0.38, -3.0)
	_result.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_result.modulate = Color("#ffe3a3")
	_result.outline_size = 7
	_result.outline_modulate = Color("#142235")
	_result.visible = false
	_hud_root.add_child(_result)

	_action_button = _create_spatial_button(_hud_root, "AKSI", Vector3(1.25, -0.62, -2.8), "open", Vector3(0.9, 0.56, 0.16))
	_menu = Node3D.new()
	_menu.name = "SpatialActionMenu"
	_menu.position = Vector3(0, 0, -3.2)
	_menu.visible = false
	_hud_root.add_child(_menu)

	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(3.6, 2.75, 0.12)
	panel.mesh = panel_mesh
	panel.material_override = _spatial_material(Color("#14283d"))
	_menu.add_child(panel)

	var title := Label3D.new()
	title.text = "PILIH AKSI"
	title.font_size = 30
	title.pixel_size = 0.004
	title.position = Vector3(0, 1.02, -0.1)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color("#f3d99a")
	_menu.add_child(title)

	_add_menu_button("GUNAKAN", Vector3(-0.88, 0.42, -0.18), "use")
	_add_menu_button("SAPA", Vector3(0.88, 0.42, -0.18), "greet")
	_add_menu_button("DUDUK", Vector3(-0.88, -0.28, -0.18), "sit")
	_add_menu_button("BERDIRI", Vector3(0.88, -0.28, -0.18), "stand")
	_create_spatial_button(_menu, "BATAL", Vector3(0, -0.98, -0.18), "cancel", Vector3(1.35, 0.42, 0.14))


func _add_menu_button(label_text: String, local_position: Vector3, action_id: String) -> void:
	var button := _create_spatial_button(_menu, label_text, local_position, action_id, Vector3(1.35, 0.52, 0.15))
	_menu_buttons.append(button)
	_menu_button_by_action[action_id] = button


func _create_spatial_button(parent: Node3D, label_text: String, local_position: Vector3, action_id: String, dimensions: Vector3) -> Area3D:
	var area := Area3D.new()
	area.name = "SpatialAction_" + action_id
	area.position = local_position
	area.input_ray_pickable = true
	area.collision_layer = 16
	area.collision_mask = 0
	area.set_meta("spatial_action", action_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	area.add_child(collision)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions * Vector3(0.96, 0.94, 0.72)
	body.mesh = box
	body.material_override = _spatial_material(Color("#315b70") if action_id != "open" else Color("#a77a36"))
	area.add_child(body)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 20 if label_text.length() < 8 else 16
	label.pixel_size = 0.0038
	label.position.z = -dimensions.z * 0.42
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffffff")
	area.add_child(label)
	parent.add_child(area)
	return area


func _spatial_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.32
	material.metallic = 0.22
	material.emission_enabled = true
	material.emission = color.darkened(0.32)
	material.emission_energy_multiplier = 0.18
	return material

func _show_result(message: String) -> void:
	_result_generation += 1
	var current_generation := _result_generation
	_result.text = message
	_result.visible = true
	await get_tree().create_timer(2.4).timeout
	if is_instance_valid(_result) and current_generation == _result_generation:
		_result.visible = false

func _is_target_interactable_and_in_range() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	if not _target.is_in_group("world_interactable") or not (_target is Node3D):
		return false
	var player := get_parent()
	if not (player is Node3D):
		return false
	return player.global_position.distance_squared_to((_target as Node3D).global_position) <= pow(interaction_distance + 0.75, 2.0)

func _broadcast_social_action(action_id: String) -> void:
	var world := get_parent().get_parent()
	if world == null:
		return
	var manager := world.get_node_or_null("MultiplayerManager")
	if manager != null and manager.has_method("broadcast_social_action"):
		manager.call("broadcast_social_action", action_id)
