extends Node3D
## Production models require QA approval. Pending assets load only when explicitly enabled for smoke tests.
const LOADER_SCRIPT := preload("res://scripts/production_asset_loader.gd")
@export var environment_key := ""
@export var character_key := ""
@export var allow_candidate_smoke_test := false
@export var environment_mount_path: NodePath = NodePath("../ProductionEnvironmentMount")
@export var character_mount_path: NodePath = NodePath("../Player/ProductionCharacterMount")
var _loader: Node

func _ready() -> void:
	_loader = LOADER_SCRIPT.new()
	_mount("environment", environment_key, environment_mount_path)
	_mount("character", character_key, character_mount_path)

func _mount(category: String, key: String, mount_path: NodePath) -> void:
	var mount := get_node_or_null(mount_path)
	if mount == null:
		push_warning("Mount point missing: %s" % mount_path)
		return
	var model: Node3D = null
	var is_approved := false
	if key.strip_edges() != "":
		model = _loader.load_approved_model(category, key)
		is_approved = model != null
		if model == null and allow_candidate_smoke_test:
			model = _loader.load_runtime_candidate(category, key)
	else:
		model = _loader.load_first_approved(category)
		is_approved = model != null
		if model == null and allow_candidate_smoke_test:
			model = _loader.load_first_runtime_candidate(category)
	if model == null:
		return
	mount.add_child(model)
	model.name = "RuntimeModel_" + (key if key.strip_edges() != "" else category)
	# In isolated visual QA, hide the procedural avatar so candidate appearance can be evaluated.
	# In normal gameplay, pending candidates remain gated and the fallback stays visible.
	if category == "character" and (is_approved or allow_candidate_smoke_test):
		var fallback := get_node_or_null("../Player/AvatarVisual")
		if fallback is Node3D:
			fallback.visible = false
