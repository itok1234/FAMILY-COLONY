extends Node3D
## Procedural avatar blockout with simple locomotion and social action poses.

var _time := 0.0
var _motion := 0.0
var _motion_target := 0.0
var _action := "idle"
var _action_time := 0.0
var _is_seated := false
var _head: Node3D
var _name_label: Label3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _appearance_materials: Dictionary = {}

func _ready() -> void:
	_build_avatar()

func set_motion_strength(value: float) -> void:
	_motion_target = clampf(value, 0.0, 1.0)

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


func set_display_name(value: String) -> void:
	if _name_label == null:
		return
	var clean_name := value.strip_edges()
	_name_label.text = "Colony Member" if clean_name.is_empty() else clean_name.left(24)


func get_appearance_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for key in _appearance_materials.keys():
		var material := _appearance_materials[key] as StandardMaterial3D
		if material != null:
			result[key] = material.albedo_color.to_html(true)
	return result


func play_action(action_name: String) -> void:
	if action_name == "sit":
		_is_seated = true
		_action = "sit"
		_action_time = 0.0
	elif action_name == "stand":
		stand_up()
	elif action_name == "wave" and not _is_seated:
		_action = "wave"
		_action_time = 0.0

func stand_up() -> void:
	_is_seated = false
	_action = "idle"
	_action_time = 0.0

func is_seated() -> bool:
	return _is_seated

