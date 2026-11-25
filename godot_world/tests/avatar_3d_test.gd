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
	var default_appearance: Dictionary = avatar.call("get_appearance_snapshot")
	_expect(default_appearance.has("trousers") and default_appearance.has("shoes"), "snapshot should include lower-body and footwear colors")
	_expect(avatar.get_child_count() >= 12, "avatar should generate a substantial mesh structure")
	_expect(avatar.get_node_or_null("WingVein_Left_0") != null, "left translucent wing vein detail should exist")
	_expect(avatar.get_node_or_null("WingVein_Right_2") != null, "right translucent wing vein detail should exist")
	_expect(avatar.get_node_or_null("LeftShoulderCap") != null, "left shoulder detail should exist")
	_expect(avatar.get_node_or_null("RightShoulderCap") != null, "right shoulder detail should exist")
	_expect(avatar.get_node_or_null("LeftShoeSole") != null, "left shoe sole detail should exist")
	_expect(avatar.get_node_or_null("RightShoeUpper") != null, "right shoe upper detail should exist")
	_expect(avatar.get_node_or_null("Head/LeftEarInner") != null, "left ear inner detail should exist")
	_expect(avatar.get_node_or_null("Head/RightEarInner") != null, "right ear inner detail should exist")
	_expect(avatar.get_node_or_null("LeftLeg/LeftLace_0") != null, "left shoe lace detail should exist")
	_expect(avatar.get_node_or_null("RightLeg/RightLace_2") != null, "right shoe lace detail should exist")
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
	avatar.call("play_action", "sit")
	_expect(avatar.call("is_seated") == true, "sit action should set seated state")
	avatar.call("stand_up")
	_expect(avatar.call("is_seated") == false, "stand_up should clear seated state")
	avatar.call("set_motion_strength", 0.75)
	_expect(is_equal_approx(avatar.call("get_motion_strength"), 0.0), "motion strength should blend rather than jump immediately")
	avatar.call("apply_appearance", {"skin": "#e0b080", "hair": "#663399", "top": "#ff0000", "trousers": "#112233", "shoes": "#00ff00"})
	var updated_appearance: Dictionary = avatar.call("get_appearance_snapshot")
	_expect(updated_appearance.has("top") and updated_appearance.has("shoes"), "appearance preview should retain clothing slots")
	_expect(updated_appearance["top"] == Color.from_string("#ff0000", Color.WHITE).to_html(true), "appearance preview should apply requested clothing color")
	avatar.call("reset_appearance_preview")
	var reset_appearance: Dictionary = avatar.call("get_appearance_snapshot")
	_expect(reset_appearance["top"] != Color.from_string("#ff0000", Color.WHITE).to_html(true), "appearance preview should restore default top color")
	for slot in ["skin", "hair", "top", "trousers", "shoes"]:
		_expect(reset_appearance[slot] == default_appearance[slot], "reset should restore default color for " + slot)
	if failures == 0:
		print("AVATAR_3D_TEST: PASS — head, name label, materials, shoulder and shoe details")
	else:
		push_error("AVATAR_3D_TEST: %d assertion(s) failed" % failures)
	avatar.queue_free()
	quit(0 if failures == 0 else 1)
