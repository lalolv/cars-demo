extends Node

signal car_changed(car_name: String)

const DEFAULT_CAR_SCENE: PackedScene = preload("res://scenes/cars/pony_cartoon.tscn")

@export var stage: Node3D
@export var car_scenes: Array[PackedScene] = []
@export var car_names: Array[String] = []
@export var load_first_on_ready: bool = true

var current_index: int = -1

func _ready() -> void:
	if not stage:
		stage = get_node_or_null("../Stage") as Node3D

	if car_scenes.is_empty():
		car_scenes.append(DEFAULT_CAR_SCENE)

	if car_names.size() < car_scenes.size():
		for i in range(car_names.size(), car_scenes.size()):
			car_names.append("Car %d" % (i + 1))

	if load_first_on_ready and not car_scenes.is_empty():
		switch_to_car(0)

func switch_to_car(index: int) -> void:
	if index < 0 or index >= car_scenes.size():
		return

	current_index = index
	_load_car(index)

func get_car_list() -> Array[String]:
	return car_names.duplicate()

func get_current_index() -> int:
	return current_index

func _load_car(index: int) -> void:
	if not stage:
		push_error("CarManager: stage is not assigned.")
		return

	if not stage.has_method("set_car"):
		push_error("CarManager: stage has no set_car(car_scene) method.")
		return

	var selected_scene: PackedScene = car_scenes[index]
	if not selected_scene:
		push_error("CarManager: selected car scene is null.")
		return

	stage.call("set_car", selected_scene)
	car_changed.emit(car_names[index])
