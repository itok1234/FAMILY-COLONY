extends Node
## Contextual interaction controller: camera ray selection + keyboard/touch action.
## Gameplay authority and multiplayer validation must be added server-side later.

@export var camera_path: NodePath = NodePath("../CameraPivot/Camera3D")
@export var interaction_distance: float = 5.0
@onready var camera: Camera3D = get_node_or_null(camera_path) as Camera3D

var _target: Node
var _prompt: Label
var _result: Label
var _action_button: Button
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
		_perform_interaction()
		get_viewport().set_input_as_handled()

func _refresh_target() -> void:
	_target = null
	if camera == null or not is_instance_valid(camera):
		_set_prompt("")
		return
	var origin := camera.global_position
	var endpoint := origin + (-camera.global_basis.z * interaction_distance)
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.collision_mask = 2
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

func _perform_interaction() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var message := "Interaksi selesai."
	if _target.has_method("interact"):
		message = str(_target.call("interact", get_parent()))
	_result.text = message
	_result.visible = true
	_target = null
	_set_prompt("")
	await get_tree().create_timer(2.2).timeout
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
	_prompt.offset_top = 0
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
	_action_button.text = "INTERAKSI"
	_action_button.anchor_left = 0.78
	_action_button.anchor_right = 0.96
	_action_button.anchor_top = 0.76
	_action_button.anchor_bottom = 0.88
	_action_button.add_theme_font_size_override("font_size", 17)
	_action_button.pressed.connect(_perform_interaction)
	_action_button.visible = false
	layer.add_child(_action_button)

	_result = Label.new()
	_result.name = "InteractionResult"
	_result.anchor_left = 0.2
	_result.anchor_right = 0.8
	_result.anchor_top = 0.2
	_result.anchor_bottom = 0.2
	_result.offset_top = 0
	_result.offset_bottom = 50
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result.add_theme_font_size_override("font_size", 18)
	_result.add_theme_color_override("font_color", Color(1, 0.92, 0.72))
	_result.visible = false
	layer.add_child(_result)
