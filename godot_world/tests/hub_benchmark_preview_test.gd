extends SceneTree
## Standalone hub benchmark harness regression check (headless; not visual acceptance).

var failures := 0

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("HUB_BENCHMARK_PREVIEW: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview = load("res://scenes/hub_benchmark_preview.tscn")
	_expect(preview != null, "preview scene should load")
	if preview == null:
		quit(1)
		return
	var root: Node = preview.instantiate()
	root.name = "BenchmarkPreviewTestRoot"
	get_root().add_child(root)
	await process_frame
	await process_frame
	var hub: Node = root.get_node_or_null("BenchmarkHub")
	_expect(hub is Node3D, "preview should instantiate production hub script")
	if hub != null:
		var camera := hub.get_node_or_null("HubCamera") as Camera3D
		_expect(camera != null, "hub camera should exist")
		if camera != null:
			_expect(camera.current, "hub benchmark camera should be active")
			_expect(camera.fov >= 50.0 and camera.fov <= 75.0, "camera FOV should remain in benchmark range")
		_expect(hub.get_node_or_null("PlazaBeacon") != null, "central beacon should exist")
		var beacon := hub.get_node_or_null("PlazaBeacon")
		if beacon != null:
			_expect(beacon.get_node_or_null("BeaconHalo_0") is MeshInstance3D, "beacon first halo must exist")
			_expect(beacon.get_node_or_null("BeaconHalo_1") is MeshInstance3D, "beacon second halo must exist")
			_expect(beacon.get_node_or_null("BeaconHalo_2") is MeshInstance3D, "beacon third halo must exist")
			_expect(beacon.get_node_or_null("BeaconAccentLight") is OmniLight3D, "beacon accent light must exist")
		for spoke_index in range(12):
			_expect(hub.get_node_or_null("PlazaRadialInlay_%02d" % spoke_index) is MeshInstance3D, "radial plaza inlay missing: %d" % spoke_index)
		_expect(hub.get_node_or_null("SpatialInformationBoard") != null, "spatial information board should exist")
		for destination in ["profile", "chat", "games", "settings", "world"]:
			_expect(hub.get_node_or_null("Kiosk_" + destination) is Area3D, "feature station missing: " + destination)
		_expect(hub.get_node_or_null("DeveloperBeeEmblem") is Area3D, "developer bee interaction should exist")
	if failures == 0:
		print("HUB_BENCHMARK_PREVIEW: PASS — isolated harness, camera, beacon and stations")
	else:
		push_error("HUB_BENCHMARK_PREVIEW: %d assertion(s) failed" % failures)
	root.queue_free()
	quit(0 if failures == 0 else 1)
