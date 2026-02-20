extends Node3D

var car_manager: Node
var music_player: Node
var world_environment: WorldEnvironment
var directional_light: DirectionalLight3D
var lighting_rig: Node3D
var ambient_lights_root: Node3D
var play_pause_button: Button
var music_selector: OptionButton
var car_selector: OptionButton
var screen_toggle_button: Button
var slide_interval_slider: HSlider
var wall_promo_toggle_button: Button
var base_lights_toggle: CheckButton
var car_lights_toggle: CheckButton
var ambient_lights_toggle: CheckButton
var lighting_mode_selector: OptionButton
var env_intensity_slider: HSlider
var back_screen_root: Node3D
var spec_poster_panel: MeshInstance3D
var left_wing_poster_panel: MeshInstance3D
var right_wing_poster_panel: MeshInstance3D
var screen_slideshow: Node

@export var spec_poster_texture: Texture2D = preload("res://assets/slides/slide_02.png")
@export var left_wing_poster_texture: Texture2D = preload("res://assets/slides/slide_03.png")
@export var right_wing_poster_texture: Texture2D = preload("res://assets/slides/slide_01.png")

const LIGHT_TWEEN_DURATION: float = 0.3
const LIGHTING_MODE_PRESENTATION: int = 0
const LIGHTING_MODE_SHOWROOM_BRIGHT: int = 1
const LIGHTING_MODE_ATMOSPHERE: int = 2

var _light_groups: Dictionary = {}
var _default_light_energy: Dictionary = {}
var _group_scales: Dictionary = {
	"base": 1.0,
	"car": 1.0,
	"ambient": 1.0,
}
var _base_environment_energy: float = 1.0
var _base_background_energy: float = 1.0
var _promo_panels: Array[MeshInstance3D] = []

func _ready() -> void:
	_cache_nodes()
	_setup_selectors()
	_connect_ui_signals()
	_connect_manager_signals()
	_sync_selector_state()
	_setup_promo_materials()
	_setup_showroom_controls()
	_setup_lighting_controls()
	_refresh_play_pause_text()

func _cache_nodes() -> void:
	car_manager = get_node_or_null("CarManager")
	music_player = get_node_or_null("MusicPlayer")
	world_environment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	directional_light = get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	lighting_rig = get_node_or_null("LightingRig") as Node3D
	ambient_lights_root = get_node_or_null("AmbientLights") as Node3D
	play_pause_button = get_node_or_null("CanvasLayer/MainUI/TopBar/PlayPauseButton") as Button
	music_selector = get_node_or_null("CanvasLayer/MainUI/TopBar/MusicSelector") as OptionButton
	car_selector = get_node_or_null("CanvasLayer/MainUI/TopBar/CarSelector") as OptionButton
	screen_toggle_button = get_node_or_null("CanvasLayer/MainUI/TopBar/ScreenToggleButton") as Button
	slide_interval_slider = get_node_or_null("CanvasLayer/MainUI/TopBar/SlideIntervalSlider") as HSlider
	wall_promo_toggle_button = get_node_or_null("CanvasLayer/MainUI/TopBar/WallPromoToggleButton") as Button
	base_lights_toggle = get_node_or_null("CanvasLayer/MainUI/LightingPanel/LightingVBox/BaseLightsToggle") as CheckButton
	car_lights_toggle = get_node_or_null("CanvasLayer/MainUI/LightingPanel/LightingVBox/CarLightsToggle") as CheckButton
	ambient_lights_toggle = get_node_or_null("CanvasLayer/MainUI/LightingPanel/LightingVBox/AmbientLightsToggle") as CheckButton
	lighting_mode_selector = get_node_or_null("CanvasLayer/MainUI/LightingPanel/LightingVBox/LightingModeSelector") as OptionButton
	env_intensity_slider = get_node_or_null("CanvasLayer/MainUI/LightingPanel/LightingVBox/EnvIntensitySlider") as HSlider
	back_screen_root = get_node_or_null("BackScreenRoot") as Node3D
	spec_poster_panel = get_node_or_null("BackScreenRoot/SpecWall/SpecPosterPanel") as MeshInstance3D
	left_wing_poster_panel = get_node_or_null("BackScreenRoot/LeftWingWall/LeftWingPoster") as MeshInstance3D
	right_wing_poster_panel = get_node_or_null("BackScreenRoot/RightWingWall/RightWingPoster") as MeshInstance3D
	screen_slideshow = get_node_or_null("BackScreenRoot/ScreenSlideshow")

