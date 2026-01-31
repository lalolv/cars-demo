extends Node3D

@export var rotation_speed: float = 5.0
@export var auto_rotate: bool = true

var current_car: Node3D = null
@onready var car_mount: Node3D = $CarMount

func _process(delta: float) -> void:
	if auto_rotate:
		rotate_y(deg_to_rad(rotation_speed * delta))

func set_car(car_scene: PackedScene) -> void:
	if current_car:
		current_car.queue_free()

	current_car = car_scene.instantiate()
	car_mount.add_child(current_car)
