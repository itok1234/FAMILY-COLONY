extends Node
## Room-scoped LAN chat transport foundation.
## Sender identity is an ENet peer ID only; never treat it as a verified member account.

signal message_received(message: Dictionary)
signal chat_error(message: String)

@export_range(1, 1000, 1) var max_message_characters: int = 500
@export_range(1, 10, 1) var minimum_send_interval: float = 1.0
@export_range(1, 200, 1) var history_limit: int = 50

var _network: Node
var _rooms: Node
var _last_send_at: Dictionary = {}
var _history: Array[Dictionary] = []
var _current_room_id: String = ""


func _ready() -> void:
	_network = get_parent().get_node_or_null("MultiplayerManager")
	_rooms = get_parent().get_node_or_null("RoomManager")
	if _network == null or _rooms == null:
		push_warning("FAMILY COLONY: ChatManager requires MultiplayerManager and RoomManager.")
		return
	if _rooms.has_signal("local_room_changed"):
		_rooms.local_room_changed.connect(_on_local_room_changed)
	if _network.has_signal("peer_roster_changed"):
		_network.peer_roster_changed.connect(_on_peer_roster_changed)
	if _network.has_signal("connection_state_changed"):
		_network.connection_state_changed.connect(_on_connection_state_changed)
	_build_chat_hud()
	for message in _history:
		_append_message_to_hud(message)
	message_received.connect(_on_message_received)
	chat_error.connect(_on_chat_error)


func open_spatial_chat(active_camera: Camera3D) -> bool:
	if not is_instance_valid(_chat_root) or active_camera == null:
		return false
	if _chat_root.get_parent() != active_camera:
		_chat_root.reparent(active_camera)
	_chat_camera = active_camera
	_chat_root.visible = true
	_chat_panel.visible = true
	_update_chat_messages()
	_update_chat_draft()
	return true


func restore_spatial_chat(player_camera: Camera3D) -> void:
	if not is_instance_valid(_chat_root) or player_camera == null:
		return
	if _chat_root.get_parent() != player_camera:
		_chat_root.reparent(player_camera)
	_chat_camera = player_camera
	_chat_root.visible = true
	if is_instance_valid(_chat_panel):
		_chat_panel.visible = false


func get_recent_messages() -> Array[Dictionary]:
	return _history.duplicate(true)


func send_message(raw_text: String) -> bool:
	var clean_text := raw_text.strip_edges()
	if clean_text.is_empty():
		chat_error.emit("Pesan tidak boleh kosong.")
		return false
	if clean_text.length() > max_message_characters:
		chat_error.emit("Pesan maksimal %d karakter." % max_message_characters)
		return false
	if _current_room_id.is_empty():
		chat_error.emit("Masuk ke room terlebih dahulu sebelum mengirim pesan.")
		return false
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		chat_error.emit("Koneksi room belum aktif. Chat belum dapat dikirim.")
		return false
	if multiplayer.is_server():
		_accept_message(multiplayer.get_unique_id(), clean_text)
	else:
		_rpc_submit_message.rpc_id(1, clean_text)
	return true


func _accept_message(sender_id: int, clean_text: String) -> void:
	if not multiplayer.is_server() or _rooms == null:
		return
	if sender_id != multiplayer.get_unique_id() and not multiplayer.get_peers().has(sender_id):
		return
	var room_id: String = str(_rooms.call("get_peer_room_id", sender_id))
	if room_id.is_empty():
		_reject_sender(sender_id, "Kamu belum berada di room.")
		return
	var now := Time.get_ticks_msec() / 1000.0
	var last_time := float(_last_send_at.get(sender_id, -10000.0))
	if now - last_time < minimum_send_interval:
		_reject_sender(sender_id, "Terlalu cepat mengirim pesan.")
		return
	_last_send_at[sender_id] = now
	var message := {
		"room_id": room_id,
		"sender_peer_id": sender_id,
		"sender_label": "Anggota #%d" % sender_id,
		"text": clean_text,
		"sent_at": int(Time.get_unix_time_from_system())
	}
	_store_message(message)
	var room_peer_ids: Array = _rooms.call("get_room_peer_ids", room_id)
	for peer_id in room_peer_ids:
		if peer_id == multiplayer.get_unique_id():
			continue
		_rpc_receive_message.rpc_id(peer_id, message)


func _on_peer_roster_changed(peer_ids: Array[int]) -> void:
	# Drop per-peer throttling state after disconnect so stale peer IDs do not
	# accumulate and a later connection cannot inherit an old cooldown.
	for peer_id in _last_send_at.keys().duplicate():
		if int(peer_id) != multiplayer.get_unique_id() and not peer_ids.has(int(peer_id)):
			_last_send_at.erase(peer_id)
	if not multiplayer.is_server() and peer_ids.is_empty():
		_clear_local_chat_state()


func _on_connection_state_changed(state: String, _detail: String) -> void:
	if state == "offline" or state == "error":
		_clear_local_chat_state()


