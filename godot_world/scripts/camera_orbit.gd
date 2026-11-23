extends Node3D
## Third-person orbit camera: right-side touch drag on Android, right mouse drag in editor.

@export var sensitivity: float = 0.006
@export var min_pitch: float = -0.72
@export var max_pitch: float = 0.18
@export var touch_right_zone: float = 0.38

var _dragging_mouse := false
var _active_touch := -1
var _last_position := Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging_mouse = event.pressed
		_last_position = event.position
	elif event is InputEventMouseMotion and _dragging_mouse:
		_apply_look(event.position - _last_position)
		_last_position = event.position
	elif event is InputEventScreenTouch:
		if event.pressed and _active_touch == -1 and event.position.x >= get_viewport().get_visible_rect().size.x * touch_right_zone:
			_active_touch = event.index
			_last_position = event.position
		elif not event.pressed and event.index == _active_touch:
			_active_touch = -1
	elif event is InputEventScreenDrag and event.index == _active_touch:
		_apply_look(event.position - _last_position)
		_last_position = event.position

func _apply_look(delta: Vector2) -> void:
	rotation.y -= delta.x * sensitivity
	rotation.x = clampf(rotation.x - delta.y * sensitivity, min_pitch, max_pitch)
