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
	_build_central_plaza()
	_build_fountain_feature()
	_build_road_network()
	_build_buildings()
	_build_trees()
	_build_lamps()
	_build_benches()
	_build_community_interior()
	_build_royal_hive_citadel()
	_build_landscape_details()
	_build_fountain_walkway()

func apply_quality_density(trees: int, lamps: int, buildings: int) -> void:
	tree_count = maxi(0, trees)
	lamp_count = maxi(0, lamps)
	building_count = maxi(0, buildings)
	if not is_node_ready():
		return
	_rng.seed = random_seed
	for node_name in ["CommunityBuildings", "TreeInstances", "LampInstances"]:
		var old_section := get_node_or_null(node_name)
		if old_section != null:
			old_section.free()
	_build_buildings()
	_build_trees()
	_build_lamps()


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


func _add_static_collision_box(parent: Node3D, size: Vector3, at: Vector3, label: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label + "Collision"
	body.position = at
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

func _build_central_plaza() -> void:
	var stone := _mat("plaza_stone", Color(0.63, 0.65, 0.62))
	var inset := _mat("plaza_inset", Color(0.43, 0.51, 0.53))
	_box(self, Vector3(30.0, 0.12, 24.0), Vector3(0, -0.43, 0), stone, "CentralPlaza")
	for x in range(-5, 6):
		_box(self, Vector3(0.035, 0.012, 22.0), Vector3(float(x) * 2.7, -0.365, 0), inset, "StoneJoint")
	for z in range(-4, 5):
		_box(self, Vector3(29.0, 0.012, 0.035), Vector3(0, -0.364, float(z) * 2.7), inset, "StoneJoint")



func _build_fountain_feature() -> void:
	## Layered plaza fountain focal point; lightweight mesh-only art for mobile.
	var fountain := Node3D.new()
	fountain.name = "PlazaFountain"
	fountain.position = Vector3(0, -0.34, 0)
	add_child(fountain)
	var stone := _mat("fountain_stone", Color(0.72, 0.75, 0.73), 0.78)
	var trim := _mat("fountain_trim", Color(0.82, 0.67, 0.42), 0.42, 0.22)
	var water := _mat("fountain_water", Color(0.19, 0.46, 0.58, 0.78), 0.18, 0.28)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.metallic = 0.22
	# Broad stepped basin and reflective-looking inset water surface.
	var base := CylinderMesh.new()
	base.top_radius = 4.3
	base.bottom_radius = 4.6
	base.height = 0.42
	base.radial_segments = 32
	_mesh_node(fountain, base, stone, Vector3(0, 0.18, 0), "FountainBase")
	var rim := CylinderMesh.new()
	rim.top_radius = 3.95
	rim.bottom_radius = 4.15
	rim.height = 0.28
	rim.radial_segments = 32
	_mesh_node(fountain, rim, trim, Vector3(0, 0.52, 0), "FountainRim")
	var basin := CylinderMesh.new()
	basin.top_radius = 3.78
	basin.bottom_radius = 3.78
	basin.height = 0.12
	basin.radial_segments = 32
	_mesh_node(fountain, basin, water, Vector3(0, 0.53, 0), "FountainWaterSurface")
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = 1.15
	pedestal.bottom_radius = 1.55
	pedestal.height = 1.4
	pedestal.radial_segments = 16
	_mesh_node(fountain, pedestal, stone, Vector3(0, 1.12, 0), "FountainPedestal")
	var upper_bowl := CylinderMesh.new()
	upper_bowl.top_radius = 2.0
	upper_bowl.bottom_radius = 0.9
	upper_bowl.height = 0.35
	upper_bowl.radial_segments = 24
	_mesh_node(fountain, upper_bowl, trim, Vector3(0, 1.88, 0), "FountainUpperBowlTrim")
	var upper_water := CylinderMesh.new()
	upper_water.top_radius = 1.85
	upper_water.bottom_radius = 1.85
	upper_water.height = 0.09
	upper_water.radial_segments = 24
	_mesh_node(fountain, upper_water, water, Vector3(0, 1.93, 0), "FountainUpperWater")
	var jet := CylinderMesh.new()
	jet.top_radius = 0.12
	jet.bottom_radius = 0.18
	jet.height = 1.25
	jet.radial_segments = 12
	_mesh_node(fountain, jet, water, Vector3(0, 2.55, 0), "FountainJet")

	# Central luminous crystal landmark with restrained mobile-friendly glow.
	var crystal_material := _mat("fountain_crystal", Color("#62c9ef"), 0.2, 0.32)
	crystal_material.emission_enabled = true
	crystal_material.emission = Color("#45bce8")
	crystal_material.emission_energy_multiplier = 1.25
	var crystal_mesh := CylinderMesh.new()
	crystal_mesh.top_radius = 0.0
	crystal_mesh.bottom_radius = 0.38
	crystal_mesh.height = 1.55
	crystal_mesh.radial_segments = 6
	var crystal := _mesh_node(fountain, crystal_mesh, crystal_material, Vector3(0, 3.08, 0), "FountainCrystal")
	crystal.rotation_degrees.y = 30.0
	var crystal_light := OmniLight3D.new()
	crystal_light.name = "FountainAccentLight"
	crystal_light.position = Vector3(0, 3.1, 0)
	crystal_light.light_color = Color("#68c9f1")
	crystal_light.light_energy = 0.7
	crystal_light.omni_range = 6.5
	crystal_light.shadow_enabled = false
	fountain.add_child(crystal_light)
	# Eight radial decorative accents break up the circular silhouette.
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var accent := SphereMesh.new()
		accent.radius = 0.22
		accent.height = 0.44
		accent.radial_segments = 10
		accent.rings = 6
		_mesh_node(fountain, accent, trim, Vector3(cos(angle) * 3.82, 0.72, sin(angle) * 3.82), "FountainAccent")
	var collision := StaticBody3D.new()
	collision.name = "FountainCollision"
	fountain.add_child(collision)
	var shape_node := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 4.25
	shape.height = 1.0
	shape_node.shape = shape
	shape_node.position.y = 0.35
	collision.add_child(shape_node)

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
	var buildings_root := Node3D.new()
	buildings_root.name = "CommunityBuildings"
	add_child(buildings_root)
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
		buildings_root.add_child(group)
		var wall_material: Material = walls[i % walls.size()]
		_box(group, Vector3(width, height, depth), Vector3(0, height * 0.5, 0), wall_material, "BuildingShell")
		_add_static_collision_box(group, Vector3(width, height, depth), Vector3(0, height * 0.5, 0), "BuildingShell")
		# Layered roof silhouette and eaves break up the primitive rectangular outline.
		_box(group, Vector3(width + 1.15, 0.32, depth + 1.15), Vector3(0, height + 0.12, 0), roof, "RoofEaves")
		var roof_mesh := CylinderMesh.new()
		roof_mesh.top_radius = 0.12
		roof_mesh.bottom_radius = maxf(width, depth) * 0.62
		roof_mesh.height = 3.1
		roof_mesh.radial_segments = 4
		var roof_peak := _mesh_node(group, roof_mesh, roof, Vector3(0, height + 1.78, 0), "PitchedRoof")
		roof_peak.rotation.y = PI * 0.25
		var trim := _mat("building_trim", Color(0.88, 0.82, 0.68))
		for column_x in [-width * 0.42, width * 0.42]:
			_box(group, Vector3(0.24, height, 0.28), Vector3(column_x, height * 0.5, depth * 0.5 + 0.12), trim, "FacadePillar")
		_box(group, Vector3(width * 0.78, 0.22, 0.24), Vector3(0, 3.75, depth * 0.5 + 0.13), trim, "FacadeBand")
		for floor_index in range(2):
			var y := 2.0 + float(floor_index) * 3.2
			for window_index in range(3):
				var wx := -width * 0.32 + float(window_index) * width * 0.32
				_box(group, Vector3(1.75, 1.78, 0.12), Vector3(wx, y, depth * 0.5 + 0.07), trim, "WindowFrame")
				_box(group, Vector3(1.42, 1.43, 0.07), Vector3(wx, y, depth * 0.5 + 0.15), glass, "FrontWindow")

				# Window crossbars and sill give the facade layered, architectural detail.
				_box(group, Vector3(1.46, 0.055, 0.09), Vector3(wx, y, depth * 0.5 + 0.205), trim, "WindowCrossbar")
				_box(group, Vector3(1.9, 0.14, 0.24), Vector3(wx, y - 0.96, depth * 0.5 + 0.20), trim, "WindowSill")
		# Compact facade sconces flanking the entrance; emissive but not real-time lights.
		var sconce_material := _mat("building_sconce_glow", Color("#f3d49a"), 0.32, 0.1)
		sconce_material.emission_enabled = true
		sconce_material.emission = Color("#f3d49a")
		sconce_material.emission_energy_multiplier = 0.55
		for sconce_side in [-1.0, 1.0]:
			var sconce_x: float = float(sconce_side) * 1.85
			_box(group, Vector3(0.22, 0.42, 0.16), Vector3(sconce_x, 2.05, depth * 0.5 + 0.16), roof, "EntranceSconceHousing")
			_box(group, Vector3(0.12, 0.25, 0.08), Vector3(sconce_x, 2.05, depth * 0.5 + 0.25), sconce_material, "EntranceSconceGlow")
		# Slim balcony-like ledges below the upper facade windows.
		_box(group, Vector3(width * 0.76, 0.12, 0.42), Vector3(0, 4.78, depth * 0.5 + 0.27), trim, "FacadeWindowLedge")
		# Low planter boxes on the entrance sides.
		var planter_material := _mat("facade_planter", Color("#536c60"), 0.85)
		var planter_green := _mat("facade_planter_green", Color("#315c3d"), 0.95)
		for planter_side in [-1.0, 1.0]:
			var planter_x: float = float(planter_side) * 2.55
			_box(group, Vector3(0.78, 0.42, 0.62), Vector3(planter_x, 0.16, depth * 0.5 + 0.82), planter_material, "EntrancePlanter")
			for shrub_index in range(3):
				var shrub_mesh := SphereMesh.new()
				shrub_mesh.radius = 0.20
				shrub_mesh.height = 0.32
				shrub_mesh.radial_segments = 8
				shrub_mesh.rings = 5
				_mesh_node(group, shrub_mesh, planter_green, Vector3(planter_x - 0.22 + float(shrub_index) * 0.22, 0.46, depth * 0.5 + 0.82), "EntrancePlanterShrub")
		_box(group, Vector3(2.1, 2.7, 0.12), Vector3(0, 1.35, depth * 0.5 + 0.06), roof, "EntryDoor")
		_box(group, Vector3(2.8, 0.18, 0.8), Vector3(0, 2.78, depth * 0.5 + 0.38), trim, "EntryCanopy")
		# Entrance platform, step and readable building identity.
		_box(group, Vector3(3.8, 0.24, 1.8), Vector3(0, -0.22, depth * 0.5 + 1.0), trim, "EntryLanding")
		_box(group, Vector3(3.2, 0.18, 0.85), Vector3(0, -0.34, depth * 0.5 + 2.05), wall_material, "EntryStep")
		_add_static_collision_box(group, Vector3(3.5, 0.3, 2.4), Vector3(0, -0.2, depth * 0.5 + 1.35), "EntryLanding")
		var sign_plate := _box(group, Vector3(width * 0.55, 0.65, 0.16), Vector3(0, height - 0.7, depth * 0.5 + 0.2), roof, "BuildingSignPlate")
		var building_sign := Label3D.new()
		building_sign.name = "BuildingIdentity"
		building_sign.text = "COLONY HUB %02d" % (i + 1)
		building_sign.position = Vector3(0, height - 0.7, depth * 0.5 + 0.32)
		building_sign.font_size = 32
		building_sign.pixel_size = 0.012
		building_sign.outline_size = 5
		building_sign.modulate = Color(0.91, 0.84, 0.65)
		building_sign.outline_modulate = Color(0.12, 0.15, 0.17)
		building_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		group.add_child(building_sign)

func _build_trees() -> void:
	var trees_root := Node3D.new()
	trees_root.name = "TreeInstances"
	add_child(trees_root)
	var bark := _mat("tree_bark", Color(0.28, 0.19, 0.12))
	var leaves := [_mat("leaf_deep", Color(0.13, 0.31, 0.20)), _mat("leaf_mid", Color(0.22, 0.40, 0.24)), _mat("leaf_light", Color(0.33, 0.48, 0.27))]
	for i in range(tree_count):
		var x := _rng.randf_range(-48.0, 48.0)
		var z := _rng.randf_range(-150.0, 20.0)
		if absf(x) < 9.0 or (absf(x) < 18.0 and absf(z) < 15.0) or (absf(x) < 22.0 and z < -48.0 and z > -92.0):
			continue
		var height := _rng.randf_range(2.8, 4.0)
		var trunk := _cylinder(trees_root, 0.22, height, Vector3(x, height * 0.5 - 0.48, z), bark, "TreeTrunk")
		trunk.rotation.z = _rng.randf_range(-0.07, 0.07)
		# Overlapping organic crowns replace the single spherical placeholder canopy.
		var crown_material: Material = leaves[i % leaves.size()]
		for cluster in range(5):
			var crown := SphereMesh.new()
			var radius := _rng.randf_range(1.05, 1.65)
			crown.radius = radius
			crown.height = radius * 2.0
			crown.radial_segments = 16
			crown.rings = 10
			var offset := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.25, 1.15), _rng.randf_range(-0.9, 0.9))
			_mesh_node(trees_root, crown, leaves[(i + cluster) % leaves.size()], Vector3(x, height + 0.45, z) + offset, "TreeCanopyCluster")

