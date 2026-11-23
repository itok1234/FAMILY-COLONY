extends Node
## Session presence layer keyed by transport peer IDs only.
## A peer ID is not a verified FAMILY COLONY member identity.

signal presence_snapshot_changed(snapshot: Array)
signal peer_presence_changed(peer_id: int, state: String)

var _presence: Dictionary = {}
var _last_snapshot_request_at: Dictionary = {}
var _network: Node


func _ready() -> void:
	_network = get_parent().get_node_or_null("MultiplayerManager")
	if _network == null:
		push_warning("FAMILY COLONY: MultiplayerManager is missing.")
		return
	_network.peer_roster_changed.connect(_on_peer_roster_changed)
	_network.connection_state_changed.connect(_on_connection_state_changed)


func get_presence_snapshot() -> Array:
	return _snapshot()


func _on_connection_state_changed(state: String, _detail: String) -> void:
	if state == "connected":
		_rpc_request_presence_snapshot.rpc_id(1)
	elif state == "offline" or state == "error":
		_presence.clear()
		presence_snapshot_changed.emit([])


func _on_peer_roster_changed(peer_ids: Array[int]) -> void:
	if not multiplayer.is_server():
		return
	for peer_id in peer_ids:
		if not _presence.has(peer_id):
			_presence[peer_id] = {"peer_id": peer_id, "state": "online"}
			peer_presence_changed.emit(peer_id, "online")
	for peer_id in _presence.keys():
		if not peer_ids.has(int(peer_id)):
			_presence.erase(peer_id)
			_last_snapshot_request_at.erase(int(peer_id))
			peer_presence_changed.emit(int(peer_id), "offline")
	_broadcast_snapshot()


func _snapshot() -> Array:
	var result: Array = []
	for peer_id in _presence.keys():
		result.append(_presence[peer_id].duplicate())
	return result


func _broadcast_snapshot() -> void:
	var current := _snapshot()
	presence_snapshot_changed.emit(current)
	if multiplayer.is_server():
		_rpc_receive_presence_snapshot.rpc(current)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_presence_snapshot() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1 or not multiplayer.get_peers().has(sender):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var last_request := float(_last_snapshot_request_at.get(sender, -10000.0))
	if now - last_request < 1.0:
		return
	_last_snapshot_request_at[sender] = now
	_rpc_receive_presence_snapshot.rpc_id(sender, _snapshot())


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_presence_snapshot(snapshot: Array) -> void:
	presence_snapshot_changed.emit(snapshot)
