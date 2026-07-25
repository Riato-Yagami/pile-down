class_name SoftAudio
extends Node

const SAMPLE_RATE := 22050
const Settings := preload("res://resources/scripts/settings/settings.gd")
const SFX_BUS_NAME := &"SFX"


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
	# Deux notes descendantes rendent l'erreur identifiable sans regarder le HUD.
	play_tone(165.0, 0.16, 0.16)
	var delayed_tone := get_tree().create_timer(0.075)
	delayed_tone.timeout.connect(func() -> void: play_tone(105.0, 0.22, 0.19))


func play_start() -> void:
	_play_sequence([392.0, 523.25], 0.07, 0.07, 0.055)


func play_clock_tick(urgency := 0.0) -> void:
	var intensity := pow(clampf(urgency, 0.0, 1.0), 2.0)
	var frequency := lerpf(820.0, 980.0, intensity)
	var volume := lerpf(0.032, 0.048, intensity)
	play_tone(frequency, 0.03, volume)


func play_special_rule() -> void:
	_play_sequence([261.63, 392.0, 311.13], 0.065, 0.08, 0.045)


func play_game_over() -> void:
	_play_sequence([220.0, 164.81, 110.0], 0.11, 0.14, 0.06)


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
