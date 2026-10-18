extends SceneTree


func _init() -> void:
	var settings := preload("res://resources/scripts/settings/difficulty.gd")
	for bounds in [
		[settings.ADD_PILE_WEIGHT, settings.START_PILES, settings.MAX_PILES],
		[settings.ADD_CARD_WEIGHT, settings.START_HAND_SIZE, settings.MAX_HAND_SIZE],
		[settings.ADD_START_VALUE_WEIGHT, settings.START_CARD_VALUE, settings.MAX_CARD_VALUE],
		[settings.REDUCE_TURN_TIME_WEIGHT, settings.START_TURN_TIME, settings.MIN_TURN_TIME],
	]:
		var base := float(bounds[0])
		var initial := float(bounds[1])
		var limit := float(bounds[2])
		assert(is_equal_approx(DifficultyProgression.proximity_weight(base, initial, initial, limit), base))
		assert(is_equal_approx(DifficultyProgression.proximity_weight(base, lerpf(initial, limit, 0.5), initial, limit), base * 0.5))
		assert(DifficultyProgression.proximity_weight(base, limit, initial, limit) == 0.0)
	assert(DifficultyProgression.proximity_weight(10, 4, 4, 4) == 0.0)
	var progression := DifficultyProgression.new()
	progression.pile_count = settings.MAX_PILES
	progression.hand_size = settings.MAX_HAND_SIZE
	progression.start_value = settings.MAX_CARD_VALUE
	progression.turn_time = settings.MIN_TURN_TIME + 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	assert(progression.increase(rng, false) == "-1 SECOND")
	assert(progression.turn_time == settings.MIN_TURN_TIME)
	assert(progression.increase(rng, false).is_empty())
	print("Difficulty proximity weights tests passed.")
	quit()
