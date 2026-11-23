extends Area3D
## Local scene portal. Production access and room permissions must be checked by the trusted backend.

@export var destination: Vector3 = Vector3.ZERO
@export var destination_yaw_degrees: float = 0.0
@export var status_message: String = "Lokasi berhasil dimasuki."

func _ready() -> void:
	add_to_group("world_interactable")
	collision_layer = 2
	collision_mask = 0

func get_interaction_label() -> String:
	return "Masuk • " + name

func interact(actor: Node, action_id: String = "use") -> String:
	if action_id != "use":
		return "Pilih aksi GUNAKAN untuk berpindah lokasi."
	if actor is Node3D:
		actor.global_position = destination
		actor.global_rotation.y = deg_to_rad(destination_yaw_degrees)
		if actor is CharacterBody3D:
			actor.velocity = Vector3.ZERO
		return status_message
	return "Karakter tidak dapat dipindahkan."


func get_available_actions() -> Array[String]:
	return ["use"]
