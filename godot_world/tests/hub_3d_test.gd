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
		_expect(hub.get_node_or_null("Kiosk_" + destination) is Area3D, "3D kiosk missing: " + destination)
	_expect(hub.get_node_or_null("WorldEnvironment") is WorldEnvironment, "3D environment must be present")
	_expect(hub.get_node_or_null("CentralHall") != null or hub.get_child_count() > 5, "hub should generate central hall and spatial elements")
	if failures == 0:
		print("HUB_3D_TEST: PASS — camera, environment, information board, developer access and five kiosks")
	else:
		push_error("HUB_3D_TEST: %d assertion(s) failed" % failures)
	hub.queue_free()
	quit(0 if failures == 0 else 1)
