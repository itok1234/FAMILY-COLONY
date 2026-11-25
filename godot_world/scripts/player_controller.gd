extends CharacterBody3D
## Hybrid desktop + Android touch movement controller.

@export var walk_speed: float = 4.5
@export var acceleration: float = 14.0
@export var gravity_strength: float = 18.0
@export var turn_speed: float = 8.0

var _is_seated := false
var _is_sprinting := false
func set_seated(value: bool) -> void:
	_is_seated = value
	if value:
		velocity = Vector3.ZERO
	var avatar := get_node_or_null("AvatarVisual")
	if avatar != null:
		if value and avatar.has_method("play_action"):
			avatar.call("play_action", "sit")
		elif not value and avatar.has_method("stand_up"):
			avatar.call("stand_up")

func is_seated() -> bool:
	return _is_seated

func _physics_process(delta: float) -> void:
	if _is_seated:
		velocity = Vector3.ZERO
		move_and_slide()
		var seated_avatar := get_node_or_null("AvatarVisual")
		if seated_avatar != null and seated_avatar.has_method("set_motion_strength"):
			seated_avatar.call("set_motion_strength", 0.0)
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var joystick := get_tree().get_first_node_in_group("mobile_joystick")
	var touch_sprinting := false
	if joystick != null and joystick.has_method("get_output"):
		var touch_input: Vector2 = joystick.get_output()
		if touch_input.length_squared() > 0.001:
			input_vector = touch_input
		if joystick.has_method("is_sprinting"):
			touch_sprinting = bool(joystick.call("is_sprinting"))
	_is_sprinting = touch_sprinting or Input.is_key_pressed(KEY_SHIFT)

	# Keep movement aligned with the camera yaw so forward always means
	# "toward the direction the player is looking" on both touch and desktop.
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var camera_pivot := get_node_or_null("CameraPivot") as Node3D
	if camera_pivot != null:
		var camera_basis := camera_pivot.global_transform.basis
		var camera_forward := -camera_basis.z
		var camera_right := camera_basis.x
		camera_forward.y = 0.0
		camera_right.y = 0.0
		if camera_forward.length_squared() > 0.001 and camera_right.length_squared() > 0.001:
			camera_forward = camera_forward.normalized()
			camera_right = camera_right.normalized()
			direction = camera_right * input_vector.x + camera_forward * -input_vector.y
	direction = direction.normalized()
	var current_speed := walk_speed * (1.5 if _is_sprinting and direction.length_squared() > 0.001 else 1.0)
	var current_acceleration := acceleration * (1.35 if _is_sprinting else 1.0)
	var target_velocity := direction * current_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, current_acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, current_acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(turn_speed * delta, 1.0))

	move_and_slide()

	var avatar := get_node_or_null("AvatarVisual")
	if avatar != null and avatar.has_method("set_motion_strength"):
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		avatar.set_motion_strength(clampf(horizontal_speed / maxf(walk_speed * 1.5, 0.01), 0.0, 1.0))