func _setup_selectors() -> void:
	car_selector.clear()
	var cars: Array = []
	if car_manager.has_method("get_car_list"):
		cars = car_manager.call("get_car_list") as Array
	for car_name in cars:
		car_selector.add_item(str(car_name))

	music_selector.clear()
	var tracks: Array = []
	if music_player.has_method("get_music_list"):
		tracks = music_player.call("get_music_list") as Array
	for track_name in tracks:
		music_selector.add_item(str(track_name))

func _connect_ui_signals() -> void:
	if not play_pause_button.pressed.is_connected(_on_play_pause_pressed):
		play_pause_button.pressed.connect(_on_play_pause_pressed)

	if not car_selector.item_selected.is_connected(_on_car_selected):
		car_selector.item_selected.connect(_on_car_selected)

	if not music_selector.item_selected.is_connected(_on_music_selected):
		music_selector.item_selected.connect(_on_music_selected)

	if screen_toggle_button and not screen_toggle_button.pressed.is_connected(_on_screen_toggle_pressed):
		screen_toggle_button.pressed.connect(_on_screen_toggle_pressed)

	if slide_interval_slider and not slide_interval_slider.value_changed.is_connected(_on_slide_interval_changed):
		slide_interval_slider.value_changed.connect(_on_slide_interval_changed)

	if wall_promo_toggle_button and not wall_promo_toggle_button.pressed.is_connected(_on_wall_promo_toggle_pressed):
		wall_promo_toggle_button.pressed.connect(_on_wall_promo_toggle_pressed)

func _connect_manager_signals() -> void:
	if car_manager.has_signal("car_changed") and not car_manager.is_connected("car_changed", _on_car_changed):
		car_manager.connect("car_changed", _on_car_changed)

	if music_player.has_signal("music_changed") and not music_player.is_connected("music_changed", _on_music_changed):
		music_player.connect("music_changed", _on_music_changed)

func _sync_selector_state() -> void:
	if car_selector.item_count > 0 and car_manager.has_method("get_current_index"):
		var car_index: int = car_manager.call("get_current_index") as int
		car_selector.select(clamp(car_index, 0, car_selector.item_count - 1))

	if music_selector.item_count > 0 and music_player.has_method("get_current_index"):
		var music_index: int = music_player.call("get_current_index") as int
		music_selector.select(clamp(music_index, 0, music_selector.item_count - 1))

func _on_car_selected(index: int) -> void:
	if car_manager.has_method("switch_to_car"):
		car_manager.call("switch_to_car", index)

func _on_music_selected(index: int) -> void:
	if music_player.has_method("play_music"):
		music_player.call("play_music", index)

func _on_play_pause_pressed() -> void:
	if music_player.has_method("toggle_play"):
		music_player.call("toggle_play")
	_refresh_play_pause_text()

func _on_car_changed(car_name: String) -> void:
	var index: int = _find_item_by_text(car_selector, car_name)
	if index >= 0:
		car_selector.select(index)

func _on_music_changed(music_name: String) -> void:
	var index: int = _find_item_by_text(music_selector, music_name)
	if index >= 0:
		music_selector.select(index)
	_refresh_play_pause_text()

func _refresh_play_pause_text() -> void:
	var button_text: String = "Play"
	var audio_player: AudioStreamPlayer = music_player.get("audio_player") as AudioStreamPlayer
	if audio_player and audio_player.playing and not audio_player.stream_paused:
		button_text = "Pause"
	play_pause_button.text = button_text

func _setup_showroom_controls() -> void:
	if not screen_slideshow:
		return

	var interval_value: float = screen_slideshow.get("seconds_per_slide") as float
	if slide_interval_slider:
		slide_interval_slider.value = maxf(slide_interval_slider.min_value, interval_value)

	var is_enabled: bool = screen_slideshow.get("screen_enabled") as bool
	if back_screen_root:
		back_screen_root.visible = is_enabled
	_refresh_screen_toggle_text(is_enabled)

	var promo_visible: bool = _are_promos_visible()
	_refresh_wall_promo_toggle_text(promo_visible)

func _on_screen_toggle_pressed() -> void:
	if not screen_slideshow:
		return

	var is_enabled: bool = screen_slideshow.get("screen_enabled") as bool
	var next_enabled: bool = not is_enabled
	if screen_slideshow.has_method("set_screen_enabled"):
		screen_slideshow.call("set_screen_enabled", next_enabled)

	if back_screen_root:
		back_screen_root.visible = next_enabled
	_refresh_screen_toggle_text(next_enabled)

func _on_wall_promo_toggle_pressed() -> void:
	var next_visible: bool = not _are_promos_visible()
	_set_promos_visible(next_visible)
	_refresh_wall_promo_toggle_text(next_visible)

func _on_slide_interval_changed(value: float) -> void:
	if not screen_slideshow:
		return

	if screen_slideshow.has_method("set_interval_seconds"):
		screen_slideshow.call("set_interval_seconds", value)

