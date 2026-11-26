extends Node3D
## Optional production asset mounting point in the live world scene.
## Mounts only assets that have passed the project's explicit visual acceptance gate.

const LOADER_SCRIPT := preload("res://scripts/production_asset_loader.gd")
@export var environment_key := ""
@export var character_key := ""
@export var environment_mount_path: NodePath = NodePath("../ProductionEnvironmentMount")
@export var character_mount_path: NodePath = NodePath("../Player/ProductionCharacterMount")

var _loader: Node

func _ready() -> void:
	_loader = LOADER_SCRIPT.new()
	_mount_selected_or_first("environment", environment_key, environment_mount_path)
	_mount_selected_or_first("character", character_key, character_mount_path)

func _mount_selected_or_first(category: String, key: String, mount_path: NodePath) -> void:
	var mount := get_node_or_null(mount_path)
	if mount == null:
		push_warning("Production asset mount point missing: %s" % mount_path)
		return
	var model: Node3D = null
	if key.strip_edges() != "":
		model = _loader.load_approved_model(category, key)
	else:
		model = _loader.load_first_approved(category)
	if model == null:
		return
	mount.add_child(model)
	model.name = "ApprovedProduction_" + (key if key.strip_edges() != "" else category)
	if category == "character":
		var fallback_avatar := get_node_or_null("../Player/AvatarVisual")
		if fallback_avatar is Node3D:
			fallback_avatar.visible = false
