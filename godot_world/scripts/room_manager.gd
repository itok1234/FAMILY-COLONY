extends Node
## Host-authoritative LAN room registry foundation.
## Room state is in-memory only and resets when the host exits.

signal room_list_changed(rooms: Array)
signal local_room_changed(room_id: String, members: Array[int])
signal room_action_result(ok: bool, message: String)

@export_range(2, 64, 1) var default_room_capacity: int = 16
const MAX_ACTIVE_ROOMS: int = 64
var _rooms: Dictionary = {}
var _peer_room: Dictionary = {}
var _last_room_create_at: Dictionary = {}
var _client_room_snapshot: Array = []
var _network: Node


func _ready() -> void:
	_network = get_parent().get_node_or_null("MultiplayerManager")
	if _network == null:
		push_warning("FAMILY COLONY: MultiplayerManager is missing.")
		return
	_network.peer_roster_changed.connect(_on_peer_roster_changed)
	_network.connection_state_changed.connect(_on_connection_state_changed)


func create_room(room_name: String, capacity: int = -1) -> void:
	var clean_name := room_name.strip_edges()
	var has_control_character := false
	for character in clean_name:
		if character.unicode_at(0) < 32 or character.unicode_at(0) == 127:
			has_control_character = true
			break
	if clean_name.length() < 2 or clean_name.length() > 32 or has_control_character:
		room_action_result.emit(false, "Nama room harus 2–32 karakter dan tidak boleh berisi karakter kontrol.")
		return
	var chosen_capacity := default_room_capacity if capacity < 2 else mini(capacity, 64)
	if multiplayer.is_server():
		_create_room_for_peer(multiplayer.get_unique_id(), clean_name, chosen_capacity)
	else:
		_rpc_request_create_room.rpc_id(1, clean_name, chosen_capacity)


func join_room(room_id: String) -> void:
	var clean_id := room_id.strip_edges()
	if clean_id.is_empty():
		room_action_result.emit(false, "ID room tidak valid.")
		return
	if multiplayer.is_server():
		if clean_id == "lobby":
			_join_or_create_lobby(multiplayer.get_unique_id())
			_broadcast_room_state()
		else:
			_join_room_for_peer(multiplayer.get_unique_id(), clean_id)
	else:
		_rpc_request_join_room.rpc_id(1, clean_id)


func leave_room() -> void:
	if multiplayer.is_server():
		var local_peer := multiplayer.get_unique_id()
		_leave_room_for_peer(local_peer)
		_join_or_create_lobby(local_peer)
		_broadcast_room_state()
	else:
		_rpc_request_leave_room.rpc_id(1)


func get_room_snapshot() -> Array:
	if multiplayer.is_server():
		return _public_room_snapshot()
	return _client_room_snapshot.duplicate(true)


func _on_connection_state_changed(state: String, _detail: String) -> void:
	if state == "connected":
		_rpc_request_room_snapshot.rpc_id(1)
	elif state == "offline" or state == "error":
		# Do not leave stale room cards or membership visible after disconnect.
		_rooms.clear()
		_peer_room.clear()
		_client_room_snapshot.clear()
		room_list_changed.emit([])
		local_room_changed.emit("", [])


func _on_peer_roster_changed(peer_ids: Array[int]) -> void:
	if not multiplayer.is_server():
		return
	for peer_id in peer_ids:
		if not _peer_room.has(peer_id):
			_join_or_create_lobby(peer_id)
	for peer_id in _peer_room.keys().duplicate():
		if not peer_ids.has(int(peer_id)):
			_leave_room_for_peer(int(peer_id))
			_last_room_create_at.erase(int(peer_id))
	_broadcast_room_state()


func _join_or_create_lobby(peer_id: int) -> void:
	# The transport allows more peers than one default lobby can hold when
	# the host is counted. Select the least-populated lobby shard with space;
	# create another shard instead of silently leaving a connected member
	# outside every room.
	if _peer_room.has(peer_id):
		_leave_room_for_peer(peer_id)
	var selected_lobby := ""
	var selected_count := 2147483647
	for room_key in _rooms.keys():
		var room_id := str(room_key)
		if room_id != "lobby" and not room_id.begins_with("lobby_"):
			continue
		var room: Dictionary = _rooms[room_id]
		var members: Array = room["members"]
		var capacity := int(room["capacity"])
		if members.size() < capacity and members.size() < selected_count:
			selected_lobby = room_id
			selected_count = members.size()
	if selected_lobby.is_empty():
		# Keep the first shard on the canonical "lobby" ID so existing
		# invitations and UI links continue to resolve to the primary Lobby.
		# Additional shards use lobby_2, lobby_3, ... with matching labels.
		var shard_number := 1
		selected_lobby = "lobby"
		while _rooms.has(selected_lobby):
			shard_number += 1
			selected_lobby = "lobby_%d" % shard_number
		var lobby_label := "Lobby" if shard_number == 1 else "Lobby %d" % shard_number
		_rooms[selected_lobby] = {
			"name": lobby_label,
			"capacity": default_room_capacity,
			"members": []
		}
	var target_members: Array = _rooms[selected_lobby]["members"]
	target_members.append(peer_id)
	_peer_room[peer_id] = selected_lobby


