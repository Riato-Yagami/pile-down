class_name BonusManager
extends Node

signal bonuses_changed()
signal bonus_selected(bonus_id: StringName)
signal bonuses_seen(bonus_ids: Array[StringName])

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const Debug := preload("res://resources/scripts/settings/debug.gd")
const ACTIVE_BADGE_SCENE := preload(
	"res://resources/scenes/bonuses/ActiveBonusBadge.tscn"
)

@onready var selection: BonusSelection = %BonusSelection
@onready var active_bar: GridContainer = %ActiveBonusBar
@onready var active_description: PanelContainer = %ActiveBonusDescription
@onready var active_description_text: Label = %ActiveBonusDescriptionText

var rng := RandomNumberGenerator.new()
var definitions: Array[BonusData] = BonusRegistry.create_all()
var active: Dictionary = {}
var completed_rounds := 0
var hands_started_this_round := 0
var hands_since_quick_peek := 0
var redraws_left := 0
var safety_net_available := false
var clean_slate_uses_left := 0
var banked_time := 0.0
var force_next_joker := false
var _debug_locked_bonus_ids: Array[StringName] = []
var _debug_forced_activation_bonus_ids: Array[StringName] = []
var disabled_bonus_ids: Array[StringName] = []


func _ready() -> void:
	rng.randomize()
	active_description.visible = false


func begin_run() -> void:
	active.clear()
	completed_rounds = 0
	banked_time = 0.0
	force_next_joker = false
	_apply_debug_locked_bonuses()
	_refresh_bar()


func end_run() -> void:
	selection.cancel()
	active.clear()
	completed_rounds = 0
	banked_time = 0.0
	force_next_joker = false
	active_description.visible = false
	_refresh_bar()


func grant_starting_bonuses(configured_bonuses: Dictionary) -> void:
	for id_value in configured_bonuses:
		var id := StringName(id_value)
		if disabled_bonus_ids.has(id):
			push_warning("Starting bonus '%s' is also disabled; ignoring it." % id)
			continue
		var data := _find_definition(id)
		if data == null:
			push_warning("Unknown starting bonus id '%s'." % id)
			continue
		var requested_level := int(configured_bonuses[id_value])
		if requested_level <= 0:
			push_warning("Starting bonus '%s' must have a positive level." % id)
			continue
		var owned := ActiveBonus.new(data)
		owned.level = clampi(requested_level, 1, data.max_level)
		active[id] = owned
		if id == &"wild_card":
			force_next_joker = true
	_refresh_bar()
	bonuses_changed.emit()


func begin_round() -> void:
	hands_started_this_round = 0
	hands_since_quick_peek = 0
	safety_net_available = has_bonus(&"safety_net")
	var redraw_level := level(&"redraw")
	redraws_left = Difficulty.REDRAW_COUNTS[redraw_level]
	var clean_level := level(&"clean_slate")
	clean_slate_uses_left = Difficulty.CLEAN_SLATE_USES[clean_level]


func offer_if_due(completed_round_number: int) -> bool:
	completed_rounds = completed_round_number
	if completed_round_number % Difficulty.BONUS_INTERVAL != 0:
		return false
	var choices := generate_choices(completed_round_number + 1)
	if choices.size() < Difficulty.MIN_BONUS_CHOICES_TO_OFFER:
		return false
	var levels: Array[int] = []
	for choice in choices:
		levels.append(level(choice.id) + 1)
	_emit_bonuses_seen(choices)
	active_bar.visible = false
	var chosen_index := await selection.present(choices, levels)
	if chosen_index == BonusSelection.SKIPPED_INDEX:
		active_bar.visible = not active.is_empty()
		return true
	if chosen_index < 0 or chosen_index >= choices.size():
		active_bar.visible = not active.is_empty()
		return false
	_add_or_upgrade(choices[chosen_index])
	active_bar.visible = not active.is_empty()
	return true


