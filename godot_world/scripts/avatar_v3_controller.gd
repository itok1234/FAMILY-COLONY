extends Node
## Consolidated runtime interface for Avatar V3 appearance, movement and social actions.
## This controller delegates rendering to the avatar visual instance and does not grant cosmetics.

@export var avatar_path: NodePath
var _avatar: Node3D
var _appearance: Dictionary = {}
var _display_name := "Colony Member"

func _ready() -> void:
	if not avatar_path.is_empty():
		_avatar = get_node_or_null(avatar_path) as Node3D

func bind_avatar(visual: Node3D) -> bool:
	if visual == null:
		return false
	_avatar = visual
	_apply_cached_state()
	return true

func set_display_name(value: String) -> void:
	_display_name = value.strip_edges().left(24)
	if _display_name.is_empty():
		_display_name = "Colony Member"
	if _avatar != null and _avatar.has_method("set_display_name"):
		_avatar.set_display_name(_display_name)

func set_motion_strength(value: float) -> void:
	if _avatar != null and _avatar.has_method("set_motion_strength"):
		_avatar.set_motion_strength(clampf(value, 0.0, 1.0))

func play_social_action(action: String) -> bool:
	if _avatar == null or not _avatar.has_method("play_action"):
		return false
	if action not in ["wave", "sit", "stand", "jump", "dance"]:
		return false
	_avatar.play_action(action)
	return true

func set_appearance_preview(values: Dictionary) -> void:
	# Preview only; server-side ownership and persistence remain authoritative.
	_appearance = values.duplicate(true)
	if _avatar != null and _avatar.has_method("apply_appearance"):
		_avatar.apply_appearance(_appearance)

func get_preview_snapshot() -> Dictionary:
	return _appearance.duplicate(true)

func reset_preview() -> void:
	_appearance.clear()
	if _avatar != null and _avatar.has_method("reset_appearance_preview"):
		_avatar.reset_appearance_preview()

func _apply_cached_state() -> void:
	if _avatar == null:
		return
	if _avatar.has_method("set_display_name"):
		_avatar.set_display_name(_display_name)
	if not _appearance.is_empty() and _avatar.has_method("apply_appearance"):
		_avatar.apply_appearance(_appearance)
