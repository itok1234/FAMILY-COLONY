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
	# QA-only: mount pending CC0 candidate assets for a rendered integration check.
	# This does not change production approval status or the production scene flag.
	var integrator := world.get_node_or_null("ProductionAssetIntegrator")
	if integrator != null:
		integrator.allow_candidate_smoke_test = true
	root.add_child(world)
	for i in range(8):
		await process_frame
	# Clean environment capture: hide camera-mounted UI/control panels so QA
	# evaluates the 3D world geometry rather than fixed spatial HUD elements.
	var player_camera := world.get_node_or_null("Player/CameraPivot/Camera3D")
	if player_camera != null:
		# QA framing: set a deterministic world-space view instead of relying on inherited pivot rotation.
		var camera_pivot := world.get_node_or_null("Player/CameraPivot")
		if camera_pivot != null:
			camera_pivot.rotation = Vector3.ZERO
			camera_pivot.position = Vector3(0, 1.25, 0)
		player_camera.position = Vector3(0, 3.8, 8.5)
		player_camera.look_at(Vector3(0, 0.8, -5.0), Vector3.UP)
		player_camera.make_current()
		for ui_name in ["SpatialInteractionConsole", "SpatialRoomChat", "SpatialGraphicsQualityPanel", "SpatialNetworkStatus", "MobileControls3D"]:
			var ui_node := player_camera.get_node_or_null(ui_name)
			if ui_node != null:
				ui_node.visible = false
	# Allow CI renderer several frames after camera activation.
	for i in range(12):
		await process_frame
		await RenderingServer.frame_post_draw
	# Emit scene-node diagnostics to trace obstructing UI/panel meshes.
	_dump_visual_nodes(world, world)
	var viewport := root.get_viewport()
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("VISUAL_CAPTURE_FAIL: viewport image empty")
		quit(1)
		return
	# Basic pixel-level sanity checks: reject blank/near-uniform frames.
	var samples := 0
	var min_luma := 1.0
	var max_luma := 0.0
	var non_dark := 0
	for y in range(0, image.get_height(), max(1, image.get_height() / 24)):
		for x in range(0, image.get_width(), max(1, image.get_width() / 24)):
			var px := image.get_pixel(x, y)
			var luma := (px.r * 0.299) + (px.g * 0.587) + (px.b * 0.114)
			samples += 1
			min_luma = min(min_luma, luma)
			max_luma = max(max_luma, luma)
			if luma > 0.08:
				non_dark += 1
	var varied := max_luma - min_luma > 0.08 and non_dark > 8
	print("VISUAL_CAPTURE_STATS: samples=", samples, " min_luma=", min_luma, " max_luma=", max_luma, " non_dark=", non_dark)
	if samples < 20 or not varied:
		push_error("VISUAL_CAPTURE_FAIL: image appears blank or uniform")
		quit(1)
		return
	var out_dir := "user://visual_qa"
	var absolute_dir := ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var path := out_dir + "/world_capture.png"
	var err := image.save_png(path)
	if err != OK:
		push_error("VISUAL_CAPTURE_FAIL: save PNG error " + str(err))
		quit(1)
		return
	print("VISUAL_CAPTURE: PASS " + ProjectSettings.globalize_path(path))
	world.queue_free()
	quit(0)
