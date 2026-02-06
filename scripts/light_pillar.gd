extends Node3D

@export var base_height: float = 3.0
@export var base_color: Color = Color.CYAN

@onready var mesh: MeshInstance3D = $MeshInstance3D
var material: StandardMaterial3D
var _base_mesh_height: float = 1.0

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
	material.emission_energy_multiplier = 0.7
	_apply_base_color()

	update_from_audio(0.0)

func set_base_color(color: Color) -> void:
	base_color = color
	_apply_base_color()

func update_from_audio(magnitude: float) -> void:
	var target_base_height: float = max(base_height, 0.01)
	var normalized: float = clamp(magnitude, 0.0, 1.0)
	var height: float = target_base_height * (0.5 + normalized * 0.5)

	mesh.scale.y = height / _base_mesh_height
	mesh.position.y = height * 0.5
	material.emission_energy_multiplier = 0.7 + normalized * 2.0

func _apply_base_color() -> void:
	if material:
		material.emission = base_color