func _refresh_screen_toggle_text(is_enabled: bool) -> void:
	if not screen_toggle_button:
		return
	screen_toggle_button.text = "Screen On" if is_enabled else "Screen Off"

func _refresh_wall_promo_toggle_text(is_enabled: bool) -> void:
	if not wall_promo_toggle_button:
		return
	wall_promo_toggle_button.text = "Promo On" if is_enabled else "Promo Off"

func _setup_promo_materials() -> void:
	_apply_texture_to_panel(spec_poster_panel, spec_poster_texture)
	_apply_texture_to_panel(left_wing_poster_panel, left_wing_poster_texture)
	_apply_texture_to_panel(right_wing_poster_panel, right_wing_poster_texture)

	_promo_panels = [
		spec_poster_panel,
		left_wing_poster_panel,
		right_wing_poster_panel,
	]

func _apply_texture_to_panel(panel: MeshInstance3D, texture: Texture2D) -> void:
	if not panel or not texture:
		return

	var material: StandardMaterial3D = panel.material_override as StandardMaterial3D
	if not material:
		material = panel.get_active_material(0) as StandardMaterial3D
	if not material:
		material = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		panel.material_override = material

	material.albedo_texture = texture
	material.emission_texture = texture

func _set_promos_visible(show_promos: bool) -> void:
	for panel in _promo_panels:
		if panel:
			panel.visible = show_promos

func _are_promos_visible() -> bool:
	for panel in _promo_panels:
		if panel and panel.visible:
			return true
	return false

func _setup_lighting_controls() -> void:
	_collect_light_groups()
	_cache_environment_defaults()
	_connect_lighting_signals()
	_setup_lighting_modes()

	if base_lights_toggle:
		base_lights_toggle.button_pressed = true
	if car_lights_toggle:
		car_lights_toggle.button_pressed = true
	if ambient_lights_toggle:
		ambient_lights_toggle.button_pressed = true
	if env_intensity_slider:
		env_intensity_slider.value = _base_environment_energy

	_apply_lighting_mode(LIGHTING_MODE_SHOWROOM_BRIGHT)

func _collect_light_groups() -> void:
	_light_groups.clear()
	_default_light_energy.clear()

	var base_lights: Array[Light3D] = []
	if directional_light:
		base_lights.append(directional_light)
	_register_light_group("base", base_lights)

	_register_light_group("car", _collect_lights_from_node(lighting_rig))

	var ambient_lights: Array[Light3D] = _collect_lights_from_node(ambient_lights_root)
	_register_light_group("ambient", ambient_lights)

func _register_light_group(group_name: String, lights: Array[Light3D]) -> void:
	_light_groups[group_name] = lights
	for light in lights:
		if not light:
			continue
		_default_light_energy[light.get_instance_id()] = light.light_energy

func _collect_lights_from_node(root: Node) -> Array[Light3D]:
	var lights: Array[Light3D] = []
	if not root:
		return lights

	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Light3D:
			lights.append(current as Light3D)
		for child in current.get_children():
			stack.append(child)

	return lights

func _cache_environment_defaults() -> void:
	if not world_environment or not world_environment.environment:
		return

	var environment: Environment = world_environment.environment
	_base_environment_energy = maxf(environment.ambient_light_energy, 0.01)
	_base_background_energy = maxf(environment.background_energy_multiplier, 0.01)

func _connect_lighting_signals() -> void:
	if base_lights_toggle and not base_lights_toggle.toggled.is_connected(_on_base_lights_toggled):
		base_lights_toggle.toggled.connect(_on_base_lights_toggled)

	if car_lights_toggle and not car_lights_toggle.toggled.is_connected(_on_car_lights_toggled):
		car_lights_toggle.toggled.connect(_on_car_lights_toggled)

	if ambient_lights_toggle and not ambient_lights_toggle.toggled.is_connected(_on_ambient_lights_toggled):
		ambient_lights_toggle.toggled.connect(_on_ambient_lights_toggled)

	if env_intensity_slider and not env_intensity_slider.value_changed.is_connected(_on_env_intensity_changed):
		env_intensity_slider.value_changed.connect(_on_env_intensity_changed)

	if lighting_mode_selector and not lighting_mode_selector.item_selected.is_connected(_on_lighting_mode_selected):
		lighting_mode_selector.item_selected.connect(_on_lighting_mode_selected)

func _setup_lighting_modes() -> void:
	if not lighting_mode_selector:
		return

	lighting_mode_selector.clear()
	lighting_mode_selector.add_item("Presentation")
	lighting_mode_selector.add_item("Showroom Bright")
	lighting_mode_selector.add_item("Atmosphere")
	lighting_mode_selector.select(LIGHTING_MODE_SHOWROOM_BRIGHT)

