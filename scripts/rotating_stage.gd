extends Node3D

@export var rotation_speed: float = 5.0
@export var auto_rotate: bool = true

var current_car: Node = null
@onready var car_mount: Node3D = $CarMount

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

	if current_car and is_instance_valid(current_car):
		current_car.queue_free()
		current_car = null

	var new_car: Node = car_scene.instantiate()
	car_mount.add_child(new_car)
	current_car = new_car
