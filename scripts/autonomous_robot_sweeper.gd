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
@export var back_wheel_node: Node3D
@export var front_wheel_node: Node3D
@export var back_wheel_visual_node: Node3D
@export var front_wheel_visual_node: Node3D
@export var back_wheel_visual_name: StringName = &"backWheel_low"
@export var front_wheel_visual_name: StringName = &"frontWheel_low"
@export var brush_left_node: Node3D
@export var brush_right_node: Node3D
@export var brush_left_name: StringName = &"brushLeft"
@export var brush_right_name: StringName = &"brushRight"
@export var brush_spin_axis_local: Vector3 = Vector3.UP
@export var brush_spin_speed: float = 12.0
@export var brush_spin_min_move_speed: float = 0.05
@export var brush_left_spin_multiplier: float = 1.0
@export var brush_right_spin_multiplier: float = -1.0
@export var wheel_radius: float = 0.06
@export var wheel_spin_axis_local: Vector3 = Vector3.RIGHT
@export var wheel_spin_multiplier: float = 1.0
@export var model_animation_player: AnimationPlayer
@export var moving_animation_name: StringName = &"Scene"
@export var moving_animation_min_speed: float = 0.05
@export var moving_animation_speed_scale: float = 1.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var model_root: Node = $Model

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _origin: Vector3 = Vector3.ZERO
var _ground_y: float = 0.0
var _idle_timer: float = 0.0
var _navigation_ready: bool = false
var _repath_cooldown_left: float = 0.0
var _moving_animation_ready: bool = false

func _ready() -> void:
	process_priority = 100
	_rng.randomize()
	_origin = global_position
	_ground_y = global_position.y

	navigation_agent.path_desired_distance = 0.2
	navigation_agent.target_desired_distance = 0.28
	navigation_agent.avoidance_enabled = true
	navigation_agent.max_speed = move_speed

	if back_wheel_node == null:
		push_warning("AutonomousRobotSweeper: back_wheel_node is not assigned. Please bind BackWheelPivot.")

	if front_wheel_node == null:
		push_warning("AutonomousRobotSweeper: front_wheel_node is not assigned. Please bind FrontWheelPivot.")

	if back_wheel_visual_node == null:
		var found_back_visual: Node = _find_descendant_by_name(model_root, back_wheel_visual_name)
		if found_back_visual is Node3D:
			back_wheel_visual_node = found_back_visual as Node3D
		else:
			push_warning("AutonomousRobotSweeper: back_wheel_visual_node is not assigned and '%s' was not found." % String(back_wheel_visual_name))

	if front_wheel_visual_node == null:
		var found_front_visual: Node = _find_descendant_by_name(model_root, front_wheel_visual_name)
		if found_front_visual is Node3D:
			front_wheel_visual_node = found_front_visual as Node3D
		else:
			push_warning("AutonomousRobotSweeper: front_wheel_visual_node is not assigned and '%s' was not found." % String(front_wheel_visual_name))

	if brush_left_node == null:
		var found_brush_left: Node = _find_descendant_by_name(model_root, brush_left_name)
		if found_brush_left is Node3D:
			brush_left_node = found_brush_left as Node3D
		else:
			push_warning("AutonomousRobotSweeper: brush_left_node is not assigned and '%s' was not found." % String(brush_left_name))

	if brush_right_node == null:
		var found_brush_right: Node = _find_descendant_by_name(model_root, brush_right_name)
		if found_brush_right is Node3D:
			brush_right_node = found_brush_right as Node3D
		else:
			push_warning("AutonomousRobotSweeper: brush_right_node is not assigned and '%s' was not found." % String(brush_right_name))

	if model_animation_player == null:
		var found_animation_player: Node = model_root.find_child("AnimationPlayer", true, false)
		if found_animation_player is AnimationPlayer:
			model_animation_player = found_animation_player as AnimationPlayer

	if model_animation_player != null:
		var moving_animation: Animation = model_animation_player.get_animation(moving_animation_name)
		if moving_animation != null:
			moving_animation.loop_mode = Animation.LOOP_LINEAR
			model_animation_player.play(moving_animation_name)
			model_animation_player.speed_scale = 0.0
			_moving_animation_ready = true
		else:
			push_warning("AutonomousRobotSweeper: animation not found: %s" % String(moving_animation_name))
	else:
		push_warning("AutonomousRobotSweeper: model_animation_player is not assigned and AnimationPlayer was not found under Model.")

	if not _has_navigation_map():
		return

	_navigation_ready = true
	_pick_next_target()

