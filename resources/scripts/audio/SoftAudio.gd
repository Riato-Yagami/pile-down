class_name SoftAudio
extends Node

const SAMPLE_RATE := 22050


func toggle_mute() -> bool:
	var master_bus := AudioServer.get_bus_index("Master")
	var muted := not AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, muted)
	return muted


func is_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))


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
	player.finished.connect(player.queue_free)
	player.play()


func play_error() -> void:
	# Deux notes descendantes rendent l'erreur identifiable sans regarder le HUD.
	play_tone(165.0, 0.14, 0.075)
	var delayed_tone := get_tree().create_timer(0.075)
	delayed_tone.timeout.connect(func() -> void: play_tone(105.0, 0.2, 0.085))
