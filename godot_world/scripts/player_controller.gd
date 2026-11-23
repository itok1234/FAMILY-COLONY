extends CharacterBody3D
## Desktop/editor movement test. Touch controls will be added for Android.

@export var walk_speed: float = 4.5
@export var acceleration: float = 14.0
@export var gravity_strength: float = 18.0
@export var turn_speed: float = 8.0

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