func _process(delta: float) -> void:
	_update_brush_spin(delta)

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
		_update_visual_motion(delta)
		if _idle_timer <= 0.0:
			_pick_next_target()
		return

	if navigation_agent.is_navigation_finished():
		_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)
		velocity = Vector3.ZERO
		_update_visual_motion(delta)
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var to_next: Vector3 = next_position - global_position
	to_next.y = 0.0

	if to_next.length() <= 0.01:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		_lock_ground_height()
		_update_visual_motion(delta)
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
	_update_visual_motion(delta)

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

func _update_back_wheel_spin(delta: float) -> void:
	if back_wheel_node == null and front_wheel_node == null:
		return

	var axis: Vector3 = wheel_spin_axis_local
	if axis.length_squared() <= 0.0001:
		return
	axis = axis.normalized()
	var axis_world: Vector3 = global_transform.basis * axis
	if axis_world.length_squared() <= 0.0001:
		return
	axis_world = axis_world.normalized()

	var planar_velocity: Vector3 = velocity
	planar_velocity.y = 0.0
	var speed: float = planar_velocity.length()
	if speed < 0.01:
		return

	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return
	forward = forward.normalized()

	var velocity_dir: Vector3 = planar_velocity.normalized()
	var dir_sign: float = signf(forward.dot(velocity_dir))
	if dir_sign == 0.0:
		dir_sign = 1.0

	var safe_radius: float = maxf(wheel_radius, 0.001)
	var angular_speed: float = (speed / safe_radius) * dir_sign * wheel_spin_multiplier
	var spin_angle: float = angular_speed * delta
	_spin_wheel_around_pivot(back_wheel_visual_node, back_wheel_node, axis_world, spin_angle)
	_spin_wheel_around_pivot(front_wheel_visual_node, front_wheel_node, axis_world, spin_angle)

func _update_moving_animation() -> void:
	if not _moving_animation_ready or model_animation_player == null:
		return

	if model_animation_player.current_animation != moving_animation_name or not model_animation_player.is_playing():
		model_animation_player.play(moving_animation_name)

	var planar_velocity: Vector3 = velocity
	planar_velocity.y = 0.0
	var speed: float = planar_velocity.length()
	if speed < moving_animation_min_speed:
		model_animation_player.speed_scale = 0.0
		return

	var base_speed: float = maxf(move_speed, 0.01)
	model_animation_player.speed_scale = (speed / base_speed) * moving_animation_speed_scale

func _update_visual_motion(delta: float) -> void:
	_update_back_wheel_spin(delta)
	_update_moving_animation()

func _update_brush_spin(delta: float) -> void:
	if brush_left_node == null and brush_right_node == null:
		return

	var axis: Vector3 = brush_spin_axis_local
	if axis.length_squared() <= 0.0001:
		return
	axis = axis.normalized()
	var axis_world: Vector3 = global_transform.basis * axis
	if axis_world.length_squared() <= 0.0001:
		return
	axis_world = axis_world.normalized()

	var planar_velocity: Vector3 = velocity
	planar_velocity.y = 0.0
	var speed: float = planar_velocity.length()
	if speed < brush_spin_min_move_speed:
		return

	var angle: float = brush_spin_speed * delta
	if brush_left_node != null:
		brush_left_node.global_rotate(axis_world, angle * brush_left_spin_multiplier)
	if brush_right_node != null:
		brush_right_node.global_rotate(axis_world, angle * brush_right_spin_multiplier)

func _spin_wheel_around_pivot(wheel_node: Node3D, pivot_node: Node3D, axis_world: Vector3, spin_angle: float) -> void:
	if wheel_node == null or pivot_node == null:
		return

	var pivot_origin: Vector3 = pivot_node.global_position
	var current_transform: Transform3D = wheel_node.global_transform
	var offset: Vector3 = current_transform.origin - pivot_origin
	var rotation_basis: Basis = Basis(axis_world, spin_angle)

	offset = offset.rotated(axis_world, spin_angle)
	current_transform.origin = pivot_origin + offset
	current_transform.basis = rotation_basis * current_transform.basis
	wheel_node.global_transform = current_transform

func _find_descendant_by_name(root: Node, target_name: StringName) -> Node:
	if root == null:
		return null
	if root.name == target_name:
		return root

	for child in root.get_children():
		var found: Node = _find_descendant_by_name(child, target_name)
		if found != null:
			return found

	return null
