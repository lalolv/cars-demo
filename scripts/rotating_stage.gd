extends Node3D

@export var rotation_speed: float = 5.0
@export var auto_rotate: bool = true
@export var target_car_size: float = 3.8

var current_car: Node = null
@onready var car_mount: Node3D = $CarMount

func _ready() -> void:
	if car_mount and car_mount.get_child_count() > 0:
		current_car = car_mount.get_child(0)

func _process(delta: float) -> void:
	if auto_rotate:
		rotate_y(deg_to_rad(rotation_speed * delta))

func set_car(car_scene: PackedScene) -> void:
	if not car_mount:
		push_error("RotatingStage: CarMount node is missing.")
		return
	if not car_scene:
		push_error("RotatingStage: car_scene is null.")
		return

	var new_car: Node = car_scene.instantiate()
	if not new_car:
		push_error("RotatingStage: failed to instantiate selected car scene.")
		return

	if current_car and is_instance_valid(current_car):
		current_car.queue_free()
		current_car = null

	car_mount.add_child(new_car)
	_fit_car_to_stage(new_car)
	current_car = new_car

func _fit_car_to_stage(car_root: Node) -> void:
	var car_node: Node3D = car_root as Node3D
	if not car_node:
		return

	var mesh_nodes: Array[MeshInstance3D] = []
	_collect_mesh_nodes(car_root, mesh_nodes)
	if mesh_nodes.is_empty():
		return

	var inv_root: Transform3D = car_node.global_transform.affine_inverse()
	var has_aabb: bool = false
	var combined_aabb: AABB

	for mesh_node in mesh_nodes:
		if not mesh_node.mesh:
			continue
		var local_aabb: AABB = mesh_node.get_aabb()
		var to_root: Transform3D = inv_root * mesh_node.global_transform
		var mesh_aabb_in_root: AABB = to_root * local_aabb
		if has_aabb:
			combined_aabb = combined_aabb.merge(mesh_aabb_in_root)
		else:
			combined_aabb = mesh_aabb_in_root
			has_aabb = true

	if not has_aabb:
		return

	var max_extent: float = maxf(combined_aabb.size.x, maxf(combined_aabb.size.y, combined_aabb.size.z))
	if max_extent <= 0.0001:
		return

	var scale_factor: float = target_car_size / max_extent
	var center: Vector3 = combined_aabb.position + combined_aabb.size * 0.5
	var target_position: Vector3 = Vector3(-center.x, -combined_aabb.position.y, -center.z) * scale_factor

	if car_node is RigidBody3D:
		var model_node: Node3D = _find_model_root(car_node)
		if model_node:
			model_node.scale = Vector3.ONE * scale_factor
			model_node.position = target_position
		_ensure_collision_shape(car_node, combined_aabb, scale_factor, target_position)
		car_node.position = Vector3.ZERO
		car_node.scale = Vector3.ONE
	else:
		car_node.scale = Vector3.ONE * scale_factor
		car_node.position = target_position

func _collect_mesh_nodes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_mesh_nodes(child, result)

func _ensure_collision_shape(car_node: Node3D, aabb: AABB, scale_factor: float, offset: Vector3) -> void:
	if not (car_node is RigidBody3D):
		return
	if _has_collision_shape(car_node):
		return

	var shape_size: Vector3 = aabb.size * scale_factor
	var shape_center: Vector3 = (aabb.position + aabb.size * 0.5) * scale_factor + offset

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.name = "AutoCollisionShape3D"
	collision_shape.position = shape_center

	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = shape_size
	collision_shape.shape = box_shape

	car_node.add_child(collision_shape)

func _find_model_root(car_node: Node3D) -> Node3D:
	for child in car_node.get_children():
		if child is Node3D and not (child is CollisionShape3D):
			return child as Node3D
	return null

func _has_collision_shape(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape3D:
			return true
		if _has_collision_shape(child):
			return true
	return false
