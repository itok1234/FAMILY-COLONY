extends Node3D
signal action_pressed
## Camera-mounted spatial touch controls. All visible controls are real 3D meshes.

@export_range(30.0, 180.0, 1.0) var joystick_radius_px: float = 92.0
@export_range(0.0, 0.4, 0.01) var deadzone: float = 0.12

var _move_touch := -1
var _sprint_touch := -1
var _action_touch := -1
var _action_label: Label3D
var _move_origin := Vector2.ZERO
var _move_output := Vector2.ZERO
var _sprinting := false
var _knob: MeshInstance3D
var _sprint_label: Label3D


func _ready() -> void:
	add_to_group("mobile_joystick")
	visible = OS.has_feature("android")
	if visible:
		_build_spatial_controls()


func get_output() -> Vector2:
	return _move_output


func is_sprinting() -> bool:
	return _sprinting


func _build_spatial_controls() -> void:
	var base := Node3D.new()
	base.name = "SpatialMoveJoystick"
	base.position = Vector3(-1.32, -0.78, -3.0)
	add_child(base)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.34
	ring_mesh.outer_radius = 0.43
	ring.mesh = ring_mesh
	ring.material_override = _make_material(Color("#d9bd7d"), 0.62)
	base.add_child(ring)

	var center := MeshInstance3D.new()
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.38
	center_mesh.bottom_radius = 0.38
	center_mesh.height = 0.035
	center.mesh = center_mesh
	center.rotation_degrees.x = 90.0
	center.material_override = _make_material(Color(0.12, 0.2, 0.28, 0.58), 0.2)
	base.add_child(center)

	_knob = MeshInstance3D.new()
	var knob_mesh := SphereMesh.new()
	knob_mesh.radius = 0.25
	knob_mesh.height = 0.5
	_knob.mesh = knob_mesh
	_knob.material_override = _make_material(Color("#e8cf98"), 0.75)
	_knob.position.z = -0.08
	base.add_child(_knob)

	var move_label := Label3D.new()
	move_label.text = "MOVE"
	move_label.font_size = 18
	move_label.pixel_size = 0.003
	move_label.position = Vector3(0, -0.62, 0)
	move_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	move_label.modulate = Color("#e8edf2")
	base.add_child(move_label)

	var sprint := Node3D.new()
	sprint.name = "SpatialSprintControl"
	sprint.position = Vector3(1.32, -0.78, -3.0)
	add_child(sprint)

	var sprint_orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.39
	orb_mesh.height = 0.78
	sprint_orb.mesh = orb_mesh
	sprint_orb.material_override = _make_material(Color("#b58a45"), 0.42)
	sprint.add_child(sprint_orb)

	_sprint_label = Label3D.new()
	_sprint_label.text = "LARI"
	_sprint_label.font_size = 22
	_sprint_label.pixel_size = 0.0035
	_sprint_label.position = Vector3(0, -0.58, 0)
	_sprint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprint_label.modulate = Color("#fff1cc")
	sprint.add_child(_sprint_label)

	var action := Node3D.new()
	action.name = "SpatialActionControl"
	action.position = Vector3(1.32, 0.35, -3.0)
	add_child(action)
	var action_orb := MeshInstance3D.new()
	var action_mesh := SphereMesh.new()
	action_mesh.radius = 0.34
	action_mesh.height = 0.68
	action_orb.mesh = action_mesh
	action_orb.material_override = _make_material(Color("#527b91"), 0.4)
	action.add_child(action_orb)
	_action_label = Label3D.new()
	_action_label.text = "AKSI"
	_action_label.font_size = 22
	_action_label.pixel_size = 0.0035
	_action_label.position = Vector3(0, -0.5, 0)
	_action_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_action_label.modulate = Color("#eaf6ff")
	action.add_child(_action_label)


func _notification(what: int) -> void:
	# Clear held touch state if Android suspends the app or focus is interrupted.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_reset_move()
		_sprint_touch = -1
		_action_touch = -1
		_set_sprinting(false)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	if event is InputEventScreenTouch:
		var point: Vector2 = event.position
		if event.pressed:
			if _move_touch == -1 and point.x <= viewport_size.x * 0.48 and point.y >= viewport_size.y * 0.42:
				_move_touch = event.index
				_move_origin = point
				_update_move(point)
				get_viewport().set_input_as_handled()
			elif _action_touch == -1 and point.x >= viewport_size.x * 0.68 and point.y >= viewport_size.y * 0.12 and point.y < viewport_size.y * 0.48:
				_action_touch = event.index
				if is_instance_valid(_action_label):
					_action_label.text = "..."
				action_pressed.emit()
				get_viewport().set_input_as_handled()
			elif _sprint_touch == -1 and point.x >= viewport_size.x * 0.68 and point.y >= viewport_size.y * 0.48:
				_sprint_touch = event.index
				_set_sprinting(true)
				get_viewport().set_input_as_handled()
		else:
			if event.index == _move_touch:
				_reset_move()
				get_viewport().set_input_as_handled()
			elif event.index == _action_touch:
				_action_touch = -1
				if is_instance_valid(_action_label):
					_action_label.text = "AKSI"
				get_viewport().set_input_as_handled()
			elif event.index == _sprint_touch:
				_sprint_touch = -1
				_set_sprinting(false)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _move_touch:
			_update_move(event.position)
			get_viewport().set_input_as_handled()


func _update_move(point: Vector2) -> void:
	var delta := point - _move_origin
	var limited := delta.limit_length(joystick_radius_px)
	_move_output = Vector2(limited.x, limited.y) / joystick_radius_px
	if _move_output.length() < deadzone:
		_move_output = Vector2.ZERO
	if is_instance_valid(_knob):
		_knob.position = Vector3(_move_output.x * 0.34, -_move_output.y * 0.34, -0.08)


func _reset_move() -> void:
	_move_touch = -1
	_move_output = Vector2.ZERO
	if is_instance_valid(_knob):
		_knob.position = Vector3(0, 0, -0.08)


func _set_sprinting(value: bool) -> void:
	_sprinting = value
	if is_instance_valid(_sprint_label):
		_sprint_label.text = "LARI!" if value else "LARI"


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.18
	material.emission_enabled = true
	material.emission = color.darkened(0.38)
	material.emission_energy_multiplier = 0.12
	return material
