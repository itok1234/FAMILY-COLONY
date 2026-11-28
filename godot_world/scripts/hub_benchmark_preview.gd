extends Node3D
## Standalone visual benchmark harness: instantiate the production hub scene script
## without login/session/network dependencies, for scene QA and screenshot capture.

const HUB_SCRIPT = preload("res://scripts/main_hub_3d.gd")

func _ready() -> void:
	var hub := Node3D.new()
	hub.name = "BenchmarkHub"
	hub.set_script(HUB_SCRIPT)
	add_child(hub)
