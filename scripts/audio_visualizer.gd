extends Node

@export var light_pillars: Array[Node3D] = []
@export var spectrum_analyzer_bus: StringName = &"Master"
@export var spectrum_effect_index: int = 0
@export var min_freq: float = 20.0
@export var max_freq: float = 4000.0
@export var smoothing: float = 0.2
@export var gain: float = 1.6
@export var response_curve: float = 0.8
@export var edge_weight: float = 0.45
@export var center_focus_curve: float = 1.25
@export var audio_player_path: NodePath = ^"../AudioStreamPlayer"
@export var reset_when_no_music: bool = true
@export var silence_smoothing: float = 0.25
@export var force_stream_loop: bool = true

const NOISE_FLOOR_DB: float = -72.0
const PEAK_DB: float = -28.0
const MIN_DYNAMIC_RANGE_DB: float = 12.0
const FLOOR_FALL_SPEED: float = 0.28
const FLOOR_RISE_SPEED: float = 0.02
const PEAK_RISE_SPEED: float = 0.35
const PEAK_FALL_SPEED: float = 0.03

var spectrum: AudioEffectSpectrumAnalyzerInstance
var _smoothed_values: Array[float] = []
var _band_floor_db: Array[float] = []
var _band_peak_db: Array[float] = []
var _audio_player: AudioStreamPlayer

func _ready() -> void:
	if not audio_player_path.is_empty():
		_audio_player = get_node_or_null(audio_player_path) as AudioStreamPlayer

	if force_stream_loop and _audio_player and _audio_player.stream:
		_set_stream_loop(_audio_player.stream, true)

	var bus_idx: int = AudioServer.get_bus_index(spectrum_analyzer_bus)
	if bus_idx < 0:
		push_error("AudioVisualizer: bus not found: %s" % [spectrum_analyzer_bus])
		return

	spectrum = AudioServer.get_bus_effect_instance(bus_idx, spectrum_effect_index) as AudioEffectSpectrumAnalyzerInstance
	if not spectrum:
		push_error("AudioVisualizer: SpectrumAnalyzer instance not found.")
		return

	_smoothed_values.resize(light_pillars.size())
	_band_floor_db.resize(light_pillars.size())
	_band_peak_db.resize(light_pillars.size())
	for i in range(_smoothed_values.size()):
		_smoothed_values[i] = 0.0
		_band_floor_db[i] = NOISE_FLOOR_DB
		_band_peak_db[i] = PEAK_DB

func _process(_delta: float) -> void:
	if not spectrum:
		return

	var pillar_count: int = light_pillars.size()
	if pillar_count == 0:
		return

	if reset_when_no_music and not _is_audio_active():
		_decay_to_silence(pillar_count)
		return

	if _smoothed_values.size() != pillar_count:
		_smoothed_values.resize(pillar_count)
		_band_floor_db.resize(pillar_count)
		_band_peak_db.resize(pillar_count)
		for i in range(_smoothed_values.size()):
			if typeof(_smoothed_values[i]) != TYPE_FLOAT:
				_smoothed_values[i] = 0.0
			if typeof(_band_floor_db[i]) != TYPE_FLOAT:
				_band_floor_db[i] = NOISE_FLOOR_DB
			if typeof(_band_peak_db[i]) != TYPE_FLOAT:
				_band_peak_db[i] = PEAK_DB

	var source_band_count: int = int(ceil(float(pillar_count) * 0.5))

	for i in range(pillar_count):
		var band_index: int = _get_band_index_for_pillar(i, pillar_count, source_band_count)
		var band: Vector2 = _get_frequency_band(band_index, source_band_count)
		var freq_low: float = band.x
		var freq_high: float = band.y

		var magnitude: float = spectrum.get_magnitude_for_frequency_range(freq_low, freq_high).length()
		var magnitude_db: float = linear_to_db(max(magnitude, 0.0000001))

		var floor_db: float = min(NOISE_FLOOR_DB, PEAK_DB - 6.0)
		var ceiling_db: float = max(PEAK_DB, floor_db + 6.0)
		var tracked_floor: float = _band_floor_db[i]
		var tracked_peak: float = _band_peak_db[i]

		tracked_floor = lerp(tracked_floor, magnitude_db, FLOOR_FALL_SPEED if magnitude_db < tracked_floor else FLOOR_RISE_SPEED)
		tracked_peak = lerp(tracked_peak, magnitude_db, PEAK_RISE_SPEED if magnitude_db > tracked_peak else PEAK_FALL_SPEED)

		if tracked_peak < tracked_floor + MIN_DYNAMIC_RANGE_DB:
			tracked_peak = tracked_floor + MIN_DYNAMIC_RANGE_DB

		_band_floor_db[i] = tracked_floor
		_band_peak_db[i] = tracked_peak
		floor_db = tracked_floor
		ceiling_db = tracked_peak

		var normalized: float = inverse_lerp(floor_db, ceiling_db, magnitude_db)
		normalized = clamp(normalized * gain, 0.0, 1.0)
		normalized = pow(normalized, response_curve)
		normalized *= _get_center_weight(i, pillar_count)

		_smoothed_values[i] = lerp(_smoothed_values[i], normalized, smoothing)

		var pillar: Node3D = light_pillars[i]
		if pillar and pillar.has_method("update_from_audio"):
			pillar.call("update_from_audio", _smoothed_values[i])

func _get_band_index_for_pillar(index: int, pillar_count: int, source_band_count: int) -> int:
	var mirrored: int = min(index, pillar_count - 1 - index)
	return clamp(mirrored, 0, source_band_count - 1)

func _get_frequency_band(index: int, total_bands: int) -> Vector2:
	var low_limit: float = max(min_freq, 1.0)
	var high_limit: float = max(max_freq, low_limit + 1.0)

	if total_bands <= 1:
		return Vector2(low_limit, high_limit)

	var ratio: float = high_limit / low_limit
	var t0: float = float(index) / float(total_bands)
	var t1: float = float(index + 1) / float(total_bands)
	var log_low: float = low_limit * pow(ratio, t0)
	var log_high: float = low_limit * pow(ratio, t1)
	return Vector2(log_low, log_high)

func _get_center_weight(index: int, total: int) -> float:
	if total <= 1:
		return 1.0

	var center: float = (float(total) - 1.0) * 0.5
	var max_distance: float = max(center, 1.0)
	var distance_t: float = abs(float(index) - center) / max_distance
	var center_t: float = pow(1.0 - clamp(distance_t, 0.0, 1.0), max(center_focus_curve, 0.01))
	return lerp(clamp(edge_weight, 0.0, 1.0), 1.0, center_t)

func _decay_to_silence(pillar_count: int) -> void:
	if _smoothed_values.size() != pillar_count:
		_smoothed_values.resize(pillar_count)

	for i in range(pillar_count):
		_smoothed_values[i] = lerp(_smoothed_values[i], 0.0, clamp(silence_smoothing, 0.0, 1.0))
		var pillar: Node3D = light_pillars[i]
		if pillar and pillar.has_method("update_from_audio"):
			pillar.call("update_from_audio", _smoothed_values[i])

func _is_audio_active() -> bool:
	if not _audio_player:
		return true
	return _audio_player.playing and not _audio_player.stream_paused

func _set_stream_loop(stream: AudioStream, enabled: bool) -> void:
	for property_info in stream.get_property_list():
		if property_info.name == &"loop":
			stream.set("loop", enabled)
			return
