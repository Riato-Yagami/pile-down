class_name HandManager
extends Node

signal card_selected(card)
signal card_drag_started(card)
signal card_drag_released(card, release_position)
signal card_entered_screen(card)
signal card_forced_return_requested(card, reason)

@export var card_scene: PackedScene
var rng := RandomNumberGenerator.new()
var current_cards: Array[PlayingCard] = []
var value_font: Font
var value_font_size := 20


func _ready() -> void:
	rng.randomize()


func generate_hand(
	container: Control,
	hand_size: int,
	start_value: int,
	playable_values: Array[int],
	pile_up := false,
	hover_reveal := false,
	use_roman_numerals := false,
	animate_draw := true,
	clear_existing := true,
	enter_from_right := false,
	modifiers: RoundModifiers = null,
	joker_chance := 0.0,
	force_joker := false,
	lucky_hand_chance := 0.0,
	lucky_hand_level := 0,
	double_down_level := 0,
	deja_vu_level := 0,
	active_piles: Array[MemoryPile] = []
) -> void:
	if clear_existing:
		clear_hand(container, true)
	if playable_values.is_empty():
		return

	var existing_card_count := 0
	for existing in current_cards:
		if is_instance_valid(existing) and existing.visible:
			existing_card_count += 1
	var cards_to_create := maxi(hand_size - existing_card_count, 0)
	if cards_to_create == 0:
		return
	var should_create_joker := (
		force_joker
		or (joker_chance > 0.0 and rng.randf() < joker_chance)
	)
	var joker_position := (
		rng.randi_range(0, cards_to_create - 1)
		if should_create_joker
		else -1
	)
	var guaranteed_value := playable_values[rng.randi_range(0, playable_values.size() - 1)]
	var values: Array[int] = []
	for i in cards_to_create:
		values.append(rng.randi_range(1 if pile_up else 0, start_value if pile_up else start_value - 1))
	var regular_slots: Array[int] = []
	for index in cards_to_create:
		if index != joker_position:
			regular_slots.append(index)
	var lucky_hand_triggered := (
		lucky_hand_chance > 0.0
		and rng.randf() < lucky_hand_chance
	)
	var guaranteed_position := (
		(
			regular_slots[0]
			if lucky_hand_triggered
			else regular_slots[rng.randi_range(0, regular_slots.size() - 1)]
		)
		if not regular_slots.is_empty()
		else -1
	)
	if guaranteed_position >= 0:
		values[guaranteed_position] = guaranteed_value
	var protected_slots: Array[int] = []
	if joker_position >= 0:
		protected_slots.append(joker_position)
	if (
		guaranteed_position >= 0
		and lucky_hand_triggered
	):
		_apply_lucky_hand(
			values, playable_values, guaranteed_position, pile_up, start_value,
			lucky_hand_level, double_down_level, deja_vu_level,
			protected_slots, active_piles
		)
	for index in values.size():
		_create_card(
			container, values[index], index == joker_position,
			hover_reveal, use_roman_numerals,
			modifiers, animate_draw, enter_from_right
		)


func _apply_lucky_hand(
	values: Array[int],
	playable_values: Array[int],
	guaranteed_position: int,
	pile_up: bool,
	maximum_value: int,
	lucky_level: int,
	double_down_level: int,
	deja_vu_level: int,
	protected_slots: Array[int] = [],
	active_piles: Array[MemoryPile] = []
) -> void:
	if values.is_empty() or playable_values.is_empty():
		return
	var lucky_slots: Array[int] = []
	if not protected_slots.has(guaranteed_position):
		lucky_slots.append(guaranteed_position)
	for index in values.size():
		if index != guaranteed_position and not protected_slots.has(index):
			lucky_slots.append(index)
	var lucky_count := mini(clampi(lucky_level, 1, 3), lucky_slots.size())
	if lucky_count <= 0:
		return
	var advanced_pile := get_most_advanced_pile(active_piles, pile_up)
	var target := (
		advanced_pile.expected_value()
		if advanced_pile != null
		else get_most_advanced_value(playable_values, pile_up)
	)
	var plan: Array[int] = [target]
	if lucky_count >= 2:
		var chain_value := target + (1 if pile_up else -1)
		if (
			double_down_level > 0
			and chain_value >= (1 if pile_up else 0)
			and chain_value <= maximum_value
		):
			plan.append(chain_value)
		else:
			plan.append(_next_immediately_playable_value(
				playable_values, target, pile_up
			))
	if lucky_count >= 3:
		var second_chain_value := target + (2 if pile_up else -2)
		if (
			double_down_level >= 2
			and second_chain_value >= (1 if pile_up else 0)
			and second_chain_value <= maximum_value
		):
			plan.append(second_chain_value)
		else:
			plan.append(get_most_shared_expected_value(playable_values, pile_up))

	# Deja Vu needs one played card plus at most `level` automatic copies, and
	# never more cards than compatible piles waiting for that value.
	if deja_vu_level > 0 and lucky_count >= 2:
		var shared := get_most_shared_expected_value(playable_values, pile_up)
		var copy_count := mini(
			lucky_count,
			mini(playable_values.count(shared), deja_vu_level + 1)
		)
		if copy_count >= 2:
			for index in copy_count:
				plan[index] = shared
			for index in range(copy_count, lucky_count):
				if plan[index] == shared:
					plan[index] = _next_immediately_playable_value(
						playable_values, shared, pile_up
					)

	for index in lucky_count:
		values[lucky_slots[index]] = plan[index]


