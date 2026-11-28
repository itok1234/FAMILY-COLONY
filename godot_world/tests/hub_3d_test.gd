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
	_expect(hub.get_node_or_null("PlazaBeacon") is Node3D, "central plaza beacon must exist")
	var beacon := hub.get_node_or_null("PlazaBeacon")
	_expect(beacon.get_child_count() >= 2, "beacon must contain core and illuminated cap elements")
	var camera := hub.get_node_or_null("HubCamera") as Camera3D
	_expect(camera != null and camera.current, "benchmark camera must be active")
	if camera != null:
		_expect(camera.fov >= 50.0 and camera.fov <= 75.0, "benchmark camera FOV must remain within the mobile composition range")
	var accent_count := 0
	var ring_count := 0
	for child in hub.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size == Vector3(0.18, 0.12, 1.25):
			accent_count += 1
		if child is MeshInstance3D and child.mesh is TorusMesh:
			ring_count += 1
	_expect(accent_count >= 12, "central landmark radial accent set must contain twelve pieces")
	_expect(ring_count >= 2, "plaza must retain two inset path rings")
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
	hub.call("_open_destination_panel", "games")
	var games_panel := hub.get_node_or_null("SpatialFeaturePanel")
	_expect(games_panel != null, "mini-game panel should be created in 3D")
	var game_actions := []
	if games_panel != null:
		for game_button in games_panel.get_children():
			if game_button is Area3D and game_button.has_meta("hub_panel_action"):
				var action := str(game_button.get_meta("hub_panel_action"))
				if action.begins_with("game:"):
					game_actions.append(action)
	_expect(game_actions.size() == 4, "Game Center must expose exactly four locked mini-games")
	_expect(game_actions.has("game:guess_who"), "Guess Who entry missing")
	_expect(game_actions.has("game:royal_bomb"), "Royal Bomb entry missing")
	_expect(game_actions.has("game:royal_murder_mystery"), "Royal Murder Mystery entry missing")
	_expect(game_actions.has("game:royal_dice"), "Royal Dice entry missing")
	_expect(not game_actions.has("game:honey_hunt"), "legacy Honey Hunt must not appear in Game Center")
	if is_instance_valid(hub.get_node_or_null("SpatialFeaturePanel")):
		hub.get_node("SpatialFeaturePanel").queue_free()
	await process_frame
	hub.call("_open_destination_panel", "chat")
	await process_frame
	await process_frame
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
		await process_frame
		_expect(room_root.get_node_or_null("JoinRoom_0") != null, "room join button should render after paging")
		_expect(room_root.get_node_or_null("JoinRoom_1") == null, "room paging should clear stale join buttons")
		var page_two_button := room_root.get_node_or_null("JoinRoom_0") as Area3D
		if page_two_button != null:
			_expect(str(page_two_button.get_meta("hub_panel_action", "")).contains("room_c"), "page two button should reference the third room")
		hub.call("change_room_snapshot_page", -1)
		await process_frame
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
		hub.call("set_room_snapshot", ["invalid-row", {"id":"room_d","name":"Room Delta","member_count":4,"capacity":8}])
		await process_frame
		var malformed_data_button := room_root.get_node_or_null("JoinRoom_0") as Area3D
		_expect(malformed_data_button != null, "valid room should still render beside malformed room data")
		if malformed_data_button != null:
			_expect(str(malformed_data_button.get_meta("hub_panel_action", "")).contains("room_d"), "malformed room data should be skipped without shifting valid room identity")
	_expect(hub.get_node_or_null("CentralHall") != null or hub.get_child_count() > 5, "hub should generate central hall and spatial elements")
	if failures == 0:
		print("HUB_3D_TEST: PASS — camera, environment, information board, developer access and five kiosks")
	else:
		push_error("HUB_3D_TEST: %d assertion(s) failed" % failures)
	hub.queue_free()
	quit(0 if failures == 0 else 1)
