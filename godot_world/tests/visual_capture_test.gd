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
	await process_frame
	await process_frame
	await process_frame
	var viewport := root.get_viewport()
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("VISUAL_CAPTURE_FAIL: viewport image empty")
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
