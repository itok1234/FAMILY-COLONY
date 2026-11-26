extends SceneTree
## Smoke-test loader fail-closed behaviour and manifest schema.
func _initialize() -> void:
	var loader_script = load("res://scripts/production_asset_loader.gd")
	if loader_script == null:
		push_error("Production loader unavailable")
		quit(1)
		return
	var loader = loader_script.new()
	if loader.load_approved_model("invalid", "x") != null:
		push_error("Loader accepted unsupported category")
		quit(1)
		return
	var manifest_path := "res://assets/production_asset_manifest.json"
	if not FileAccess.file_exists(manifest_path):
		push_error("Production manifest missing")
		quit(1)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary or not parsed.has("character") or not parsed.has("environment"):
		push_error("Manifest schema incomplete")
		quit(1)
		return
	print("PRODUCTION_MOUNT_TEST: PASS (schema and fail-closed gate)")
	quit(0)
