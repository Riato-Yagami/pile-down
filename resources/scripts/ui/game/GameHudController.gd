class_name GameHudController
extends RefCounted

## Clock feedback, run timing and gameplay visual feedback.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func on_time_updated(host: GameManager, time_left: float) -> void:
	var displayed_second := ceili(time_left)
	var formatted_time := RoundModifiers.format_value(
		displayed_second,
		host.round_modifiers.roman_numerals_enabled
	)
	host.timer_label.text = (
		str(ceili(time_left))
		if host.challenge_modifiers.shared_round_clock
		else formatted_time
	)
	host.timer_ring.set_ratio(host.timer_manager.ratio())
	if (
		not host._timer_display_hidden
		and time_left > 2.0
		and displayed_second != host._last_clock_second
	):
		host._last_clock_second = displayed_second
		host.soft_audio.play_clock_tick()
	elif time_left <= 2.0 and (not host._timer_display_hidden or time_left <= 1.0):
		while (
			host._urgent_tick_index < host.URGENT_TICK_THRESHOLDS.size()
			and time_left <= host.URGENT_TICK_THRESHOLDS[host._urgent_tick_index]
		):
			var threshold := host.URGENT_TICK_THRESHOLDS[host._urgent_tick_index]
			var urgency := 1.0 - threshold / 2.0
			host.soft_audio.play_clock_tick(urgency)
			host._flash_clock_tick(urgency)
			host._urgent_tick_index += 1


static func on_timer_visibility_requested(host: GameManager, visible: bool) -> void:
	var was_hidden := host._timer_display_hidden
	host._timer_display_hidden = not visible
	if host._timer_visibility_tween != null and host._timer_visibility_tween.is_valid():
		host._timer_visibility_tween.kill()
	if not visible:
		if was_hidden:
			return
		host.timer_ring.visible = true
		host._timer_visibility_tween = host.create_tween().set_parallel()
		host._timer_visibility_tween.set_trans(Tween.TRANS_QUAD)
		host._timer_visibility_tween.set_ease(Tween.EASE_IN)
		host._timer_visibility_tween.tween_property(host.timer_ring, "modulate:a", 0.0, 0.15)
		host._timer_visibility_tween.tween_property(
			host.timer_ring,
			"scale",
			Vector2(0.9, 0.9),
			0.15
		)
		host._timer_visibility_tween.chain().tween_callback(func() -> void:
			if host._timer_display_hidden:
				host.timer_ring.visible = false
		)
		return
	host.timer_ring.visible = true
	if not was_hidden:
		host.timer_ring.scale = Vector2.ONE
		host.timer_ring.modulate.a = 1.0
		return
	host.timer_ring.scale = Vector2(0.9, 0.9)
	host.timer_ring.modulate.a = 0.0
	host._timer_visibility_tween = host.create_tween().set_parallel()
	host._timer_visibility_tween.set_trans(Tween.TRANS_QUAD)
	host._timer_visibility_tween.set_ease(Tween.EASE_OUT)
	host._timer_visibility_tween.tween_property(host.timer_ring, "modulate:a", 1.0, 0.18)
	host._timer_visibility_tween.tween_property(host.timer_ring, "scale", Vector2.ONE, 0.18)


