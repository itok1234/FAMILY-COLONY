extends Node
## Contextual interaction controller with compact radial-style action menu.
## This is local presentation/gameplay scaffolding; authoritative multiplayer checks are not implemented.

@export var camera_path: NodePath = NodePath("../CameraPivot/Camera3D")
@export var interaction_distance: float = 5.0
@onready var camera: Camera3D = get_node_or_null(camera_path) as Camera3D

var _target: Node
var _prompt: Label
var _result: Label
var _action_button: Button
var _menu: Control
var _menu_buttons: Array[Button] = []
var _refresh_timer := 0.0

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
	elif event.is_action_pressed("ui_cancel") and _menu.visible:
		_menu.visible = false
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
	_action_button.visible = not value.is_empty()

func _open_action_menu() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	_menu.visible = true
	_prompt.visible = false
	_action_button.visible = false

func _choose_action(action_id: String) -> void:
	_menu.visible = false
	if _target == null or not is_instance_valid(_target):
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
	_result.text = message
	_result.visible = true
	_target = null
	_set_prompt("")
	await get_tree().create_timer(2.4).timeout
	if is_instance_valid(_result):
		_result.visible = false

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "InteractionHUD"
	layer.layer = 12
	add_child(layer)

	_prompt = Label.new()
	_prompt.name = "ContextPrompt"
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 0.12
	_prompt.anchor_bottom = 0.12
	_prompt.offset_left = -190
	_prompt.offset_right = 190
	_prompt.offset_bottom = 42
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 19)
	_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
	_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_prompt.visible = false
	layer.add_child(_prompt)

	_action_button = Button.new()
	_action_button.name = "InteractButton"
	_action_button.text = "AKSI"
	_action_button.anchor_left = 0.78
	_action_button.anchor_right = 0.96
	_action_button.anchor_top = 0.76
	_action_button.anchor_bottom = 0.88
	_action_button.add_theme_font_size_override("font_size", 17)
	_action_button.pressed.connect(_open_action_menu)
	_action_button.visible = false
	layer.add_child(_action_button)

	_menu = Control.new()
	_menu.name = "RadialActionMenu"
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.visible = false
	layer.add_child(_menu)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu.add_child(shade)

	var title := Label.new()
	title.text = "PILIH AKSI"
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.anchor_top = 0.34
	title.anchor_bottom = 0.34
	title.offset_left = -120
	title.offset_right = 120
	title.offset_bottom = 34
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	_menu.add_child(title)

	_add_menu_button("GUNAKAN", Vector2(-165, 0), "use")
	_add_menu_button("SAPA", Vector2(0, 82), "greet")
	_add_menu_button("DUDUK", Vector2(165, 0), "sit")

	var cancel := Button.new()
	cancel.text = "BATAL"
	cancel.anchor_left = 0.5
	cancel.anchor_right = 0.5
	cancel.anchor_top = 0.68
	cancel.anchor_bottom = 0.68
	cancel.offset_left = -75
	cancel.offset_right = 75
	cancel.offset_bottom = 44
	cancel.pressed.connect(func(): _menu.visible = false)
	_menu.add_child(cancel)

	_result = Label.new()
	_result.name = "InteractionResult"
	_result.anchor_left = 0.15
	_result.anchor_right = 0.85
	_result.anchor_top = 0.2
	_result.anchor_bottom = 0.2
	_result.offset_bottom = 50
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result.add_theme_font_size_override("font_size", 18)
	_result.add_theme_color_override("font_color", Color(1, 0.92, 0.72))
	_result.visible = false
	layer.add_child(_result)

func _add_menu_button(label_text: String, center_offset: Vector2, action_id: String) -> void:
	var button := Button.new()
	button.text = label_text
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.52
	button.anchor_bottom = 0.52
	button.offset_left = center_offset.x - 72
	button.offset_right = center_offset.x + 72
	button.offset_top = center_offset.y - 25
	button.offset_bottom = center_offset.y + 25
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_choose_action.bind(action_id))
	_menu.add_child(button)
	_menu_buttons.append(button)

func _show_result(message: String) -> void:
	_result.text = message
	_result.visible = true
	await get_tree().create_timer(2.4).timeout
	if is_instance_valid(_result):
		_result.visible = false

func _broadcast_social_action(action_id: String) -> void:
	var world := get_parent().get_parent()
	if world == null:
		return
	var manager := world.get_node_or_null("MultiplayerManager")
	if manager != null and manager.has_method("broadcast_social_action"):
		manager.call("broadcast_social_action", action_id)