func _next_immediately_playable_value(
	playable_values: Array[int],
	target: int,
	pile_up: bool
) -> int:
	var ordered := playable_values.duplicate()
	ordered.sort()
	if pile_up:
		ordered.reverse()
	# The most advanced target is already present. Prefer a different expected
	# value, then fall back to a useful duplicate if every pile expects target.
	for value in ordered:
		if value != target:
			return value
	return target


func get_most_advanced_value(playable_values: Array[int], pile_up: bool) -> int:
	var result := playable_values[0]
	for value in playable_values:
		if (pile_up and value > result) or (not pile_up and value < result):
			result = value
	return result


func get_most_advanced_pile(
	active_piles: Array[MemoryPile],
	pile_up: bool
) -> MemoryPile:
	var result: MemoryPile
	for pile in active_piles:
		if not is_instance_valid(pile) or pile.completed or not pile.visible:
			continue
		if (
			result == null
			or (pile_up and pile.current_value > result.current_value)
			or (not pile_up and pile.current_value < result.current_value)
		):
			result = pile
	return result


func get_most_shared_expected_value(
	playable_values: Array[int],
	pile_up := false
) -> int:
	var counts: Dictionary = {}
	for value in playable_values:
		counts[value] = int(counts.get(value, 0)) + 1
	if playable_values.is_empty():
		return 0
	var maximum_count := 0
	var tied: Array[int] = []
	for value_variant in counts:
		var value := int(value_variant)
		var count := int(counts[value])
		if count > maximum_count:
			maximum_count = count
			tied.assign([value])
		elif count == maximum_count:
			tied.append(value)
	var advanced := get_most_advanced_value(playable_values, pile_up)
	if tied.has(advanced):
		return advanced
	return tied[rng.randi_range(0, tied.size() - 1)]


func _create_card(
	container: Control,
	value: int,
	joker: bool,
	hover_reveal: bool,
	use_roman_numerals: bool,
	modifiers: RoundModifiers,
	animate_draw: bool,
	enter_from_right: bool
) -> void:
	var card := card_scene.instantiate() as PlayingCard
	container.add_child(card)
	card.set_value_font(value_font, value_font_size)
	card.setup(value, true, hover_reveal, use_roman_numerals, modifiers)
	card.set_joker(joker)
	card.card_selected.connect(_on_card_selected)
	card.drag_started.connect(func(dragged_card: PlayingCard) -> void: card_drag_started.emit(dragged_card))
	card.drag_released.connect(
		func(dragged_card: PlayingCard, release_position: Vector2) -> void:
			card_drag_released.emit(dragged_card, release_position)
	)
	card.entrance_became_interactive.connect(
		func(entered_card: PlayingCard) -> void:
			card_entered_screen.emit(entered_card)
	)
	card.forced_return_requested.connect(
		func(forced_card: PlayingCard, reason: int) -> void:
			card_forced_return_requested.emit(forced_card, reason)
	)
	current_cards.append(card)
	if animate_draw:
		if enter_from_right:
			card.set_selectable(false)
			# The HBox needs one frame to assign the final slot before Card can
			# calculate its off-screen entrance offset. Hide it synchronously so
			# that slot is never rendered before the entrance starts.
			card.modulate.a = 0.0
			card.call_deferred("play_draw_from_right", (current_cards.size() - 1) * 0.045)
		else:
			card.call_deferred("play_draw", (current_cards.size() - 1) * 0.045)


