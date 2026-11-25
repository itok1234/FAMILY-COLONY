extends SceneTree
## Regression tests for room-chat input sanitization.

const ChatManagerScript = preload("res://scripts/chat_manager.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("CHAT_MANAGER_TEST: " + message)

func _run_tests() -> void:
	var manager = ChatManagerScript.new()
	_expect(manager._is_safe_chat_text("Halo Colony!"), "ordinary ASCII text must be accepted")
	_expect(manager._is_safe_chat_text("Selamat datang 🐝"), "Unicode and emoji must be accepted")
	_expect(manager._is_safe_chat_text(""), "empty string is validated separately and should not be classified as unsafe")
	_expect(not manager._is_safe_chat_text("line one\nline two"), "line feed must be rejected")
	_expect(not manager._is_safe_chat_text("line one\rline two"), "carriage return must be rejected")
	_expect(not manager._is_safe_chat_text("tab\ttext"), "tab must be rejected")
	# Godot String may truncate at embedded NUL before this function receives it.
	# Only assert rejection if the test payload survives as a character in the String.
	var nul_payload := "nul" + char(0)
	if nul_payload.length() > 3:
		_expect(not manager._is_safe_chat_text(nul_payload), "embedded NUL must be rejected when representable")
	_expect(not manager._is_safe_chat_text("del" + char(127)), "DEL must be rejected")
	# Incoming packets are normalized; sender labels and extra payload fields cannot be spoofed.
	var incoming := manager._sanitize_received_message({
		"room_id": "room_test", "sender_peer_id": 7, "sender_label": "ADMIN",
		"text": "  Halo Colony  ", "sent_at": 42, "extra": "ignored"
	})
	_expect(incoming.sender_label == "Anggota #7", "sender label must be generated from the peer ID")
	_expect(incoming.text == "Halo Colony", "received text must be trimmed")
	_expect(not incoming.has("extra"), "unrecognized packet fields must be stripped")
	_expect(not manager._sanitize_received_message({"room_id": "r", "sender_peer_id": 1, "text": "hi"}).is_empty(), "host sender messages must be accepted")
	_expect(manager._sanitize_received_message({"room_id": "r", "sender_peer_id": "7", "text": "hi"}).is_empty(), "sender ID must be an integer")
	_expect(manager._sanitize_received_message({"room_id": "r", "sender_peer_id": 7, "text": "bad" + char(10) + "text"}).is_empty(), "unsafe incoming text must be rejected")
	_expect(manager._sanitize_received_message({"room_id": "r", "sender_peer_id": 7, "text": "x".repeat(manager.max_message_characters + 1)}).is_empty(), "oversized incoming text must be rejected")

	# Disconnect cleanup removes departed peers' cooldown entries, preserving host state.
	manager._last_send_at = {1: 1.0, 2: 2.0, 3: 3.0, 8: 4.0}
	var removed := manager._prune_send_timestamps([2, 3], 1)
	_expect(removed == 1, "pruning must remove exactly the disconnected peer timestamp")
	_expect(manager._last_send_at.has(1), "host-local timestamp must be preserved")
	_expect(manager._last_send_at.has(2) and manager._last_send_at.has(3), "connected peer timestamps must be preserved")
	_expect(not manager._last_send_at.has(8), "disconnected peer timestamp must be removed")
	if failures == 0:
		print("CHAT_MANAGER_TEST: PASS — control characters rejected; Unicode accepted; disconnect state pruned")
	else:
		push_error("CHAT_MANAGER_TEST: %d assertion(s) failed" % failures)
	manager.free()
	quit(0 if failures == 0 else 1)
