extends Control
## Minimal touch joystick for Android. Emits normalized movement intent only.

@export var deadzone: float = 0.12
@export var knob_limit: float = 62.0

var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _output: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("mobile_joystick")
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func get_output() -> Vector2:
	return _output

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = event.position
			_update_stick(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset_stick()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_stick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_index = 0
			_origin = event.position
			_update_stick(event.position)
		else:
			_reset_stick()
	elif event is InputEventMouseMotion and _touch_index == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_stick(event.position)

func _update_stick(position: Vector2) -> void:
	var delta := position - _origin
	_knob = delta.limit_length(knob_limit)
	_output = Vector2(_knob.x, -_knob.y) / knob_limit
	if _output.length() < deadzone:
		_output = Vector2.ZERO
	queue_redraw()

func _reset_stick() -> void:
	_touch_index = -1
	_knob = Vector2.ZERO
	_output = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var base_radius := minf(size.x, size.y) * 0.34
	draw_circle(center, base_radius, Color(0.04, 0.08, 0.13, 0.30))
	draw_arc(center, base_radius, 0.0, TAU, 48, Color(0.82, 0.72, 0.48, 0.55), 2.0, true)
	draw_circle(center + _knob, base_radius * 0.42, Color(0.88, 0.78, 0.56, 0.58))