func offer_bonus_choice(round_number: int, _choice_index := 0) -> bool:
	var choices := generate_choices(round_number)
	if choices.size() < Difficulty.MIN_BONUS_CHOICES_TO_OFFER:
		return false
	var levels: Array[int] = []
	for choice in choices:
		levels.append(level(choice.id) + 1)
	_emit_bonuses_seen(choices)
	active_bar.visible = false
	var chosen_index := await selection.present(choices, levels)
	if chosen_index == BonusSelection.SKIPPED_INDEX:
		active_bar.visible = not active.is_empty()
		return true
	if chosen_index < 0 or chosen_index >= choices.size():
		active_bar.visible = not active.is_empty()
		return false
	_add_or_upgrade(choices[chosen_index])
	active_bar.visible = not active.is_empty()
	return true


func _emit_bonuses_seen(choices: Array[BonusData]) -> void:
	var ids: Array[StringName] = []
	for choice in choices:
		ids.append(choice.id)
	bonuses_seen.emit(ids)


func generate_choices(round_number: int) -> Array[BonusData]:
	var pool: Array[BonusData] = []
	for data in definitions:
		if disabled_bonus_ids.has(data.id):
			continue
		if not Difficulty.is_bonus_enabled(data.id):
			continue
		if _debug_locked_bonus_ids.has(data.id):
			continue
		if round_number < data.minimum_round or level(data.id) >= data.max_level:
			continue
		if active.size() >= Difficulty.MAX_ACTIVE_BONUS_TYPES and not has_bonus(data.id):
			continue
		pool.append(data)
	if pool.size() < Difficulty.MIN_BONUS_CHOICES_TO_OFFER:
		return pool
	var target_count := mini(
		maxi(
			Difficulty.BONUS_CHOICE_COUNT,
			Difficulty.MIN_BONUS_CHOICES_TO_OFFER
		),
		pool.size()
	)
	var selected: Array[BonusData] = []
	while selected.size() < target_count:
		var candidates: Array[BonusData] = []
		for candidate in pool:
			if _contains_bonus(selected, candidate.id):
				continue
			if not _contains_category(selected, candidate.category):
				candidates.append(candidate)
		if candidates.is_empty():
			for candidate in pool:
				if not _contains_bonus(selected, candidate.id):
					candidates.append(candidate)
		if candidates.is_empty():
			break
		selected.append(_weighted_pick(candidates))
	return selected


func _contains_bonus(bonuses: Array[BonusData], id: StringName) -> bool:
	for bonus in bonuses:
		if bonus.id == id:
			return true
	return false


func _contains_category(
	bonuses: Array[BonusData],
	category: int
) -> bool:
	for bonus in bonuses:
		if bonus.category == category:
			return true
	return false


func _apply_debug_locked_bonuses() -> void:
	_debug_locked_bonus_ids.clear()
	_debug_forced_activation_bonus_ids.clear()
	var locked := Debug.get_locked_bonuses()
	for locked_id_value in locked:
		var locked_id := StringName(locked_id_value)
		if disabled_bonus_ids.has(locked_id):
			continue
		var data := _find_definition(locked_id)
		if data == null:
			push_warning("Bonus debug lock: unknown bonus id '%s'." % locked_id)
			continue
		var configured_level := int(locked[locked_id_value])
		if configured_level == 0:
			push_warning(
				"Bonus debug lock: level for '%s' cannot be zero." % locked_id
			)
			continue
		var requested_level := absi(configured_level)
		var owned := ActiveBonus.new(data)
		owned.level = clampi(requested_level, 1, data.max_level)
		active[locked_id] = owned
		_debug_locked_bonus_ids.append(locked_id)
		if configured_level < 0:
			_debug_forced_activation_bonus_ids.append(locked_id)
		if locked_id == &"wild_card":
			force_next_joker = true


func _find_definition(id: StringName) -> BonusData:
	for data in definitions:
		if data.id == id:
			return data
	return null


func _weighted_pick(pool: Array[BonusData]) -> BonusData:
	var total := 0.0
	for data in pool:
		total += data.weight
	var roll := rng.randf_range(0.0, total)
	for data in pool:
		roll -= data.weight
		if roll <= 0.0:
			return data
	return pool.back()


