extends SceneTree
## Rendered screenshot capture for visual QA evidence (not automatic visual approval).
func _initialize() -> void:
	call_deferred("_capture")
func _dump_visual_nodes(node: Node, scene_root: Node) -> void:
	var rel := scene_root.get_path_to(node)
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var mesh_info := "mesh=" + str(mesh_node.mesh.get_class()) if mesh_node.mesh != null else "mesh=null"
		if mesh_node.mesh is BoxMesh:
			mesh_info += " size=" + str((mesh_node.mesh as BoxMesh).size)
		var material := mesh_node.material_override
		if material is StandardMaterial3D:
			mesh_info += " color=" + str((material as StandardMaterial3D).albedo_color)
			mesh_info += " transparency=" + str((material as StandardMaterial3D).transparency)
		print("VISUAL_NODE: ", rel, " visible=", mesh_node.is_visible_in_tree(), " ", mesh_info)
	elif node is Label3D:
		print("VISUAL_LABEL: ", rel, " visible=", node.is_visible_in_tree(), " text=", (node as Label3D).text)
	for child in node.get_children():
		_dump_visual_nodes(child, scene_root)
func _capture() -> void:
	var packed := load("res://scenes/world.tscn") as PackedScene
	if packed == null:
		push_error("VISUAL_CAPTURE_FAIL: world scene missing")
		quit(1)
		return
	var world := packed.instantiate()
	var integrator := world.get_node_or_null("ProductionAssetIntegrator")
	if integrator != null:
		integrator.allow_candidate_smoke_test = false
	root.add_child(world)
	for i in range(8):
		await process_frame
	var player_camera := world.get_node_or_null("Player/CameraPivot/Camera3D")
	if player_camera != null:
		for ui_name in ["SpatialInteractionConsole", "SpatialRoomChat", "SpatialGraphicsQualityPanel", "SpatialNetworkStatus", "MobileControls3D"]:
			var ui_node := player_camera.get_node_or_null(ui_name)
			if ui_node != null:
				ui_node.visible = false
	# QA camera is explicitly bound to the instantiated scene's World3D to
	# avoid capturing the viewport's unrelated/default 3D world.
	var qa_camera := Camera3D.new()
	qa_camera.name = "VisualQACaptureCamera"
	qa_camera.position = Vector3(0, 14.0, 22.0)
	qa_camera.fov = 60.0
	qa_camera.near = 0.1
	qa_camera.far = 500.0
	qa_camera.world_3d = world.get_world_3d()
	world.add_child(qa_camera)
	qa_camera.look_at_from_position(qa_camera.position, Vector3(0, 0.0, 0.0), Vector3.UP)
	qa_camera.make_current()
	print("VISUAL_QA_CAMERA: scene-bound camera position=", qa_camera.global_position, " target=(0,0,0)")
	for i in range(12):
		await process_frame
		await RenderingServer.frame_post_draw
	_dump_visual_nodes(world, world)
	print("VISUAL_VIEWPORT_DIAG: viewport_size=", root.size, " camera=", root.get_camera_3d(), " world3d=", root.world_3d)
	print("VISUAL_CAMERA_DIAG: QA camera viewport=", qa_camera.get_viewport(), " current=", qa_camera.current, " world3d=", qa_camera.world_3d, " global=", qa_camera.global_transform)
	if player_camera != null:
		print("VISUAL_PLAYER_CAMERA_DIAG: viewport=", player_camera.get_viewport(), " current=", player_camera.current, " global=", player_camera.global_transform)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("VISUAL_CAPTURE_FAIL: viewport image empty")
		quit(1)
		return
	var samples := 0
	var min_luma := 1.0
	var max_luma := 0.0
	var non_dark := 0
	var color_bins: Dictionary = {}
	var sum_rgb := Vector3.ZERO
	var sum_sq_rgb := Vector3.ZERO
	var rgb_samples := 0
	for y in range(0, image.get_height(), max(1, image.get_height() / 24)):
		for x in range(0, image.get_width(), max(1, image.get_width() / 24)):
			var px := image.get_pixel(x, y)
			var luma := (px.r * 0.299) + (px.g * 0.587) + (px.b * 0.114)
			samples += 1
			min_luma = min(min_luma, luma)
			max_luma = max(max_luma, luma)
			if luma > 0.08:
				non_dark += 1
			color_bins["%d_%d_%d" % [int(px.r * 8.0), int(px.g * 8.0), int(px.b * 8.0)]] = true
			var rgb: Vector3 = Vector3(px.r, px.g, px.b)
			sum_rgb += rgb
			sum_sq_rgb += rgb * rgb
			rgb_samples += 1
	var mean_rgb: Vector3 = sum_rgb / float(max(1, rgb_samples))
	var variance_rgb: Vector3 = (sum_sq_rgb / float(max(1, rgb_samples))) - (mean_rgb * mean_rgb)
	var spread: float = variance_rgb.length()
	var varied := max_luma - min_luma > 0.08 and non_dark > 8 and color_bins.size() >= 18 and spread > 0.025
	print("VISUAL_CAPTURE_STATS: samples=", samples, " min_luma=", min_luma, " max_luma=", max_luma, " non_dark=", non_dark, " color_bins=", color_bins.size(), " rgb_spread=", spread)
	var out_dir := "user://visual_qa"
	var absolute_dir := ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var path := out_dir + "/world_capture.png"
	var err := image.save_png(path)
	if err != OK:
		push_error("VISUAL_CAPTURE_FAIL: save PNG error " + str(err))
		quit(1)
		return
	if samples < 20 or not varied:
		push_error("VISUAL_CAPTURE_FAIL: image appears blank, uniform, or insufficiently varied; evidence=" + ProjectSettings.globalize_path(path))
		quit(1)
		return
	print("VISUAL_CAPTURE: PASS " + ProjectSettings.globalize_path(path))
	world.queue_free()
	quit(0)
