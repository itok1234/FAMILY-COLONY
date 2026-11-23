extends Node
## Room-scoped presence transport keyed by ENet peer IDs only.
## A peer ID is not a verified FAMILY COLONY member identity.

signal presence_snapshot_changed(snapshot: Array)
signal peer_presence_changed(peer_id: int, state: String)

var _presence: Dictionary = {}
var _last_snapshot_request_at: Dictionary = {}
var _network: Node
var _rooms: Node
var _current_room_id: String = ""


func _ready() -> void:
	_network = get_parent().get_node_or_null("MultiplayerManager")
	_rooms = get_parent().get_node_or_null("RoomManager")
	if _network == null or _rooms == null:
		push_warning("FAMILY COLONY: PresenceManager requires MultiplayerManager and RoomManager.")
		return
	_network.peer_roster_changed.connect(_on_peer_roster_changed)
	_network.connection_state_changed.connect(_on_connection_state_changed)
	if _rooms.has_signal("local_room_changed"):
		_rooms.local_room_changed.connect(_on_local_room_changed)
	if _rooms.has_signal("room_list_changed"):
		_rooms.room_list_changed.connect(_on_room_list_changed)


func get_presence_snapshot() -> Array:
	if _current_room_id.is_empty():
		return []
	if multiplayer.is_server():
		return _snapshot_for_room(_current_room_id)
	return []


func _on_connection_state_changed(state: String, _detail: String) -> void:
	if state == "connected":
		_request_current_room_snapshot()
	elif state == "offline" or state == "error":
		_presence.clear()
		_current_room_id = ""
		presence_snapshot_changed.emit([])


func _on_local_room_changed(room_id: String, _members: Array[int]) -> void:
	_current_room_id = room_id
	if multiplayer.is_server():
		presence_snapshot_changed.emit(_snapshot_for_room(room_id))
	else:
		_request_current_room_snapshot()


func _on_room_list_changed(_rooms_snapshot: Array) -> void:
	if multiplayer.is_server():
		_broadcast_room_snapshots()


func _request_current_room_snapshot() -> void:
	if _current_room_id.is_empty():
		presence_snapshot_changed.emit([])
		return
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	if multiplayer.is_server():
		presence_snapshot_changed.emit(_snapshot_for_room(_current_room_id))
	else:
		_rpc_request_presence_snapshot.rpc_id(1)


func _on_peer_roster_changed(peer_ids: Array[int]) -> void:
	if not multiplayer.is_server():
		return
	for peer_id in peer_ids:
		if not _presence.has(peer_id):
			_presence[peer_id] = {"peer_id": peer_id, "state": "online"}
			peer_presence_changed.emit(peer_id, "online")
	for peer_id in _presence.keys().duplicate():
		if not peer_ids.has(int(peer_id)):
			_presence.erase(peer_id)
			_last_snapshot_request_at.erase(int(peer_id))
			peer_presence_changed.emit(int(peer_id), "offline")
	_broadcast_room_snapshots()


func _snapshot_for_room(room_id: String) -> Array:
	var result: Array = []
	if room_id.is_empty() or _rooms == null or not multiplayer.is_server():
		return result
	var room_peer_ids: Array = _rooms.call("get_room_peer_ids", room_id)
	for peer_id in room_peer_ids:
		var peer_key := int(peer_id)
		if _presence.has(peer_key):
			result.append(_presence[peer_key].duplicate(true))
	return result


func _broadcast_room_snapshots() -> void:
	if not multiplayer.is_server() or _rooms == null:
		return
	var room_ids: Dictionary = {}
	for peer_id in _presence.keys():
		var room_id := str(_rooms.call("get_peer_room_id", int(peer_id)))
		if not room_id.is_empty():
			room_ids[room_id] = true
	for room_id_variant in room_ids.keys():
		var room_id := str(room_id_variant)
		var snapshot := _snapshot_for_room(room_id)
		var room_peer_ids: Array = _rooms.call("get_room_peer_ids", room_id)
		for peer_id_variant in room_peer_ids:
			var peer_id := int(peer_id_variant)
			if peer_id == multiplayer.get_unique_id():
				if _current_room_id == room_id:
					presence_snapshot_changed.emit(snapshot)
			elif multiplayer.get_peers().has(peer_id):
				_rpc_receive_presence_snapshot.rpc_id(peer_id, room_id, snapshot)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_presence_snapshot() -> void:
	if not multiplayer.is_server() or _rooms == null:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1 or not multiplayer.get_peers().has(sender):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var last_request := float(_last_snapshot_request_at.get(sender, -10000.0))
	if now - last_request < 1.0:
		return
	_last_snapshot_request_at[sender] = now
	var room_id := str(_rooms.call("get_peer_room_id", sender))
	if room_id.is_empty():
		_rpc_receive_presence_snapshot.rpc_id(sender, "", [])
		return
	_rpc_receive_presence_snapshot.rpc_id(sender, room_id, _snapshot_for_room(room_id))


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_presence_snapshot(room_id: String, snapshot: Array) -> void:
	if room_id != _current_room_id:
		return
	presence_snapshot_changed.emit(snapshot)