func _build_lamps() -> void:
	var lamps_root := Node3D.new()
	lamps_root.name = "LampInstances"
	add_child(lamps_root)
	var metal := _mat("lamp_metal", Color(0.12, 0.16, 0.18), 0.38, 0.72)
	var warm := _mat("lamp_glow", Color(1.0, 0.78, 0.42), 0.25, 0.1)
	for i in range(lamp_count):
		var z := -float(i) * 16.0 - 8.0
		var x := -7.0 if i % 2 == 0 else 7.0
		_cylinder(lamps_root, 0.09, 4.2, Vector3(x, 1.65, z), metal, "LampPost")
		_box(lamps_root, Vector3(0.8, 0.12, 0.25), Vector3(x, 3.75, z), metal, "LampArm")
		var bulb := SphereMesh.new()
		bulb.radius = 0.17
		bulb.height = 0.34
		_mesh_node(lamps_root, bulb, warm, Vector3(x, 3.55, z), "LampBulb")

func _build_benches() -> void:
	var wood := _mat("bench_wood", Color(0.38, 0.23, 0.13))
	var metal := _mat("bench_frame", Color(0.12, 0.17, 0.19), 0.45, 0.65)
	for z_value in [-8.0, 8.0, -34.0, 34.0]:
		var z: float = float(z_value)
		var x: float = -11.0 if z < 0.0 else 11.0
		_box(self, Vector3(2.2, 0.16, 0.65), Vector3(x, 0.15, z), wood, "BenchSeat")
		_box(self, Vector3(2.2, 0.72, 0.14), Vector3(x, 0.55, z - 0.24), wood, "BenchBack")
		_box(self, Vector3(0.12, 0.48, 0.75), Vector3(x - 0.8, -0.05, z), metal, "BenchLeg")
		_box(self, Vector3(0.12, 0.48, 0.75), Vector3(x + 0.8, -0.05, z), metal, "BenchLeg")
		_add_static_collision_box(self, Vector3(2.2, 0.2, 0.8), Vector3(x, 0.15, z), "BenchSeat")
		_add_static_collision_box(self, Vector3(2.2, 0.8, 0.25), Vector3(x, 0.55, z - 0.24), "BenchBack")
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
	area.set("available_actions", ["sit", "greet"])
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

	# Lounge finishes: wall feature panel, framed community display and ceiling accents.
	var feature_panel_material := _mat("interior_feature_panel", Color("#263b50"), 0.68, 0.18)
	var display_material := _mat("interior_display_glow", Color("#70c9ec"), 0.22, 0.16)
	_box(room, Vector3(5.4, 2.6, 0.18), Vector3(0, 2.55, -5.78), feature_panel_material, "LoungeFeatureWall")
	_box(room, Vector3(4.1, 1.75, 0.12), Vector3(0, 2.65, -5.62), trim_material, "CommunityDisplayFrame")
	_box(room, Vector3(3.78, 1.48, 0.08), Vector3(0, 2.65, -5.52), display_material, "CommunityDisplay")
	var display_label := Label3D.new()
	display_label.name = "CommunityDisplayText"
	display_label.text = "FAMILY COLONY\\nTOGETHER • CONNECT • BELONG"
	display_label.font_size = 42
	display_label.pixel_size = 0.006
	display_label.position = Vector3(0, 2.65, -5.42)
	display_label.modulate = Color("#eaf7ff")
	display_label.outline_size = 5
	display_label.outline_modulate = Color("#16314a")
	display_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	room.add_child(display_label)
	# Accent wall strips and restrained ceiling light fixtures.
	var accent_material := _mat("interior_accent", Color("#8bb8c7"), 0.38, 0.2)
	for strip_x in [-2.65, 2.65]:
		_box(room, Vector3(0.12, 2.8, 0.14), Vector3(strip_x, 2.55, -5.66), accent_material, "FeatureWallAccent")
	for light_x in [-4.0, -1.35, 1.35, 4.0]:
		var fixture := BoxMesh.new()
		fixture.size = Vector3(1.0, 0.08, 1.0)
		_mesh_node(room, fixture, trim_material, Vector3(light_x, 4.72, -1.0), "CeilingFixture")
		var fixture_glow := SphereMesh.new()
		fixture_glow.radius = 0.16
		fixture_glow.height = 0.32
		fixture_glow.radial_segments = 10
		_mesh_node(room, fixture_glow, lamp_material, Vector3(light_x, 4.62, -1.0), "CeilingFixtureGlow")
	# Seating corner with a small ottoman and side table to reinforce lounge scale.
	_box(room, Vector3(1.4, 0.48, 1.1), Vector3(4.8, 0.22, -2.8), sofa_material, "LoungeOttoman")
	_box(room, Vector3(0.72, 0.55, 0.72), Vector3(5.3, 0.28, -4.0), table_material, "LoungeSideTable")
	_box(room, Vector3(0.12, 0.28, 0.12), Vector3(5.0, 0.02, -4.25), trim_material, "SideTableLeg")
	_box(room, Vector3(0.12, 0.28, 0.12), Vector3(5.6, 0.02, -4.25), trim_material, "SideTableLeg")

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

	var wall_specs: Array[Dictionary] = [
		{"size": Vector3(14, 5.5, 0.25), "position": Vector3(0, 2.25, -6)},
		{"size": Vector3(0.25, 5.5, 12), "position": Vector3(-7, 2.25, 0)},
		{"size": Vector3(0.25, 5.5, 12), "position": Vector3(7, 2.25, 0)},
		{"size": Vector3(4.5, 5.5, 0.25), "position": Vector3(-4.75, 2.25, 6)},
		{"size": Vector3(4.5, 5.5, 0.25), "position": Vector3(4.75, 2.25, 6)}
	]
	for wall_spec in wall_specs:
		var wall_collision := CollisionShape3D.new()
		var wall_shape := BoxShape3D.new()
		wall_shape.size = wall_spec["size"]
		wall_collision.shape = wall_shape
		wall_collision.position = wall_spec["position"]
		floor_body.add_child(wall_collision)

	_box(room, Vector3(4.2, 0.55, 1.65), Vector3(-3.8, 0.1, -1.8), sofa_material, "LoungeSofa")
	_box(room, Vector3(4.2, 1.15, 0.35), Vector3(-3.8, 0.75, -2.45), sofa_material, "SofaBack")
	_box(room, Vector3(2.6, 0.18, 1.5), Vector3(0.4, 0.35, -1.7), table_material, "CoffeeTable")
	_box(room, Vector3(0.18, 0.35, 0.18), Vector3(-0.65, 0.05, -1.7), trim_material, "TableLeg")
	_box(room, Vector3(0.18, 0.35, 0.18), Vector3(1.45, 0.05, -1.7), trim_material, "TableLeg")
	_box(room, Vector3(3.2, 0.65, 0.7), Vector3(3.9, 0.32, 2.4), table_material, "CommunityCounter")
	_add_static_collision_box(room, Vector3(4.3, 0.7, 1.8), Vector3(-3.8, 0.1, -1.8), "LoungeSofa")
	_add_static_collision_box(room, Vector3(2.8, 0.3, 1.7), Vector3(0.4, 0.35, -1.7), "CoffeeTable")
	_add_static_collision_box(room, Vector3(3.3, 0.8, 0.8), Vector3(3.9, 0.32, 2.4), "CommunityCounter")
	_box(room, Vector3(3.5, 0.12, 0.12), Vector3(0, 3.7, 0), trim_material, "CeilingBeam")
	var ceiling_light := SphereMesh.new()
	ceiling_light.radius = 0.28
	ceiling_light.height = 0.56
	_mesh_node(room, ceiling_light, lamp_material, Vector3(0, 4.55, 0), "WarmCeilingLight")
	var warm_light := OmniLight3D.new()
	warm_light.name = "HubAmbientLight"
	warm_light.position = Vector3(0, 4.15, 0)
	warm_light.light_color = Color(1.0, 0.78, 0.58)
	warm_light.light_energy = 1.35
	warm_light.omni_range = 13.0
	room.add_child(warm_light)

	var sofa_interaction := Area3D.new()
	sofa_interaction.name = "LoungeSofaInteraction"
	sofa_interaction.position = Vector3(-3.8, 0.85, -1.8)
	sofa_interaction.collision_layer = 2
	sofa_interaction.collision_mask = 0
	sofa_interaction.set_script(INTERACTABLE_SCRIPT)
	sofa_interaction.set("display_name", "Sofa Balai Komunitas")
	sofa_interaction.set("action_label", "Duduk")
	sofa_interaction.set("response_text", "Kamu beristirahat di sofa Balai Komunitas.")
	sofa_interaction.set("available_actions", ["sit", "greet"])
	room.add_child(sofa_interaction)
	var sofa_shape := CollisionShape3D.new()
	var sofa_box := BoxShape3D.new()
	sofa_box.size = Vector3(4.5, 2.0, 2.3)
	sofa_shape.shape = sofa_box
	sofa_interaction.add_child(sofa_shape)

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


