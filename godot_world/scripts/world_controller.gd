extends Node3D
## FAMILY COLONY world scene controller.
## Networking and account/session binding are deliberately kept out of this prototype.

@export var player_path: NodePath = NodePath("Player")
@onready var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D

func _ready() -> void:
	if player == null:
		push_warning("FAMILY COLONY: Player node is not assigned.")
