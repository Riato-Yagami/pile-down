class_name SoftAudio
extends Node

const SAMPLE_RATE := 22050
const Settings := preload("res://resources/scripts/settings/settings.gd")
const SFX_BUS_NAME := &"SFX"
const SAFETY_NET_BREAK_GAIN := 0.6 # Environ -4,4 dB.


func toggle_mute() -> bool:
	var master_bus := AudioServer.get_bus_index("Master")
	var muted := not AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, muted)
	if not muted:
		play_tone(440.0, 0.05, 0.035)
	return muted


func is_muted() -> bool:
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index(SFX_BUS_NAME)
	if music_bus < 0 or sfx_bus < 0:
		return AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	return (
		AudioServer.is_bus_mute(music_bus)
		and AudioServer.is_bus_mute(sfx_bus)
	)


func play_tone(frequency: float, duration := 0.075, volume := 0.12) -> void:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var time := float(index) / SAMPLE_RATE
		var progress := float(index) / sample_count
		var envelope := pow(1.0 - progress, 2.4)
		var sample := int(sin(TAU * frequency * time) * envelope * volume * 32767.0)
		data.encode_s16(index * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.bus = SFX_BUS_NAME
	player.volume_db = Settings.SFX_VOLUME_DB
	player.finished.connect(player.queue_free)
	player.play()


func play_error() -> void:
	# Use a harmonically rich mid-range buzz: the former low sine tones could
	# disappear almost entirely on phone and laptop speakers.
	_play_alert_tone(380.0, 0.18, 0.34)
	var delayed_tone := get_tree().create_timer(0.085)
	delayed_tone.timeout.connect(
		func() -> void:
			_play_alert_tone(220.0, 0.26, 0.38)
	)


func play_timeout_error() -> void:
	# A short alarm followed by a low impact distinguishes timeouts from bad drops.
	_play_alert_tone(980.0, 0.09, 0.28)
	var second_alarm := get_tree().create_timer(0.065)
	second_alarm.timeout.connect(
		func() -> void:
			_play_alert_tone(680.0, 0.11, 0.31)
	)
	var impact := get_tree().create_timer(0.14)
	impact.timeout.connect(
		func() -> void:
			_play_alert_tone(210.0, 0.28, 0.4)
	)


func play_safety_net_break() -> void:
	# Bright inharmonic strikes read as a small metallic shield breaking.
	_play_alert_tone(
		1030.0,
		0.12,
		0.34 * SAFETY_NET_BREAK_GAIN
	)
	var high_strike := get_tree().create_timer(0.045)
	high_strike.timeout.connect(
		func() -> void:
			_play_alert_tone(
				1480.0,
				0.1,
				0.28 * SAFETY_NET_BREAK_GAIN
			)
	)
	var body_strike := get_tree().create_timer(0.095)
	body_strike.timeout.connect(
		func() -> void:
			_play_alert_tone(
				540.0,
				0.2,
				0.34 * SAFETY_NET_BREAK_GAIN
			)
	)


func _play_alert_tone(frequency: float, duration: float, volume: float) -> void:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var time := float(index) / SAMPLE_RATE
		var progress := float(index) / maxf(float(sample_count), 1.0)
		var attack := minf(progress / 0.025, 1.0)
		var envelope := attack * pow(1.0 - progress, 1.45)
		var wave := (
			sin(TAU * frequency * time)
			+ sin(TAU * frequency * 2.0 * time) * 0.42
			+ sin(TAU * frequency * 3.0 * time) * 0.2
		) / 1.62
		var sample := int(
			clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0
		)
		data.encode_s16(index * 2, sample)
	_play_wav_data(data)


func _play_wav_data(data: PackedByteArray) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.bus = SFX_BUS_NAME
	player.volume_db = Settings.SFX_VOLUME_DB
	player.finished.connect(player.queue_free)
	player.play()


func play_start() -> void:
	_play_sequence([392.0, 523.25], 0.07, 0.07, 0.055)


func play_clock_tick(urgency := 0.0) -> void:
	var intensity := pow(clampf(urgency, 0.0, 1.0), 2.0)
	var frequency := lerpf(820.0, 980.0, intensity)
	var volume := lerpf(0.032, 0.048, intensity)
	play_tone(frequency, 0.03, volume)


func play_special_rule() -> void:
	_play_sequence([261.63, 392.0, 311.13], 0.065, 0.08, 0.045)


func play_achievement() -> void:
	# A compact rising sparkle stays distinct from round and victory cues.
	_play_sequence([659.25, 783.99, 1046.5], 0.055, 0.1, 0.05)


func play_game_over() -> void:
	# A loud three-stage fall accompanies the death popup. Rich harmonics keep
	# the cue audible while the music bus is filtered.
	_play_alert_tone(520.0, 0.17, 0.34)
	var middle_fall := get_tree().create_timer(0.1)
	middle_fall.timeout.connect(
		func() -> void:
			_play_alert_tone(310.0, 0.25, 0.4)
	)
	var final_impact := get_tree().create_timer(0.23)
	final_impact.timeout.connect(
		func() -> void:
			_play_alert_tone(155.0, 0.42, 0.46)
	)


func play_victory() -> void:
	_play_sequence([523.25, 659.25, 783.99], 0.09, 0.12, 0.055)


func _play_sequence(
	frequencies: Array[float],
	spacing: float,
	duration: float,
	volume: float
) -> void:
	for index in frequencies.size():
		if index == 0:
			play_tone(frequencies[index], duration, volume)
			continue
		var delayed_tone := get_tree().create_timer(index * spacing)
		delayed_tone.timeout.connect(
			play_tone.bind(frequencies[index], duration, volume)
		)
