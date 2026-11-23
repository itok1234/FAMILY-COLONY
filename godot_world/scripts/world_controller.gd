extends Node3D
## FAMILY COLONY world scene controller.
## Android gameplay is locked until the existing app session is verified by Supabase.

@export var player_path: NodePath = NodePath("Player")
@onready var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D
@onready var session_client: Node = get_node_or_null("WorldSessionClient")

var _android_session_required := false
var _gate_layer: CanvasLayer
var _gate_status: Label


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


func _unhandled_input(event: InputEvent) -> void:
	if _android_session_required and event.is_action_pressed("ui_cancel"):
		_return_to_app()
		get_viewport().set_input_as_handled()


func _build_session_gate() -> void:
	_gate_layer = CanvasLayer.new()
	_gate_layer.name = "SessionVerificationGate"
	_gate_layer.layer = 60
	add_child(_gate_layer)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.045, 0.075, 0.94)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_gate_layer.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.36
	panel.anchor_bottom = 0.64
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	_gate_layer.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var title := Label.new()
	title.text = "FAMILY COLONY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)

	_gate_status = Label.new()
	_gate_status.text = "Memverifikasi akun..."
	_gate_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gate_status.add_theme_font_size_override("font_size", 16)
	column.add_child(_gate_status)

	var exit_button := Button.new()
	exit_button.text = "KEMBALI KE APLIKASI"
	exit_button.custom_minimum_size = Vector2(0, 48)
	exit_button.pressed.connect(_return_to_app)
	column.add_child(exit_button)


func _set_gate_status(message: String) -> void:
	if is_instance_valid(_gate_status):
		_gate_status.text = message


func _on_session_verified(member: Dictionary, permissions: Dictionary) -> void:
	if not bool(permissions.get("can_enter_world", false)):
		_on_session_rejected("world_access_denied")
		return
	_set_player_enabled(true)
	if is_instance_valid(_gate_layer):
		_gate_layer.queue_free()
	_gate_layer = null
	print("FAMILY COLONY: verified world session for member ", str(member.get("member_id", "")))


func _on_session_rejected(error_code: String) -> void:
	_set_player_enabled(false)
	_set_gate_status(
		"Sesi belum dapat diverifikasi. "
		+ error_code.replace("_", " ")
		+ ". Silakan kembali ke aplikasi dan masuk lagi."
	)


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
	if Engine.has_singleton("FamilyColonyBridge"):
		var bridge: Object = Engine.get_singleton("FamilyColonyBridge")
		if bridge.has_method("requestExitToApp"):
			bridge.call("requestExitToApp")
			return
	get_tree().quit()
