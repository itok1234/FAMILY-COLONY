extends Node3D
## Remote-only visual proxy. Local player remains controlled by player_controller.gd.

var target_position: Vector3
var target_rotation: float = 0.0
var motion_strength: float = 0.0
var peer_id: int = 0
var _avatar: Node3D


func _ready() -> void:
	_avatar = Node3D.new()
	_avatar.name = "AvatarVisual"
	_avatar.set_script(load("res://scripts/avatar_visual.gd"))
	add_child(_avatar)
	target_position = global_position


func apply_network_state(new_position: Vector3, new_rotation: float, new_motion: float) -> void:
	target_position = new_position
	target_rotation = new_rotation
	motion_strength = clampf(new_motion, 0.0, 1.0)
	if is_instance_valid(_avatar) and _avatar.has_method("set_motion_strength"):
		_avatar.set_motion_strength(motion_strength)


func apply_network_appearance(appearance: Dictionary) -> void:
	if is_instance_valid(_avatar) and _avatar.has_method("apply_appearance"):
		_avatar.apply_appearance(appearance)


func _process(delta: float) -> void:
	global_position = global_position.lerp(target_position, minf(delta * 12.0, 1.0))
	rotation.y = lerp_angle(rotation.y, target_rotation, minf(delta * 12.0, 1.0))

func play_network_action(action_id: String) -> void:
	if action_id in ["wave", "sit", "stand"] and is_instance_valid(_avatar) and _avatar.has_method("play_action"):
		_avatar.play_action(action_id)
