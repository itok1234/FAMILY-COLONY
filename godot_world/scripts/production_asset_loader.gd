extends Node
## Runtime loader for explicitly accepted production GLB assets.
## This helper deliberately does not load intake candidates or bootstrap placeholders.
## Call load_approved_model(category, asset_key) from an existing scene integration.

const MANIFEST_PATH := "res://assets/production_asset_manifest.json"

func load_approved_model(category: String, asset_key: String) -> Node3D:
	if category not in ["character", "environment"]:
		push_error("Unsupported production asset category: %s" % category)
		return null
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		push_warning("Production asset manifest unavailable; no model loaded.")
		return null
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		push_error("Production asset manifest is malformed.")
		return null
	var entries: Variant = parsed.get(category, [])
	if not entries is Array:
		push_error("Manifest category is not an array: %s" % category)
		return null
	for entry in entries:
		if not entry is Dictionary:
			continue
		if str(entry.get("key", entry.get("name", ""))) != asset_key:
			continue
		if str(entry.get("visual_qa", "")) != "approved":
			push_warning("Asset is not visually approved: %s" % asset_key)
			return null
		var asset_path := str(entry.get("path", ""))
		if asset_path.is_empty() or not asset_path.begins_with("res://"):
			push_error("Approved entry has invalid resource path.")
			return null
		if not ResourceLoader.exists(asset_path):
			push_error("Approved model resource missing: %s" % asset_path)
			return null
		var packed := load(asset_path) as PackedScene
		if packed == null:
			push_error("GLB could not be loaded as PackedScene: %s" % asset_path)
			return null
		var instance := packed.instantiate()
		if instance is Node3D:
			return instance as Node3D
		instance.free()
		push_error("Loaded asset root is not Node3D: %s" % asset_path)
		return null
	push_warning("No accepted manifest entry matches key: %s" % asset_key)
	return null

func load_first_approved(category: String) -> Node3D:
	if category not in ["character", "environment"]:
		return null
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return null
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary or not parsed.get(category, []) is Array:
		return null
	for entry in parsed.get(category, []):
		if entry is Dictionary and str(entry.get("visual_qa", "")) == "approved":
			var key := str(entry.get("key", entry.get("name", "")))
			if not key.is_empty():
				var model := load_approved_model(category, key)
				if model != null:
					return model
	return null