func _process(delta: float) -> void:
	_time += delta
	_action_time += delta
	# Blend gait in and out to avoid abrupt limb movement.
	_motion = move_toward(_motion, _motion_target, delta * 4.5)
	var gait_rate := lerpf(5.2, 8.4, _motion)
	var gait_phase := _time * gait_rate
	var leg_swing := sin(gait_phase) * 0.48 * _motion
	var arm_swing := -leg_swing * 0.72
	var body_bob := absf(cos(gait_phase)) * 0.045 * _motion
	var idle := sin(_time * 1.55) * 0.018
	var wave_weight := 0.0
	var sit_weight := 0.0
	if _action == "wave":
		wave_weight = 1.0 if _action_time < 1.5 else maxf(0.0, 1.0 - (_action_time - 1.5) * 2.0)
		if wave_weight <= 0.0:
			_action = "idle"
	elif _action == "sit":
		sit_weight = 1.0
	if _left_arm != null:
		_left_arm.rotation.x = lerpf(arm_swing, -0.28, sit_weight)
		_right_arm.rotation.x = lerpf(-arm_swing - wave_weight * 2.15 + sin(_time * 11.5) * 0.24 * wave_weight, -0.28, sit_weight)
		_left_leg.rotation.x = lerpf(leg_swing, 0.9, sit_weight)
		_right_leg.rotation.x = lerpf(-leg_swing, 0.9, sit_weight)
		_head.rotation.x = idle * 0.35 - wave_weight * 0.08
		_head.rotation.y = sin(_time * 0.8) * 0.025
		position.y = idle * (1.0 - _motion) + body_bob - sit_weight * 0.28
		rotation.z = lerpf(rotation.z, sin(gait_phase) * 0.025 * _motion, minf(delta * 7.0, 1.0))

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
	# Rounded shoulder and hip volumes soften the mannequin-like silhouette.
	_add_sphere(self, "UpperTorso", Vector3(0, 1.34, 0), Vector3(0.30, 0.27, 0.22), shirt)
	_add_capsule(self, "Torso", Vector3(0, 1.12, 0), 0.28, 0.82, shirt)
	_add_sphere(self, "HipShape", Vector3(0, 0.78, 0), Vector3(0.265, 0.19, 0.205), trousers)
	# Layered clothing details keep the procedural preview readable at mobile distance.
	var trim := _material(Color(0.78, 0.67, 0.43), 0.52)
	_add_box(self, "CollarFront", Vector3(0, 1.48, -0.245), Vector3(0.22, 0.075, 0.045), trim)
	_add_box(self, "ShirtPlacket", Vector3(0, 1.16, -0.286), Vector3(0.035, 0.48, 0.025), trim)
	for button_index in range(3):
		_add_sphere(self, "ShirtButton_%d" % button_index, Vector3(0, 1.31 - float(button_index) * 0.14, -0.306), Vector3(0.018, 0.018, 0.012), trim)
	_add_capsule(self, "Neck", Vector3(0, 1.61, 0), 0.105, 0.22, skin)
	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0, 1.82, 0)
	add_child(_head)
	_add_sphere(_head, "Face", Vector3.ZERO, Vector3(0.225, 0.265, 0.215), skin)
	_add_sphere(_head, "HairCap", Vector3(0, 0.145, 0.025), Vector3(0.232, 0.145, 0.222), hair)
	_add_sphere(_head, "HairBack", Vector3(0, -0.045, 0.105), Vector3(0.218, 0.205, 0.145), hair)
	_add_sphere(_head, "FrontHair", Vector3(0, 0.105, -0.16), Vector3(0.19, 0.105, 0.075), hair)
	_add_sphere(_head, "LeftHairLock", Vector3(-0.19, -0.005, -0.005), Vector3(0.055, 0.19, 0.085), hair)
	_add_sphere(_head, "RightHairLock", Vector3(0.19, -0.005, -0.005), Vector3(0.055, 0.19, 0.085), hair)
	_add_sphere(_head, "HairCrownVolume", Vector3(0, 0.19, 0.015), Vector3(0.205, 0.09, 0.20), hair)
	_add_sphere(_head, "CheekLeft", Vector3(-0.125, -0.065, -0.165), Vector3(0.075, 0.06, 0.04), skin)
	_add_sphere(_head, "CheekRight", Vector3(0.125, -0.065, -0.165), Vector3(0.075, 0.06, 0.04), skin)
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

	_name_label = Label3D.new()
	_name_label.name = "VerifiedMemberName"
	_name_label.text = "Colony Member"
	_name_label.position = Vector3(0, 2.42, 0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.font_size = 36
	_name_label.pixel_size = 0.006
	_name_label.outline_size = 6
	_name_label.modulate = Color(1.0, 0.91, 0.72, 1.0)
	_name_label.outline_modulate = Color(0.025, 0.04, 0.065, 0.92)
	add_child(_name_label)

	_left_arm = _make_limb("LeftArm", Vector3(-0.34, 1.42, 0), skin, 0.115, 0.72)
	_right_arm = _make_limb("RightArm", Vector3(0.34, 1.42, 0), skin, 0.115, 0.72)
	_left_arm.rotation.z = -0.12
	_right_arm.rotation.z = 0.12
	_add_capsule(_left_arm, "Sleeve", Vector3(0, 0.12, 0), 0.14, 0.48, shirt)
	_add_capsule(_right_arm, "Sleeve", Vector3(0, 0.12, 0), 0.14, 0.48, shirt)
	_add_capsule(_left_arm, "LeftCuff", Vector3(0, -0.13, 0), 0.119, 0.10, trim)
	_add_capsule(_right_arm, "RightCuff", Vector3(0, -0.13, 0), 0.119, 0.10, trim)
	_add_sphere(_left_arm, "LeftHand", Vector3(0, -0.34, 0), Vector3(0.105, 0.13, 0.09), skin)
	_add_sphere(_right_arm, "RightHand", Vector3(0, -0.34, 0), Vector3(0.105, 0.13, 0.09), skin)
	# Subtle shoulder caps smooth the transition between torso and sleeves.
	_add_sphere(self, "LeftShoulder", Vector3(-0.34, 1.42, 0), Vector3(0.17, 0.18, 0.17), shirt)
	_add_sphere(self, "RightShoulder", Vector3(0.34, 1.42, 0), Vector3(0.17, 0.18, 0.17), shirt)
	_left_leg = _make_limb("LeftLeg", Vector3(-0.15, 0.72, 0), trousers, 0.145, 0.78)
	_right_leg = _make_limb("RightLeg", Vector3(0.15, 0.72, 0), trousers, 0.145, 0.78)
	_add_box(_left_leg, "ShoeSole", Vector3(0, -0.445, -0.07), Vector3(0.27, 0.055, 0.40), trim)
	_add_box(_right_leg, "ShoeSole", Vector3(0, -0.445, -0.07), Vector3(0.27, 0.055, 0.40), trim)
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
