class_name SpecialRuleManager
extends Node

signal rules_selected(rules: Array[SpecialRuleData])

const RuleData := preload("res://resources/scripts/special_rules/SpecialRuleData.gd")
const Modifiers := preload("res://resources/scripts/core/RoundModifiers.gd")
const Context := preload("res://resources/scripts/core/RoundContext.gd")
const Difficulty := preload("res://resources/scripts/core/difficulty.gd")
const Debug := preload("res://resources/scripts/core/debug.gd")

@onready var announcement: Control = %SpecialRuleAnnouncement
@onready var flashlight_overlay: Control = %FlashlightOverlay
@onready var moving_pile_pattern: Node = %MovingPilePattern

var active_rules: Array[SpecialRuleData] = []
var modifiers := RoundModifiers.new()
var context := RoundContext.new(1, modifiers)
var rng := RandomNumberGenerator.new()

var _rules: Array[SpecialRuleData] = [
	RuleData.new(&"shell_game", "SHELL GAME", "Now you see it...", [&"merry_go_stack"]),
	RuleData.new(&"merry_go_stack", "MERRY-GO-STACK", "Please remain seated.", [&"shell_game"]),
	RuleData.new(&"free_range_cards", "FREE-RANGE CARDS", "They escaped again.", [&"lights_out"]),
	RuleData.new(&"pile_up", "PILE UP", "Wrong way. Keep going."),
	RuleData.new(&"lights_out", "LIGHTS OUT", "Hope you brought a mouse.", [&"free_range_cards"]),
	RuleData.new(&"peek_a_card", "PEEK-A-CARD", "No peeking. Except peeking."),
	RuleData.new(&"stack_attack", "STACK ATTACK", "Progress is temporary."),
	RuleData.new(&"roman_holiday", "ROMAN HOLIDAY", "When in Rome..."),
]


func _ready() -> void:
	rng.randomize()


func get_special_rule_capacity(round_number: int) -> int:
	var start_round: int = Difficulty.SPECIAL_RULE_START_ROUND
	if round_number < start_round:
		return 0
	return mini(
		int(round_number / start_round),
		Difficulty.MAX_COMBINED_RULES
	)


func get_guaranteed_rule_count(round_number: int) -> int:
	if round_number < Difficulty.SPECIAL_RULE_START_ROUND:
		return 0
	if round_number % Difficulty.SPECIAL_RULE_FREQUENCY != 0:
		return 0
	return 1


func roll_rule_count(round_number: int) -> int:
	var capacity := get_special_rule_capacity(round_number)
	var count := get_guaranteed_rule_count(round_number)
	while count < capacity and rng.randf() < Difficulty.EXTRA_SPECIAL_RULE_CHANCE:
		count += 1
	return count


func begin_round(round_number: int) -> RoundModifiers:
	await end_round()
	var locked_rule_ids := Debug.get_locked_special_rules()
	if locked_rule_ids.is_empty():
		var requested_count := roll_rule_count(round_number)
		active_rules = select_special_rules(round_number, requested_count)
	else:
		active_rules = _select_locked_rules(locked_rule_ids, round_number)
	modifiers = RoundModifiers.new()
	context = RoundContext.new(round_number, modifiers)
	for rule in active_rules:
		rule.activate(context)
	if flashlight_overlay != null:
		flashlight_overlay.visible = modifiers.flashlight_enabled
	if not active_rules.is_empty() and announcement != null:
		await announcement.show_rules(active_rules)
	rules_selected.emit(active_rules)
	return modifiers


func _select_locked_rules(
	rule_ids: Array[StringName],
	round_number: int
) -> Array[SpecialRuleData]:
	var selected: Array[SpecialRuleData] = []
	for rule_id in rule_ids:
		if selected.any(func(rule: SpecialRuleData) -> bool: return rule.id == rule_id):
			push_warning("Special Rules debug lock: duplicate rule id '%s'." % rule_id)
			continue
		var candidate: SpecialRuleData
		for rule in _rules:
			if rule.id == rule_id:
				candidate = rule
				break
		if candidate == null:
			push_warning("Special Rules debug lock: unknown rule id '%s'." % rule_id)
			continue
		# Debug locks bypass progression gates, but structurally conflicting
		# movement rules remain forbidden.
		var compatibility_round := maxi(
			round_number,
			Difficulty.HARD_COMBO_MINIMUM_ROUND
		)
		if not _is_compatible(candidate, selected, compatibility_round):
			push_warning(
				"Special Rules debug lock: incompatible rule id '%s' skipped."
				% rule_id
			)
			continue
		selected.append(candidate)
	return selected


