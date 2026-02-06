extends Node3D

@export var pillar_scene: PackedScene
@export var pillar_count: int = 8
@export var radius: float = 3.0
@export var y_offset: float = 0.0
@export var spawn_if_missing: bool = true
@export var uniform_base_height: float = 3.0
@export var uniform_color_enabled: bool = false
@export var uniform_color: Color = Color.CYAN

var _generated_colors: Array[Color] = []

func _ready() -> void:
	if spawn_if_missing:
		_ensure_pillar_count()

	_layout_children()
	_apply_visual_settings()

func _ensure_pillar_count() -> void:
	if not pillar_scene:
		push_error("LightPillarsLayout: pillar_scene is null.")
		return

	var current: Array[Node3D] = _get_pillar_children()
	var missing: int = max(pillar_count - current.size(), 0)

	for i in range(missing):
		var pillar := pillar_scene.instantiate() as Node3D
		if not pillar:
			push_error("LightPillarsLayout: pillar_scene is not Node3D.")
			return
		pillar.name = "LightPillar%d" % (current.size() + i + 1)
		add_child(pillar)

func _layout_children() -> void:
	var pillars: Array[Node3D] = _get_pillar_children()
	if pillars.is_empty():
		return

	var count: int = min(pillar_count, pillars.size())
	var step_deg: float = 360.0 / float(count)

	for i in range(count):
		var angle: float = deg_to_rad(step_deg * i)
		var x: float = sin(angle) * radius
		var z: float = cos(angle) * radius

		pillars[i].position = Vector3(x, y_offset, z)
		pillars[i].rotation = Vector3.ZERO
		pillars[i].scale = Vector3.ONE

func _get_pillar_children() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in get_children():
		if child is Node3D:
			result.append(child as Node3D)
	return result

func _apply_visual_settings() -> void:
	var pillars: Array[Node3D] = _get_pillar_children()
	if pillars.is_empty():
		return

	_generate_random_colors(pillars.size())

	for i in range(pillars.size()):
		var pillar: Node3D = pillars[i]

		if _has_property(pillar, &"base_height"):
			pillar.set("base_height", uniform_base_height)

		if _has_property(pillar, &"base_color"):
			var target_color: Color = uniform_color if uniform_color_enabled else _generated_colors[i]
			if pillar.has_method("set_base_color"):
				pillar.call("set_base_color", target_color)
			else:
				pillar.set("base_color", target_color)

		if pillar.has_method("update_from_audio"):
			pillar.call("update_from_audio", 0.0)

func _has_property(target: Object, property_name: StringName) -> bool:
	for property_info in target.get_property_list():
		if property_info.name == property_name:
			return true
	return false

func _generate_random_colors(count: int) -> void:
	_generated_colors.clear()
	if count <= 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var hue_offset: float = rng.randf()

	for i in range(count):
		var hue: float = fposmod(hue_offset + float(i) / float(count), 1.0)
		var saturation: float = rng.randf_range(0.8, 1.0)
		var value: float = rng.randf_range(0.65, 0.85)
		_generated_colors.append(Color.from_hsv(hue, saturation, value, 1.0))