static func flash_clock_tick(host: GameManager, urgency: float) -> void:
	if host._clock_flash_tween != null and host._clock_flash_tween.is_valid():
		host._clock_flash_tween.kill()
	var red_strength := lerpf(0.55, 0.9, clampf(urgency, 0.0, 1.0))
	host.timer_ring.flash_strength = red_strength
	host._clock_flash_tween = host.create_tween()
	host._clock_flash_tween.tween_property(
		host.timer_ring,
		"flash_strength",
		0.0,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func update_hud(host: GameManager) -> void:
	var displayed_round := host.round_number
	if host.game_mode == host.GameMode.CHECKPOINT and not host.checkpoint_uses_endless_progression:
		displayed_round = maxi(host.Difficulty.TOTAL_ROUNDS - host.round_number + 1, 0)
	host.round_label.text = RoundModifiers.format_value(
		displayed_round,
		host.round_modifiers.roman_numerals_enabled
	)
	host.mistakes_dots.set_remaining(host.mistakes_left)


static func total_time_milliseconds(host: GameManager) -> int:
	var paused := host.run_paused_msec
	if host.run_pause_started_msec >= 0:
		paused += Time.get_ticks_msec() - host.run_pause_started_msec
	return maxi(Time.get_ticks_msec() - host.game_started_msec - paused, 0)


static func pause_run_time(host: GameManager) -> void:
	if host.run_pause_started_msec < 0:
		host.run_pause_started_msec = Time.get_ticks_msec()


static func resume_run_time(host: GameManager) -> void:
	if host.run_pause_started_msec < 0:
		return
	host.run_paused_msec += Time.get_ticks_msec() - host.run_pause_started_msec
	host.run_pause_started_msec = -1


static func format_duration(host: GameManager, total_msec: int) -> String:
	var milliseconds := total_msec % 1000
	var total_seconds := total_msec / 1000
	var seconds := total_seconds % 60
	var total_minutes := total_seconds / 60
	var minutes := total_minutes % 60
	var hours := total_minutes / 60
	var parts := PackedStringArray()
	if hours > 0:
		parts.append("%d h" % hours)
	if total_minutes > 0:
		parts.append("%d min" % minutes)
	parts.append("%d s" % seconds)
	parts.append("%03d ms" % milliseconds)
	return " ".join(parts)


static func emit_motion_dust(host: GameManager, delta: float) -> void:
	if not is_instance_valid(host.dust_pool) or delta <= 0.0:
		return
	var moving_items: Array[Dictionary] = []
	if host.selected_card != null and is_instance_valid(host.selected_card) and host.selected_card.dragging:
		moving_items.append({
			"control": host.selected_card,
			"impulse": host.dust_dragged_tile_influence,
		})
		for companion in host.drag_companions:
			if is_instance_valid(companion):
				moving_items.append({
					"control": companion,
					"impulse": host.dust_dragged_tile_influence * 0.42,
				})
	if host.round_modifiers.moving_pile_pattern:
		for pile in host.piles:
			if is_instance_valid(pile) and pile.visible and not pile.completed:
				moving_items.append({
					"control": pile,
					"impulse": host.dust_automatic_tile_influence,
				})
	elif host.moving_pile != null and is_instance_valid(host.moving_pile):
		moving_items.append({
			"control": host.moving_pile,
			"impulse": host.dust_dragged_tile_influence,
		})
	var active_ids: Array[int] = []
	for item in moving_items:
		var control := item["control"] as Control
		var center := control.get_global_rect().abs().get_center()
		var instance_id := control.get_instance_id()
		active_ids.append(instance_id)
		if host._dust_previous_positions.has(instance_id):
			var previous := host._dust_previous_positions[instance_id] as Vector2
			if previous.distance_squared_to(center) >= 4.0:
				host.dust_pool.emit_motion(
					center,
					(center - previous) / delta,
					float(item["impulse"])
				)
				host.background_effects.emit_motion(
					center,
					(center - previous) / delta,
					float(item["impulse"])
				)
		host._dust_previous_positions[instance_id] = center
	for tracked_id in host._dust_previous_positions.keys():
		if not active_ids.has(int(tracked_id)):
			host._dust_previous_positions.erase(tracked_id)


static func update_tile_background_weight(host: GameManager) -> void:
	if not is_instance_valid(host.background_effects):
		return
	var dragged_tile: Control = null
	if host.selected_card != null and is_instance_valid(host.selected_card) and host.selected_card.dragging:
		dragged_tile = host.selected_card
	elif host.moving_pile != null and is_instance_valid(host.moving_pile):
		dragged_tile = host.moving_pile
	var effect: BackgroundEffects = host.background_effects
	effect.begin_tile_weights()
	for pile in host.piles:
		if is_instance_valid(pile) and pile.visible:
			effect.add_tile_weight(
				pile, effect.pile_weight_multiplier * pile.background_weight,
				pile == dragged_tile
			)
	for card in host.hand_manager.current_cards:
		effect.add_tile_weight(card, effect.card_weight_multiplier, card == dragged_tile)
	effect.end_tile_weights()