func _create_room_for_peer(peer_id: int, room_name: String, capacity: int) -> void:
	# Apply the same cooldown to the host and remote members. Previously the
	# remote RPC enforced this, but the host-local path bypassed the limit.
	var now := Time.get_ticks_msec() / 1000.0
	var last_create := float(_last_room_create_at.get(peer_id, -10000.0))
	if now - last_create < 5.0:
		_send_result(peer_id, false, "Tunggu 5 detik sebelum membuat room lagi.")
		return
	var active_custom_rooms := 0
	for existing_key in _rooms.keys():
		var existing_id := str(existing_key)
		if existing_id != "lobby" and not existing_id.begins_with("lobby_"):
			active_custom_rooms += 1
	if active_custom_rooms >= MAX_ACTIVE_ROOMS:
		_send_result(peer_id, false, "Kapasitas jumlah room sedang penuh. Coba lagi nanti.")
		return
	_last_room_create_at[peer_id] = now
	var room_id := "room_%d_%d" % [peer_id, Time.get_ticks_msec()]
	_rooms[room_id] = {"name": room_name, "capacity": capacity, "members": []}
	_join_room_for_peer(peer_id, room_id)
	_broadcast_room_state()


func _join_room_for_peer(peer_id: int, room_id: String) -> void:
	if not _rooms.has(room_id):
		_send_result(peer_id, false, "Room tidak ditemukan.")
		return
	var room: Dictionary = _rooms[room_id]
	var members: Array = room["members"]
	if members.has(peer_id):
		_send_result(peer_id, true, "Kamu sudah berada di room ini.")
		return
	if members.size() >= int(room["capacity"]):
		_send_result(peer_id, false, "Room sudah penuh.")
		return
	_leave_room_for_peer(peer_id)
	members.append(peer_id)
	_peer_room[peer_id] = room_id
	_send_result(peer_id, true, "Berhasil masuk ke %s." % room["name"])
	_broadcast_room_state()


func _leave_room_for_peer(peer_id: int) -> void:
	if not _peer_room.has(peer_id):
		return
	var room_id := String(_peer_room[peer_id])
	_peer_room.erase(peer_id)
	if _rooms.has(room_id):
		var members: Array = _rooms[room_id]["members"]
		members.erase(peer_id)
		# Remove empty custom rooms and secondary lobby shards. Keep the
		# canonical primary lobby available for invitations and first entry.
		if members.is_empty() and room_id != "lobby":
			_rooms.erase(room_id)


func _broadcast_room_state() -> void:
	var snapshot := _public_room_snapshot()
	room_list_changed.emit(snapshot)
	if multiplayer.is_server():
		_rpc_receive_room_snapshot.rpc(snapshot)
		for peer_id in _peer_room.keys():
			var room_id := String(_peer_room[peer_id])
			var ids: Array[int] = []
			for member_id in _rooms[room_id]["members"]:
				ids.append(int(member_id))
			if int(peer_id) == multiplayer.get_unique_id():
				local_room_changed.emit(room_id, ids)
			else:
				_rpc_receive_local_room.rpc_id(int(peer_id), room_id, ids)


func _public_room_snapshot() -> Array:
	var result: Array = []
	for room_id in _rooms.keys():
		var room: Dictionary = _rooms[room_id]
		result.append({
			"id": String(room_id),
			"name": String(room["name"]),
			"capacity": int(room["capacity"]),
			"member_count": room["members"].size()
		})
	return result


func _send_result(peer_id: int, ok: bool, message: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		room_action_result.emit(ok, message)
	else:
		_rpc_room_result.rpc_id(peer_id, ok, message)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_room_snapshot() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1 or not multiplayer.get_peers().has(sender):
		return
	_rpc_receive_room_snapshot.rpc_id(sender, _public_room_snapshot())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_create_room(room_name: String, capacity: int) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1 or not multiplayer.get_peers().has(sender):
		return
	if room_name.length() > 32 or room_name.strip_edges().length() < 2 or room_name.strip_edges().length() > 32:
		_send_result(sender, false, "Nama room tidak valid.")
		return
	_create_room_for_peer(sender, room_name.strip_edges(), clampi(capacity, 2, 64))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_join_room(room_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var clean_id := room_id.strip_edges()
	if sender <= 1 or not multiplayer.get_peers().has(sender):
		return
	if room_id.length() > 64 or clean_id.length() < 3 or clean_id.length() > 64:
		_send_result(sender, false, "ID room tidak valid.")
		return
	if clean_id == "lobby":
		_join_or_create_lobby(sender)
		_send_result(sender, true, "Berhasil masuk ke Lobby.")
		_broadcast_room_state()
	else:
		_join_room_for_peer(sender, clean_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_leave_room() -> void:
	if multiplayer.is_server():
		var sender := multiplayer.get_remote_sender_id()
		if sender <= 1 or not multiplayer.get_peers().has(sender):
			return
		_leave_room_for_peer(sender)
		_join_or_create_lobby(sender)
		_broadcast_room_state()


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_room_snapshot(snapshot: Array) -> void:
	_client_room_snapshot = snapshot.duplicate(true)
	room_list_changed.emit(_client_room_snapshot.duplicate(true))


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_local_room(room_id: String, members: Array) -> void:
	var typed_members: Array[int] = []
	for member_id in members:
		typed_members.append(int(member_id))
	local_room_changed.emit(room_id, typed_members)


@rpc("authority", "call_remote", "reliable")
func _rpc_room_result(ok: bool, message: String) -> void:
	room_action_result.emit(ok, message)


## Server-side membership queries for trusted room-scoped systems.
func get_peer_room_id(peer_id: int) -> String:
	if not multiplayer.is_server():
		return ""
	return String(_peer_room.get(peer_id, ""))


func get_room_peer_ids(room_id: String) -> Array[int]:
	var result: Array[int] = []
	if not multiplayer.is_server() or not _rooms.has(room_id):
		return result
	for peer_id in _rooms[room_id]["members"]:
		result.append(int(peer_id))
	return result
