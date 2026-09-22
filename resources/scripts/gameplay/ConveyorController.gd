class_name ConveyorController
extends RefCounted

## Conveyor card generation and movement using the existing hand RNG stream.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func start_conveyor(host: GameManager) -> void:
	host._conveyor_active = true
	host._conveyor_spawn_distance = 0.0
	host._conveyor_unplayable_spawns = 0
	host._lucky_conveyor_queue.clear()
	# Cards enter directly from the right in the hand lane, then cross over the
	# life counter before leaving on the left.
	host._conveyor_left_to_right = false
	host._spawn_conveyor_card()


static func process_conveyor(host: GameManager, delta: float) -> void:
	if not host._conveyor_active or host.overlay.visible or host.splash.visible:
		return
	var speed := host.Difficulty.get_conveyor_speed(
		host._progression_round(),
		host.challenge_modifiers.conveyor_speed
		if host.challenge_modifiers.conveyor_speed >= 0.0
		else host.Difficulty.CONVEYOR_BASE_SPEED
	)
	var direction := 1.0 if host._conveyor_left_to_right else -1.0
	for card in host.hand_manager.current_cards.duplicate():
		if not is_instance_valid(card) or not card.has_meta(&"conveyor_card"):
			continue
		if (
			card == host.selected_card
			or card.dragging
			or card.drag_state != PlayingCard.DragState.IDLE
		):
			continue
		if card.has_meta(&"conveyor_exiting_down"):
			card.global_position.y += (
				speed * host.Difficulty.CONVEYOR_EXIT_SPEED_MULTIPLIER * delta
			)
		else:
			card.global_position.x += speed * direction * delta
			if (
				not host._conveyor_left_to_right
				and card.get_global_rect().get_center().x
				<= host.hand_tray.conveyor_turn_point_x
			):
				card.global_position.x = (
					host.hand_tray.conveyor_turn_point_x - card.size.x * 0.5
				)
				card.set_meta(&"conveyor_exiting_down", true)
		var outside: bool = (
			card.global_position.y > host.get_viewport_rect().size.y + card.size.y
			if card.has_meta(&"conveyor_exiting_down")
			else card.global_position.x > host.get_viewport_rect().size.x + card.size.x
		)
		if outside:
			host.hand_manager.forget_card(card)
			card.queue_free()
	host._conveyor_spawn_distance += speed * delta
	while host._conveyor_spawn_distance >= host.Difficulty.CONVEYOR_MIN_CARD_SPACING:
		host._spawn_conveyor_card()
		host._conveyor_spawn_distance -= host.Difficulty.CONVEYOR_MIN_CARD_SPACING
	host._refresh_conveyor_pointer_hover()


static func refresh_conveyor_pointer_hover(host: GameManager) -> void:
	var card_under_pointer := false
	for card in host.hand_manager.current_cards:
		if (
			is_instance_valid(card)
			and card.has_meta(&"conveyor_card")
			and card.refresh_pointer_hover()
		):
			card_under_pointer = true
	if host.hand_tray.get_global_rect().has_point(host.get_global_mouse_position()):
		DisplayServer.cursor_set_shape(
			DisplayServer.CURSOR_POINTING_HAND
			if card_under_pointer
			else DisplayServer.CURSOR_ARROW
		)


