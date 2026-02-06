extends Node

@export var light_pillars: Array[Node3D] = []
@export var spectrum_analyzer_bus: StringName = &"Master"
@export var spectrum_effect_index: int = 0
@export var min_freq: float = 20.0
@export var max_freq: float = 4000.0
@export var smoothing: float = 0.2
@export var audio_player_path: NodePath = ^"../AudioStreamPlayer"
@export var reset_when_no_music: bool = true
@export var silence_smoothing: float = 0.25
@export var force_stream_loop: bool = true

var spectrum: AudioEffectSpectrumAnalyzerInstance
var _smoothed_values: Array[float] = []
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
	for i in range(_smoothed_values.size()):
		_smoothed_values[i] = 0.0

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
		for i in range(_smoothed_values.size()):
			if typeof(_smoothed_values[i]) != TYPE_FLOAT:
				_smoothed_values[i] = 0.0

	var freq_step: float = (max_freq - min_freq) / float(pillar_count)

	for i in range(pillar_count):
		var freq_low: float = min_freq + i * freq_step
		var freq_high: float = freq_low + freq_step

		var magnitude: float = spectrum.get_magnitude_for_frequency_range(freq_low, freq_high).length()
		var normalized: float = clamp((60.0 + linear_to_db(max(magnitude, 0.00001))) / 60.0, 0.0, 1.0)

		_smoothed_values[i] = lerp(_smoothed_values[i], normalized, smoothing)

		var pillar: Node3D = light_pillars[i]
		if pillar and pillar.has_method("update_from_audio"):
			pillar.call("update_from_audio", _smoothed_values[i])

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
