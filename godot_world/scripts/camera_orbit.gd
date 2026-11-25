extends Node3D
## Third-person orbit camera: right-side touch drag on Android, right mouse drag in editor.

@export var sensitivity: float = 0.006
@export var min_pitch: float = -0.72
@export var max_pitch: float = 0.18
@export var touch_right_zone: float = 0.38

var _dragging_mouse := false
var _active_touch := -1
var _last_position := Vector2.ZERO
var _touch_drag_started := false
@export_range(0.0, 24.0, 1.0) var touch_drag_deadzone_px: float = 4.0

func _notification(what: int) -> void:
	# Release drag state when Android interrupts the app or changes focus.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_dragging_mouse = false
		_active_touch = -1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging_mouse = event.pressed
		_last_position = event.position
	elif event is InputEventMouseMotion and _dragging_mouse:
		_apply_look(event.position - _last_position)
		_last_position = event.position
	elif event is InputEventScreenTouch:
		var viewport_size := get_viewport().get_visible_rect().size
		# Reserve the bottom-right area for the sprint button; do not start orbit there.
		var sprint_zone := event.position.x >= viewport_size.x * 0.68 and event.position.y >= viewport_size.y * 0.48
		if event.pressed and _active_touch == -1 and not sprint_zone and event.position.x >= viewport_size.x * touch_right_zone:
			_active_touch = event.index
			_last_position = event.position
			_touch_drag_started = false
		elif not event.pressed and event.index == _active_touch:
			_active_touch = -1
			_touch_drag_started = false
	elif event is InputEventScreenDrag and event.index == _active_touch:
		var drag_delta := event.position - _last_position
		if not _touch_drag_started and drag_delta.length() >= touch_drag_deadzone_px:
			_touch_drag_started = true
		if _touch_drag_started:
			_apply_look(drag_delta)
		_last_position = event.position

func _apply_look(delta: Vector2) -> void:
	rotation.y -= delta.x * sensitivity
	rotation.x = clampf(rotation.x - delta.y * sensitivity, min_pitch, max_pitch)
