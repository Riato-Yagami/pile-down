extends SceneTree

# Run the real hand generator, replacing only visual instantiation.
class SamplingHand extends HandManager:
	var sampled: Array[int] = []
	var unique_values := false
	var spread_window := false
	var spread_strength := 0.7
	var spread_target := 2.0
	var growing_target := false
	var board: Array[MemoryPile] = []

	func _create_card(_container: Control, value: int, _joker: bool, _hover: bool,
		_roman: bool, _modifiers: RoundModifiers, _animate: bool, _right: bool) -> PlayingCard:
		sampled.append(value)
		return null

	func draw_spaced_value(pool: Array[int], avoided: int, suppression: float,
		repeated: int, repeat_suppression: float, value_weights: Dictionary = {}) -> int:
		if not spread_window:
			if not unique_values:
				return super.draw_spaced_value(pool, avoided, suppression, repeated, repeat_suppression, value_weights)
			var unique: Array[int] = []
			for value in pool:
				if not unique.has(value):
					unique.append(value)
			return super.draw_spaced_value(unique, avoided, suppression, repeated, repeat_suppression, value_weights)
		var target_spread := spread_target
		if growing_target:
			var progress := 0.0
			for pile in board:
				progress += 7.0 - pile.current_value
			target_spread = 1.0 + 2.0 * progress / (7.0 * board.size())
		var counts := {}
		for value in pool:
			counts[value] = int(counts.get(value, 0)) + 1
		var weights: Array[float] = []
		var total := 0.0
		for value in pool:
			var weight := 1.0
			if value == avoided:
				weight *= 1.0 - suppression
			if value == repeated:
				weight *= 1.0 - repeat_suppression
			if unique_values:
				weight /= counts[value]
			var target: MemoryPile
			for pile in board:
				if not pile.completed and pile.expected_value() == value:
					target = pile
					break
			if target != null:
				var low := board[0].current_value
				var high := 0
				for pile in board:
					var after := pile.current_value - (1 if pile == target else 0)
					low = mini(low, after)
					high = maxi(high, after)
				weight *= exp(-spread_strength * pow(float(high - low) - target_spread, 2.0))
			weights.append(weight)
			total += weight
		if total <= 0.0:
			return pool[rng.randi_range(0, pool.size() - 1)]
		var roll := rng.randf() * total
		for index in pool.size():
			roll -= weights[index]
			if roll < 0.0:
				return pool[index]
		return pool.back()

const CONFIGS := [
	{"id": "uniform", "chain": 0.0, "align": 0.0},
	{"id": "current", "chain": 0.4, "align": 0.6},
	{"id": "both_70", "chain": 0.7, "align": 0.7},
	{"id": "both_90", "chain": 0.9, "align": 0.9},
	{"id": "unique_current", "chain": 0.4, "align": 0.6, "unique": true},
	{"id": "unique_70", "chain": 0.7, "align": 0.7, "unique": true},
	{"id": "hand_scaled", "chain": 0.4, "align": 0.6, "scaled": true},
	{"id": "unique_scaled", "chain": 0.4, "align": 0.6, "unique": true, "scaled": true},
]
const EXTRA_CONFIGS := [
	{"id": "asymmetric_60_80", "chain": 0.6, "align": 0.8},
	{"id": "asymmetric_80_90", "chain": 0.8, "align": 0.9},
	{"id": "window_current", "chain": 0.4, "align": 0.6, "window": true},
	{"id": "window_unique", "chain": 0.4, "align": 0.6, "window": true, "unique": true},
	{"id": "window_only", "chain": 0.0, "align": 0.0, "window": true, "unique": true},
]
const SOFT_CONFIGS := [
	{"id": "window_soft", "chain": 0.4, "align": 0.6, "window": true, "strength": 0.3, "target": 2.5},
	{"id": "window_growing", "chain": 0.4, "align": 0.6, "window": true, "strength": 0.4, "growing": true},
]
const ROUNDS := 300
const PROBES := 20000
var sampler := SamplingHand.new()
var container := Control.new()
var draw_maximum := 7

func _init() -> void:
	_run.call_deferred()

