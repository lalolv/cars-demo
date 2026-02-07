extends Node3D

@export var base_height: float = 3.0
@export var base_color: Color = Color.CYAN
@export var silent_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var emission_energy: float = 1.35
@export var color_response_curve: float = 0.65
@export var albedo_tint_strength: float = 0.18

@onready var mesh: MeshInstance3D = $MeshInstance3D
var material: StandardMaterial3D
var _base_mesh_height: float = 1.0
var _last_audio_level: float = 0.0

func _ready() -> void:
	if mesh.mesh is CylinderMesh:
		var cylinder := mesh.mesh as CylinderMesh
		if cylinder.height > 0.0:
			_base_mesh_height = cylinder.height

	material = mesh.get_active_material(0) as StandardMaterial3D
	if not material:
		material = StandardMaterial3D.new()
	else:
		material = material.duplicate() as StandardMaterial3D

	mesh.set_surface_override_material(0, material)

	material.emission_enabled = true
	material.emission_energy_multiplier = emission_energy
	material.albedo_color = silent_color
	_apply_base_color()

	update_from_audio(0.0)

func set_base_color(color: Color) -> void:
	base_color = color
	_apply_base_color()

func update_from_audio(magnitude: float) -> void:
	var normalized: float = clamp(magnitude, 0.0, 1.0)
	_last_audio_level = normalized
	var target_base_height: float = max(base_height, 0.01)

	mesh.scale.y = target_base_height / _base_mesh_height
	mesh.position.y = target_base_height * 0.5
	_apply_audio_color(normalized)

func _apply_base_color() -> void:
	if material:
		material.emission_energy_multiplier = emission_energy
		_apply_audio_color(_last_audio_level)

func _apply_audio_color(level: float) -> void:
	if not material:
		return

	var curve: float = max(color_response_curve, 0.01)
	var drive: float = pow(clamp(level, 0.0, 1.0), curve)
	var emissive: Color = silent_color.lerp(base_color, drive)
	material.emission = emissive

	var tint_strength: float = clamp(albedo_tint_strength, 0.0, 1.0)
	material.albedo_color = silent_color.lerp(base_color * tint_strength, drive)
