extends Node3D
## Procedural, animation-ready FAMILY COLONY avatar blockout.
## Replace these primitives with authored character assets during the art-production pass.

var _time := 0.0
var _motion := 0.0
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D

func _ready() -> void:
	_build_avatar()

func set_motion_strength(value: float) -> void:
	_motion = clampf(value, 0.0, 1.0)

func _process(delta: float) -> void:
	_time += delta
	var swing := sin(_time * 9.0) * 0.58 * _motion
	var idle := sin(_time * 1.8) * 0.025
	if _left_arm != null:
		_left_arm.rotation.x = swing
		_right_arm.rotation.x = -swing
		_left_leg.rotation.x = -swing
		_right_leg.rotation.x = swing
		_head.rotation.x = idle * 0.35
		position.y = idle * (1.0 - _motion)

func _build_avatar() -> void:
	var skin := _material(Color(0.72, 0.48, 0.34), 0.82)
	var hair := _material(Color(0.075, 0.052, 0.045), 0.9)
	var shirt := _material(Color(0.16, 0.30, 0.48), 0.78)
	var trousers := _material(Color(0.12, 0.15, 0.19), 0.92)
	var shoes := _material(Color(0.055, 0.06, 0.07), 0.88)
	var eyes := _material(Color(0.035, 0.025, 0.02), 0.5)

	_add_capsule(self, "Torso", Vector3(0, 1.12, 0), 0.28, 0.82, shirt)
	_add_capsule(self, "Neck", Vector3(0, 1.61, 0), 0.105, 0.22, skin)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0, 1.82, 0)
	add_child(_head)
	_add_sphere(_head, "Face", Vector3.ZERO, Vector3(0.225, 0.265, 0.215), skin)
	_add_sphere(_head, "HairCap", Vector3(0, 0.145, 0.025), Vector3(0.232, 0.145, 0.222), hair)
	_add_sphere(_head, "FrontHair", Vector3(0, 0.105, -0.16), Vector3(0.19, 0.105, 0.075), hair)
	_add_sphere(_head, "LeftEye", Vector3(-0.078, 0.025, -0.198), Vector3(0.022, 0.027, 0.012), eyes)
	_add_sphere(_head, "RightEye", Vector3(0.078, 0.025, -0.198), Vector3(0.022, 0.027, 0.012), eyes)

	_left_arm = _make_limb("LeftArm", Vector3(-0.34, 1.42, 0), skin, 0.115, 0.72)
	_right_arm = _make_limb("RightArm", Vector3(0.34, 1.42, 0), skin, 0.115, 0.72)
	_left_arm.rotation.z = -0.12
	_right_arm.rotation.z = 0.12
	_add_capsule(_left_arm, "Sleeve", Vector3(0, 0.12, 0), 0.14, 0.48, shirt)
	_add_capsule(_right_arm, "Sleeve", Vector3(0, 0.12, 0), 0.14, 0.48, shirt)

	_left_leg = _make_limb("LeftLeg", Vector3(-0.15, 0.72, 0), trousers, 0.145, 0.78)
	_right_leg = _make_limb("RightLeg", Vector3(0.15, 0.72, 0), trousers, 0.145, 0.78)
	_add_box(_left_leg, "Shoe", Vector3(0, -0.38, -0.07), Vector3(0.25, 0.13, 0.38), shoes)
	_add_box(_right_leg, "Shoe", Vector3(0, -0.38, -0.07), Vector3(0.25, 0.13, 0.38), shoes)

func _make_limb(node_name: String, at: Vector3, mat: Material, radius: float, height: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = at
	add_child(pivot)
	_add_capsule(pivot, "Limb", Vector3(0, -height * 0.25, 0), radius, height, mat)
	return pivot

func _add_capsule(parent: Node3D, node_name: String, at: Vector3, radius: float, height: float, mat: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	_add_mesh(parent, node_name, at, mesh, mat)

func _add_sphere(parent: Node3D, node_name: String, at: Vector3, scale_value: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var instance := _add_mesh(parent, node_name, at, mesh, mat)
	instance.scale = scale_value * 2.0

func _add_box(parent: Node3D, node_name: String, at: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_add_mesh(parent, node_name, at, mesh, mat)

func _add_mesh(parent: Node3D, node_name: String, at: Vector3, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = mat
	parent.add_child(instance)
	return instance

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness_value
	return mat
