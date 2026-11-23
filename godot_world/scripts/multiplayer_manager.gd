extends Node
## LAN multiplayer transport foundation. No account identity or gameplay authority is assigned here.

signal connection_state_changed(state: String, detail: String)
signal peer_roster_changed(peer_ids: Array[int])

@export var default_port: int = 24560
@export_range(1, 64, 1) var max_clients: int = 16

var connection_state: String = "offline"
var connection_detail: String = "Belum terhubung"
var peer_ids: Array[int] = []
var _status_label: Label
var _remote_players: Dictionary = {}
var _sync_accumulator: float = 0.0
const SYNC_INTERVAL: float = 0.05
const REMOTE_AVATAR_SCRIPT: Script = preload("res://scripts/network_avatar.gd")


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_create_status_hud()
	_update_status("offline", "LAN multiplayer siap")


func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	_sync_accumulator += delta
	if _sync_accumulator >= SYNC_INTERVAL:
		_sync_accumulator = 0.0
		_publish_local_player_state()


func host_game(port: int = -1) -> Error:
	var chosen_port := default_port if port <= 0 else port
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(chosen_port, max_clients)
	if result != OK:
		_update_status("error", "Gagal membuka host. Kode: %s" % result)
		return result
	multiplayer.multiplayer_peer = peer
	_clear_remote_players()
	peer_ids.clear()
	peer_ids.append(multiplayer.get_unique_id())
	_emit_roster()
	_update_status("hosting", "Host LAN aktif di port %d" % chosen_port)
	return OK


func join_game(address: String, port: int = -1) -> Error:
	var host_address := address.strip_edges()
	if host_address.is_empty():
		_update_status("error", "Alamat host belum diisi")
		return ERR_INVALID_PARAMETER
	var chosen_port := default_port if port <= 0 else port
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(host_address, chosen_port)
	if result != OK:
		_update_status("error", "Gagal memulai koneksi. Kode: %s" % result)
		return result
	multiplayer.multiplayer_peer = peer
	peer_ids.clear()
	_update_status("connecting", "Menghubungkan ke %s:%d" % [host_address, chosen_port])
	return OK


func leave_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_clear_remote_players()
	peer_ids.clear()
	_emit_roster()
	_update_status("offline", "Koneksi diputus")


func get_peer_roster() -> Array[int]:
	return peer_ids.duplicate()


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_rpc_spawn_remote.rpc(id)
		for existing_id in peer_ids:
			if existing_id != multiplayer.get_unique_id():
				_rpc_spawn_remote.rpc_id(id, existing_id)
	if not peer_ids.has(id):
		peer_ids.append(id)
		peer_ids.sort()
	_emit_roster()
	_update_status(connection_state, "Peer %d terhubung" % id)


func _on_peer_disconnected(id: int) -> void:
	peer_ids.erase(id)
	_remove_remote_player(id)
	if multiplayer.is_server():
		_rpc_remove_remote.rpc(id)
	_emit_roster()
	_update_status(connection_state, "Peer %d terputus" % id)


func _on_connected_to_server() -> void:
	_request_peer_roster.rpc_id(1)
	var local_id := multiplayer.get_unique_id()
	if not peer_ids.has(local_id):
		peer_ids.append(local_id)
	peer_ids.sort()
	_emit_roster()
	_update_status("connected", "Terhubung ke host LAN")


func _on_connection_failed() -> void:
	leave_game()
	_update_status("error", "Koneksi ke host gagal")


func _on_server_disconnected() -> void:
	leave_game()
	_update_status("offline", "Host memutus koneksi")