static func spawn_conveyor_card(host: GameManager) -> PlayingCard:
	var playable_values := host._playable_values_with_duplicates()
	if playable_values.is_empty():
		return null
	var force_playable := (
		host._conveyor_unplayable_spawns
		>= (
			host.challenge_modifiers.conveyor_guaranteed_interval
			if host.challenge_modifiers.conveyor_guaranteed_interval > 0
			else host.Difficulty.CONVEYOR_MAX_UNPLAYABLE_SPAWNS
		)
	)
	var useful_card_visible := false
	for existing_card in host.hand_manager.active_cards():
		if (
			existing_card.has_meta(&"conveyor_card")
			and not existing_card.has_meta(&"conveyor_exiting_down")
			and not existing_card.dragging
			and playable_values.has(existing_card.card_value)
		):
			useful_card_visible = true
			break
	# Random junk is allowed only while a solution is already on screen. The
	# player can miss that card, but can never lose because no solution spawned.
	force_playable = force_playable or not useful_card_visible
	var lucky := (
		host.bonus_manager.lucky_hand_chance() > 0.0
		and host.hands_rng.randf() < host.bonus_manager.lucky_hand_chance()
	)
	var value := host.hands_rng.randi_range(
		1 if host.round_modifiers.stack_direction == RoundModifiers.StackDirection.UP else 0,
		host.start_value if host.round_modifiers.stack_direction == RoundModifiers.StackDirection.UP else host.start_value - 1
	)
	var spawn_high_tile := (
		not force_playable
		and not lucky
		and host.round_modifiers.stack_direction == RoundModifiers.StackDirection.DOWN
		and host.start_value < host.Difficulty.MAX_CARD_VALUE
		and host.hands_rng.randf() < host.Difficulty.CONVEYOR_HIGH_TILE_CHANCE
	)
	if spawn_high_tile:
		value = host.hands_rng.randi_range(host.start_value + 1, host.Difficulty.MAX_CARD_VALUE)
	if lucky and host._lucky_conveyor_queue.is_empty():
		var lucky_value := host.hand_manager.get_most_advanced_value(
			playable_values,
			host.round_modifiers.stack_direction == RoundModifiers.StackDirection.UP
		)
		host._lucky_conveyor_queue.append(lucky_value)
		for copy_index in mini(
			host.bonus_manager.level(&"deja_vu"),
			maxi(playable_values.count(lucky_value) - 1, 0)
		):
			host._lucky_conveyor_queue.append(lucky_value)
		var step := (
			1
			if host.round_modifiers.stack_direction == RoundModifiers.StackDirection.UP
			else -1
		)
		for chain_index in host.bonus_manager.level(&"double_down"):
			var chain_value := lucky_value + step * (chain_index + 1)
			if chain_value >= 0 and chain_value <= host.start_value:
				host._lucky_conveyor_queue.append(chain_value)
	if not host._lucky_conveyor_queue.is_empty():
		value = host._lucky_conveyor_queue.pop_front()
	elif force_playable:
		value = host.hand_manager.get_most_advanced_value(
			playable_values,
			host.round_modifiers.stack_direction == RoundModifiers.StackDirection.UP
		)
	if playable_values.has(value):
		host._conveyor_unplayable_spawns = 0
	else:
		host._conveyor_unplayable_spawns += 1
	var card := host.hand_manager._create_card(
		host.drag_layer,
		value,
		false,
		host.round_modifiers.hover_reveal_enabled,
		host.round_modifiers.roman_numerals_enabled,
		host.round_modifiers,
		false,
		false
	)
	card.set_meta(&"conveyor_card", true)
	host._return_card_to_conveyor(card)
	return card


static func return_card_to_conveyor(host: GameManager, card: PlayingCard) -> void:
	if not is_instance_valid(card):
		return
	if card.get_parent() != host.drag_layer:
		card.reparent(host.drag_layer, false)
	var tray_rect := host.hand_tray.get_global_rect()
	# Spawn the whole tile beyond the right edge. It only becomes visible after
	# the belt has physically carried it onto the screen.
	var entry_x := host.get_viewport_rect().size.x + 2.0
	for other in host.hand_manager.current_cards:
		if (
			is_instance_valid(other)
			and other != card
			and other.has_meta(&"conveyor_card")
			and absf(other.global_position.x - entry_x)
			< host.Difficulty.CONVEYOR_MIN_CARD_SPACING
		):
			entry_x += (
				-host.Difficulty.CONVEYOR_MIN_CARD_SPACING
				if host._conveyor_left_to_right
				else host.Difficulty.CONVEYOR_MIN_CARD_SPACING
			)
	card.global_position = Vector2(
		entry_x,
		tray_rect.get_center().y
		+ host.Difficulty.CONVEYOR_CARD_VERTICAL_OFFSET
		- card.size.y * 0.5
	)
	card.set_meta(&"conveyor_card", true)
	card.remove_meta(&"conveyor_exiting_down")


static func configure_challenge_hand_tray(host: GameManager) -> void:
	host.hand_tray.set_conveyor_enabled(host.challenge_modifiers.conveyor_hand)


static func discard_rejected_conveyor_card(host: GameManager, card: PlayingCard) -> void:
	card.finish_drag()
	card.end_commit()
	card.set_selectable(false)
	host._clear_drag_placeholder()
	var tween := (
		card.create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN)
		.set_parallel()
	)
	tween.tween_property(card, "global_position:y", card.global_position.y + 20.0, 0.24)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_property(card, "scale", Vector2(0.72, 0.72), 0.24)
	tween.tween_property(card, "rotation", -0.12, 0.24)
	await tween.finished
	host.hand_manager.forget_card(card)
	card.queue_free()