func _add_or_upgrade(data: BonusData) -> void:
	if active.has(data.id):
		var owned := active[data.id] as ActiveBonus
		owned.level = mini(owned.level + 1, data.max_level)
	else:
		active[data.id] = ActiveBonus.new(data)
		if data.id == &"wild_card":
			force_next_joker = true
	_refresh_bar()
	bonuses_changed.emit()
	bonus_selected.emit(data.id)


func has_bonus(id: StringName) -> bool:
	return active.has(id)


func level(id: StringName) -> int:
	return (active[id] as ActiveBonus).level if active.has(id) else 0


func active_levels() -> Dictionary:
	var result: Dictionary = {}
	for id: StringName in active.keys():
		result[id] = (active[id] as ActiveBonus).level
	return result


func next_hand_time(base_time: float) -> float:
	hands_started_this_round += 1
	var extra := banked_time
	banked_time = 0.0
	var warmup := level(&"slow_start")
	if warmup > 0:
		var tier := int(
			(hands_started_this_round - 1)
			/ Difficulty.WARM_UP_HANDS_PER_TIER
		)
		extra += maxf(float(warmup - tier), 0.0)
	return base_time + extra


func should_trigger_quick_peek() -> bool:
	var quick_peek_level := level(&"quick_peek")
	if quick_peek_level <= 0:
		return false
	hands_since_quick_peek += 1
	var interval: int = Difficulty.QUICK_PEEK_HAND_INTERVALS[quick_peek_level - 1]
	if hands_since_quick_peek < interval:
		return false
	hands_since_quick_peek = 0
	return true


func quick_peek_duration() -> float:
	var quick_peek_level := level(&"quick_peek")
	if quick_peek_level <= 0:
		return 0.0
	return Difficulty.QUICK_PEEK_DURATIONS[quick_peek_level - 1]


func bank_remaining_time(time_left: float) -> void:
	banked_time = minf(
		time_left * Difficulty.TIME_BANK_RATES[level(&"time_bank")],
		Difficulty.TIME_BANK_MAXIMUM
	)


func shared_clock_time_bonus(base_hand_time: float) -> float:
	return minf(
		base_hand_time * Difficulty.TIME_BANK_RATES[level(&"time_bank")],
		Difficulty.TIME_BANK_MAXIMUM
	)


func joker_chance() -> float:
	if _debug_forced_activation_bonus_ids.has(&"wild_card"):
		return 1.0
	return Difficulty.WILD_CARD_CHANCES[level(&"wild_card")]


func lucky_hand_chance() -> float:
	if _debug_forced_activation_bonus_ids.has(&"lucky_hand"):
		return 1.0
	return Difficulty.LUCKY_HAND_CHANCES[level(&"lucky_hand")]


func consume_forced_joker() -> bool:
	if force_next_joker:
		force_next_joker = false
		return true
	return false


func consume_safety_net() -> bool:
	if not safety_net_available:
		return false
	safety_net_available = false
	_refresh_bar()
	return true


func consume_redraw() -> bool:
	if redraws_left <= 0:
		return false
	redraws_left -= 1
	return true


func spare_lives() -> int:
	return Difficulty.SPARE_LIFE_COUNTS[level(&"spare_life")]


func recover_on_completed_pile(current: int, maximum: int) -> int:
	if clean_slate_uses_left <= 0:
		return current
	clean_slate_uses_left -= 1
	if level(&"clean_slate") >= Difficulty.CLEAN_SLATE_FULL_RESTORE_LEVEL:
		return maximum
	return mini(current + 1, maximum)


func adaptation_multiplier() -> float:
	return Difficulty.ADAPTATION_MULTIPLIERS[level(&"adaptation")]


func rule_breaker_deletion_count() -> int:
	return Difficulty.RULE_BREAKER_DELETION_COUNTS[level(&"rule_breaker")]


