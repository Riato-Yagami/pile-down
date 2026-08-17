class_name DifficultyProgression
extends RefCounted

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")

var pile_count := Difficulty.START_PILES
var hand_size := Difficulty.START_HAND_SIZE
var start_value := Difficulty.START_CARD_VALUE
var turn_time := Difficulty.START_TURN_TIME
var droughts := new_droughts()
var tier_reliefs_applied := 0


func reset() -> void:
	pile_count = Difficulty.START_PILES
	hand_size = Difficulty.START_HAND_SIZE
	start_value = Difficulty.START_CARD_VALUE
	turn_time = Difficulty.START_TURN_TIME
	droughts = new_droughts()
	tier_reliefs_applied = 0


func increase(rng: RandomNumberGenerator, first_upgrade: bool) -> String:
	var options: Array[StringName] = []
	var weights: Array[float] = []
	var pile_weight := Difficulty.FIRST_ADD_PILE_WEIGHT if first_upgrade else Difficulty.ADD_PILE_WEIGHT
	var card_weight := Difficulty.FIRST_ADD_CARD_WEIGHT if first_upgrade else Difficulty.ADD_CARD_WEIGHT
	if pile_count < Difficulty.MAX_PILES and (first_upgrade or pile_weight > 0.0):
		options.append(&"pile")
		if pile_count == 1:
			pile_weight *= Difficulty.STARTER_STAT_MULTIPLIER
		weights.append(directed_weight(pile_weight, droughts[&"pile"]))
	if hand_size < Difficulty.MAX_HAND_SIZE and (first_upgrade or card_weight > 0.0):
		options.append(&"hand")
		if hand_size == 1:
			card_weight *= Difficulty.STARTER_STAT_MULTIPLIER
		weights.append(directed_weight(card_weight, droughts[&"hand"]))
	if not first_upgrade and start_value < Difficulty.MAX_CARD_VALUE and Difficulty.ADD_START_VALUE_WEIGHT > 0.0:
		options.append(&"start_value")
		weights.append(directed_weight(Difficulty.ADD_START_VALUE_WEIGHT, droughts[&"start_value"]))
	if not first_upgrade and turn_time > Difficulty.MIN_TURN_TIME and Difficulty.REDUCE_TURN_TIME_WEIGHT > 0.0:
		options.append(&"time")
		weights.append(directed_weight(Difficulty.REDUCE_TURN_TIME_WEIGHT, droughts[&"time"]))
	var all_eligible_options := options.duplicate()
	var guaranteed_options: Array[StringName] = []
	var guaranteed_weights: Array[float] = []
	for index in options.size():
		if int(droughts.get(options[index], 0)) >= Difficulty.MAX_STAT_DROUGHT:
			guaranteed_options.append(options[index])
			guaranteed_weights.append(weights[index])
	if not guaranteed_options.is_empty():
		options = guaranteed_options
		weights = guaranteed_weights
	if options.is_empty():
		return ""
	var total := 0.0
	for weight in weights:
		total += weight
	if total <= 0.0:
		weights.fill(1.0)
		total = float(weights.size())
	var roll := rng.randf_range(0.0, total)
	var choice: StringName = options[0]
	for index in options.size():
		roll -= weights[index]
		if roll <= 0.0:
			choice = options[index]
			break
	_update_droughts(choice, all_eligible_options)
	match choice:
		&"pile":
			pile_count += 1
			return "+1 PILE"
		&"hand":
			hand_size += 1
			return "+1 CARD"
		&"start_value":
			start_value += 1
			return "+1 START VALUE"
		&"time":
			turn_time -= 1.0
			return "-1 SECOND"
	return ""


func advance(rng: RandomNumberGenerator, progression_round: int, first_upgrade_override := -1) -> String:
	if is_tier_relief_round(progression_round):
		apply_tier_relief(rng)
		return "TIER RELIEF"
	if not has_due_guarantee() and rng.randf() < no_change_chance(progression_round):
		return ""
	var changes: Array[String] = []
	var first_upgrade := first_upgrade_override == 1 if first_upgrade_override >= 0 else progression_round == 2
	var first_change := increase(rng, first_upgrade)
	if not first_change.is_empty():
		changes.append(first_change)
	if rng.randf() < extra_change_chance(progression_round):
		var extra_change := increase(rng, false)
		if not extra_change.is_empty():
			changes.append(extra_change)
	return "\n".join(changes)


func apply_until(rng: RandomNumberGenerator, start_round: int) -> void:
	for completed_round in range(1, start_round):
		advance(rng, completed_round + 1, 1 if completed_round == 1 else 0)


func has_due_guarantee() -> bool:
	return (
		pile_count < Difficulty.MAX_PILES and int(droughts.get(&"pile", 0)) >= Difficulty.MAX_STAT_DROUGHT
	) or (
		hand_size < Difficulty.MAX_HAND_SIZE and int(droughts.get(&"hand", 0)) >= Difficulty.MAX_STAT_DROUGHT
	) or (
		start_value < Difficulty.MAX_CARD_VALUE and int(droughts.get(&"start_value", 0)) >= Difficulty.MAX_STAT_DROUGHT
	) or (
		turn_time > Difficulty.MIN_TURN_TIME and int(droughts.get(&"time", 0)) >= Difficulty.MAX_STAT_DROUGHT
	)


