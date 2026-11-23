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


func _ready() -> void:
	_network = get_parent().get_node_or_null("MultiplayerManager")
	_rooms = get_parent().get_node_or_null("RoomManager")
	if _network == null or _rooms == null:
		push_warning("FAMILY COLONY: ChatManager requires MultiplayerManager and RoomManager.")
	_build_chat_hud()
	for message in _history:
		_append_message_to_hud(message)
	message_received.connect(_on_message_received)
	chat_error.connect(_on_chat_error)


func get_recent_messages() -> Array[Dictionary]:
	return _history.duplicate(true)


func send_message(raw_text: String) -> void:
	var clean_text := raw_text.strip_edges()
	if clean_text.is_empty():
		chat_error.emit("Pesan tidak boleh kosong.")
		return
	if clean_text.length() > max_message_characters:
		chat_error.emit("Pesan maksimal %d karakter." % max_message_characters)
		return
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		chat_error.emit("Hubungkan ke room terlebih dahulu.")
		return
	if multiplayer.is_server():
		_accept_message(multiplayer.get_unique_id(), clean_text)
	else:
		_rpc_submit_message.rpc_id(1, clean_text)


func _accept_message(sender_id: int, clean_text: String) -> void:
	if not multiplayer.is_server() or _rooms == null:
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


func _store_message(message: Dictionary) -> void:
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
	var clean_text := raw_text.strip_edges()
	if clean_text.is_empty() or clean_text.length() > max_message_characters:
		_reject_sender(sender_id, "Pesan kosong atau melebihi batas karakter.")
		return
	_accept_message(sender_id, clean_text)


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_message(message: Dictionary) -> void:
	if String(message.get("text", "")).is_empty():
		return
	_store_message(message)


@rpc("authority", "call_remote", "reliable")
func _rpc_chat_error(reason: String) -> void:
	chat_error.emit(reason)


var _chat_panel: PanelContainer
var _chat_log: VBoxContainer
var _chat_scroll: ScrollContainer
var _chat_input: LineEdit
var _chat_error_label: Label
var _chat_toggle: Button
var _chat_empty_label: Label


func _build_chat_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RoomChatHUD"
	layer.layer = 18
	add_child(layer)

	_chat_toggle = Button.new()
	_chat_toggle.name = "ChatToggle"
	_chat_toggle.text = "CHAT ROOM"
	_chat_toggle.anchor_left = 0.81
	_chat_toggle.anchor_right = 0.97
	_chat_toggle.anchor_top = 0.13
	_chat_toggle.anchor_bottom = 0.20
	_chat_toggle.offset_left = 0
	_chat_toggle.offset_right = 0
	_chat_toggle.offset_top = 0
	_chat_toggle.offset_bottom = 0
	_chat_toggle.custom_minimum_size = Vector2(110, 42)
	_chat_toggle.pressed.connect(_toggle_chat_panel)
	layer.add_child(_chat_toggle)

	_chat_panel = PanelContainer.new()
	_chat_panel.name = "RoomChatPanel"
	_chat_panel.anchor_left = 0.54
	_chat_panel.anchor_right = 0.98
	_chat_panel.anchor_top = 0.43
	_chat_panel.anchor_bottom = 0.96
	_chat_panel.offset_left = 0
	_chat_panel.offset_right = 0
	_chat_panel.offset_top = 0
	_chat_panel.offset_bottom = 0
	_chat_panel.visible = false
	layer.add_child(_chat_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_chat_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)

	var title := Label.new()
	title.text = "CHAT ROOM"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "TUTUP"
	close_button.pressed.connect(_toggle_chat_panel)
	header.add_child(close_button)

	var identity_note := Label.new()
	identity_note.text = "Nama pengirim sementara memakai ID koneksi, bukan identitas akun."
	identity_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity_note.add_theme_font_size_override("font_size", 11)
	column.add_child(identity_note)

	_chat_scroll = ScrollContainer.new()
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.custom_minimum_size = Vector2(0, 150)
	column.add_child(_chat_scroll)

	_chat_log = VBoxContainer.new()
	_chat_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_log.add_theme_constant_override("separation", 4)
	_chat_scroll.add_child(_chat_log)
	_chat_empty_label = Label.new()
	_chat_empty_label.text = "Belum ada pesan di room ini."
	_chat_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chat_log.add_child(_chat_empty_label)

	_chat_error_label = Label.new()
	_chat_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chat_error_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.58))
	_chat_error_label.add_theme_font_size_override("font_size", 12)
	_chat_error_label.visible = false
	column.add_child(_chat_error_label)

	var composer := HBoxContainer.new()
	column.add_child(composer)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Tulis pesan..."
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.max_length = max_message_characters
	_chat_input.text_submitted.connect(_on_chat_text_submitted)
	composer.add_child(_chat_input)

	var send_button := Button.new()
	send_button.text = "KIRIM"
	send_button.pressed.connect(_send_chat_input)
	composer.add_child(send_button)


func _toggle_chat_panel() -> void:
	_chat_panel.visible = not _chat_panel.visible
	if _chat_panel.visible:
		_scroll_chat_to_bottom()


func _send_chat_input() -> void:
	if not is_instance_valid(_chat_input):
		return
	var message_text := _chat_input.text
	if message_text.strip_edges().is_empty():
		return
	send_message(message_text)
	_chat_input.clear()


func _on_chat_text_submitted(_submitted_text: String) -> void:
	_send_chat_input()


func _on_message_received(message: Dictionary) -> void:
	if is_instance_valid(_chat_error_label):
		_chat_error_label.visible = false
	_append_message_to_hud(message)


func _on_chat_error(message: String) -> void:
	if not is_instance_valid(_chat_error_label):
		return
	_chat_error_label.text = message
	_chat_error_label.visible = true


func _append_message_to_hud(message: Dictionary) -> void:
	if not is_instance_valid(_chat_log):
		return
	if is_instance_valid(_chat_empty_label):
		_chat_empty_label.visible = false
	var line := Label.new()
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.text = "%s: %s" % [
		str(message.get("sender_label", "Anggota")),
		str(message.get("text", ""))
	]
	_chat_log.add_child(line)
	while _chat_log.get_child_count() > history_limit:
		var oldest := _chat_log.get_child(0)
		_chat_log.remove_child(oldest)
		oldest.queue_free()
	call_deferred("_scroll_chat_to_bottom")


func _scroll_chat_to_bottom() -> void:
	if is_instance_valid(_chat_scroll):
		var scrollbar := _chat_scroll.get_v_scroll_bar()
		_chat_scroll.scroll_vertical = int(scrollbar.max_value)
