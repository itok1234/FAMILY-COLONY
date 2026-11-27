extends Node3D
## Isolated visual prototype only: authentication and navigation are not yet wired.
@onready var camera: Camera3D = $Camera3D
var rotation_root: Node3D

func _ready() -> void:
    _build_scene()

func _build_scene() -> void:
    var env_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.025, 0.07, 0.16)
    sky_mat.sky_horizon_color = Color(0.12, 0.23, 0.34)
    sky_mat.ground_bottom_color = Color(0.02, 0.04, 0.08)
    sky_mat.ground_horizon_color = Color(0.12, 0.23, 0.34)
    sky.sky_material = sky_mat
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.42, 0.56, 0.72)
    environment.ambient_light_energy = 0.65
    env_node.environment = environment
    add_child(env_node)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-38, -28, 0)
    light.light_color = Color(0.82, 0.9, 1.0)
    light.light_energy = 0.8
    add_child(light)

    camera.position = Vector3(0, 2.4, 9.8)
    camera.look_at(Vector3(0, 1.6, 0))
    rotation_root = Node3D.new()
    rotation_root.position = Vector3(0, 1.6, 0)
    add_child(rotation_root)

    _add_sphere(Vector3.ZERO, 1.35, Color(0.12, 0.27, 0.42), rotation_root)
    _add_torus(Vector3(0, 0.05, 0), 1.7, 0.055, Color(0.88, 0.68, 0.26), rotation_root)
    _add_torus(Vector3(0, 0.05, 0), 2.05, 0.025, Color(0.48, 0.72, 0.9), rotation_root)
    _add_sphere(Vector3(0, 0.15, 0), 0.72, Color(0.92, 0.68, 0.25), rotation_root)
    _add_sphere(Vector3(0, 0.15, 0), 0.58, Color(0.12, 0.22, 0.32), rotation_root)
    _add_sphere(Vector3(-0.72, 0.88, 0.15), 0.3, Color(0.78, 0.91, 0.97, 0.65), rotation_root)
    _add_sphere(Vector3(0.72, 0.88, 0.15), 0.3, Color(0.78, 0.91, 0.97, 0.65), rotation_root)

    for i in range(12):
        var angle := float(i) * TAU / 12.0
        _add_sphere(Vector3(cos(angle) * 2.65, sin(angle) * 1.15, 0), 0.07, Color(0.92, 0.72, 0.28), rotation_root)
    for i in range(24):
        var angle := float(i) * TAU / 24.0
        _add_sphere(Vector3(cos(angle) * 4.2, sin(angle) * 2.2, -1.4), 0.035, Color(0.65, 0.82, 0.98), self)

func _add_sphere(pos: Vector3, radius: float, color: Color, parent: Node) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 24
    mesh.rings = 12
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.25
    mat.roughness = 0.3
    if color.a < 1.0:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    node.material_override = mat
    parent.add_child(node)

func _add_torus(pos: Vector3, radius: float, tube: float, color: Color, parent: Node) -> void:
    var mesh := TorusMesh.new()
    mesh.inner_radius = radius - tube
    mesh.outer_radius = radius + tube
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.65
    mat.roughness = 0.25
    node.material_override = mat
    parent.add_child(node)

func _process(delta: float) -> void:
    if rotation_root:
        rotation_root.rotation.y += delta * 0.12