func _on_lighting_mode_selected(index: int) -> void:
	_apply_lighting_mode(index)

func _apply_lighting_mode(mode_index: int) -> void:
	_set_all_light_toggles(true)

	match mode_index:
		LIGHTING_MODE_PRESENTATION:
			_set_group_energy_scale("base", 1.0)
			_set_group_energy_scale("car", 1.3)
			_set_group_energy_scale("ambient", 0.9)
			_set_environment_energy(2.0)
		LIGHTING_MODE_SHOWROOM_BRIGHT:
			_set_group_energy_scale("base", 1.0)
			_set_group_energy_scale("car", 0.82)
			_set_group_energy_scale("ambient", 1.05)
			_set_environment_energy(0.8)
		LIGHTING_MODE_ATMOSPHERE:
			_set_group_energy_scale("base", 0.7)
			_set_group_energy_scale("car", 1.0)
			_set_group_energy_scale("ambient", 0.7)
			_set_environment_energy(1.5)
		_:
			_set_group_energy_scale("base", 1.0)
			_set_group_energy_scale("car", 1.0)
			_set_group_energy_scale("ambient", 1.0)
			_set_environment_energy(_base_environment_energy)

func _set_all_light_toggles(enabled: bool) -> void:
	if base_lights_toggle:
		base_lights_toggle.set_pressed_no_signal(enabled)
	if car_lights_toggle:
		car_lights_toggle.set_pressed_no_signal(enabled)
	if ambient_lights_toggle:
		ambient_lights_toggle.set_pressed_no_signal(enabled)

	_set_group_enabled("base", enabled)
	_set_group_enabled("car", enabled)
	_set_group_enabled("ambient", enabled)
	_set_environment_enabled(enabled)

func _on_base_lights_toggled(enabled: bool) -> void:
	_set_group_enabled("base", enabled)
	_set_environment_enabled(enabled)

func _on_car_lights_toggled(enabled: bool) -> void:
	_set_group_enabled("car", enabled)

func _on_ambient_lights_toggled(enabled: bool) -> void:
	_set_group_enabled("ambient", enabled)

func _on_env_intensity_changed(value: float) -> void:
	if not world_environment or not world_environment.environment:
		return
	if base_lights_toggle and not base_lights_toggle.button_pressed:
		return

	_set_environment_energy(value)

func _set_group_enabled(group_name: String, enabled: bool) -> void:
	if not _light_groups.has(group_name):
		return

	var lights: Array[Light3D] = []
	for item in _light_groups[group_name]:
		if item is Light3D:
			lights.append(item as Light3D)

	for light in lights:
		if not light:
			continue
		var default_energy: float = _default_light_energy.get(light.get_instance_id(), 1.0) as float
		var group_scale: float = _group_scales.get(group_name, 1.0) as float
		var target_energy: float = (default_energy * group_scale) if enabled else 0.0
		var tween: Tween = create_tween()
		tween.tween_property(light, "light_energy", target_energy, LIGHT_TWEEN_DURATION)

func _set_group_energy_scale(group_name: String, energy_scale: float) -> void:
	_group_scales[group_name] = maxf(energy_scale, 0.0)
	if not _is_group_enabled(group_name):
		return
	_set_group_enabled(group_name, true)

func _is_group_enabled(group_name: String) -> bool:
	match group_name:
		"base":
			return base_lights_toggle and base_lights_toggle.button_pressed
		"car":
			return car_lights_toggle and car_lights_toggle.button_pressed
		"ambient":
			return ambient_lights_toggle and ambient_lights_toggle.button_pressed
		_:
			return true

func _set_environment_enabled(enabled: bool) -> void:
	if not world_environment or not world_environment.environment:
		return

	var target_energy: float = env_intensity_slider.value if enabled and env_intensity_slider else _base_environment_energy
	if not enabled:
		target_energy = 0.0
	_set_environment_energy(target_energy, enabled)

func _set_environment_energy(value: float, sync_slider: bool = true) -> void:
	if not world_environment or not world_environment.environment:
		return

	var clamped_value: float = maxf(value, 0.0)
	if sync_slider and env_intensity_slider and not is_equal_approx(env_intensity_slider.value, clamped_value):
		env_intensity_slider.set_value_no_signal(clamped_value)

	var environment: Environment = world_environment.environment
	environment.ambient_light_energy = clamped_value
	environment.background_energy_multiplier = clamped_value * (_base_background_energy / _base_environment_energy)

func _find_item_by_text(selector: OptionButton, value: String) -> int:
	for i in range(selector.item_count):
		if selector.get_item_text(i) == value:
			return i
	return -1