func _on_local_room_changed(room_id: String, _members: Array[int]) -> void:
	if room_id == _current_room_id:
		return
	_current_room_id = room_id
	_clear_local_chat_history()


func _clear_local_chat_state() -> void:
	_current_room_id = ""
	_clear_local_chat_history()


func _clear_local_chat_history() -> void:
	_history.clear()
	if is_instance_valid(_chat_messages):
		_chat_messages.text = "Belum ada pesan di room ini."
	if is_instance_valid(_chat_error_label):
		_chat_error_label.text = ""
		_chat_error_label.visible = false


func _store_message(message: Dictionary) -> void:
	var message_room_id := str(message.get("room_id", ""))
	if _current_room_id.is_empty() or message_room_id != _current_room_id:
		return
	_history.append(message.duplicate(true))
	while _history.size() > history_limit:
		_history.pop_front()
	message_received.emit(message.duplicate(true))


func _reject_sender(peer_id: int, reason: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		chat_error.emit(reason)
	else:
		_rpc_chat_error.rpc_id(peer_id, reason)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_message(raw_text: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1 or not multiplayer.get_peers().has(sender_id):
		return
	if raw_text.length() > max_message_characters:
		_reject_sender(sender_id, "Pesan melebihi batas karakter.")
		return
	var clean_text := raw_text.strip_edges()
	if clean_text.is_empty():
		_reject_sender(sender_id, "Pesan tidak boleh kosong.")
		return
	_accept_message(sender_id, clean_text)


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_message(message: Dictionary) -> void:
	var text_value := str(message.get("text", ""))
	var message_room_id := str(message.get("room_id", ""))
	if text_value.strip_edges().is_empty() or text_value.length() > max_message_characters:
		return
	if message_room_id.is_empty() or message_room_id != _current_room_id:
		return
	_store_message(message)


@rpc("authority", "call_remote", "reliable")
func _rpc_chat_error(reason: String) -> void:
	chat_error.emit(reason)


var _chat_root: Node3D
var _chat_panel: Node3D
var _chat_messages: Label3D
var _chat_draft_label: Label3D
var _chat_error_label: Label3D
var _chat_toggle: Area3D
var _chat_draft := ""
var _chat_camera: Camera3D


func _build_chat_hud() -> void:
	var player := get_parent().get_node_or_null("Player")
	_chat_camera = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D if player != null else null
	if _chat_camera == null:
		push_warning("FAMILY COLONY: 3D chat requires the player camera.")
		return

	_chat_root = Node3D.new()
	_chat_root.name = "SpatialRoomChat"
	_chat_camera.add_child(_chat_root)

	_chat_toggle = _create_chat_button(_chat_root, "CHAT", Vector3(1.45, 0.0, -2.8), "toggle", Vector3(0.92, 0.5, 0.14), Color("#a77a36"))
	_chat_panel = Node3D.new()
	_chat_panel.name = "SpatialRoomChatPanel"
	_chat_panel.position = Vector3(0, 0, -3.2)
	_chat_panel.visible = false
	_chat_root.add_child(_chat_panel)

	var backing := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(5.7, 4.9, 0.14)
	backing.mesh = panel_mesh
	backing.material_override = _chat_material(Color("#10263b"))
	_chat_panel.add_child(backing)

	var title := Label3D.new()
	title.text = "ALUN-ALUN CHAT"
	title.font_size = 32
	title.pixel_size = 0.0035
	title.position = Vector3(0, 2.12, -0.1)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color("#f3d99a")
	_chat_panel.add_child(title)

	_chat_messages = Label3D.new()
	_chat_messages.name = "ChatMessages3D"
	_chat_messages.font_size = 17
	_chat_messages.pixel_size = 0.0035
	_chat_messages.position = Vector3(-2.45, 1.42, -0.1)
	_chat_messages.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_chat_messages.modulate = Color("#e5edf4")
	_chat_panel.add_child(_chat_messages)

	_chat_error_label = Label3D.new()
	_chat_error_label.font_size = 15
	_chat_error_label.pixel_size = 0.0035
	_chat_error_label.position = Vector3(0, 0.53, -0.1)
	_chat_error_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_chat_error_label.modulate = Color("#ffb9a8")
	_chat_error_label.visible = false
	_chat_panel.add_child(_chat_error_label)

	_chat_draft_label = Label3D.new()
	_chat_draft_label.text = "PESAN: "
	_chat_draft_label.font_size = 17
	_chat_draft_label.pixel_size = 0.0035
	_chat_draft_label.position = Vector3(-2.45, 0.18, -0.1)
	_chat_draft_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_chat_draft_label.modulate = Color("#f3d99a")
	_chat_panel.add_child(_chat_draft_label)

	var row_one := "QWERTYUIOP"
	var row_two := "ASDFGHJKL"
	var row_three := "ZXCVBNM"
	_create_chat_key_row(row_one, -2.05, 0.43)
	_create_chat_key_row(row_two, -1.82, -0.12)
	_create_chat_key_row(row_three, -1.58, -0.67)
	_create_chat_button(_chat_panel, "SPASI", Vector3(-0.95, -1.28, -0.18), "space", Vector3(1.65, 0.42, 0.14), Color("#315b70"))
	_create_chat_button(_chat_panel, "HAPUS", Vector3(0.55, -1.28, -0.18), "delete", Vector3(1.05, 0.42, 0.14), Color("#65568d"))
	_create_chat_button(_chat_panel, "KIRIM", Vector3(1.95, -1.28, -0.18), "send", Vector3(1.05, 0.42, 0.14), Color("#a77a36"))
	_create_chat_button(_chat_panel, "TUTUP", Vector3(0, -1.92, -0.18), "close", Vector3(1.55, 0.42, 0.14), Color("#52677a"))
	_update_chat_messages()


func _create_chat_key_row(characters: String, y_position: float, key_width: float) -> void:
	var count := characters.length()
	var spacing := 0.46
	var start_x := -float(count - 1) * spacing * 0.5
	for i in range(count):
		var character := characters.substr(i, 1)
		_create_chat_button(_chat_panel, character, Vector3(start_x + float(i) * spacing, y_position, -0.18), "char:" + character, Vector3(0.4, 0.4, 0.14), Color("#315b70"))


func _create_chat_button(parent: Node3D, label_text: String, local_position: Vector3, action_id: String, dimensions: Vector3, color: Color) -> Area3D:
	var area := Area3D.new()
	area.name = "ChatKey_" + action_id.replace(":", "_")
	area.position = local_position
	area.input_ray_pickable = true
	area.collision_layer = 64
	area.collision_mask = 0
	area.set_meta("chat_action", action_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	area.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions * Vector3(0.96, 0.92, 0.72)
	mesh.mesh = box
	mesh.material_override = _chat_material(color)
	area.add_child(mesh)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 17 if label_text.length() <= 2 else 14
	label.pixel_size = 0.0034
	label.position.z = -dimensions.z * 0.42
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffffff")
	area.add_child(label)
	parent.add_child(area)
	return area


func _chat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.34
	material.metallic = 0.18
	material.emission_enabled = true
	material.emission = color.darkened(0.3)
	material.emission_energy_multiplier = 0.16
	return material


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_chat_root) or not _chat_root.visible:
		return
	var pressed := false
	var screen_position := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		screen_position = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		screen_position = event.position
	if not pressed or _chat_camera == null:
		return
	var origin := _chat_camera.project_ray_origin(screen_position)
	var direction := _chat_camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 12.0)
	query.collide_with_areas = true
	query.collision_mask = 64
	var hit := _chat_camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is Area3D and collider.has_meta("chat_action"):
		_handle_chat_key(str(collider.get_meta("chat_action")))
		get_viewport().set_input_as_handled()


func _handle_chat_key(action_id: String) -> void:
	match action_id:
		"toggle":
			_toggle_chat_panel()
		"close":
			_chat_panel.visible = false
		"space":
			if _chat_draft.length() < max_message_characters:
				_chat_draft += " "
		"delete":
			_chat_draft = _chat_draft.left(maxi(0, _chat_draft.length() - 1))
		"send":
			_send_chat_input()
		_:
			if action_id.begins_with("char:") and _chat_draft.length() < max_message_characters:
				_chat_draft += action_id.trim_prefix("char:")
	_update_chat_draft()


func _toggle_chat_panel() -> void:
	if not is_instance_valid(_chat_panel):
		return
	_chat_panel.visible = not _chat_panel.visible
	_update_chat_messages()


func _send_chat_input() -> void:
	if _chat_draft.strip_edges().is_empty():
		return
	if send_message(_chat_draft):
		_chat_draft = ""
		_update_chat_draft()


func _update_chat_draft() -> void:
	if is_instance_valid(_chat_draft_label):
		_chat_draft_label.text = "PESAN: " + _chat_draft


func _update_chat_messages() -> void:
	if not is_instance_valid(_chat_messages):
		return
	var lines: Array[String] = []
	var start_index := maxi(0, _history.size() - 6)
	for i in range(start_index, _history.size()):
		var message: Dictionary = _history[i]
		lines.append("%s: %s" % [str(message.get("sender_label", "Anggota")), str(message.get("text", ""))])
	if lines.is_empty():
		lines.append("Belum ada pesan di room ini.")
	_chat_messages.text = "\\n".join(lines)


func _on_message_received(_message: Dictionary) -> void:
	if is_instance_valid(_chat_error_label):
		_chat_error_label.visible = false
	_update_chat_messages()


func _on_chat_error(message: String) -> void:
	if not is_instance_valid(_chat_error_label):
		return
	_chat_error_label.text = message
	_chat_error_label.visible = true


func _append_message_to_hud(_message: Dictionary) -> void:
	_update_chat_messages()


func _scroll_chat_to_bottom() -> void:
	_update_chat_messages()