func rule_breaker_can_delete_last_rule() -> bool:
	return (
		level(&"rule_breaker")
		>= Difficulty.RULE_BREAKER_DELETE_LAST_MINIMUM_LEVEL
	)


func choose_rule_to_break(rules: Array[SpecialRuleData]) -> int:
	if not has_bonus(&"rule_breaker") or rules.size() < 2:
		return -1
	active_bar.visible = false
	var chosen_index := await selection.present_rules(rules)
	active_bar.visible = not active.is_empty()
	return chosen_index if chosen_index >= 0 and chosen_index < rules.size() else -1


func _refresh_bar() -> void:
	if active_bar == null:
		return
	var unique_acronyms := ActiveBonusBadge.build_unique_acronyms(definitions)
	active_bar.visible = not active.is_empty()
	for child in active_bar.get_children():
		child.queue_free()
	for owned_value in active.values():
		var owned := owned_value as ActiveBonus
		var badge := ACTIVE_BADGE_SCENE.instantiate() as ActiveBonusBadge
		badge.setup(
			owned.data,
			owned.level,
			owned.data.id == &"safety_net" and not safety_net_available,
			unique_acronyms.get(owned.data.id, "")
		)
		badge.description_requested.connect(_show_active_description.bind(badge))
		badge.description_hidden.connect(_hide_active_description.bind(badge))
		active_bar.add_child(badge)


func _show_active_description(description: String, badge: ActiveBonusBadge) -> void:
	active_description.set_meta(&"source_badge", badge)
	active_description_text.text = description
	active_description.modulate.a = 0.0
	active_description.visible = true
	var desired_size := _size_active_description()
	await get_tree().process_frame
	if active_description.get_meta(&"source_badge", null) != badge:
		return
	# The old editor-layout minimum is now invalidated, so the panel can shrink.
	active_description.size = desired_size
	_position_active_description(badge)
	active_description.modulate.a = 1.0


func _size_active_description() -> Vector2:
	var viewport_size := active_description.get_viewport_rect().size
	var font := active_description_text.get_theme_font(&"font")
	var font_size := active_description_text.get_theme_font_size(&"font_size")
	var text_width := font.get_string_size(
		active_description_text.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x
	var box_width := clampf(text_width + 20.0, 80.0, viewport_size.x * 0.5)
	var panel_style := active_description.get_theme_stylebox(&"panel")
	var panel_margins := panel_style.get_minimum_size()
	var content_width := maxf(box_width - panel_margins.x, 1.0)
	var wrapped_text_size := font.get_multiline_string_size(
		active_description_text.text,
		HORIZONTAL_ALIGNMENT_CENTER,
		content_width,
		font_size
	)
	var box_height := maxf(wrapped_text_size.y + panel_margins.y, 24.0)
	active_description.set_anchor(SIDE_LEFT, 0.0)
	active_description.set_anchor(SIDE_TOP, 0.0)
	active_description.set_anchor(SIDE_RIGHT, 0.0)
	active_description.set_anchor(SIDE_BOTTOM, 0.0)
	active_description_text.custom_minimum_size = Vector2(
		content_width,
		wrapped_text_size.y
	)
	var desired_size := Vector2(box_width, box_height)
	active_description.size = desired_size
	return desired_size


func _position_active_description(badge: ActiveBonusBadge) -> void:
	var viewport_size := active_description.get_viewport_rect().size
	var box_size := active_description.size
	var badge_rect := badge.get_global_rect()
	var desired_x := badge_rect.get_center().x - box_size.x * 0.5
	var box_x := clampf(desired_x, 4.0, viewport_size.x - box_size.x - 4.0)
	var box_y := maxf(badge_rect.position.y - box_size.y - 4.0, 4.0)
	active_description.global_position = Vector2(box_x, box_y)


func _hide_active_description(badge: ActiveBonusBadge) -> void:
	if active_description.get_meta(&"source_badge", null) != badge:
		return
	active_description.visible = false
	active_description.modulate.a = 1.0
	active_description.remove_meta(&"source_badge")
