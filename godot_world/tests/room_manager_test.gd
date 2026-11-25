extends SceneTree

const RoomManagerScript = preload("res://scripts/room_manager.gd")
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run_room_manager_tests")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("ROOM_MANAGER_TEST: " + message)


func _run_room_manager_tests() -> void:
	# Exercise host-side snapshot behavior under Godot offline peer semantics.
	var manager = RoomManagerScript.new()
	manager.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	root.add_child(manager)
	manager.default_room_capacity = 2

	# Room names containing control characters must be rejected before dispatch.
	var invalid_name_rejected := false
	manager.room_action_result.connect(func(ok: bool, _message: String):
		if not ok:
			invalid_name_rejected = true
	)
	manager.create_room("Bad\nRoom", 2)
	_expect(invalid_name_rejected, "room names containing control characters must be rejected")
	_expect(not manager._is_valid_room_name("Bad\nRoom"), "server validator must reject control characters")
	_expect(not manager._is_valid_room_name("A"), "server validator must reject names shorter than two characters")
	_expect(not manager._is_valid_room_name("X".repeat(33)), "server validator must reject names longer than 32 characters")
	_expect(manager._is_valid_room_name("Valid Room"), "server validator must accept valid room names")
	_expect(manager._is_valid_room_id("lobby"), "canonical lobby ID must be accepted")
	_expect(manager._is_valid_room_id("room_2_12345"), "generated room IDs must be accepted")
	_expect(not manager._is_valid_room_id("room\ninvalid"), "room IDs containing control characters must be rejected")
	_expect(not manager._is_valid_room_id(""), "empty room IDs must be rejected")
	_expect(not manager._is_valid_room_id("X".repeat(65)), "room IDs longer than 64 characters must be rejected")

	# Five connected peers at capacity two must be assigned exactly once
	# across three lobby shards.
	for peer_id in range(1, 6):
		manager._join_or_create_lobby(peer_id)

	_expect(manager._peer_room.size() == 5, "all connected peers must have a room assignment")
	_expect(manager.get_room_snapshot().size() == 3, "host room snapshot API must expose live lobby shards even with offline transport")
	_expect(manager._rooms.size() == 3, "five peers with capacity two must create three lobby shards")
	_expect(manager._rooms.has("lobby"), "the primary lobby ID must remain canonical")
	_expect(manager._rooms.has("lobby_2"), "the second lobby shard must use lobby_2")
	_expect(manager._rooms.has("lobby_3"), "the third lobby shard must use lobby_3")

	var seen_peers: Dictionary = {}
	for room_id in manager._rooms.keys():
		var room: Dictionary = manager._rooms[room_id]
		var members: Array = room["members"]
		_expect(members.size() <= 2, "lobby capacity must never be exceeded")
		for peer_id in members:
			_expect(not seen_peers.has(peer_id), "a peer must not appear in multiple lobbies")
			seen_peers[peer_id] = true
	_expect(seen_peers.size() == 5, "every peer must appear in exactly one lobby")
	_expect(manager._peer_room.get(5, "") == "lobby_3", "least-populated selection should fill shards evenly")

	# Removing the only member from a shard must delete that empty shard.
	manager._leave_room_for_peer(5)
	_expect(not manager._rooms.has("lobby_3"), "empty secondary lobby shards must be removed")
	_expect(not manager._peer_room.has(5), "leaving must clear the peer-to-room index")

	# Rejoining after a disconnect must produce a valid membership without
	# duplicating the peer in another room.
	manager._join_or_create_lobby(5)
	_expect(manager._peer_room.has(5), "rejoining peer must receive a lobby assignment")
	var rejoin_occurrences := 0
	for room_id in manager._rooms.keys():
		rejoin_occurrences += manager._rooms[room_id]["members"].count(5)
	_expect(rejoin_occurrences == 1, "rejoining peer must occur exactly once")

	# Client-side room snapshots must be cached and returned by the public API.
	var sample_snapshot: Array = [{
		"id": "lobby",
		"name": "Lobby",
		"capacity": 2,
		"member_count": 2
	}]
	manager._rpc_receive_room_snapshot(sample_snapshot)
	_expect(manager.get_room_snapshot().size() == 1, "client snapshot API must return cached room data")
	_expect(manager.get_room_snapshot()[0]["id"] == "lobby", "cached snapshot must preserve room identity")


	# Client snapshot normalization rejects malformed, duplicate, and oversized data.
	var incoming_rooms: Array = [
		{"id": "lobby", "name": "Lobby", "capacity": 16, "member_count": 3, "extra": "stripped"},
		{"id": "lobby", "name": "Duplicate", "capacity": 16, "member_count": 1},
		{"id": "bad room", "name": "Unsafe", "capacity": 4, "member_count": 1},
		{"id": "room_bad", "name": "Over capacity", "capacity": 2, "member_count": 3},
		{"id": "room_valid", "name": "Valid Room", "capacity": 8, "member_count": 4}
	]
	var normalized := manager._sanitize_room_snapshot(incoming_rooms)
	_expect(normalized.size() == 2, "only valid, unique room cards should survive snapshot normalization")
	_expect(normalized[0].id == "lobby" and not normalized[0].has("extra"), "snapshot output must normalize fields and strip extras")
	_expect(normalized[1].id == "room_valid", "second valid room must remain in order")

	# Custom-room lifecycle: joining a room must remove the peer from the
	# previous lobby, and an empty custom room must be cleaned up.
	manager._rooms["room_test"] = {"name": "Test Room", "capacity": 2, "members": []}
	manager._join_room_for_peer(1, "room_test")
	_expect(manager._peer_room.get(1, "") == "room_test", "joining a custom room must update the peer index")
	_expect(not manager._rooms["lobby"]["members"].has(1), "switching rooms must remove the peer from its previous lobby")
	_expect(manager._rooms["room_test"]["members"].has(1), "switching rooms must add the peer to the destination room")
	manager._leave_room_for_peer(1)
	_expect(not manager._rooms.has("room_test"), "empty custom rooms must be removed")
	_expect(not manager._peer_room.has(1), "leaving a custom room must clear peer membership")

	# A room at capacity rejects another member without corrupting either index.
	manager._rooms["room_full"] = {"name": "Full Room", "capacity": 1, "members": [2]}
	manager._peer_room[2] = "room_full"
	manager._join_room_for_peer(1, "room_full")
	_expect(manager._peer_room.get(1, "") != "room_full", "a full room must reject additional members")
	_expect(manager._rooms["room_full"]["members"].size() == 1, "a full room must retain its original member")
	manager._rooms.erase("room_full")
	manager._peer_room.erase(2)

	# The custom-room cap excludes every lobby shard and stops at 64 rooms.
	manager._rooms.clear()
	manager._peer_room.clear()
	for room_index in range(RoomManagerScript.MAX_ACTIVE_ROOMS):
		manager._rooms["room_cap_%d" % room_index] = {
			"name": "Cap Test %d" % room_index,
			"capacity": 2,
			"members": []
		}
	_expect(manager._rooms.size() == RoomManagerScript.MAX_ACTIVE_ROOMS, "64 existing custom rooms must be represented")
	manager._last_room_create_at[1] = -10000.0
	manager._create_room_for_peer(1, "Overflow Room", 2)
	var custom_room_count_after_rejection := 0
	for room_key in manager._rooms.keys():
		var room_id := str(room_key)
		if room_id != "lobby" and not room_id.begins_with("lobby_"):
			custom_room_count_after_rejection += 1
	_expect(custom_room_count_after_rejection == RoomManagerScript.MAX_ACTIVE_ROOMS, "the 65th custom room must be rejected")

	# Host-local creation must also respect the five-second cooldown.
	manager._rooms.clear()
	manager._peer_room.clear()
	manager._last_room_create_at[1] = Time.get_ticks_msec() / 1000.0
	manager._create_room_for_peer(1, "Cooldown Test", 2)
	_expect(manager._rooms.is_empty(), "host-local room creation must respect the cooldown")

	# Internal room creation rejects invalid names and clamps capacity even if bypassing public API.
	manager._rooms.clear()
	manager._peer_room.clear()
	manager._last_room_create_at[1] = -10000.0
	manager._create_room_for_peer(1, "Bad\\nName", 2)
	_expect(manager._rooms.is_empty(), "internal room creation must reject control-character names")
	manager._create_room_for_peer(1, "  Valid Internal  ", 100)
	var internal_room_id := String(manager._peer_room.get(1, ""))
	_expect(not internal_room_id.is_empty(), "internal creation should accept a trimmed valid name")
	if manager._rooms.has(internal_room_id):
		_expect(manager._rooms[internal_room_id]["name"] == "Valid Internal", "internal room name must be trimmed")
		_expect(manager._rooms[internal_room_id]["capacity"] == 64, "internal creation must clamp capacity to 64")

	# Successful host-local creation must register a room and membership once
	# the cooldown has elapsed; the guard must not block legitimate creation.
	manager._last_room_create_at[1] = -10000.0
	manager._create_room_for_peer(1, "Host Created Room", 3)
	var host_created_room_id := String(manager._peer_room.get(1, ""))
	_expect(not host_created_room_id.is_empty(), "host-local creation should succeed when cooldown expires")
	_expect(manager._rooms.has(host_created_room_id), "successful creation must register the room")
	if manager._rooms.has(host_created_room_id):
		_expect(manager._rooms[host_created_room_id]["members"].count(1) == 1, "host must join its newly created room exactly once")
		_expect(manager._rooms[host_created_room_id]["capacity"] == 3, "room creation must retain selected capacity")

	if failures == 0:
		print("ROOM_MANAGER_TEST: PASS — lobby sharding, capacity, unique membership, cleanup, rejoin and client snapshot cache")
	else:
		push_error("ROOM_MANAGER_TEST: %d assertion(s) failed" % failures)
	manager.free()
	quit(0 if failures == 0 else 1)