func _build_royal_hive_citadel() -> void:
	# Signature landmark for the first FAMILY COLONY kingdom zone.
	# Procedural low-poly architecture is deliberately lightweight for Android;
	# authored high-detail art can replace these meshes without changing gameplay.
	var citadel := Node3D.new()
	citadel.name = "RoyalHiveCitadel"
	citadel.position = Vector3(0, 0, -68)
	add_child(citadel)

	var stone := _mat("citadel_stone", Color(0.72, 0.75, 0.72), 0.86)
	var ivory := _mat("citadel_ivory", Color(0.88, 0.85, 0.73), 0.78)
	var honey := _mat("citadel_honey_gold", Color(0.88, 0.61, 0.19), 0.42, 0.18)
	var deep_gold := _mat("citadel_deep_gold", Color(0.48, 0.29, 0.10), 0.5, 0.22)
	var teal := _mat("citadel_teal_glass", Color(0.16, 0.39, 0.43), 0.22, 0.28)
	var garden := _mat("citadel_garden", Color(0.23, 0.43, 0.29), 0.96)

	# Forecourt and raised foundation.
	_box(citadel, Vector3(34, 0.35, 28), Vector3(0, -0.28, 0), stone, "CitadelForecourt")
	_box(citadel, Vector3(26, 0.5, 20), Vector3(0, 0.12, -1.5), ivory, "CitadelFoundation")
	_box(citadel, Vector3(21, 0.22, 16), Vector3(0, 0.48, -1.5), honey, "GoldenFoundationTrim")

	# Main hexagonal keep and crown.
	var keep := CylinderMesh.new()
	keep.top_radius = 5.8
	keep.bottom_radius = 6.8
	keep.height = 13.0
	keep.radial_segments = 6
	_mesh_node(citadel, keep, ivory, Vector3(0, 7.0, -4.0), "GreatHiveKeep")
	var keep_roof := CylinderMesh.new()
	keep_roof.top_radius = 0.0
	keep_roof.bottom_radius = 7.6
	keep_roof.height = 5.2
	keep_roof.radial_segments = 6
	_mesh_node(citadel, keep_roof, honey, Vector3(0, 16.0, -4.0), "GoldenHiveCrown")
	var crown_cap := SphereMesh.new()
	crown_cap.radius = 1.0
	crown_cap.height = 2.0
	_mesh_node(citadel, crown_cap, deep_gold, Vector3(0, 18.9, -4.0), "CrownFinial")
	# Decorative vertical ribs, cornices and balcony rings give the keep a crafted silhouette.
	for rib_index in range(6):
		var angle := TAU * float(rib_index) / 6.0
		var rib := _cylinder(citadel, 0.13, 10.8, Vector3(cos(angle) * 6.05, 7.1, -4.0 + sin(angle) * 6.05), honey, "KeepFacadeRib")
		rib.rotation.z = 0.0
	var cornice := CylinderMesh.new()
	cornice.top_radius = 6.35
	cornice.bottom_radius = 6.35
	cornice.height = 0.38
	cornice.radial_segments = 6
	_mesh_node(citadel, cornice, deep_gold, Vector3(0, 12.7, -4.0), "KeepUpperCornice")
	var balcony := CylinderMesh.new()
	balcony.top_radius = 7.15
	balcony.bottom_radius = 7.15
	balcony.height = 0.22
	balcony.radial_segments = 6
	_mesh_node(citadel, balcony, honey, Vector3(0, 13.0, -4.0), "KeepBalconyRing")
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		var banner := _box(citadel, Vector3(1.05, 3.8, 0.10), Vector3(side * 5.3, 8.8, 2.62), teal, "RoyalBanner")
		banner.rotation.z = side * -0.08
		_box(citadel, Vector3(1.22, 0.12, 0.16), Vector3(side * 5.3, 10.75, 2.62), honey, "RoyalBannerTop")
		for level in range(3):
			var tower_band := CylinderMesh.new()
			tower_band.top_radius = 2.78 - float(level) * 0.12
			tower_band.bottom_radius = 2.78 - float(level) * 0.12
			tower_band.height = 0.18
			tower_band.radial_segments = 6
			_mesh_node(citadel, tower_band, honey, Vector3(side * 9.0, 3.0 + float(level) * 3.0, -0.5), "TowerDecorativeBand")

	# Two side towers frame the entrance and make the silhouette readable at a distance.
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		var tower := CylinderMesh.new()
		tower.top_radius = 2.2
		tower.bottom_radius = 2.7
		tower.height = 10.0
		tower.radial_segments = 6
		_mesh_node(citadel, tower, ivory, Vector3(side * 9.0, 5.5, -0.5), "CitadelWatchTower")
		var tower_roof := CylinderMesh.new()
		tower_roof.top_radius = 0.0
		tower_roof.bottom_radius = 3.0
		tower_roof.height = 3.2
		tower_roof.radial_segments = 6
		_mesh_node(citadel, tower_roof, honey, Vector3(side * 9.0, 12.1, -0.5), "WatchTowerCrown")
		_cylinder(citadel, 0.16, 5.0, Vector3(side * 9.0, 2.9, 1.0), deep_gold, "EntranceColumn")

	# A broad gate, colored glass panels and a honeycomb crest.
	_box(citadel, Vector3(8.0, 0.55, 0.65), Vector3(0, 5.5, 2.1), honey, "RoyalGateLintel")
	_box(citadel, Vector3(5.2, 4.2, 0.3), Vector3(0, 2.65, 2.35), deep_gold, "RoyalGate")
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		var window := CylinderMesh.new()
		window.top_radius = 0.95
		window.bottom_radius = 0.95
		window.height = 0.16
		window.radial_segments = 6
		var pane := _mesh_node(citadel, window, teal, Vector3(side * 3.0, 8.2, 2.35), "HoneycombWindow")
		pane.rotation.x = PI * 0.5
		var frame := CylinderMesh.new()
		frame.top_radius = 1.12
		frame.bottom_radius = 1.12
		frame.height = 0.12
		frame.radial_segments = 6
		var frame_node := _mesh_node(citadel, frame, honey, Vector3(side * 3.0, 8.2, 2.2), "HoneycombWindowFrame")
		frame_node.rotation.x = PI * 0.5

	var crest := CylinderMesh.new()
	crest.top_radius = 1.55
	crest.bottom_radius = 1.55
	crest.height = 0.2
	crest.radial_segments = 6
	var crest_node := _mesh_node(citadel, crest, honey, Vector3(0, 11.2, 2.15), "RoyalHoneycombCrest")
	crest_node.rotation.x = PI * 0.5

	# Garden beds and golden path markers lead from the road to the royal gate.
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		_box(citadel, Vector3(4.0, 0.18, 12.0), Vector3(side * 12.5, 0.05, 7.0), garden, "RoyalGardenBed")
		for index in range(5):
			var flower := SphereMesh.new()
			flower.radius = 0.28
			flower.height = 0.56
			_mesh_node(citadel, flower, honey, Vector3(side * (11.0 + float(index % 2)), 0.55, 3.0 + float(index) * 2.0), "RoyalGardenBloom")
		for index in range(4):
			_box(citadel, Vector3(0.22, 0.18, 0.22), Vector3(side * 6.0, 0.72, 7.0 + float(index) * 2.4), honey, "PathLanternMarker")

	# Ground collision prevents walking through the central keep.
	var keep_collision := StaticBody3D.new()
	keep_collision.name = "RoyalKeepCollision"
	keep_collision.position = Vector3(0, 6.5, -4.0)
	citadel.add_child(keep_collision)
	var keep_shape := CollisionShape3D.new()
	var keep_box := BoxShape3D.new()
	keep_box.size = Vector3(11.5, 13.0, 11.5)
	keep_shape.shape = keep_box
	keep_collision.add_child(keep_shape)

	# Clear the approach so the citadel remains visible from the main road.
	var sign := Label3D.new()
	sign.name = "CitadelName"
	sign.text = "ISTANA KERAJAAN LEBAH"
	sign.position = Vector3(0, 7.2, 3.0)
	sign.font_size = 44
	sign.pixel_size = 0.012
	sign.outline_size = 8
	sign.modulate = Color(1.0, 0.86, 0.55, 1.0)
	sign.outline_modulate = Color(0.10, 0.12, 0.15, 1.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	citadel.add_child(sign)


func _build_landscape_details() -> void:
	# Lightweight decorative pass for the current procedural world.
	# This improves visual richness without pretending to replace final authored PBR art.
	var details := Node3D.new()
	details.name = "LandscapeDetails"
	add_child(details)

	var stone := _mat("garden_stone", Color(0.43, 0.48, 0.46), 0.94)
	var shrub_materials: Array[Material] = [
		_mat("shrub_deep", Color(0.12, 0.27, 0.19), 1.0),
		_mat("shrub_mid", Color(0.20, 0.36, 0.23), 1.0),
		_mat("shrub_light", Color(0.29, 0.43, 0.25), 1.0)
	]
	var flower_materials: Array[Material] = [
		_mat("flower_cream", Color(0.91, 0.87, 0.70), 0.72),
		_mat("flower_lavender", Color(0.56, 0.49, 0.72), 0.68),
		_mat("flower_blue", Color(0.42, 0.65, 0.76), 0.68)
	]
	var leaf_material := _mat("flower_leaf", Color(0.19, 0.39, 0.24), 0.9)

	# Small planted islands soften the hard edges around the central plaza.
	for bed_index in range(10):
		var side := -1.0 if bed_index % 2 == 0 else 1.0
		var z := -6.0 - float(bed_index / 2) * 7.0
		var x := side * _rng.randf_range(11.5, 14.0)
		var bed := Node3D.new()
		bed.name = "FlowerBed_%02d" % bed_index
		bed.position = Vector3(x, -0.38, z)
		details.add_child(bed)

		var border := BoxMesh.new()
		border.size = Vector3(3.4, 0.16, 2.0)
		_mesh_node(bed, border, stone, Vector3.ZERO, "StonePlanter")
		var soil := BoxMesh.new()
		soil.size = Vector3(3.12, 0.08, 1.72)
		_mesh_node(bed, soil, _mat("planter_soil", Color(0.20, 0.16, 0.12), 1.0), Vector3(0, 0.105, 0), "PlanterSoil")

		for flower_index in range(7):
			var fx := _rng.randf_range(-1.35, 1.35)
			var fz := _rng.randf_range(-0.68, 0.68)
			var stem_height := _rng.randf_range(0.28, 0.48)
			_cylinder(bed, 0.025, stem_height, Vector3(fx, 0.12 + stem_height * 0.5, fz), leaf_material, "FlowerStem")
			var leaf := SphereMesh.new()
			leaf.radius = 0.10
			leaf.height = 0.12
			leaf.radial_segments = 7
			leaf.rings = 4
			_mesh_node(bed, leaf, leaf_material, Vector3(fx + 0.09, 0.22, fz), "FlowerLeaf")
			var bloom := SphereMesh.new()
			bloom.radius = _rng.randf_range(0.09, 0.14)
			bloom.height = bloom.radius * 1.35
			bloom.radial_segments = 8
			bloom.rings = 5
			_mesh_node(bed, bloom, flower_materials[flower_index % flower_materials.size()], Vector3(fx, 0.12 + stem_height, fz), "FlowerBloom")

	# Repeated stone edging, seating islands and path lights create a readable landscaped public space.
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		for segment in range(7):
			var z: float = -5.0 - float(segment) * 7.0
			var x: float = side * 16.0
			_box(details, Vector3(0.22, 0.24, 4.8), Vector3(x, -0.27, z), stone, "GardenKerb")
			if segment % 2 == 0:
				var post := _cylinder(details, 0.11, 1.15, Vector3(side * 7.6, 0.12, z), stone, "PathLightPost")
				var cap := SphereMesh.new()
				cap.radius = 0.22
				cap.height = 0.44
				_mesh_node(details, cap, flower_materials[0], Vector3(side * 7.6, 0.82, z), "PathLightCap")
	# Low-cost shrub clusters add depth to the road edges without costly foliage simulation.
	for shrub_index in range(22):
		var side: float = -1.0 if shrub_index % 2 == 0 else 1.0
		var x: float = side * _rng.randf_range(8.5, 17.5)
		var z: float = _rng.randf_range(-145.0, 12.0)
		if absf(z) < 17.0 and absf(x) < 13.0:
			continue
		var shrub := SphereMesh.new()
		shrub.radius = _rng.randf_range(0.55, 0.9)
		shrub.height = shrub.radius * 1.35
		shrub.radial_segments = 9
		shrub.rings = 5
		var scale_value := Vector3(_rng.randf_range(1.0, 1.5), _rng.randf_range(0.7, 1.0), _rng.randf_range(0.9, 1.3))
		var instance := _mesh_node(details, shrub, shrub_materials[shrub_index % shrub_materials.size()], Vector3(x, 0.1, z), "RoadsideShrub")
		instance.scale = scale_value

 
func _build_fountain_walkway() -> void:
	## A segmented, circular promenade and low planting ring frame the fountain.
	## Uses modest mesh counts and no realtime foliage simulation for mobile.
	var root := Node3D.new()
	root.name = "FountainPromenade"
	root.position = Vector3(0, -0.34, 0)
	add_child(root)
	var paving_a := _mat("promenade_paving_a", Color("#c6c9c4"), 0.92)
	var paving_b := _mat("promenade_paving_b", Color("#aab4b5"), 0.9)
	var border := _mat("promenade_border", Color("#d6c5a0"), 0.62, 0.12)
	var foliage := _mat("promenade_foliage", Color("#315c3d"), 0.95)
	var bloom := _mat("promenade_bloom", Color("#6d9ec9"), 0.7)
	var bloom_light := _mat("promenade_bloom_light", Color("#e5d5b4"), 0.7)
	# Tiled outer ring: each tile is rotated to follow the fountain's circular edge.
	for tile_index in range(36):
		var angle := TAU * float(tile_index) / 36.0
		var radius := 5.65
		var tile := _box(root, Vector3(1.08, 0.075, 1.38),
			Vector3(cos(angle) * radius, 0.035, sin(angle) * radius),
			paving_a if tile_index % 2 == 0 else paving_b, "PromenadeTile")
		tile.rotation.y = -angle
		var edge := _box(root, Vector3(0.18, 0.09, 1.4),
			Vector3(cos(angle) * 6.42, 0.06, sin(angle) * 6.42), border, "PromenadeAccent")
		edge.rotation.y = -angle
	# Small raised planting beds spaced around the circular path.
	for bed_index in range(12):
		var angle := TAU * float(bed_index) / 12.0
		var bed_root := Node3D.new()
		bed_root.name = "PromenadePlanting_%02d" % bed_index
		bed_root.position = Vector3(cos(angle) * 7.55, 0.0, sin(angle) * 7.55)
		bed_root.rotation.y = -angle
		root.add_child(bed_root)
		_box(bed_root, Vector3(1.45, 0.18, 0.72), Vector3(0, 0.02, 0), border, "RaisedBedEdge")
		_box(bed_root, Vector3(1.28, 0.08, 0.55), Vector3(0, 0.12, 0), _mat("promenade_soil", Color("#403326"), 1.0), "BedSoil")
		for plant_index in range(5):
			var px := -0.48 + float(plant_index) * 0.24
			var plant_height := 0.38 + float(plant_index % 3) * 0.08
			_cylinder(bed_root, 0.025, plant_height, Vector3(px, 0.16 + plant_height * 0.5, 0), foliage, "PlantStem")
			var crown := SphereMesh.new()
			crown.radius = 0.13
			crown.height = 0.19
			crown.radial_segments = 8
			crown.rings = 5
			_mesh_node(bed_root, crown, foliage, Vector3(px, 0.28 + plant_height, 0), "PlantCrown")
			var flower := SphereMesh.new()
			flower.radius = 0.09
			flower.height = 0.13
			flower.radial_segments = 8
			flower.rings = 5
			_mesh_node(bed_root, flower, bloom if plant_index % 2 == 0 else bloom_light, Vector3(px, 0.28 + plant_height + 0.12, 0), "PlantFlower")
