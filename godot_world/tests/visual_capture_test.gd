extends SceneTree
## Rendered screenshot capture for visual QA evidence (not automatic visual approval).
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/world.tscn") as PackedScene
	if packed == null:
		push_error("VISUAL_CAPTURE_FAIL: world scene missing")
		quit(1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport := root.get_viewport()
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("VISUAL_CAPTURE_FAIL: viewport image empty")
		quit(1)
		return
	# Basic pixel-level sanity checks: reject blank/near-uniform frames.
	var samples := 0
	var varied := false
	var first := image.get_pixel(0, 0)
	for y in range(0, image.get_height(), max(1, image.get_height() / 16)):
		for x in range(0, image.get_width(), max(1, image.get_width() / 16)):
			var px := image.get_pixel(x, y)
			samples += 1
			if abs(px.r - first.r) + abs(px.g - first.g) + abs(px.b - first.b) > 0.12:
				varied = true
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
