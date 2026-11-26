extends Node
## Loads approved production assets, or pending candidates only for runtime smoke tests.
const MANIFEST_PATH := "res://assets/production_asset_manifest.json"

func _load_entry(category: String, entry: Dictionary, allow_pending: bool) -> Node3D:
	var status := str(entry.get("visual_qa", ""))
	if status != "approved" and not (allow_pending and bool(entry.get("runtime_test_candidate", false)) and status == "pending"):
		push_warning("Asset blocked by QA gate: %s" % entry.get("key", ""))
		return null
	var asset_path := str(entry.get("path", ""))
	if asset_path.is_empty() or not asset_path.begins_with("res://") or not ResourceLoader.exists(asset_path):
		push_error("Candidate resource missing/unloadable: %s" % asset_path)
		return null
	var packed := load(asset_path) as PackedScene
	if packed == null: push_error("Could not load GLB scene: %s" % asset_path);return null
	var instance := packed.instantiate()
	if instance is Node3D: return instance as Node3D
	instance.free();push_error("Asset root not Node3D: %s" % asset_path);return null

func _entries(category: String) -> Array:
	if category not in ["character","environment"]:return []
	var f:=FileAccess.open(MANIFEST_PATH,FileAccess.READ)
	if f==null:return []
	var parsed:Variant=JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary or not parsed.get(category,[]) is Array:return []
	return parsed.get(category,[])

func load_approved_model(category: String, asset_key: String) -> Node3D:
	for entry in _entries(category):
		if entry is Dictionary and str(entry.get("key",entry.get("name",""))) == asset_key:
			return _load_entry(category,entry,false)
	return null

func load_runtime_candidate(category: String, asset_key: String) -> Node3D:
	for entry in _entries(category):
		if entry is Dictionary and str(entry.get("key",entry.get("name",""))) == asset_key:
			return _load_entry(category,entry,true)
	return null

func load_first_approved(category: String) -> Node3D:
	for entry in _entries(category):
		if entry is Dictionary and str(entry.get("visual_qa",""))=="approved":
			var node:=load_approved_model(category,str(entry.get("key",entry.get("name",""))))
			if node:return node
	return null

func load_first_runtime_candidate(category: String) -> Node3D:
	for entry in _entries(category):
		if entry is Dictionary and bool(entry.get("runtime_test_candidate",false)) and str(entry.get("visual_qa",""))=="pending":
			var node:=load_runtime_candidate(category,str(entry.get("key","")))
			if node:return node
	return null
