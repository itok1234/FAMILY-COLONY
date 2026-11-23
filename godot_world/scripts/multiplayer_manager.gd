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


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_create_status_hud()
	_update_status("offline", "LAN multiplayer siap")


func host_game(port: int = -1) -> Error:
	var chosen_port := default_port if port <= 0 else port
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(chosen_port, max_clients)
	if result != OK:
		_update_status("error", "Gagal membuka host. Kode: %s" % result)
		return result
	multiplayer.multiplayer_peer = peer
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
	peer_ids.clear()
	_emit_roster()
	_update_status("offline", "Koneksi diputus")


func get_peer_roster() -> Array[int]:
	return peer_ids.duplicate()


func _on_peer_connected(id: int) -> void:
	if not peer_ids.has(id):
		peer_ids.append(id)
		peer_ids.sort()
	_emit_roster()
	_update_status(connection_state, "Peer %d terhubung" % id)


func _on_peer_disconnected(id: int) -> void:
	peer_ids.erase(id)
	_emit_roster()
	_update_status(connection_state, "Peer %d terputus" % id)


func _on_connected_to_server() -> void:
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