func _draw(piles: Array[MemoryPile], last: MemoryPile, hand_size: int,
	config: Dictionary, lucky_level: int) -> Array[int]:
	var playable: Array[int] = []
	for pile in piles:
		if not pile.completed:
			playable.append(pile.expected_value())
	sampler.sampled.clear()
	sampler.unique_values = config.get("unique", false)
	sampler.spread_window = config.get("window", false)
	sampler.board = piles
	sampler.spread_strength = config.get("strength", 0.7)
	sampler.spread_target = config.get("target", 2.0)
	sampler.growing_target = config.get("growing", false)
	var chain := float(config.chain)
	var align := float(config.align)
	if config.get("scaled", false):
		chain = 1.0 - (1.0 - chain) / sqrt(float(hand_size))
		align = 1.0 - (1.0 - align) / sqrt(float(hand_size))
	sampler.generate_hand(container, hand_size, draw_maximum, playable,
		false, false, false, false, true, false, null, 0.0, false,
		DifficultySettings.LUCKY_HAND_CHANCES[lucky_level], lucky_level,
		0, 0, piles, true, false, last, chain, align, config.get("production_strength", 0.0))
	assert(sampler.sampled.any(func(value: int): return playable.has(value)))
	assert(sampler.sampled.all(func(value: int): return value >= 0 and value < draw_maximum))
	return sampler.sampled

func _make_piles(count: int) -> Array[MemoryPile]:
	var piles: Array[MemoryPile] = []
	for index in count:
		var pile := MemoryPile.new()
		pile.current_value = draw_maximum
		piles.append(pile)
	return piles

func _probe(config: Dictionary, hand_size: int, maximum := 7) -> Dictionary:
	draw_maximum = maximum
	var piles := _make_piles(4)
	for pile in piles:
		pile.current_value = maxi(2, maximum - 1)
	piles[3].current_value = maxi(2, maximum - 1) - 1
	sampler.rng.seed = 9001
	var align := 0
	var chain := 0
	for sample in PROBES:
		var hand := _draw(piles, piles[3], hand_size, config, 0)
		align += int(hand.has(piles[3].current_value))
		chain += int(hand.has(piles[3].expected_value()))
	for pile in piles:
		pile.free()
	return {"config": config.id, "hand": hand_size, "maximum": maximum,
		"alignment_available": float(align) / PROBES,
		"chain_available": float(chain) / PROBES}

func _simulate(config: Dictionary, hand_size: int, pile_count: int,
	strategy: String, lucky: int, maximum := 7) -> Dictionary:
	draw_maximum = maximum
	var metrics := {"turns": 0, "same_pile": 0, "tight": 0,
		"spread": 0.0, "first_finish_untouched": 0, "longest_chain": 0.0,
		"one_value": 0}
	for seed_index in ROUNDS:
		sampler.rng.seed = 10000 + seed_index
		var piles := _make_piles(pile_count)
		var last: MemoryPile
		var chain_length := 0
		var longest := 0
		var first_finish := false
		for turn in pile_count * maximum:
			var hand := _draw(piles, last, hand_size, config, lucky)
			var candidates: Array[MemoryPile] = []
			var useful_values: Array[int] = []
			for pile in piles:
				if not pile.completed and hand.has(pile.expected_value()):
					candidates.append(pile)
					if not useful_values.has(pile.expected_value()):
						useful_values.append(pile.expected_value())
			assert(not candidates.is_empty())
			var chosen := candidates[0]
			for candidate in candidates:
				if strategy == "serial" and candidate.current_value < chosen.current_value:
					chosen = candidate
				elif strategy == "align" and candidate.current_value > chosen.current_value:
					chosen = candidate
			if chosen == last:
				metrics.same_pile += 1
				chain_length += 1
			else:
				chain_length = 1
			longest = maxi(longest, chain_length)
			chosen.current_value -= 1
			chosen.completed = chosen.current_value == 0
			last = chosen
			if chosen.completed and not first_finish:
				first_finish = true
				metrics.first_finish_untouched += int(piles.any(func(pile: MemoryPile): return pile.current_value == maximum))
			# Include completed piles: the board's spread and first finishes matter.
			var low := maximum
			var high := 0
			for pile in piles:
				low = mini(low, pile.current_value)
				high = maxi(high, pile.current_value)
			metrics.tight += int(high - low <= 1)
			metrics.spread += high - low
			metrics.one_value += int(useful_values.size() == 1)
			metrics.turns += 1
		assert(piles.all(func(pile: MemoryPile): return pile.completed))
		metrics.longest_chain += longest
		for pile in piles:
			pile.free()
	var turns := float(metrics.turns)
	return {"config": config.id, "hand": hand_size, "piles": pile_count,
		"strategy": strategy, "lucky": lucky, "maximum": maximum, "rounds": ROUNDS,
		"same_pile_rate": metrics.same_pile / turns,
		"tight_board_rate": metrics.tight / turns,
		"mean_spread": metrics.spread / turns,
		"first_finish_with_untouched": float(metrics.first_finish_untouched) / ROUNDS,
		"mean_longest_chain": metrics.longest_chain / ROUNDS,
		"single_useful_value_rate": metrics.one_value / turns}

