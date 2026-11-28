extends SceneTree
## Standalone hub benchmark harness regression check (headless; not visual acceptance).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview = load("res://scenes/hub_benchmark_preview.tscn")
	if preview == null:
		push_error("Benchmark preview scene failed to load")
		quit(1)
		return
	var root = preview.instantiate()
	root.name = "BenchmarkPreviewTestRoot"
	get_root().add_child(root)
	await process_frame
	await process_frame
	if root.get_node_or_null("BenchmarkHub") == null:
		push_error("Preview harness did not instantiate hub")
		quit(1)
		return
	print("HUB_BENCHMARK_PREVIEW: PASS")
	quit(0)
