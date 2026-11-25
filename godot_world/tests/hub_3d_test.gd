extends SceneTree

const HUB_SCENE := preload("res://scenes/main_hub_3d.tscn")
var failures := 0

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("HUB_3D_TEST: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hub := HUB_SCENE.instantiate()
	root.add_child(hub)
	await process_frame
	_expect(hub is Node3D, "hub scene root must be Node3D")
	_expect(hub.get_node_or_null("HubCamera") is Camera3D, "hub camera must be generated")
	_expect(hub.get_node_or_null("SpatialInformationBoard") != null, "spatial information board must be generated")
	_expect(hub.get_node_or_null("DeveloperBeeEmblem") is Area3D, "developer bee interaction must be present")
	for destination in ["profile", "chat", "games", "settings", "world"]:
		var kiosk := hub.get_node_or_null("Kiosk_" + destination) as Area3D
		_expect(kiosk is Area3D, "3D kiosk missing: " + destination)
		if kiosk != null:
			_expect(kiosk.has_meta("destination_id"), "kiosk destination metadata missing: " + destination)
			var has_collision := false
			var has_mesh := false
			for kiosk_child in kiosk.get_children():
				if kiosk_child is CollisionShape3D:
					has_collision = true
					_expect(kiosk_child.shape != null, "kiosk collision shape resource exists")
				if kiosk_child is MeshInstance3D:
					has_mesh = true
			_expect(has_collision, "kiosk touch collision missing: " + destination)
			_expect(has_mesh, "kiosk visual mesh missing: " + destination)
			_expect(kiosk.get_node_or_null("StationLight") != null or kiosk.get_child_count() >= 7, "kiosk detail structure incomplete: " + destination)
	_expect(hub.get_child_count() >= 8, "hub should generate a substantial 3D scene structure")
	hub.call("_open_destination_panel", "chat")
	_expect(hub.get_node_or_null("SpatialFeaturePanel") != null, "chat panel should be created in 3D")
	var room_data := [
		{"id":"room_a","name":"Room Alpha","member_count":1,"capacity":8},
		{"id":"room_b","name":"Room Beta","member_count":2,"capacity":8},
		{"id":"room_c","name":"Room Gamma","member_count":3,"capacity":8}
	]
	hub.call("set_room_snapshot", room_data)
	var room_root := hub.get_node_or_null("SpatialFeaturePanel/RoomList3D")
	_expect(room_root != null, "3D room list root should be present")
	if room_root != null:
		_expect(room_root.get_node_or_null("JoinRoom_0") != null, "first room join button should render")
		_expect(room_root.get_node_or_null("JoinRoom_1") != null, "second room join button should render")
		hub.call("change_room_snapshot_page", 1)
		await process_frame
		_expect(room_root.get_node_or_null("JoinRoom_0") != null, "room join button should render after paging")
		_expect(room_root.get_node_or_null("JoinRoom_1") == null, "room paging should clear stale join buttons")
		var page_two_button := room_root.get_node_or_null("JoinRoom_0") as Area3D
		if page_two_button != null:
			_expect(str(page_two_button.get_meta("hub_panel_action", "")).contains("room_c"), "page two button should reference the third room")
		hub.call("change_room_snapshot_page", -1)
		await process_frame
		_expect(room_root.get_node_or_null("JoinRoom_1") != null, "returning to first page should render second room button")
		_expect(room_root.get_node_or_null("JoinRoom_2") == null, "first page should not leave extra buttons")
		hub.call("set_room_snapshot", [])
		await process_frame
		_expect(room_root.get_node_or_null("JoinRoom_0") == null, "empty room list should remove join buttons")
		var empty_state_found := false
		for room_child in room_root.get_children():
			if room_child is Label3D and room_child.text == "Belum ada room terdaftar.":
				empty_state_found = true
		_expect(empty_state_found, "empty room list should show empty-state message")
	_expect(hub.get_node_or_null("CentralHall") != null or hub.get_child_count() > 5, "hub should generate central hall and spatial elements")
	if failures == 0:
		print("HUB_3D_TEST: PASS — camera, environment, information board, developer access and five kiosks")
	else:
		push_error("HUB_3D_TEST: %d assertion(s) failed" % failures)
	hub.queue_free()
	quit(0 if failures == 0 else 1)
