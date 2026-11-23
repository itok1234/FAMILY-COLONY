extends CharacterBody3D
## Hybrid desktop + Android touch movement controller.

@export var walk_speed: float = 4.5
@export var acceleration: float = 14.0
@export var gravity_strength: float = 18.0
@export var turn_speed: float = 8.0

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var joystick := get_tree().get_first_node_in_group("mobile_joystick")
	if joystick != null and joystick.has_method("get_output"):
		var touch_input: Vector2 = joystick.get_output()
		if touch_input.length_squared() > 0.001:
			input_vector = touch_input

	var direction := Vector3(input_vector.x, 0.0, input_vector.y).normalized()
	var target_velocity := direction * walk_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

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
		avatar.set_motion_strength(clampf(horizontal_speed / maxf(walk_speed, 0.01), 0.0, 1.0))
