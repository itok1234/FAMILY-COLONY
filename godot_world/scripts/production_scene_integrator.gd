extends Node3D
## Optional production asset mounting point in the live world scene.
## Existing placeholder environment/avatar are retained as fallback until an
## explicitly approved, imported asset exists in the acceptance manifest.

const LOADER_SCRIPT := preload("res://scripts/production_asset_loader.gd")
@export var environment_key := ""
@export var character_key := ""
@export var environment_mount_path: NodePath = NodePath("../ProductionEnvironmentMount")
@export var character_mount_path: NodePath = NodePath("../Player/ProductionCharacterMount")

var _loader: Node

func _ready() -> void:
	_loader = LOADER_SCRIPT.new()
	if environment_key.strip_edges() != "":
		_mount(environment_key, "environment", environment_mount_path)
	if character_key.strip_edges() != "":
		_mount(character_key, "character", character_mount_path)

func _mount(key: String, category: String, mount_path: NodePath) -> void:
	var mount := get_node_or_null(mount_path)
	if mount == null:
		push_warning("Production asset mount point missing: %s" % mount_path)
		return
	var model: Node3D = _loader.load_approved_model(category, key)
	if model == null:
		return
	mount.add_child(model)
	model.name = "ApprovedProduction_" + key
\nfunc _mount_first(category: String, mount_path: NodePath) -> void:\n\tvar mount := get_node_or_null(mount_path)\n\tif mount == null:\n\t\tpush_warning("Production asset mount point missing: %s" % mount_path)\n\t\treturn\n\tvar model: Node3D = _loader.load_first_approved(category)\n\tif model == null:\n\t\treturn\n\tmount.add_child(model)\n\tmodel.name = "ApprovedProduction_" + category\n