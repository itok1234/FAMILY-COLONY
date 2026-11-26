extends SceneTree
## Headless structural runtime check; this is not visual/device QA.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://scenes/world.tscn")
	if packed == null:
		push_error("World scene missing")
		quit(1)
		return
	var world: Node3D = packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	if not is_instance_valid(world):
		push_error("World scene failed to instantiate")
		quit(1)
		return
	print("WORLD_RUNTIME_STRUCTURE: PASS scene instantiated as Node3D")
	world.queue_free()
	quit(0)