func _run() -> void:
	root.add_child(sampler)
	root.add_child(container)
	if OS.get_cmdline_user_args().has("--production"):
		var production_results: Array = []
		for strength in [0.0, 0.2, 0.3, 0.4]:
			var config := {"id": "production_%.1f" % strength, "chain": 0.4, "align": 0.6, "production_strength": strength}
			for hand in [1, 2, 4]:
				for piles in [2, 4, 8]:
					for strategy in ["serial", "align"]:
						production_results.append(_simulate(config, hand, piles, strategy, 0))
			for maximum in [2, 3, 5, 9]:
				for strategy in ["serial", "align"]:
					production_results.append(_simulate(config, 4, 4, strategy, 0, maximum))
			for lucky in [1, 3]:
				for strategy in ["serial", "align"]:
					production_results.append(_simulate(config, 4, 4, strategy, lucky))
			print("Completed ", config.id)
		var production_file := FileAccess.open("res://tests/hand_balance_production_results.json", FileAccess.WRITE)
		production_file.store_string(JSON.stringify({"rounds_per_case": ROUNDS, "strategies": production_results}, "  "))
		sampler.queue_free()
		container.queue_free()
		await process_frame
		print("Production hand policy comparison completed.")
		quit()
		return
	if OS.get_cmdline_user_args().has("--value-games"):
		var games: Array = []
		for config in [CONFIGS[1], CONFIGS[2], SOFT_CONFIGS[0]]:
			for maximum in [2, 3, 5, 9]:
				for strategy in ["serial", "align"]:
					games.append(_simulate(config, 4, 4, strategy, 0, maximum))
			print("Completed value-range games ", config.id)
		var game_file := FileAccess.open("res://tests/hand_balance_value_games.json", FileAccess.WRITE)
		game_file.store_string(JSON.stringify({"strategies": games}, "  "))
		sampler.queue_free()
		container.queue_free()
		await process_frame
		print("Value-range games completed.")
		quit()
		return
	if OS.get_cmdline_user_args().has("--ranges"):
		var range_results: Array = []
		for config in [CONFIGS[1], CONFIGS[6]]:
			for maximum in [2, 3, 9]:
				for hand in [1, 2, 4]:
					range_results.append(_probe(config, hand, maximum))
		var range_file := FileAccess.open("res://tests/hand_balance_range_results.json", FileAccess.WRITE)
		range_file.store_string(JSON.stringify({"probe_samples": PROBES, "probes": range_results}, "  "))
		sampler.queue_free()
		container.queue_free()
		await process_frame
		print("Value-range probes completed.")
		quit()
		return
	var results: Array = []
	var probes: Array = []
	var extra := OS.get_cmdline_user_args().has("--extra")
	var soft := OS.get_cmdline_user_args().has("--soft")
	var configs: Array = SOFT_CONFIGS if soft else (EXTRA_CONFIGS if extra else CONFIGS)
	for config in configs:
		for hand in [1, 2, 4]:
			probes.append(_probe(config, hand))
			for piles in [2, 4, 8]:
				for strategy in ["serial", "align"]:
					results.append(_simulate(config, hand, piles, strategy, 0))
		print("Completed ", config.id)
	# Bonus probes retain the actual Lucky Hand implementation and probabilities.
	var lucky_configs: Array = [EXTRA_CONFIGS[0], EXTRA_CONFIGS[3], EXTRA_CONFIGS[4]] if extra else [CONFIGS[1], CONFIGS[5], CONFIGS[7]]
	if soft:
		lucky_configs = SOFT_CONFIGS
	for config in lucky_configs:
		for level in [1, 3]:
			for strategy in ["serial", "align"]:
				results.append(_simulate(config, 4, 4, strategy, level))
	var report := {"rounds_per_case": ROUNDS, "probe_samples": PROBES,
		"probes": probes, "strategies": results,
		"scope": "Perfect memory; one card per hand; no jokers, discard plays, chains, Deja Vu, errors, or time pressure. Uses real generate_hand and Lucky Hand; prototypes alter only value pool and suppression."}
	var output := "res://tests/hand_balance_soft_results.json" if soft else ("res://tests/hand_balance_extra_results.json" if extra else "res://tests/hand_balance_results.json")
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	sampler.queue_free()
	container.queue_free()
	await process_frame
	print("Hand balance analysis completed.")
	quit()
