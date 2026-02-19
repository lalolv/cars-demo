extends CharacterBody3D

@export var move_speed: float = 1.1
@export var acceleration: float = 4.5
@export var turn_speed: float = 5.0
@export var roam_radius: float = 7.5
@export var idle_time_min: float = 0.5
@export var idle_time_max: float = 1.6
@export var min_target_distance: float = 1.2
@export var max_target_attempts: int = 12
@export var keep_ground_height: bool = true
@export var blocked_pause_min: float = 0.2
@export var blocked_pause_max: float = 0.5
@export var repath_cooldown: float = 0.25

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _origin: Vector3 = Vector3.ZERO
var _ground_y: float = 0.0
var _idle_timer: float = 0.0
var _navigation_ready: bool = false
var _repath_cooldown_left: float = 0.0

func _ready() -> void:
	_rng.randomize()
	_origin = global_position
	_ground_y = global_position.y

	navigation_agent.path_desired_distance = 0.2
	navigation_agent.target_desired_distance = 0.28
	navigation_agent.avoidance_enabled = true
	navigation_agent.max_speed = move_speed

	if not _has_navigation_map():
		return

	_navigation_ready = true
	_pick_next_target()

func _physics_process(delta: float) -> void:
	if not _navigation_ready:
		if _has_navigation_map():
			_navigation_ready = true
			_pick_next_target()
		else:
			return

	if _repath_cooldown_left > 0.0:
		_repath_cooldown_left -= delta

	if _idle_timer > 0.0:
		_idle_timer -= delta
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		_lock_ground_height()
		if _idle_timer <= 0.0:
			_pick_next_target()
		return

	if navigation_agent.is_navigation_finished():
		_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)
		velocity = Vector3.ZERO
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var to_next: Vector3 = next_position - global_position
	to_next.y = 0.0

	if to_next.length() <= 0.01:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		_lock_ground_height()
		return

	var desired_velocity: Vector3 = to_next.normalized() * move_speed
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	velocity.y = 0.0

	var facing_yaw: float = atan2(velocity.x, velocity.z)
	rotation.y = lerp_angle(rotation.y, facing_yaw, turn_speed * delta)

	move_and_slide()
	_lock_ground_height()
	_handle_blocking_collision()

func _pick_next_target() -> void:
	for _attempt in range(max_target_attempts):
		var candidate: Vector3 = _origin + _random_roam_offset()
		var nearest_point: Vector3 = NavigationServer3D.map_get_closest_point(navigation_agent.get_navigation_map(), candidate)
		if nearest_point.distance_to(global_position) < min_target_distance:
			continue
		navigation_agent.target_position = nearest_point
		return

	navigation_agent.target_position = global_position
	_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)

func _random_roam_offset() -> Vector3:
	var angle: float = _rng.randf() * TAU
	var radius: float = sqrt(_rng.randf()) * roam_radius
	return Vector3(cos(angle), 0.0, sin(angle)) * radius

func _has_navigation_map() -> bool:
	var nav_map: RID = navigation_agent.get_navigation_map()
	return NavigationServer3D.map_get_iteration_id(nav_map) > 0

func _lock_ground_height() -> void:
	if keep_ground_height:
		global_position.y = _ground_y

func _handle_blocking_collision() -> void:
	if _repath_cooldown_left > 0.0:
		return

	var collision_count: int = get_slide_collision_count()
	if collision_count <= 0:
		return

	for i in range(collision_count):
		var collision: KinematicCollision3D = get_slide_collision(i)
		if not collision:
			continue
		var normal: Vector3 = collision.get_normal()
		normal.y = 0.0
		if normal.length_squared() <= 0.0001:
			continue

		velocity = Vector3.ZERO
		_repath_cooldown_left = repath_cooldown
		_idle_timer = _rng.randf_range(blocked_pause_min, blocked_pause_max)
		_pick_detour_target(normal.normalized())
		return

func _pick_detour_target(hit_normal: Vector3) -> void:
	var side_sign: float = -1.0 if _rng.randf() < 0.5 else 1.0
	var tangent: Vector3 = hit_normal.rotated(Vector3.UP, side_sign * PI * 0.5)
	var detour_distance: float = maxf(min_target_distance, 1.6)
	var candidate: Vector3 = global_position + hit_normal * 0.9 + tangent * detour_distance
	var nearest_point: Vector3 = NavigationServer3D.map_get_closest_point(navigation_agent.get_navigation_map(), candidate)

	if nearest_point.distance_to(global_position) >= 0.35:
		navigation_agent.target_position = nearest_point
	else:
		_pick_next_target()
