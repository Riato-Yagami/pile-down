class_name SpecialRuleManager
extends Node

signal rules_selected(rules: Array[SpecialRuleData])
signal rules_announcing(rules: Array[SpecialRuleData])
signal rules_announcement_finished()

const RuleData := preload("res://resources/scripts/special_rules/SpecialRuleData.gd")
const Registry := preload("res://resources/scripts/special_rules/SpecialRuleRegistry.gd")
const Modifiers := preload("res://resources/scripts/core/RoundModifiers.gd")
const Context := preload("res://resources/scripts/core/RoundContext.gd")
const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const Debug := preload("res://resources/scripts/settings/debug.gd")

@onready var announcement: SpecialRuleAnnouncement = %SpecialRuleAnnouncement
@onready var flashlight_overlay: FlashlightOverlay = %FlashlightOverlay
@onready var moving_pile_pattern: Node = %MovingPilePattern

var active_rules: Array[SpecialRuleData] = []
var modifiers := RoundModifiers.new()
var context := RoundContext.new(1, modifiers)
var rng := RandomNumberGenerator.new()
var _last_special_rule_round := -1000

var _rules: Array[SpecialRuleData] = Registry.create_all_rules()


func _ready() -> void:
	rng.randomize()


func get_special_rule_capacity(round_number: int) -> int:
	if round_number < Difficulty.FIRST_SPECIAL_RULE_ROUND:
		return 0
	var capacity := 1
	for rule_count in range(2, Difficulty.MAX_COMBINED_RULES + 1):
		if round_number < _rule_count_milestone(rule_count):
			break
		capacity = rule_count
	return capacity


func get_guaranteed_rule_count(round_number: int) -> int:
	if round_number == Difficulty.FIRST_SPECIAL_RULE_ROUND:
		return 1
	for rule_count in range(2, Difficulty.MAX_COMBINED_RULES + 1):
		if round_number == _rule_count_milestone(rule_count):
			return rule_count
	return 0


func roll_rule_count(round_number: int) -> int:
	var capacity := get_special_rule_capacity(round_number)
	var count := get_guaranteed_rule_count(round_number)
	if capacity == 0:
		return 0
	if count == 0 and rng.randf() >= Difficulty.EXTRA_SPECIAL_RULE_CHANCE:
		return 0
	if count == 0:
		count = 1
	while count < capacity and rng.randf() < Difficulty.EXTRA_SPECIAL_RULE_CHANCE:
		count += 1
	return count


func _rule_count_milestone(rule_count: int) -> int:
	return Difficulty.special_rule_milestone(rule_count)


func _round_precedes_guaranteed_combo(round_number: int) -> bool:
	return get_guaranteed_rule_count(round_number + 1) > 0


func begin_round(round_number: int) -> RoundModifiers:
	await end_round()
	var locked_rule_ids := Debug.get_locked_special_rules()
	if locked_rule_ids.is_empty():
		var requested_count := 0
		if (
			_last_special_rule_round != round_number - 1
			and not _round_precedes_guaranteed_combo(round_number)
		):
			requested_count = roll_rule_count(round_number)
		elif get_guaranteed_rule_count(round_number) > 0:
			requested_count = get_guaranteed_rule_count(round_number)
		active_rules = select_special_rules(round_number, requested_count)
	else:
		active_rules = _select_locked_rules(locked_rule_ids, round_number)
	var bonus_manager := get_node_or_null("../BonusManager") as BonusManager
	var rule_breaker_used := false
	var rule_breaker_level := (
		bonus_manager.level(&"rule_breaker")
		if bonus_manager != null
		else 0
	)
	if (
		bonus_manager != null
		and rule_breaker_level > 0
		and (
			active_rules.size() > 1
			or (
				bonus_manager.rule_breaker_can_delete_last_rule()
				and active_rules.size() == 1
			)
		)
		and announcement != null
	):
		var removed_indices := await announcement.choose_rules_to_delete(
			active_rules,
			bonus_manager.rule_breaker_deletion_count(),
			bonus_manager.rule_breaker_can_delete_last_rule()
		)
		removed_indices.sort()
		removed_indices.reverse()
		for removed_index in removed_indices:
			if removed_index >= 0 and removed_index < active_rules.size():
				active_rules.remove_at(removed_index)
		rule_breaker_used = not removed_indices.is_empty()
	if not active_rules.is_empty():
		_last_special_rule_round = round_number
	modifiers = RoundModifiers.new()
	context = RoundContext.new(round_number, modifiers)
	context.game_manager = get_parent() as GameManager
	context.hand_manager = get_node_or_null("../HandManager") as HandManager
	context.pile_manager = get_node_or_null("../PileManager") as PileManager
	context.timer_manager = get_node_or_null("../TimerManager") as CountdownManager
	context.interface = get_parent() as Control
	context.rng = rng
	for rule in active_rules:
		rule.activate(context)
	var adaptation_intensity := (
		bonus_manager.adaptation_multiplier()
		if bonus_manager != null
		else 1.0
	)
	modifiers.special_rule_intensity_multiplier = adaptation_intensity
	if flashlight_overlay != null:
		# Set the adapted target before close_in() creates its tween. Changing
		# the property afterwards does not alter a target already captured by
		# Tween.tween_property().
		flashlight_overlay.flashlight_radius = (
			Difficulty.LIGHTS_OUT_RADIUS / adaptation_intensity
		)
		if modifiers.flashlight_enabled:
			flashlight_overlay.close_in()
		else:
			flashlight_overlay.visible = false
	if (
		not active_rules.is_empty()
		and announcement != null
		and not rule_breaker_used
	):
		rules_announcing.emit(active_rules)
		await announcement.show_rules(active_rules)
		rules_announcement_finished.emit()
	rules_selected.emit(active_rules)
	return modifiers


