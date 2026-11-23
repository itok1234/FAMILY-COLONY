extends Node3D
## Procedural environment blockout for FAMILY COLONY.
## These are scalable placeholder meshes; final art will replace them with authored PBR assets.

@export var tree_count: int = 26
@export var lamp_count: int = 10
@export var building_count: int = 5
@export var random_seed: int = 24011

var _rng := RandomNumberGenerator.new()
var _materials: Dictionary = {}
const INTERACTABLE_SCRIPT: Script = preload("res://scripts/world_interactable.gd")
const PORTAL_SCRIPT: Script = preload("res://scripts/world_portal.gd")

func _ready() -> void:
	_rng.seed = random_seed
	_create_materials()
	_build_central_plaza()
	_build_road_network()
	_build_buildings()
	_build_trees()
	_build_lamps()
	_build_benches()
	_build_community_interior()

func _mat(key: String, color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_materials[key] = material
	return material

func _mesh_node(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, label: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = at
	if material != null:
		node.material_override = material
	parent.add_child(node)
	return node

func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material, label: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh_node(parent, mesh, material, at, label)

func _cylinder(parent: Node3D, radius: float, height: float, at: Vector3, material: Material, label: String) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return _mesh_node(parent, mesh, material, at, label)

func _build_central_plaza() -> void:
	var stone := _mat("plaza_stone", Color(0.63, 0.65, 0.62))
	var inset := _mat("plaza_inset", Color(0.43, 0.51, 0.53))
	_box(self, Vector3(30.0, 0.12, 24.0), Vector3(0, -0.43, 0), stone, "CentralPlaza")
	for x in range(-5, 6):
		_box(self, Vector3(0.035, 0.012, 22.0), Vector3(float(x) * 2.7, -0.365, 0), inset, "StoneJoint")
	for z in range(-4, 5):
		_box(self, Vector3(29.0, 0.012, 0.035), Vector3(0, -0.364, float(z) * 2.7), inset, "StoneJoint")

func _build_road_network() -> void:
	var asphalt := _mat("road_asphalt", Color(0.105, 0.13, 0.15), 0.95)
	var curb := _mat("road_curb", Color(0.72, 0.72, 0.68))
	var line := _mat("road_line", Color(0.91, 0.83, 0.57))
	_box(self, Vector3(11.0, 0.08, 180.0), Vector3(0, -0.49, -82), asphalt, "MainRoad")
	_box(self, Vector3(180.0, 0.08, 10.0), Vector3(0, -0.49, 0), asphalt, "CrossRoad")
	_box(self, Vector3(0.18, 0.035, 180.0), Vector3(-5.35, -0.435, -82), curb, "RoadCurb")
	_box(self, Vector3(0.18, 0.035, 180.0), Vector3(5.35, -0.435, -82), curb, "RoadCurb")
	for z in range(-160, 1, 12):
		_box(self, Vector3(0.16, 0.02, 4.0), Vector3(0, -0.435, float(z)), line, "RoadCenterMark")

func _build_buildings() -> void:
	var walls := [_mat("wall_ivory", Color(0.82, 0.79, 0.69)), _mat("wall_sand", Color(0.69, 0.58, 0.46)), _mat("wall_sage", Color(0.48, 0.61, 0.55))]
	var roof := _mat("roof_charcoal", Color(0.16, 0.20, 0.23), 0.72)
	var glass := _mat("window_glass", Color(0.12, 0.29, 0.38), 0.22, 0.35)
	for i in range(building_count):
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := -22.0 - float(i / 2) * 24.0
		var x := side * (22.0 + _rng.randf_range(0.0, 5.0))
		var width := _rng.randf_range(10.0, 14.0)
		var depth := _rng.randf_range(10.0, 14.0)
		var height := _rng.randf_range(7.0, 10.0)
		var group := Node3D.new()
		group.name = "CommunityBuilding_%02d" % i
		group.position = Vector3(x, 0, z)
		add_child(group)
		var wall_material: Material = walls[i % walls.size()]
		_box(group, Vector3(width, height, depth), Vector3(0, height * 0.5, 0), wall_material, "BuildingShell")
		_box(group, Vector3(width + 0.8, 0.45, depth + 0.8), Vector3(0, height + 0.22, 0), roof, "FlatRoof")
		for floor_index in range(2):
			var y := 2.0 + float(floor_index) * 3.2
			for window_index in range(3):
				var wx := -width * 0.32 + float(window_index) * width * 0.32
				_box(group, Vector3(1.5, 1.5, 0.08), Vector3(wx, y, depth * 0.5 + 0.045), glass, "FrontWindow")
		_box(group, Vector3(2.1, 2.7, 0.12), Vector3(0, 1.35, depth * 0.5 + 0.06), roof, "EntryDoor")

func _build_trees() -> void:
	var bark := _mat("tree_bark", Color(0.28, 0.19, 0.12))
	var leaves := [_mat("leaf_deep", Color(0.13, 0.31, 0.20)), _mat("leaf_mid", Color(0.22, 0.40, 0.24)), _mat("leaf_light", Color(0.33, 0.48, 0.27))]
	for i in range(tree_count):
		var x := _rng.randf_range(-48.0, 48.0)
		var z := _rng.randf_range(-150.0, 20.0)
		if absf(x) < 9.0 or (absf(x) < 18.0 and absf(z) < 15.0):
			continue
		var height := _rng.randf_range(2.8, 4.0)
		_cylinder(self, 0.22, height, Vector3(x, height * 0.5 - 0.48, z), bark, "TreeTrunk")
		var crown := SphereMesh.new()
		crown.radius = _rng.randf_range(1.5, 2.1)
		crown.height = crown.radius * 2.0
		crown.radial_segments = 12
		crown.rings = 8
		_mesh_node(self, crown, leaves[i % leaves.size()], Vector3(x, height + 0.7, z), "TreeCanopy")

func _build_lamps() -> void:
	var metal := _mat("lamp_metal", Color(0.12, 0.16, 0.18), 0.38, 0.72)
	var warm := _mat("lamp_glow", Color(1.0, 0.78, 0.42), 0.25, 0.1)
	for i in range(lamp_count):
		var z := -float(i) * 16.0 - 8.0
		var x := -7.0 if i % 2 == 0 else 7.0
		_cylinder(self, 0.09, 4.2, Vector3(x, 1.65, z), metal, "LampPost")
		_box(self, Vector3(0.8, 0.12, 0.25), Vector3(x, 3.75, z), metal, "LampArm")
		var bulb := SphereMesh.new()
		bulb.radius = 0.17
		bulb.height = 0.34
		_mesh_node(self, bulb, warm, Vector3(x, 3.55, z), "LampBulb")

func _build_benches() -> void:
	var wood := _mat("bench_wood", Color(0.38, 0.23, 0.13))
	var metal := _mat("bench_frame", Color(0.12, 0.17, 0.19), 0.45, 0.65)
	for z in [-8.0, 8.0, -34.0, 34.0]:
		var x := -11.0 if z < 0.0 else 11.0
		_box(self, Vector3(2.2, 0.16, 0.65), Vector3(x, 0.15, z), wood, "BenchSeat")
		_box(self, Vector3(2.2, 0.72, 0.14), Vector3(x, 0.55, z - 0.24), wood, "BenchBack")
		_box(self, Vector3(0.12, 0.48, 0.75), Vector3(x - 0.8, -0.05, z), metal, "BenchLeg")
		_box(self, Vector3(0.12, 0.48, 0.75), Vector3(x + 0.8, -0.05, z), metal, "BenchLeg")
		_add_bench_interactable(Vector3(x, 0.8, z))

	
func _add_bench_interactable(at: Vector3) -> void:
	var area := Area3D.new()
	area.name = "BenchInteraction"
	area.position = at
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_script(INTERACTABLE_SCRIPT)
	area.set("display_name", "Bangku Taman")
	area.set("action_label", "Gunakan")
	area.set("response_text", "Kamu beristirahat sejenak di taman.")
	add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 2.0, 2.2)
	shape.shape = box
	area.add_child(shape)


func _build_community_interior() -> void:
	# First enterable community hub prototype. Kept away from the outdoor blockout
	# so the same player and camera can move between spaces without scene reloads.
	var room := Node3D.new()
	room.name = "CommunityHubInterior"
	room.position = Vector3(300, 0, 0)
	add_child(room)

	var floor_material := _mat("interior_floor", Color(0.48, 0.43, 0.35), 0.92)
	var wall_material := _mat("interior_wall", Color(0.82, 0.79, 0.70), 0.9)
	var trim_material := _mat("interior_trim", Color(0.25, 0.20, 0.15), 0.72)
	var sofa_material := _mat("interior_sofa", Color(0.22, 0.34, 0.32), 0.88)
	var table_material := _mat("interior_table", Color(0.35, 0.22, 0.13), 0.55)
	var lamp_material := _mat("interior_lamp", Color(1.0, 0.78, 0.48), 0.3)

	_box(room, Vector3(14, 0.2, 12), Vector3(0, -0.5, 0), floor_material, "HubFloor")
	_box(room, Vector3(14, 5.5, 0.25), Vector3(0, 2.25, -6), wall_material, "BackWall")
	_box(room, Vector3(0.25, 5.5, 12), Vector3(-7, 2.25, 0), wall_material, "LeftWall")
	_box(room, Vector3(0.25, 5.5, 12), Vector3(7, 2.25, 0), wall_material, "RightWall")
	# Front wall is split to leave a clear doorway.
	_box(room, Vector3(4.5, 5.5, 0.25), Vector3(-4.75, 2.25, 6), wall_material, "FrontWallLeft")
	_box(room, Vector3(4.5, 5.5, 0.25), Vector3(4.75, 2.25, 6), wall_material, "FrontWallRight")
	_box(room, Vector3(5, 0.25, 12), Vector3(0, 5.05, 0), trim_material, "CeilingTrim")
	_box(room, Vector3(0.16, 0.18, 12), Vector3(-6.78, 4.85, 0), trim_material, "LeftCrown")
	_box(room, Vector3(0.16, 0.18, 12), Vector3(6.78, 4.85, 0), trim_material, "RightCrown")

	# Collision floor and perimeter so the avatar remains inside the room.
	var floor_body := StaticBody3D.new()
	floor_body.name = "InteriorCollision"
	room.add_child(floor_body)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(14, 0.3, 12)
	floor_collision.shape = floor_shape
	floor_collision.position = Vector3(0, -0.5, 0)
	floor_body.add_child(floor_collision)

	_box(room, Vector3(4.2, 0.55, 1.65), Vector3(-3.8, 0.1, -1.8), sofa_material, "LoungeSofa")
	_box(room, Vector3(4.2, 1.15, 0.35), Vector3(-3.8, 0.75, -2.45), sofa_material, "SofaBack")
	_box(room, Vector3(2.6, 0.18, 1.5), Vector3(0.4, 0.35, -1.7), table_material, "CoffeeTable")
	_box(room, Vector3(0.18, 0.35, 0.18), Vector3(-0.65, 0.05, -1.7), trim_material, "TableLeg")
	_box(room, Vector3(0.18, 0.35, 0.18), Vector3(1.45, 0.05, -1.7), trim_material, "TableLeg")
	_box(room, Vector3(3.2, 0.65, 0.7), Vector3(3.9, 0.32, 2.4), table_material, "CommunityCounter")
	_box(room, Vector3(3.5, 0.12, 0.12), Vector3(0, 3.7, 0), trim_material, "CeilingBeam")
	var ceiling_light := SphereMesh.new()
	ceiling_light.radius = 0.28
	ceiling_light.height = 0.56
	_mesh_node(room, ceiling_light, lamp_material, Vector3(0, 4.55, 0), "WarmCeilingLight")

	var entrance := Area3D.new()
	entrance.name = "CommunityHubEntrance"
	entrance.position = Vector3(-22, 1.0, -14.0)
	entrance.set_script(PORTAL_SCRIPT)
	entrance.set("destination", Vector3(300, 1.0, 0))
	entrance.set("destination_yaw_degrees", 180.0)
	entrance.set("status_message", "Kamu memasuki Balai Komunitas FAMILY COLONY.")
	add_child(entrance)
	var entrance_shape := CollisionShape3D.new()
	var entrance_sphere := SphereShape3D.new()
	entrance_sphere.radius = 1.8
	entrance_shape.shape = entrance_sphere
	entrance.add_child(entrance_shape)

	var exit_portal := Area3D.new()
	exit_portal.name = "CommunityHubExit"
	exit_portal.position = Vector3(300, 1.0, 5.1)
	exit_portal.set_script(PORTAL_SCRIPT)
	exit_portal.set("destination", Vector3(-22, 1.0, -11.5))
	exit_portal.set("destination_yaw_degrees", 0.0)
	exit_portal.set("status_message", "Kamu kembali ke area luar FAMILY COLONY.")
	room.add_child(exit_portal)
	var exit_shape := CollisionShape3D.new()
	var exit_sphere := SphereShape3D.new()
	exit_sphere.radius = 1.8
	exit_shape.shape = exit_sphere
	exit_portal.add_child(exit_shape)
