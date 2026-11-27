extends SceneTree
## Diagnostic isolation captures: Ground-only, EnvironmentBuilder-only, and combined scene.
## This test deliberately does NOT grant visual acceptance from image statistics.
func _initialize() -> void:
	call_deferred("_capture")

func _capture_image(label: String) -> void:
	for i in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("ISOLATION_FAIL: empty image " + label)
		return
	var dir := "user://visual_qa/isolation"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := dir + "/" + label + ".png"
	var err := image.save_png(path)
	if err != OK:
		push_error("ISOLATION_FAIL: PNG save " + label + " error=" + str(err))
	else:
		print("ISOLATION_CAPTURE: ", label, " path=", ProjectSettings.globalize_path(path), " size=", image.get_size())

func _capture() -> void:
	var packed := load("res://scenes/world.tscn") as PackedScene
	if packed == null:
		push_error("ISOLATION_FAIL: scene missing")
		quit(1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	for i in range(8):
		await process_frame
	var ground := world.get_node_or_null("Ground")
	var builder := world.get_node_or_null("EnvironmentBuilder")
	var player_camera := world.get_node_or_null("Player/CameraPivot/Camera3D")
	if player_camera:
		for ui_name in ["SpatialInteractionConsole", "SpatialRoomChat", "SpatialGraphicsQualityPanel", "SpatialNetworkStatus", "MobileControls3D"]:
			var ui_node := player_camera.get_node_or_null(ui_name)
			if ui_node:
				ui_node.visible = false
	var cam := Camera3D.new()
	cam.name = "VisualQADiagnosticCamera"
	cam.fov = 72.0
	cam.near = 0.1
	cam.far = 500.0
	world.add_child(cam)
	cam.position = Vector3(0.0, 24.0, 42.0)
	cam.look_at(Vector3(0.0, 9.0, -48.0), Vector3.UP)
	cam.make_current()
	print("ISOLATION_BEGIN: capture variants, camera=", cam.global_transform)
	# A: Ground baseline only.
	if builder: builder.visible = false
	await _capture_image("01_ground_baseline")
	# B: Procedural environment only; base ground is removed from view.
	if ground: ground.visible = false
	if builder: builder.visible = true
	await _capture_image("02_environment_only")
	# C: Combined scene.
	if ground: ground.visible = true
	await _capture_image("03_combined_scene")
	# D: Environment-only at a plaza-oriented target, same camera location, alternate target.
	if ground: ground.visible = false
	cam.look_at(Vector3(0.0, 1.5, 0.0), Vector3.UP)
	await _capture_image("04_environment_plaza_target")
	print("ISOLATION_DONE: four diagnostic PNGs generated; images require human visual acceptance.")
	world.queue_free()
	quit(0)
