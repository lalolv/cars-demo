extends Node

@export var screen_mesh_path: NodePath
@export var slides: Array[Texture2D] = []
@export_dir var slide_directory: String = "res://assets/slides"
@export var auto_scan_on_ready: bool = true
@export var seconds_per_slide: float = 6.0
@export var fade_in_duration: float = 0.6
@export var emission_energy: float = 1.6
@export var random_start: bool = true
@export var autoplay: bool = true
@export var screen_enabled: bool = true

var _screen_mesh: MeshInstance3D
var _material: StandardMaterial3D
var _current_slide_index: int = -1
var _slide_timer: float = 0.0
var _fade_timer: float = 0.0

func _ready() -> void:
	_screen_mesh = get_node_or_null(screen_mesh_path) as MeshInstance3D
	if not _screen_mesh:
		_screen_mesh = get_parent().get_node_or_null("BrandWall/MainScreen") as MeshInstance3D
	if not _screen_mesh:
		_screen_mesh = get_parent().get_node_or_null("MainScreen") as MeshInstance3D
	if not _screen_mesh:
		push_error("ScreenSlideshow: screen mesh is missing.")
		set_process(false)
		return

	_screen_mesh.visible = screen_enabled

	_material = _screen_mesh.get_surface_override_material(0) as StandardMaterial3D
	if not _material:
		_material = _screen_mesh.get_active_material(0) as StandardMaterial3D
	if not _material:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.emission_enabled = true
		_screen_mesh.set_surface_override_material(0, _material)

	if not _material:
		push_error("ScreenSlideshow: failed to initialize screen material.")
		set_process(false)
		return

	if auto_scan_on_ready:
		slides = _load_slides_from_directory(slide_directory)

	if slides.is_empty():
		push_warning("ScreenSlideshow: no slides found in %s." % slide_directory)
		set_process(false)
		return

	if random_start and slides.size() > 1:
		_current_slide_index = randi() % slides.size()
	else:
		_current_slide_index = 0

	_apply_slide(_current_slide_index)
	_material.emission_energy_multiplier = emission_energy
	set_process(screen_enabled)

func _process(delta: float) -> void:
	if not screen_enabled:
		return
	if not _material:
		return

	if slides.size() < 2:
		return

	if _fade_timer > 0.0:
		_fade_timer = maxf(0.0, _fade_timer - delta)
		var t: float = 1.0 - (_fade_timer / maxf(0.001, fade_in_duration))
		_material.emission_energy_multiplier = lerpf(0.0, emission_energy, clampf(t, 0.0, 1.0))

	if not autoplay:
		return

	_slide_timer += delta
	if _slide_timer >= maxf(0.1, seconds_per_slide):
		next_slide()

func next_slide() -> void:
	if slides.is_empty():
		return

	_slide_timer = 0.0
	_current_slide_index = (_current_slide_index + 1) % slides.size()
	_apply_slide(_current_slide_index)

	if fade_in_duration > 0.0:
		_fade_timer = fade_in_duration
		_material.emission_energy_multiplier = 0.0
	else:
		_material.emission_energy_multiplier = emission_energy

func set_slide(index: int) -> void:
	if slides.is_empty():
		return

	if index < 0 or index >= slides.size():
		return

	_current_slide_index = index
	_slide_timer = 0.0
	_apply_slide(index)
	_material.emission_energy_multiplier = emission_energy

func _apply_slide(index: int) -> void:
	if not _material:
		return

	var texture: Texture2D = slides[index]
	if not texture:
		return

	_material.albedo_texture = texture
	_material.emission_texture = texture

func _load_slides_from_directory(dir_path: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if dir_path.is_empty():
		return result

	var dir: DirAccess = DirAccess.open(dir_path)
	if not dir:
		push_error("ScreenSlideshow: directory not found: %s" % dir_path)
		return result

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir():
			var ext: String = file_name.get_extension().to_lower()
			if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp":
				files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	files.sort()
	for slide_file_name in files:
		var texture_path: String = "%s/%s" % [dir_path, slide_file_name]
		var texture: Texture2D = load(texture_path) as Texture2D
		if texture:
			result.append(texture)

	return result

func set_screen_enabled(enabled: bool) -> void:
	screen_enabled = enabled
	if _screen_mesh:
		_screen_mesh.visible = enabled
	set_process(enabled)

func set_interval_seconds(value: float) -> void:
	seconds_per_slide = maxf(0.5, value)
	_slide_timer = 0.0
