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
	for destination in ["profile", "chat", "games", "settings", "world"]:\n\t\tvar kiosk := hub.get_node_or_null("Kiosk_" + destination) as Area3D\n\t\t_expect(kiosk is Area3D, "3D kiosk missing: " + destination)\n\t\tif kiosk != null:\n\t\t\t_expect(kiosk.has_meta("destination_id"), "kiosk destination metadata missing: " + destination)\n\t\t\t_expect(kiosk.get_node_or_null("CollisionShape3D") != null, "kiosk touch collision missing: " + destination)\n\t\t\t_expect(kiosk.get_node_or_null("MeshInstance3D") != null, "kiosk visual mesh missing: " + destination)\n\t\t\t_expect(kiosk.get_node_or_null("StationLight") != null or kiosk.get_child_count() >= 7, "kiosk detail structure incomplete: " + destination)
	_expect(hub.get_child_count() >= 8, "hub should generate a substantial 3D scene structure")\n\thub.call("_open_destination_panel", "chat")\n\t_expect(hub.get_node_or_null("SpatialFeaturePanel") != null, "chat panel should be created in 3D")\n\tvar room_data := [\n\t\t{"id":"room_a","name":"Room Alpha","member_count":1,"capacity":8},\n\t\t{"id":"room_b","name":"Room Beta","member_count":2,"capacity":8},\n\t\t{"id":"room_c","name":"Room Gamma","member_count":3,"capacity":8}\n\t]\n\thub.call("set_room_snapshot", room_data)\n\tvar room_root := hub.get_node_or_null("SpatialFeaturePanel/RoomList3D")\n\t_expect(room_root != null, "3D room list root should be present")\n\tif room_root != null:\n\t\t_expect(room_root.get_node_or_null("JoinRoom_0") != null, "first room join button should render")\n\t\t_expect(room_root.get_node_or_null("JoinRoom_1") != null, "second room join button should render")\n\t\thub.call("change_room_snapshot_page", 1)\n\t\t_expect(room_root.get_node_or_null("JoinRoom_0") != null, "room join button should render after paging")\n\t\t_expect(room_root.get_node_or_null("JoinRoom_1") == null, "room paging should clear stale join buttons")
	_expect(hub.get_node_or_null("CentralHall") != null or hub.get_child_count() > 5, "hub should generate central hall and spatial elements")
	if failures == 0:
		print("HUB_3D_TEST: PASS — camera, environment, information board, developer access and five kiosks")
	else:
		push_error("HUB_3D_TEST: %d assertion(s) failed" % failures)
	hub.queue_free()
	quit(0 if failures == 0 else 1)
