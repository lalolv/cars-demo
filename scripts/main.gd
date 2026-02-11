extends Node3D

@onready var car_manager: Node = $CarManager
@onready var music_player: Node = $MusicPlayer
@onready var play_pause_button: Button = $CanvasLayer/MainUI/TopBar/PlayPauseButton
@onready var music_selector: OptionButton = $CanvasLayer/MainUI/TopBar/MusicSelector
@onready var car_selector: OptionButton = $CanvasLayer/MainUI/TopBar/CarSelector
@onready var screen_toggle_button: Button = $CanvasLayer/MainUI/TopBar/ScreenToggleButton
@onready var slide_interval_slider: HSlider = $CanvasLayer/MainUI/TopBar/SlideIntervalSlider
@onready var back_screen_root: Node3D = $BackScreenRoot
@onready var screen_slideshow: Node = $BackScreenRoot/ScreenSlideshow

func _ready() -> void:
	_setup_selectors()
	_connect_ui_signals()
	_connect_manager_signals()
	_sync_selector_state()
	_setup_showroom_controls()
	_refresh_play_pause_text()

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

func _on_slide_interval_changed(value: float) -> void:
	if not screen_slideshow:
		return

	if screen_slideshow.has_method("set_interval_seconds"):
		screen_slideshow.call("set_interval_seconds", value)

func _refresh_screen_toggle_text(is_enabled: bool) -> void:
	if not screen_toggle_button:
		return
	screen_toggle_button.text = "Screen On" if is_enabled else "Screen Off"

func _find_item_by_text(selector: OptionButton, value: String) -> int:
	for i in range(selector.item_count):
		if selector.get_item_text(i) == value:
			return i
	return -1
