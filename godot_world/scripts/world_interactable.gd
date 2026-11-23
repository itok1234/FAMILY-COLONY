extends Area3D
## Reusable local interaction target. Backend authorization is required for protected actions.

@export var display_name: String = "Objek"
@export_multiline var response_text: String = "Interaksi berhasil."
@export var action_label: String = "Interaksi"
@export var available_actions: Array[String] = ["use", "greet"]

func _ready() -> void:
	add_to_group("world_interactable")

func get_interaction_label() -> String:
	return action_label + " • " + display_name

func get_available_actions() -> Array[String]:
	return available_actions.duplicate()

func interact(_actor: Node, action_id: String = "use") -> String:
	match action_id:
		"greet":
			return "Kamu menyapa " + display_name + "."
		"sit":
			return "Kamu mengambil posisi duduk di dekat " + display_name + "."
		_:
			return response_text
