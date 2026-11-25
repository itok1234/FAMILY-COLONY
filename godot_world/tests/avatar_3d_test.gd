extends SceneTree

const AVATAR_SCRIPT := preload("res://scripts/avatar_visual.gd")
var failures := 0

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("AVATAR_3D_TEST: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var avatar := Node3D.new()
	avatar.set_script(AVATAR_SCRIPT)
	root.add_child(avatar)
	await process_frame
	_expect(avatar.get_node_or_null("Head") != null, "procedural head should be generated")
	_expect(avatar.get_node_or_null("VerifiedMemberName") is Label3D, "member name label should exist")
	_expect(avatar.get_appearance_snapshot().has("skin"), "appearance snapshot should include skin material")
	_expect(avatar.get_appearance_snapshot().has("hair"), "appearance snapshot should include hair material")
	_expect(avatar.get_appearance_snapshot().has("top"), "appearance snapshot should include clothing material")
	_expect(avatar.get_child_count() >= 12, "avatar should generate a substantial mesh structure")
	_expect(avatar.get_node_or_null("LeftShoulderCap") != null, "left shoulder detail should exist")
	_expect(avatar.get_node_or_null("RightShoulderCap") != null, "right shoulder detail should exist")
	_expect(avatar.get_node_or_null("LeftShoeSole") != null, "left shoe sole detail should exist")
	_expect(avatar.get_node_or_null("RightShoeUpper") != null, "right shoe upper detail should exist")
	_expect(avatar.get_node_or_null("BackpackBody") != null, "backpack body should be generated")
	_expect(avatar.get_node_or_null("BackpackTopFlap") != null, "backpack flap detail should exist")
	_expect(avatar.get_node_or_null("BackpackLeftStrap") != null, "backpack strap should exist")
	_expect(avatar.get_node_or_null("BackpackBadge") != null, "backpack badge should exist")
	_expect(avatar.get_node_or_null("BackpackLeftPocket") != null, "left backpack pocket should exist")
	_expect(avatar.get_node_or_null("BackpackRightPocket") != null, "right backpack pocket should exist")
	avatar.call("set_display_name", "Regression Member")
	_expect(avatar.get_node("VerifiedMemberName").text == "Regression Member", "member display name should update")
	avatar.call("play_action", "wave")
	_expect(avatar.get_node_or_null("Head") != null, "wave action must preserve avatar structure")
	if failures == 0:
		print("AVATAR_3D_TEST: PASS — head, name label, materials, shoulder and shoe details")
	else:
		push_error("AVATAR_3D_TEST: %d assertion(s) failed" % failures)
	avatar.queue_free()
	quit(0 if failures == 0 else 1)
