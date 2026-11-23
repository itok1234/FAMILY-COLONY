extends Area3D
## Contract for objects and characters that can receive a contextual interaction.

@export var display_name: String = "Objek"
@export_multiline var response_text: String = "Interaksi berhasil."
@export var action_label: String = "Interaksi"

func _ready() -> void:
	add_to_group("world_interactable")

func get_interaction_label() -> String:
	return action_label + " • " + display_name

func interact(_actor: Node) -> String:
	return response_text