func _select_locked_rules(
	rule_ids: Array[StringName],
	_round_number: int
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
		# Debug locks intentionally bypass minimum rounds, required rules and
		# incompatibilities so problematic combinations can be tested directly.
		selected.append(candidate)
	return selected


func activate_board_effects(piles: Array[MemoryPile], round_number: int) -> void:
	context.piles.assign(piles)
	var bonus_manager := get_node_or_null("../BonusManager") as BonusManager
	var intensity := (
		bonus_manager.adaptation_multiplier()
		if bonus_manager != null
		else 1.0
	)
	if modifiers.moving_pile_pattern and moving_pile_pattern != null:
		moving_pile_pattern.start(piles, round_number, intensity)
	if modifiers.regeneration_enabled:
		var candidates: Array[MemoryPile] = []
		for pile in piles:
			if not pile.completed:
				candidates.append(pile)
		candidates.shuffle()
		var count := maxi(1, ceili(candidates.size() * Difficulty.REGENERATING_PILE_RATIO))
		for index in mini(count, candidates.size()):
			candidates[index].enable_regeneration(
				Difficulty.REGENERATION_DURATION / intensity
			)


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
	var movement_duration := (
		0.55 / modifiers.special_rule_intensity_multiplier
	)
	for index in moving.size():
		var tween: Tween = (
			moving[index].create_tween()
			.set_trans(Tween.TRANS_SINE)
			.set_ease(Tween.EASE_IN_OUT)
		)
		tween.tween_property(
			moving[index],
			"position",
			destinations[(index + 1) % moving.size()],
			movement_duration
		)
		tweens.append(tween)
	await tweens[0].finished


func end_round(piles_to_clean: Array[MemoryPile] = []) -> void:
	if moving_pile_pattern != null:
		await moving_pile_pattern.stop()
	for pile in piles_to_clean:
		if is_instance_valid(pile):
			pile.disable_regeneration()
	if flashlight_overlay != null and flashlight_overlay.visible:
		await flashlight_overlay.open_out()
	for index in range(active_rules.size() - 1, -1, -1):
		active_rules[index].deactivate(context)
	modifiers.reset()
	active_rules.clear()


func select_special_rules(round_number: int, requested_count: int) -> Array[SpecialRuleData]:
	var selected: Array[SpecialRuleData] = []
	var candidates: Array[SpecialRuleData] = []
	for rule in _rules:
		if (
			Difficulty.is_special_rule_enabled(rule.id)
			and round_number >= rule.minimum_round
		):
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
	round_number := 999
) -> bool:
	for required in candidate.required_rules:
		if not selected.any(func(rule: SpecialRuleData) -> bool: return rule.id == required):
			return false
	for rule in selected:
		if candidate.incompatible_rules.has(rule.id) or rule.incompatible_rules.has(candidate.id):
			return false
		if round_number < 25:
			var pair := [candidate.id, rule.id]
			if (
				pair.has(&"sudden_death")
				and (
					pair.has(&"sticky_fingers")
					or pair.has(&"floor_is_lava")
					or pair.has(&"lights_out")
				)
			):
				return false
	return true
