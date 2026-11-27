extends SceneTree
## FAMILY COLONY 3DSV: independent technical gates, not visual/aesthetic acceptance.
const REQUIRED = ["WorldEnvironment", "Sun", "Ground", "Player", "Player/CameraPivot/Camera3D", "EnvironmentBuilder", "RoomManager", "ChatManager", "MiniGameManager", "AudioStudioSettings"]
var failures: Array[String] = []
var reports: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _gate(label: String, passed: bool, detail: String) -> void:
	var line := ("3DSV_PASS: " if passed else "3DSV_FAIL: ") + label + " | " + detail
	print(line)
	if not passed:
		failures.append(label)
	reports.append(line)

func _run() -> void:
	var packed := load("res://scenes/world.tscn") as PackedScene
	_gate("G1_SCENE_INTEGRITY", packed != null, "world.tscn PackedScene load")
	if packed == null:
		_finish()
		return
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var missing: Array[String] = []
	for path in REQUIRED:
		if world.get_node_or_null(path) == null:
			missing.append(path)
	_gate("G1_SCENE_INTEGRITY_NODES", missing.is_empty(), "required nodes=" + str(REQUIRED.size()) + "; missing=" + str(missing))

	var meshes := 0
	var collisions := 0
	var invalid_meshes := 0
	var geometry_nodes: Array[Node] = []
	_collect(world, geometry_nodes)
	for node in geometry_nodes:
		if node is MeshInstance3D:
			meshes += 1
			if node.mesh == null or node.mesh.get_surface_count() == 0:
				invalid_meshes += 1
		elif node is CollisionShape3D:
			collisions += 1
	_gate("G2_GEOMETRY", meshes > 0 and collisions > 0 and invalid_meshes == 0, "mesh_instances=" + str(meshes) + "; collision_shapes=" + str(collisions) + "; empty_meshes=" + str(invalid_meshes))

	var cam := world.get_node_or_null("Player/CameraPivot/Camera3D") as Camera3D
	var cam_ok := cam != null and cam.is_inside_tree() and cam.fov > 0.0 and cam.fov < 180.0 and cam.near > 0.0 and cam.far > cam.near
	if cam_ok:
		cam_ok = cam.current
	_gate("G3_CAMERA_SPATIAL", cam_ok, "camera_exists/current/valid_clip_and_fov")

	var ground_ok := world.get_node_or_null("Ground/GroundMesh") is MeshInstance3D and world.get_node_or_null("Ground/GroundCollision") is CollisionShape3D
	var env_ok := world.get_node_or_null("WorldEnvironment") is WorldEnvironment and world.get_node_or_null("Sun") is DirectionalLight3D and world.get_node_or_null("EnvironmentBuilder") != null
	_gate("G4_ENVIRONMENT", ground_ok and env_ok, "ground_mesh/collision, environment, directional light, builder present")

	await process_frame
	await process_frame
	var runtime_ok := world.is_inside_tree() and world.get_node_or_null("Player") != null and world.get_node_or_null("RoomManager") != null and world.get_node_or_null("ChatManager") != null
	_gate("G5_RUNTIME", runtime_ok, "scene remains in tree after deferred frames; core runtime nodes present")
	world.queue_free()
	await process_frame
	_finish()

func _collect(node: Node, result: Array[Node]) -> void:
	result.append(node)
	for child in node.get_children():
		_collect(child, result)

func _finish() -> void:
	print("3DSV_SUMMARY: passed=" + str(5 - failures.size()) + "/5; failed=" + str(failures))
	if failures.is_empty():
		print("3DSV_ALL_PASS")
		quit(0)
	else:
		quit(1)
