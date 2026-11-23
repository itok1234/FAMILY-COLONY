extends Area3D
## Interactive entry point for the local 3D mini-game.

var game_manager: Node


func _ready() -> void:
	add_to_group("world_interactable")
	collision_layer = 2
	collision_mask = 0


func get_interaction_label() -> String:
	return "MAIN MINI-GAME • HONEY HUNT"


func get_available_actions() -> Array[String]:
	return ["use"]


func interact(actor: Node, action_id: String = "use") -> String:
	if action_id != "use":
		return "Pilih GUNAKAN untuk memulai mini-game."
	if game_manager == null or not is_instance_valid(game_manager):
		return "Mini-game belum siap."
	return str(game_manager.call("start_honey_hunt", actor))
