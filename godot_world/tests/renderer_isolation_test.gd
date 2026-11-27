extends SceneTree
## Minimal renderer diagnostic: isolates viewport/camera/render pipeline from FAMILY COLONY scene scripts.
func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.8, 6)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	root.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.7, -0.4, 0)
	root.add_child(light)
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.35)
	mat.roughness = 0.4
	mesh_instance.material_override = mat
	root.add_child(mesh_instance)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.15, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	root.add_child(env_node)
	for i in range(8):
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("RENDERER_DIAGNOSTIC_FAIL: viewport image empty")
		quit(1)
		return
	var bins: Dictionary = {}
	var lumas: Array[float] = []
	for y in range(0, image.get_height(), max(1, image.get_height()/32)):
		for x in range(0, image.get_width(), max(1, image.get_width()/32)):
			var p := image.get_pixel(x, y)
			bins["%d_%d_%d" % [int(p.r*10), int(p.g*10), int(p.b*10)]] = true
			lumas.append(p.r*0.299+p.g*0.587+p.b*0.114)
	var out_dir := "user://renderer_diagnostic"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var err := image.save_png(out_dir+"/renderer_test.png")
	print("RENDERER_DIAGNOSTIC: size=", image.get_size(), " bins=", bins.size(), " luma_range=", (lumas.max()-lumas.min()) if not lumas.is_empty() else 0.0, " save_error=", err)
	if bins.size() < 8 or lumas.max()-lumas.min() < 0.05 or err != OK:
		push_error("RENDERER_DIAGNOSTIC_FAIL: test primitive did not render with sufficient pixel variation")
		quit(1)
	else:
		print("RENDERER_DIAGNOSTIC_PASS")
	quit(0)
