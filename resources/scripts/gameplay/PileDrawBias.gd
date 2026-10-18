class_name PileDrawBias
extends RefCounted

## Pure board snapshot: drawing never reveals values or changes pile state.
static func build_weights(
	piles: Array[MemoryPile], maximum_value: int, pile_up: bool,
	strength: float, minimum_weight := 0.05
) -> Dictionary:
	# On very short rounds, simulations found no useful anti-chain effect,
	# and a board target instead helped the alignment strategy.
	if strength <= 0.0 or maximum_value <= 3:
		return {}
	var remaining: Array[int] = []
	var targets: Dictionary = {}
	for pile in piles:
		if not is_instance_valid(pile):
			continue
		var distance := maximum_value - pile.current_value if pile_up else pile.current_value
		remaining.append(0 if pile.completed else distance)
		if not pile.completed:
			targets[pile.expected_value()] = remaining.size() - 1
	# With only one unfinished pile, the player has no distribution to manage.
	var active_count := 0
	for distance in remaining:
		active_count += int(distance > 0)
	if active_count < 2 or targets.size() < 2:
		return {}
	# Short rounds need a smaller gap; a fixed 2.5 encourages early completion.
	var target_spread := clampf(float(maximum_value) * 0.4, 1.0, 2.5)
	var weights: Dictionary = {}
	var best_score := -INF
	for value: int in targets:
		var low := maximum_value
		var high := 0
		for index in remaining.size():
			var after := remaining[index] - (1 if index == targets[value] else 0)
			low = mini(low, after)
			high = maxi(high, after)
		var deviation := float(high - low) - target_spread
		var score := -strength * deviation * deviation
		weights[value] = score
		best_score = maxf(best_score, score)
	# Relative scores retain the better move on boards far from the target,
	# without underflow or making all candidates identical at the floor.
	for value: int in weights:
		weights[value] = maxf(exp(weights[value] - best_score), clampf(minimum_weight, 0.001, 1.0))
	return weights