func probability_debug_text(progression_round: int) -> String:
	var first_upgrade := progression_round == 2
	var labels: Array[StringName] = []
	var ids: Array[StringName] = []
	var weights: Array[float] = []
	var pile_weight := Difficulty.FIRST_ADD_PILE_WEIGHT if first_upgrade else Difficulty.ADD_PILE_WEIGHT
	var hand_weight := Difficulty.FIRST_ADD_CARD_WEIGHT if first_upgrade else Difficulty.ADD_CARD_WEIGHT
	if pile_count < Difficulty.MAX_PILES:
		labels.append(&"PILE")
		ids.append(&"pile")
		weights.append(directed_weight(pile_weight * (Difficulty.STARTER_STAT_MULTIPLIER if pile_count == 1 else 1.0), droughts[&"pile"]))
	if hand_size < Difficulty.MAX_HAND_SIZE:
		labels.append(&"CARD")
		ids.append(&"hand")
		weights.append(directed_weight(hand_weight * (Difficulty.STARTER_STAT_MULTIPLIER if hand_size == 1 else 1.0), droughts[&"hand"]))
	if not first_upgrade and start_value < Difficulty.MAX_CARD_VALUE:
		labels.append(&"START VALUE")
		ids.append(&"start_value")
		weights.append(directed_weight(Difficulty.ADD_START_VALUE_WEIGHT, droughts[&"start_value"]))
	if not first_upgrade and turn_time > Difficulty.MIN_TURN_TIME:
		labels.append(&"TIME")
		ids.append(&"time")
		weights.append(directed_weight(Difficulty.REDUCE_TURN_TIME_WEIGHT, droughts[&"time"]))
	var guaranteed: Array[int] = []
	for index in ids.size():
		if int(droughts.get(ids[index], 0)) >= Difficulty.MAX_STAT_DROUGHT:
			guaranteed.append(index)
	var total := 0.0
	for index in weights.size():
		if guaranteed.is_empty() or guaranteed.has(index):
			total += weights[index]
	var lines := PackedStringArray([
		"DIFFICULTY / ROUND %d" % progression_round,
		"NO CHANGE  %5.1f%%" % ((0.0 if not guaranteed.is_empty() else no_change_chance(progression_round)) * 100.0),
		"EXTRA STAT %5.1f%%" % (extra_change_chance(progression_round) * 100.0),
		"FIRST PICK",
	])
	for index in labels.size():
		var effective := weights[index] if guaranteed.is_empty() or guaranteed.has(index) else 0.0
		lines.append("%s %5.1f%%" % [String(labels[index]), (effective / total * 100.0) if total > 0.0 else 0.0])
	return "\n".join(lines)


func _update_droughts(selected: StringName, eligible: Array[StringName]) -> void:
	for stat: StringName in droughts.keys():
		if eligible.has(stat):
			droughts[stat] = 0 if stat == selected else mini(int(droughts[stat]) + 1, Difficulty.MAX_STAT_DROUGHT)


func apply_tier_relief(rng: RandomNumberGenerator) -> void:
	var relief_count := mini(tier_reliefs_applied + 1, 4)
	var stats: Array[StringName] = []
	if pile_count > Difficulty.START_PILES: stats.append(&"piles")
	if hand_size > Difficulty.START_HAND_SIZE: stats.append(&"hand")
	if start_value > Difficulty.START_CARD_VALUE: stats.append(&"value")
	if turn_time < Difficulty.START_TURN_TIME: stats.append(&"time")
	for index in range(stats.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := stats[index]
		stats[index] = stats[swap_index]
		stats[swap_index] = temporary
	for index in mini(relief_count, stats.size()):
		match stats[index]:
			&"piles": pile_count = maxi(pile_count - 1, Difficulty.START_PILES)
			&"hand": hand_size = maxi(hand_size - 1, Difficulty.START_HAND_SIZE)
			&"value": start_value = maxi(start_value - 1, Difficulty.START_CARD_VALUE)
			&"time": turn_time = minf(turn_time + 1.0, Difficulty.START_TURN_TIME)
	tier_reliefs_applied += 1


static func directed_weight(base_weight: float, drought_count: int) -> float:
	return maxf(base_weight, 0.0) * (1.0 + mini(drought_count, Difficulty.MAX_STAT_DROUGHT) * Difficulty.STAT_PITY_RATE)


static func new_droughts() -> Dictionary:
	return {&"pile": 0, &"hand": 0, &"start_value": 0, &"time": 0}


static func extra_change_chance(progression_round: int) -> float:
	return clampf(Difficulty.EXTRA_DIFFICULTY_START_CHANCE - maxi(progression_round - 2, 0) * Difficulty.EXTRA_DIFFICULTY_CHANCE_LOSS_PER_ROUND, 0.0, 1.0)


static func no_change_chance(progression_round: int) -> float:
	return clampf(Difficulty.NO_DIFFICULTY_START_CHANCE + maxi(progression_round - 2, 0) * Difficulty.NO_DIFFICULTY_CHANCE_GAIN_PER_ROUND, 0.0, Difficulty.MAX_NO_DIFFICULTY_CHANCE)


static func is_tier_relief_round(progression_round: int) -> bool:
	var rule_count := 1
	while true:
		var milestone := Difficulty.special_rule_milestone(rule_count)
		if milestone >= progression_round:
			return milestone == progression_round
		rule_count += 1
	return false
