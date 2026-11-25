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
	_expect(not manager._is_safe_chat_text("nul" + char(0)), "NUL must be rejected")
	_expect(not manager._is_safe_chat_text("del" + char(127)), "DEL must be rejected")
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