func discard_hand(
	container: Control,
	exit_layer: Control = null,
	preserve_unused_jokers := true
) -> void:
	var cards_to_discard: Array[PlayingCard] = []
	var retained_jokers: Array[PlayingCard] = []
	for card in current_cards:
		if is_instance_valid(card) and card.visible:
			if (
				preserve_unused_jokers
				and card.is_joker
				and not card.placement_confirmed
			):
				card.finish_drag()
				card.reset_hand_pose()
				if card.get_parent() != container:
					var joker_global_position := card.global_position
					card.reparent(container, false)
					card.global_position = joker_global_position
				retained_jokers.append(card)
				continue
			card.disable_wandering()
			if exit_layer != null and card.get_parent() != exit_layer:
				var previous_global_position := card.global_position
				card.reparent(exit_layer, false)
				card.global_position = previous_global_position
			cards_to_discard.append(card)
	current_cards.assign(retained_jokers)
	for index in retained_jokers.size():
		container.move_child(retained_jokers[index], index)
	if cards_to_discard.is_empty():
		return

	var longest_duration := 0.0
	for index in cards_to_discard.size():
		var card := cards_to_discard[index]
		card.finish_drag()
		card.set_selectable(false)
		var delay := index * 0.04
		if card.free_range_card:
			longest_duration = maxf(
				longest_duration,
				card.play_wandering_exit(card.get_viewport_rect().size.x, delay)
			)
			continue
		longest_duration = delay + 0.26
		var tween := card.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_interval(delay)
		tween.tween_property(
			card,
			"global_position:y",
			card.get_viewport_rect().size.y + card.size.y + 12.0,
			0.26
		)
		tween.parallel().tween_property(card, "modulate:a", 0.0, 0.2)
	await get_tree().create_timer(longest_duration).timeout
	for card in cards_to_discard:
		if is_instance_valid(card):
			card.queue_free()


func clear_hand(container: Control, preserve_unused_jokers := false) -> void:
	var retained_jokers: Array[PlayingCard] = []
	if preserve_unused_jokers:
		for card in current_cards:
			if (
				is_instance_valid(card)
				and card.is_joker
				and card.visible
				and not card.placement_confirmed
			):
				card.finish_drag()
				card.finish_entrance_immediately()
				card.reset_hand_pose()
				if card.get_parent() != container:
					var previous_global_position := card.global_position
					card.reparent(container, false)
					card.global_position = previous_global_position
				retained_jokers.append(card)
	current_cards.assign(retained_jokers)
	for child in container.get_children():
		if not retained_jokers.has(child):
			child.queue_free()
	for index in retained_jokers.size():
		container.move_child(retained_jokers[index], index)
	if container is Container:
		(container as Container).queue_sort()


func lock_hand() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selectable(false)


func unlock_hand() -> void:
	for card in current_cards:
		if (
			is_instance_valid(card)
			and card.visible
			and not card._entrance_animation_running
		):
			card.set_selectable(true)


func finish_all_card_entrances(except_card: PlayingCard = null) -> void:
	for card in current_cards:
		if is_instance_valid(card) and card != except_card:
			card.finish_entrance_immediately()


func lock_all_cards_except(active_card: PlayingCard) -> void:
	for card in current_cards:
		if is_instance_valid(card) and card != active_card:
			card.set_selectable(false)


func clear_selection() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selected_visual(false)


func cancel_all_drags() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.finish_drag()


func stop_all_card_timers() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.cancel_drag_timers()


func reveal_all_hand_cards() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.reveal_for_cleanup()


func refresh_all_card_themes(colorblind_enabled: bool) -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_colorblind_enabled(colorblind_enabled)


func select_card(selected_card: PlayingCard) -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selected_visual(card == selected_card)


func active_cards() -> Array[PlayingCard]:
	var result: Array[PlayingCard] = []
	for card in current_cards:
		if is_instance_valid(card) and card.visible and not card.placement_confirmed:
			result.append(card)
	return result


func find_card_with_value(value: int, origin: Vector2 = Vector2.INF) -> PlayingCard:
	var matches := find_cards_with_value(value)
	if matches.is_empty():
		return null
	if origin != Vector2.INF:
		matches.sort_custom(
			func(first: PlayingCard, second: PlayingCard) -> bool:
				return first.global_position.distance_squared_to(origin) < second.global_position.distance_squared_to(origin)
		)
	return matches.front()


func find_cards_with_value(value: int) -> Array[PlayingCard]:
	var matches: Array[PlayingCard] = []
	for card in active_cards():
		if not card.is_joker and card.card_value == value:
			matches.append(card)
	return matches


func forget_card(card: PlayingCard) -> void:
	current_cards.erase(card)


func _on_card_selected(card: PlayingCard) -> void:
	select_card(card)
	card_selected.emit(card)
