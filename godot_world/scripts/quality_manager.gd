extends Node
## Device quality presets. These presets never remove app features or member access.

enum Quality { PERFORMANCE, BALANCED, HIGH, ULTRA }

@export var default_quality: Quality = Quality.BALANCED
@export var world_environment_path: NodePath = NodePath("../WorldEnvironment")

@onready var world_environment: WorldEnvironment = get_node_or_null(world_environment_path) as WorldEnvironment

func _ready() -> void:
	apply_quality(default_quality)

func apply_quality(level: Quality) -> void:
	var viewport := get_viewport()
	match level:
		Quality.PERFORMANCE:
			viewport.scaling_3d_scale = 0.70
			_set_effects(false, false)
		Quality.BALANCED:
			viewport.scaling_3d_scale = 0.85
			_set_effects(false, true)
		Quality.HIGH:
			viewport.scaling_3d_scale = 1.0
			_set_effects(true, true)
		Quality.ULTRA:
			viewport.scaling_3d_scale = 1.25
			_set_effects(true, true)

func _set_effects(ambient_occlusion: bool, glow: bool) -> void:
	if world_environment == null or world_environment.environment == null:
		return
	world_environment.environment.glow_enabled = glow
	world_environment.environment.ssr_enabled = ambient_occlusion
