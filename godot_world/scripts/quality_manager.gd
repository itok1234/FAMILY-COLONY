extends Node
## Adaptive graphics profiles for a wide range of Android devices.
## Quality changes rendering only; they never disable gameplay or member features.

enum Quality { AUTO, PERFORMANCE, BALANCED, HIGH }

@export var default_quality: Quality = Quality.AUTO
@export var world_environment_path: NodePath = NodePath("../WorldEnvironment")
@export var sun_path: NodePath = NodePath("../Sun")
@export var environment_builder_path: NodePath = NodePath("../EnvironmentBuilder")

@onready var world_environment: WorldEnvironment = get_node_or_null(world_environment_path) as WorldEnvironment
@onready var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
@onready var environment_builder: Node = get_node_or_null(environment_builder_path)

var _selected_quality: Quality = Quality.AUTO
var _quality_picker: OptionButton


func _ready() -> void:
	_load_saved_quality()
	_build_quality_picker()
	apply_quality(_selected_quality)


func _load_saved_quality() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://family_colony_settings.cfg")
	if err == OK:
		_selected_quality = int(config.get_value("graphics", "quality", int(default_quality))) as Quality
	else:
		_selected_quality = default_quality
	_selected_quality = clampi(int(_selected_quality), int(Quality.AUTO), int(Quality.HIGH)) as Quality


func _save_quality() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "quality", int(_selected_quality))
	var err := config.save("user://family_colony_settings.cfg")
	if err != OK:
		push_warning("FAMILY COLONY: Graphics preference could not be saved.")


func _build_quality_picker() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GraphicsSettingsLayer"
	layer.layer = 20
	add_child(layer)

	_quality_picker = OptionButton.new()
	_quality_picker.name = "GraphicsQualityPicker"
	_quality_picker.position = Vector2(18, 18)
	_quality_picker.custom_minimum_size = Vector2(190, 44)
	_quality_picker.add_item("Grafis: Otomatis", Quality.AUTO)
	_quality_picker.add_item("Grafis: Hemat", Quality.PERFORMANCE)
	_quality_picker.add_item("Grafis: Seimbang", Quality.BALANCED)
	_quality_picker.add_item("Grafis: Tinggi", Quality.HIGH)
	_quality_picker.item_selected.connect(_on_quality_selected)
	layer.add_child(_quality_picker)


func _on_quality_selected(index: int) -> void:
	_selected_quality = int(_quality_picker.get_item_id(index)) as Quality
	_save_quality()
	apply_quality(_selected_quality)


func _resolve_auto_quality() -> Quality:
	if OS.get_name() == "Android" and OS.get_processor_count() <= 6:
		return Quality.PERFORMANCE
	return Quality.BALANCED


func apply_quality(level: Quality) -> void:
	var resolved: Quality = _resolve_auto_quality() if level == Quality.AUTO else level
	var viewport := get_viewport()

	match resolved:
		Quality.PERFORMANCE:
			viewport.scaling_3d_scale = 0.70
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			_set_scene_density(10, 4, 3)
			_set_effects(false, false)
		Quality.BALANCED:
			viewport.scaling_3d_scale = 0.85
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			_set_scene_density(18, 7, 4)
			_set_effects(false, false)
		Quality.HIGH:
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_2X
			_set_scene_density(26, 10, 5)
			_set_effects(true, true)


func _set_scene_density(trees: int, lamps: int, buildings: int) -> void:
	if environment_builder == null:
		return
	environment_builder.set("tree_count", trees)
	environment_builder.set("lamp_count", lamps)
	environment_builder.set("building_count", buildings)


func _set_effects(shadows: bool, glow: bool) -> void:
	if sun != null:
		sun.shadow_enabled = shadows
	if world_environment == null or world_environment.environment == null:
		return
	world_environment.environment.glow_enabled = glow
	world_environment.environment.ssr_enabled = false
