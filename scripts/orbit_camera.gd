extends Camera3D

@export var target: Node3D
@export var distance: float = 4.0
@export var min_distance: float = 2.5
@export var max_distance: float = 9.0
@export var rotation_speed: float = 0.5
@export var zoom_speed: float = 0.02
@export var min_pitch: float = 10.0
@export var max_pitch: float = 60.0
@export var limit_yaw_range: bool = true
@export var min_yaw: float = -120.0
@export var max_yaw: float = 120.0
@export var mouse_rotate_button: MouseButton = MOUSE_BUTTON_LEFT

var _yaw: float = 24.0
var _pitch: float = 23.0
var _touch_positions: Dictionary = {}
var _last_pinch_distance: float = 0.0
var _is_mouse_dragging: bool = false

func _ready() -> void:
	_update_camera_position()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_positions[event.index] = event.position
			if _touch_positions.size() == 2:
				_last_pinch_distance = _get_pinch_distance()
		else:
			_touch_positions.erase(event.index)
			if _touch_positions.size() < 2:
				_last_pinch_distance = 0.0

	elif event is InputEventScreenDrag:
		_touch_positions[event.index] = event.position

		if _touch_positions.size() == 1:
			_apply_rotation_delta(event.relative)

		elif _touch_positions.size() == 2:
			_handle_pinch_zoom()

	elif event is InputEventMouseButton:
		if event.button_index == mouse_rotate_button:
			_is_mouse_dragging = event.pressed

	elif event is InputEventMouseMotion and _is_mouse_dragging:
		_apply_rotation_delta(event.relative)

func _apply_rotation_delta(relative: Vector2) -> void:
	_yaw -= relative.x * rotation_speed
	if limit_yaw_range:
		_yaw = clamp(_yaw, min_yaw, max_yaw)

	_pitch += relative.y * rotation_speed
	_pitch = clamp(_pitch, min_pitch, max_pitch)
	_update_camera_position()

func _handle_pinch_zoom() -> void:
	var current_dist = _get_pinch_distance()
	if _last_pinch_distance > 0.0:
		var delta = current_dist - _last_pinch_distance
		distance = clamp(distance - delta * zoom_speed, min_distance, max_distance)
		_update_camera_position()
	_last_pinch_distance = current_dist

func _get_pinch_distance() -> float:
	var touches = _touch_positions.values()
	return touches[0].distance_to(touches[1])

func _update_camera_position() -> void:
	if not target:
		return

	var offset = Vector3.ZERO
	offset.x = distance * sin(deg_to_rad(_yaw)) * cos(deg_to_rad(_pitch))
	offset.y = distance * sin(deg_to_rad(_pitch))
	offset.z = distance * cos(deg_to_rad(_yaw)) * cos(deg_to_rad(_pitch))

	global_position = target.global_position + offset
	look_at(target.global_position)
