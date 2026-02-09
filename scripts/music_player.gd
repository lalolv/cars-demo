extends Node

signal music_changed(music_name: String)

const DEFAULT_MUSIC: AudioStream = preload("res://assets/music/sleep-talking.ogg")
const SILENT_DB: float = -40.0

@export var audio_player: AudioStreamPlayer
@export var music_list: Array[AudioStream] = []
@export var music_names: Array[String] = []
@export var crossfade_duration: float = 1.0
@export var play_first_on_ready: bool = true
@export var auto_discover_music: bool = true
@export var music_directory: String = "res://assets/music"

var current_index: int = -1
var _tween: Tween
var _request_serial: int = 0

func _ready() -> void:
	if not audio_player:
		audio_player = get_node_or_null("../AudioStreamPlayer") as AudioStreamPlayer

	if auto_discover_music:
		_append_discovered_music()

	if music_list.is_empty():
		music_list.append(DEFAULT_MUSIC)

	if music_names.size() < music_list.size():
		for i in range(music_names.size(), music_list.size()):
			music_names.append(_build_track_name(music_list[i], i))

	if play_first_on_ready and not music_list.is_empty():
		play_music(0)

func play_music(index: int) -> void:
	if index < 0 or index >= music_list.size():
		return

	if not audio_player:
		push_error("MusicPlayer: audio_player is not assigned.")
		return

	_request_serial += 1
	var current_request: int = _request_serial

	if is_instance_valid(_tween):
		_tween.kill()

	if audio_player.playing and crossfade_duration > 0.0:
		_tween = create_tween()
		_tween.tween_property(audio_player, "volume_db", SILENT_DB, crossfade_duration)
		await _tween.finished
		if current_request != _request_serial:
			return

	current_index = index
	audio_player.stream = music_list[index]
	audio_player.volume_db = SILENT_DB if crossfade_duration > 0.0 else 0.0
	audio_player.play()

	if crossfade_duration > 0.0:
		_tween = create_tween()
		_tween.tween_property(audio_player, "volume_db", 0.0, crossfade_duration)

	music_changed.emit(music_names[index])

func toggle_play() -> void:
	if not audio_player:
		push_error("MusicPlayer: audio_player is not assigned.")
		return

	if audio_player.playing:
		audio_player.stream_paused = not audio_player.stream_paused
		return

	if current_index < 0 and not music_list.is_empty():
		play_music(0)
		return

	audio_player.play()

func get_music_list() -> Array[String]:
	return music_names.duplicate()

func get_current_index() -> int:
	return current_index

func _append_discovered_music() -> void:
	var discovered_paths: Array[String] = _find_music_files(music_directory)
	discovered_paths.sort()

	for path in discovered_paths:
		if _contains_music_path(path):
			continue

		var stream: AudioStream = load(path) as AudioStream
		if not stream:
			push_warning("MusicPlayer: failed to load audio stream: %s" % [path])
			continue

		music_list.append(stream)

func _find_music_files(directory: String) -> Array[String]:
	var result: Array[String] = []
	var dir: DirAccess = DirAccess.open(directory)
	if not dir:
		push_warning("MusicPlayer: directory not found: %s" % [directory])
		return result

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.to_lower().ends_with(".ogg"):
			result.append(_join_res_path(directory, file_name))
	dir.list_dir_end()

	return result

func _contains_music_path(path: String) -> bool:
	for stream in music_list:
		if stream and stream.resource_path == path:
			return true
	return false

func _build_track_name(stream: AudioStream, index: int) -> String:
	if stream and not stream.resource_path.is_empty():
		return stream.resource_path.get_file().get_basename()
	return "Track %d" % (index + 1)

func _join_res_path(base_path: String, file_name: String) -> String:
	if base_path.ends_with("/"):
		return "%s%s" % [base_path, file_name]
	return "%s/%s" % [base_path, file_name]
