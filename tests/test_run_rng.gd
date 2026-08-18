extends SceneTree


func _init() -> void:
	var first := RunRNG.new()
	var second := RunRNG.new()
	first.initialize(RunRNG.seed_string_to_int("PILE-DOWN"), "PILE-DOWN")
	second.initialize(RunRNG.seed_string_to_int("PILE-DOWN"), "PILE-DOWN")
	assert(first.seed_value == second.seed_value)
	assert(first.seed_label == "PILE-DOWN")
	assert(RunRNG.seed_string_to_int("739572984") == 739572984)

	for stream_id in RunRNG.STREAM_IDS:
		var first_stream := first.get_stream(stream_id)
		var second_stream := second.get_stream(stream_id)
		for index in 16:
			assert(first_stream.randi() == second_stream.randi())

	var clean := RunRNG.new()
	var cosmetic_consumed := RunRNG.new()
	clean.initialize(123456789, "123456789")
	cosmetic_consumed.initialize(123456789, "123456789")
	for index in 100:
		cosmetic_consumed.get_stream(&"cosmetic").randi()
	for stream_id in [&"hands", &"bonuses", &"special_rules", &"difficulty"]:
		for index in 16:
			assert(
				clean.get_stream(stream_id).randi()
				== cosmetic_consumed.get_stream(stream_id).randi()
			)

	first.initialize(first.seed_value, first.seed_label)
	second.initialize(second.seed_value, second.seed_label)
	for index in 32:
		assert(
			first.get_stream(&"hands").randi()
			== second.get_stream(&"hands").randi()
		)

	print("Run RNG tests passed.")
	quit()
