class_name MusicManager
extends AudioStreamPlayer

const MENU_MUSIC_PATH := "res://resources/audio/musics/menu.wav"
const GAME_SECTION_PATH := "res://resources/audio/musics/section-%d.wav"
const Settings := preload("res://resources/scripts/settings/settings.gd")
const MUSIC_BUS_NAME := &"Music"

var game_music_requested := false
var menu_music: AudioStreamWAV
var game_music: AudioStreamWAV
var current_section := 1
var section_change_requested := false
var low_pass_enabled := false
var _low_pass: AudioEffectLowPassFilter
var _low_pass_effect_index := -1
var _filter_tween: Tween
var _headless_audio := false


func _ready() -> void:
	_headless_audio = DisplayServer.get_name() == "headless"
	_ensure_music_bus()
	bus = MUSIC_BUS_NAME
	volume_db = Settings.MUSIC_VOLUME_DB
	menu_music = load(MENU_MUSIC_PATH) as AudioStreamWAV
	game_music = load(GAME_SECTION_PATH % current_section) as AudioStreamWAV
	stream = menu_music
	set_low_pass_enabled(true)
	_play_if_audible()


func _exit_tree() -> void:
	stop()
	stream = null
	menu_music = null
	game_music = null


func reset_game_sections(section_number := 1) -> void:
	current_section = maxi(section_number, 1)
	var section_path := GAME_SECTION_PATH % current_section
	while current_section > 1 and not ResourceLoader.exists(section_path):
		current_section -= 1
		section_path = GAME_SECTION_PATH % current_section
	game_music = load(section_path) as AudioStreamWAV
	section_change_requested = false
	if stream != menu_music:
		stream = game_music
		_play_if_audible()


func transition_to_game_music() -> void:
	if stream == game_music:
		return
	if game_music_requested:
		return
	game_music_requested = true
	if not playing:
		_play_game_music()
		return
	var loop_position := fmod(
		get_playback_position(),
		Settings.MUSIC_SEGMENT_SECONDS
	)
	var remaining_time := Settings.MUSIC_SEGMENT_SECONDS - loop_position
	get_tree().create_timer(remaining_time).timeout.connect(_play_game_music)


func transition_to_menu_music() -> void:
	game_music_requested = false
	section_change_requested = false
	set_low_pass_enabled(true)
	if stream == menu_music:
		return
	stream = menu_music
	_play_if_audible()


func _play_game_music() -> void:
	# A pending beat-aligned transition may outlive a return to the main menu.
	if not game_music_requested:
		return
	game_music_requested = false
	stream = game_music
	_play_if_audible()


func is_playing_menu_music() -> bool:
	return stream == menu_music


func is_playing_game_music() -> bool:
	return stream == game_music


func set_low_pass_enabled(enabled: bool, smooth_release := false) -> void:
	low_pass_enabled = enabled
	var bus_index := AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index < 0 or _low_pass_effect_index < 0 or _low_pass == null:
		return
	if _filter_tween != null and _filter_tween.is_valid():
		_filter_tween.kill()
	if enabled:
		_low_pass.cutoff_hz = Settings.MUSIC_LOW_PASS_CUTOFF_HZ
		AudioServer.set_bus_effect_enabled(bus_index, _low_pass_effect_index, true)
		return
	if (
		not smooth_release
		or not AudioServer.is_bus_effect_enabled(bus_index, _low_pass_effect_index)
	):
		AudioServer.set_bus_effect_enabled(bus_index, _low_pass_effect_index, false)
		return
	_filter_tween = create_tween()
	_filter_tween.tween_property(
		_low_pass,
		"cutoff_hz",
		20500.0,
		Settings.MUSIC_LOW_PASS_RELEASE_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_filter_tween.tween_callback(
		AudioServer.set_bus_effect_enabled.bind(
			bus_index,
			_low_pass_effect_index,
			false
		)
	)


func _ensure_music_bus() -> void:
	var bus_index := AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, MUSIC_BUS_NAME)
	for effect_index in AudioServer.get_bus_effect_count(bus_index):
		var effect := AudioServer.get_bus_effect(bus_index, effect_index)
		if effect is AudioEffectLowPassFilter:
			_low_pass = effect as AudioEffectLowPassFilter
			_low_pass.cutoff_hz = Settings.MUSIC_LOW_PASS_CUTOFF_HZ
			_low_pass_effect_index = effect_index
			return
	_low_pass = AudioEffectLowPassFilter.new()
	_low_pass.cutoff_hz = Settings.MUSIC_LOW_PASS_CUTOFF_HZ
	AudioServer.add_bus_effect(bus_index, _low_pass)
	_low_pass_effect_index = AudioServer.get_bus_effect_count(bus_index) - 1


func request_next_section() -> void:
	if section_change_requested:
		return
	var next_section := current_section + 1
	var next_section_path := GAME_SECTION_PATH % next_section
	if not ResourceLoader.exists(next_section_path):
		return
	if stream == menu_music:
		current_section = next_section
		game_music = load(next_section_path) as AudioStreamWAV
		return
	section_change_requested = true
	var segment_position := fmod(
		get_playback_position(),
		Settings.MUSIC_SEGMENT_SECONDS
	)
	var remaining_time := Settings.MUSIC_SEGMENT_SECONDS - segment_position
	if segment_position <= 0.02 or remaining_time <= 0.02:
		_play_section.call_deferred(next_section, next_section_path)
		return
	get_tree().create_timer(remaining_time).timeout.connect(
		_play_section.bind(next_section, next_section_path)
	)


func _play_section(section_number: int, section_path: String) -> void:
	current_section = section_number
	game_music = load(section_path) as AudioStreamWAV
	section_change_requested = false
	stream = game_music
	_play_if_audible()


func wait_for_next_hand_beat() -> void:
	if (
		not Settings.SYNC_HANDS_TO_MUSIC
		or _headless_audio
		or not playing
		or Settings.MUSIC_BPM <= 0.0
		or Settings.HAND_BEAT_INTERVAL <= 0.0
	):
		return
	var grid_duration := 60.0 / Settings.MUSIC_BPM * Settings.HAND_BEAT_INTERVAL
	var audible_position := (
		get_playback_position()
		+ AudioServer.get_time_since_last_mix()
		- AudioServer.get_output_latency()
	)
	var grid_position := fposmod(audible_position, grid_duration)
	var remaining_time := grid_duration - grid_position
	# Évite d'attendre une subdivision entière si la demande tombe déjà
	# pratiquement sur la pulsation.
	if grid_position <= 0.02 or remaining_time <= 0.02:
		return
	await get_tree().create_timer(remaining_time).timeout


func _play_if_audible() -> void:
	if _headless_audio:
		return
	play()
