extends SceneTree
## Captures a rendered 3D world frame in CI; artifact is evidence for visual review, not automated approval.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene := load("res://scenes/world.tscn")
	if scene == null:
		push_error("World scene missing")
		quit(1)
		return
	var world := scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Rendered viewport image unavailable")
		quit(1)
		return
	var directory := "res://qa-output"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		push_error("Failed to create QA output directory")
		quit(1)
	var output := "res://qa-output/world_runtime_capture.png"
	if image.save_png(output) != OK:
		push_error("Failed to save viewport capture")
		quit(1)
	print("WORLD_RENDER_CAPTURE: PASS ", output, " ", image.get_size())
	world.queue_free()
	quit(0)
