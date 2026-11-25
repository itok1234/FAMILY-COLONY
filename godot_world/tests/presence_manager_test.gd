extends SceneTree
## Unit checks for presence snapshot filtering.

const PresenceManagerScript = preload("res://scripts/presence_manager.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("PRESENCE_MANAGER_TEST: " + message)

func _run_tests() -> void:
	var manager = PresenceManagerScript.new()
	var input_snapshot: Array = [
		{"peer_id": 2, "state": "online"},
		{"peer_id": 3, "state": "online", "display_name": "Member"},
		{"peer_id": -1, "state": "online"},
		{"peer_id": 4, "state": "offline"},
		{"peer_id": "5", "state": "online"},
		{"peer_id": 6, "state": "online", "extra": "untrusted"}
	]
	var clean := manager._sanitize_presence_snapshot(input_snapshot)
	_expect(clean.size() == 3, "only positive integer peer IDs and online state should survive")
	_expect(clean[0].peer_id == 2, "valid first entry should be retained")
	_expect(clean[1].peer_id == 3 and clean[1].state == "online", "valid online entry should survive")
	_expect(clean[2].peer_id == 6 and not clean[2].has("extra") and not clean[2].has("display_name"), "unrecognized fields should be discarded")
	_expect(manager._sanitize_presence_snapshot([]).is_empty(), "empty snapshots should remain empty")
	var duplicate_snapshot: Array = [
		{"peer_id": 8, "state": "online"},
		{"peer_id": 8, "state": "online"},
		{"peer_id": 9, "state": "online"}
	]
	var deduplicated := manager._sanitize_presence_snapshot(duplicate_snapshot)
	_expect(deduplicated.size() == 2, "duplicate peer IDs should be discarded")
	var oversized: Array = []
	for peer_id in range(2, 80):
		oversized.append({"peer_id": peer_id, "state": "online"})
	_expect(manager._sanitize_presence_snapshot(oversized).size() == 64, "snapshot should be capped at 64 entries")
	if failures == 0:
		print("PRESENCE_MANAGER_TEST: PASS — snapshot entries filtered and bounded")
	else:
		push_error("PRESENCE_MANAGER_TEST: %d assertion(s) failed" % failures)
	manager.free()
	quit(0 if failures == 0 else 1)
