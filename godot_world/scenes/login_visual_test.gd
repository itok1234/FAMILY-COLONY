extends Node3D

var root_ui: Control
var password_field: LineEdit
var status_label: Label
var password_visible := false

func _ready() -> void:
	_build_environment()
	_build_ui()

func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.025, 0.07, 0.16)
	sky_mat.sky_horizon_color = Color(0.12, 0.23, 0.34)
	sky_mat.ground_bottom_color = Color(0.02, 0.04, 0.08)
	sky_mat.ground_horizon_color = Color(0.12, 0.23, 0.34)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.56, 0.72)
	env.ambient_light_energy = 0.7
	env_node.environment = env
	add_child(env_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, -28, 0)
	light.light_color = Color(0.82, 0.9, 1.0)
	light.light_energy = 0.8
	add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.3, 8.5)
	camera.look_at(Vector3(0, 1.4, 0))
	add_child(camera)
	var orb := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.35
	mesh.height = 2.7
	mesh.radial_segments = 48
	mesh.rings = 24
	orb.mesh = mesh
	orb.position = Vector3(-2.15, 1.4, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.27, 0.42)
	mat.metallic = 0.32
	mat.roughness = 0.28
	orb.material_override = mat
	add_child(orb)
	for pair in [[1.7, Color(0.88,0.68,0.26)],[2.05,Color(0.48,0.72,0.9)]]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = pair[0] - 0.035
		tm.outer_radius = pair[0] + 0.035
		ring.mesh = tm
		ring.position = orb.position
		ring.rotation_degrees = Vector3(22, 0, 35)
		var rm := StandardMaterial3D.new()
		rm.albedo_color = pair[1]
		rm.metallic = 0.65
		rm.roughness = 0.25
		ring.material_override = rm
		add_child(ring)

func _build_ui() -> void:
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_ui)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.53
	panel.anchor_right = 0.96
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.88
	root_ui.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.065,0.12,0.94)
	style.border_color = Color(0.36,0.62,0.82,0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel",style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",14)
	panel.add_child(v)
	var title := Label.new()
	title.text = "FAMILY COLONY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",32)
	v.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "EVERY FAMILY HAS A STORY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size",14)
	v.add_child(subtitle)
	var user := LineEdit.new()
	user.placeholder_text = "Username / Email"
	user.custom_minimum_size.y = 54
	v.add_child(user)
	password_field = LineEdit.new()
	password_field.placeholder_text = "Password"
	password_field.secret = true
	password_field.custom_minimum_size.y = 54
	v.add_child(password_field)
	var toggle := Button.new()
	toggle.text = "Show / Hide Password"
	toggle.custom_minimum_size.y = 48
	toggle.pressed.connect(_toggle_password)
	v.add_child(toggle)
	var login := Button.new()
	login.text = "LOGIN MEMBER"
	login.custom_minimum_size.y = 58
	login.pressed.connect(func(): _show_status("Login Member: integrasi autentikasi belum dihubungkan pada test visual."))
	v.add_child(login)
	var guest := Button.new()
	guest.text = "CONTINUE AS GUEST"
	guest.custom_minimum_size.y = 52
	guest.pressed.connect(func(): _show_status("Guest: alur autentikasi belum dihubungkan pada test visual."))
	v.add_child(guest)
	var dev := Button.new()
	dev.text = "DEVELOPER ACCESS"
	dev.custom_minimum_size.y = 52
	dev.pressed.connect(func(): _show_status("Developer: alur autentikasi belum dihubungkan pada test visual."))
	v.add_child(dev)
	status_label = Label.new()
	status_label.text = "Visual module test — no real authentication"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(status_label)
	var footer := Label.new()
	footer.text = "CDL PROJECT STUDIO"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(footer)

func _toggle_password() -> void:
	password_visible = not password_visible
	password_field.secret = not password_visible

func _show_status(message: String) -> void:
	status_label.text = message

func _process(delta: float) -> void:
	rotation_degrees.y += delta * 4.0