func activate_board_effects(piles: Array[MemoryPile], round_number: int) -> void:
	context.piles.assign(piles)
	if modifiers.moving_pile_pattern and moving_pile_pattern != null:
		moving_pile_pattern.start(piles, round_number)
	if modifiers.regeneration_enabled:
		var candidates: Array[MemoryPile] = []
		for pile in piles:
			if not pile.completed:
				candidates.append(pile)
		candidates.shuffle()
		var count := maxi(1, ceili(candidates.size() * Difficulty.REGENERATING_PILE_RATIO))
		for index in mini(count, candidates.size()):
			candidates[index].enable_regeneration(Difficulty.REGENERATION_DURATION)


func after_card_played(piles: Array[MemoryPile], round_number: int) -> void:
	if not modifiers.swap_piles_after_play:
		return
	var active: Array[MemoryPile] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed and pile.visible:
			active.append(pile)
	if active.size() < 2:
		return
	active.shuffle()
	var swap_count := 3 if round_number >= Difficulty.THREE_PILE_SHELL_GAME_ROUND and active.size() >= 3 else 2
	var moving: Array[MemoryPile] = []
	for index in swap_count:
		moving.append(active[index])
	var destinations: Array[Vector2] = []
	for pile in moving:
		destinations.append(pile.position)
	var tweens: Array[Tween] = []
	for index in moving.size():
		var tween: Tween = (
			moving[index].create_tween()
			.set_trans(Tween.TRANS_SINE)
			.set_ease(Tween.EASE_IN_OUT)
		)
		tween.tween_property(moving[index], "position", destinations[(index + 1) % moving.size()], 0.55)
		tweens.append(tween)
	await tweens[0].finished


func end_round(piles_to_clean: Array[MemoryPile] = []) -> void:
	if moving_pile_pattern != null:
		await moving_pile_pattern.stop()
	for pile in piles_to_clean:
		if is_instance_valid(pile):
			pile.disable_regeneration()
	if flashlight_overlay != null:
		flashlight_overlay.visible = false
	for index in range(active_rules.size() - 1, -1, -1):
		active_rules[index].deactivate(context)
	modifiers.reset()
	active_rules.clear()


func select_special_rules(round_number: int, requested_count: int) -> Array[SpecialRuleData]:
	var selected: Array[SpecialRuleData] = []
	var candidates: Array[SpecialRuleData] = []
	for rule in _rules:
		if round_number >= rule.minimum_round:
			candidates.append(rule)
	while selected.size() < requested_count and not candidates.is_empty():
		var candidate := _weighted_pick(candidates)
		candidates.erase(candidate)
		if _is_compatible(candidate, selected, round_number):
			selected.append(candidate)
	if selected.size() < requested_count:
		push_warning(
			"Special Rules: requested %d compatible rules, selected %d."
			% [requested_count, selected.size()]
		)
	return selected


func _weighted_pick(candidates: Array[SpecialRuleData]) -> SpecialRuleData:
	var total := 0.0
	for rule in candidates:
		total += maxf(rule.weight, 0.0)
	if total <= 0.0:
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	var roll := rng.randf_range(0.0, total)
	for rule in candidates:
		roll -= maxf(rule.weight, 0.0)
		if roll <= 0.0:
			return rule
	return candidates.back()


func _is_compatible(
	candidate: SpecialRuleData,
	selected: Array[SpecialRuleData],
	round_number: int
) -> bool:
	for required in candidate.required_rules:
		if not selected.any(func(rule: SpecialRuleData) -> bool: return rule.id == required):
			return false
	for rule in selected:
		if candidate.incompatible_rules.has(rule.id) or rule.incompatible_rules.has(candidate.id):
			return false
		if (
			round_number < Difficulty.HARD_COMBO_MINIMUM_ROUND
			and (
				(candidate.id == &"peek_a_card" and rule.id == &"lights_out")
				or (candidate.id == &"lights_out" and rule.id == &"peek_a_card")
			)
		):
			return false
	return true
