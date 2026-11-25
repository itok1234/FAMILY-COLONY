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
	var manager = RoomManagerScript.new()
	root.add_child(manager)
	manager.default_room_capacity = 2

	# Five connected peers at capacity two must be assigned exactly once
	# across three lobby shards.
	for peer_id in range(1, 6):
		manager._join_or_create_lobby(peer_id)

	_expect(manager._peer_room.size() == 5, "all connected peers must have a room assignment")
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

	if failures == 0:
		print("ROOM_MANAGER_TEST: PASS — lobby sharding, capacity, unique membership, cleanup, rejoin and client snapshot cache")
	else:
		push_error("ROOM_MANAGER_TEST: %d assertion(s) failed" % failures)
	manager.free()
	quit(0 if failures == 0 else 1)