func _publish_local_player_state() -> void:
	var player := get_parent().get_node_or_null("Player") as CharacterBody3D
	if player == null:
		return
	var avatar := player.get_node_or_null("AvatarVisual")
	var motion := 0.0
	if avatar != null and avatar.has_method("get_motion_strength"):
		motion = float(avatar.get_motion_strength())
	var local_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		_apply_remote_state(local_id, player.global_position, player.rotation.y, motion)
		_rpc_apply_state.rpc(local_id, player.global_position, player.rotation.y, motion)
	else:
		_rpc_submit_state.rpc_id(1, player.global_position, player.rotation.y, motion)


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_submit_state(position_value: Vector3, rotation_value: float, motion_value: float) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1:
		return
	_apply_remote_state(sender_id, position_value, rotation_value, motion_value)
	_rpc_apply_state.rpc(sender_id, position_value, rotation_value, motion_value)


@rpc("authority", "call_remote", "unreliable")
func _rpc_apply_state(peer_id: int, position_value: Vector3, rotation_value: float, motion_value: float) -> void:
	_apply_remote_state(peer_id, position_value, rotation_value, motion_value)


@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_remote(peer_id: int) -> void:
	_ensure_remote_player(peer_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_remove_remote(peer_id: int) -> void:
	_remove_remote_player(peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_peer_roster() -> void:
	if not multiplayer.is_server():
		return
	var requester := multiplayer.get_remote_sender_id()
	for peer_id in peer_ids:
		if peer_id != requester:
			_rpc_spawn_remote.rpc_id(requester, peer_id)


func _ensure_remote_player(peer_id: int) -> void:
	if peer_id == multiplayer.get_unique_id() or _remote_players.has(peer_id):
		return
	var remote := Node3D.new()
	remote.name = "RemotePlayer_%d" % peer_id
	remote.set_script(REMOTE_AVATAR_SCRIPT)
	remote.set("peer_id", peer_id)
	get_parent().add_child(remote)
	_remote_players[peer_id] = remote


func _apply_remote_state(peer_id: int, position_value: Vector3, rotation_value: float, motion_value: float) -> void:
	_ensure_remote_player(peer_id)
	var remote = _remote_players.get(peer_id)
	if is_instance_valid(remote) and remote.has_method("apply_network_state"):
		remote.apply_network_state(position_value, rotation_value, motion_value)


func _remove_remote_player(peer_id: int) -> void:
	var remote = _remote_players.get(peer_id)
	if is_instance_valid(remote):
		remote.queue_free()
	_remote_players.erase(peer_id)


func _clear_remote_players() -> void:
	for peer_id in _remote_players.keys():
		_remove_remote_player(int(peer_id))


func _emit_roster() -> void:
	peer_roster_changed.emit(peer_ids.duplicate())


func _update_status(state: String, detail: String) -> void:
	connection_state = state
	connection_detail = detail
	if is_instance_valid(_status_label):
		_status_label.text = "FAMILY COLONY  •  %s  •  %d peer\n%s" % [state.to_upper(), peer_ids.size(), detail]
	connection_state_changed.emit(connection_state, connection_detail)


func _create_status_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "NetworkStatusHUD"
	layer.layer = 20
	add_child(layer)
	_status_label = Label.new()
	_status_label.name = "NetworkStatus"
	_status_label.position = Vector2(18, 16)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.95))
	_status_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.07, 0.9))
	_status_label.add_theme_constant_override("shadow_offset_x", 1)
	_status_label.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(_status_label)

func broadcast_social_action(action_id: String) -> void:
	if action_id not in ["wave", "sit", "stand"]:
		return
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	var local_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		_rpc_social_action.rpc(local_id, action_id)
	else:
		_rpc_request_social_action.rpc_id(1, action_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_social_action(action_id: String) -> void:
	if not multiplayer.is_server() or action_id not in ["wave", "sit", "stand"]:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1 or not peer_ids.has(sender_id):
		return
	_rpc_social_action.rpc(sender_id, action_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_social_action(peer_id: int, action_id: String) -> void:
	if action_id not in ["wave", "sit", "stand"]:
		return
	var remote = _remote_players.get(peer_id)
	if is_instance_valid(remote) and remote.has_method("play_network_action"):
		remote.play_network_action(action_id)
