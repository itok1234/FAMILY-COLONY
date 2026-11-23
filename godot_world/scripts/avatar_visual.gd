extends Node3D
## Procedural avatar blockout with simple locomotion and social action poses.

var _time := 0.0
var _motion := 0.0
var _action := "idle"
var _action_time := 0.0
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _appearance_materials: Dictionary = {}
var _face_materials: Dictionary = {}

func _ready() -> void:
	_build_avatar()

func set_motion_strength(value: float) -> void:
	_motion = clampf(value, 0.0, 1.0)

func get_motion_strength() -> float:
	return _motion


func apply_appearance(appearance: Dictionary) -> void:
	## Local preview only. Trusted backend must grant and load owned cosmetics.
	if _appearance_materials.is_empty():
		return
	for key in ["skin", "hair", "top", "trousers", "shoes"]:
		if not appearance.has(key):
			continue
		var material := _appearance_materials.get(key) as StandardMaterial3D
		if material == null:
			continue
		var fallback: Color = material.albedo_color
		material.albedo_color = Color.from_string(str(appearance[key]), fallback)


func get_appearance_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for key in _appearance_materials.keys():
		var material := _appearance_materials[key] as StandardMaterial3D
		if material != null:
			result[key] = material.albedo_color.to_html(true)
	return result


func play_action(action_name: String) -> void:
	if action_name in ["wave", "sit"]:
		_action = action_name
		_action_time = 0.0

func _process(delta: float) -> void:
	_time += delta
	_action_time += delta
	var swing := sin(_time * 9.0) * 0.58 * _motion
	var idle := sin(_time * 1.8) * 0.025
	var wave_weight := 0.0
	var sit_weight := 0.0
	if _action == "wave":
		wave_weight = 1.0 if _action_time < 1.5 else maxf(0.0, 1.0 - (_action_time - 1.5) * 2.0)
		if wave_weight <= 0.0:
			_action = "idle"
	elif _action == "sit":
		sit_weight = 1.0 if _action_time < 2.8 else maxf(0.0, 1.0 - (_action_time - 2.8) * 2.0)
		if sit_weight <= 0.0:
			_action = "idle"
	if _left_arm != null:
		_left_arm.rotation.x = swing
		_right_arm.rotation.x = -swing - wave_weight * 2.15 + sin(_time * 13.0) * 0.28 * wave_weight
		_left_leg.rotation.x = -swing + sit_weight * 0.9
		_right_leg.rotation.x = swing + sit_weight * 0.9
		_head.rotation.x = idle * 0.35 - wave_weight * 0.08
		position.y = idle * (1.0 - _motion) - sit_weight * 0.28

func _build_avatar() -> void:
	var skin := _material(Color(0.72, 0.48, 0.34), 0.82)
	var hair := _material(Color(0.075, 0.052, 0.045), 0.9)
	var shirt := _material(Color(0.16, 0.30, 0.48), 0.78)
	var trousers := _material(Color(0.12, 0.15, 0.19), 0.92)
	var shoes := _material(Color(0.055, 0.06, 0.07), 0.88)
	var eyes := _material(Color(0.035, 0.025, 0.02), 0.5)
	var eye_white := _material(Color(0.94, 0.91, 0.84), 0.42)
	var lip := _material(Color(0.43, 0.20, 0.17), 0.72)
	_appearance_materials = {
		"skin": skin,
		"hair": hair,
		"top": shirt,
		"trousers": trousers,
		"shoes": shoes
	}
	_add_capsule(self, "Torso", Vector3(0, 1.12, 0), 0.28, 0.82, shirt)
	_add_capsule(self, "Neck", Vector3(0, 1.61, 0), 0.105, 0.22, skin)
	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0, 1.82, 0)
	add_child(_head)
	_add_sphere(_head, "Face", Vector3.ZERO, Vector3(0.225, 0.265, 0.215), skin)
	_add_sphere(_head, "HairCap", Vector3(0, 0.145, 0.025), Vector3(0.232, 0.145, 0.222), hair)
	_add_sphere(_head, "FrontHair", Vector3(0, 0.105, -0.16), Vector3(0.19, 0.105, 0.075), hair)
	_add_sphere(_head, "LeftHairLock", Vector3(-0.19, -0.005, -0.005), Vector3(0.055, 0.19, 0.085), hair)
	_add_sphere(_head, "RightHairLock", Vector3(0.19, -0.005, -0.005), Vector3(0.055, 0.19, 0.085), hair)
	_add_sphere(_head, "LeftEar", Vector3(-0.222, -0.005, -0.005), Vector3(0.045, 0.075, 0.055), skin)
	_add_sphere(_head, "RightEar", Vector3(0.222, -0.005, -0.005), Vector3(0.045, 0.075, 0.055), skin)
	_add_sphere(_head, "LeftEyeWhite", Vector3(-0.078, 0.025, -0.195), Vector3(0.035, 0.03, 0.018), eye_white)
	_add_sphere(_head, "RightEyeWhite", Vector3(0.078, 0.025, -0.195), Vector3(0.035, 0.03, 0.018), eye_white)
	_add_sphere(_head, "LeftEye", Vector3(-0.078, 0.025, -0.213), Vector3(0.014, 0.021, 0.009), eyes)
	_add_sphere(_head, "RightEye", Vector3(0.078, 0.025, -0.213), Vector3(0.014, 0.021, 0.009), eyes)
	_add_sphere(_head, "LeftBrow", Vector3(-0.078, 0.079, -0.195), Vector3(0.047, 0.012, 0.014), hair)
	_add_sphere(_head, "RightBrow", Vector3(0.078, 0.079, -0.195), Vector3(0.047, 0.012, 0.014), hair)
	_add_sphere(_head, "Nose", Vector3(0, -0.018, -0.224), Vector3(0.032, 0.045, 0.035), skin)
	_add_sphere(_head, "Mouth", Vector3(0, -0.105, -0.207), Vector3(0.045, 0.012, 0.012), lip)
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
