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
