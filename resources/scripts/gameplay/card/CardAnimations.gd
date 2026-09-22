class_name CardAnimations
extends RefCounted

## Card poses, entrance/exit motion and face-flip animations.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func animate_return(host: PlayingCard, destination: Vector2, duration := 0.26) -> void:
	host.drag_state = host.DragState.RETURNING
	host.dragging = false
	host.drag_collision_area.monitorable = false
	host.cancel_drag_timers()
	host.z_index = 0
	host.rotation = 0.0
	var tween := host.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(host, "global_position", destination, duration)
	await tween.finished
	host.drag_state = host.DragState.IDLE
	host.end_commit()
	if host.hover_reveal_enabled:
		await host.flip_down(true)
	elif (
		host.round_modifiers != null
		and host.round_modifiers.blind_delivery_enabled
	):
		host.pointer_inside = host.get_global_rect().abs().has_point(
			host.get_global_mouse_position()
		)
		host.hidden_by_blind_delivery = host.pointer_inside
		if host.pointer_inside:
			await host.flip_down(true)
		else:
			await host.flip_up(true)


static func reset_hand_pose(host: PlayingCard) -> void:
	if host._visual_tween != null and host._visual_tween.is_valid():
		host._visual_tween.kill()
	host.scale = Vector2.ONE
	host.rotation = 0.0
	host.face_sprite.position.y = 0.0
	host.back_sprite.position.y = 0.0
	host._apply_value_label_offset()
	host.drag_timer_ring.visible = false
	host.z_index = 0


static func record_hand_position(host: PlayingCard) -> void:
	host.stable_hand_global_position = host.global_position
	host.home_global_position = host.stable_hand_global_position
	host.has_stable_hand_position = true


static func hand_return_position(host: PlayingCard) -> Vector2:
	return host.stable_hand_global_position if host.has_stable_hand_position else host.home_global_position


static func animate_valid_drop(host: PlayingCard, destination: Vector2, duration := 0.14) -> void:
	host._materialize_entrance_for_drag()
	host.disable_wandering()
	host.finish_drag()
	var tween := host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(host, "global_position", destination, duration)
	tween.parallel().tween_property(host, "scale", Vector2(0.94, 0.94), 0.08)
	tween.tween_property(host, "scale", Vector2.ONE, 0.08)
	await tween.finished
	host.global_position = destination


static func play_draw(host: PlayingCard, delay: float) -> void:
	# Capture the HBox slot before the entrance offset is applied. A press
	# during the tween must still return to the stable layout position.
	host.record_hand_position()
	host.modulate.a = 0.0
	host.position.y += 9.0
	var destination_y := host.position.y - 9.0
	var tween := host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.tween_property(host, "position:y", destination_y, 0.18)
	tween.parallel().tween_property(host, "modulate:a", 1.0, 0.14)


static func hold_hand_position(host: PlayingCard) -> void:
	if host.visual_root.is_set_as_top_level():
		return
	var previous_position := host.visual_root.global_position
	host.finish_entrance_immediately()
	host._held_hand_visual_position = host.visual_root.position
	# The HBox may shrink and recenter while the discarded cards leave.
	# Keep the retained card visible at its old slot until the refill is laid out.
	host.visual_root.set_as_top_level(true)
	host.visual_root.global_position = previous_position


static func release_held_hand_position(host: PlayingCard) -> void:
	if not host.visual_root.is_set_as_top_level():
		return
	host.visual_root.set_as_top_level(false)
	host.visual_root.position = host._held_hand_visual_position


static func play_retained_hand_shift(host: PlayingCard, animate: bool, delay: float) -> void:
	await host.get_tree().process_frame
	if not host.is_inside_tree() or not host.visual_root.is_set_as_top_level():
		return
	var previous_position := host.visual_root.global_position
	release_held_hand_position(host)
	host.record_hand_position()
	if not animate:
		return
	host._entrance_home_positions[host.visual_root] = host.visual_root.position
	host.visual_root.global_position = previous_position
	host.set_selectable(false)
	host._entrance_animation_running = true
	host._entrance_unlock_pending = true
	host._entrance_tween = host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	host._entrance_tween.tween_interval(delay)
	host._entrance_tween.tween_property(
		host.visual_root, "position", host._held_hand_visual_position, 0.28
	)
	host._entrance_tween.tween_callback(host._finish_entrance_animation)


static func play_draw_from_right(host: PlayingCard, delay: float) -> void:
	host.set_selectable(false)
	host._entrance_unlock_pending = true
	host._entrance_animation_running = true
	# Wait until the hand container has assigned the final slot. Computing the
	# entrance offset earlier can use the previous card's layout position.
	await host.get_tree().process_frame
	if not host.is_inside_tree():
		return
	host.record_hand_position()
	host._entrance_home_positions.clear()
	var entrance_offset := host.get_viewport_rect().size.x + host.size.x + 12.0 - host.global_position.x
	var visuals: Array[Control] = [host.visual_root]
	for visual in visuals:
		host._entrance_home_positions[visual] = visual.position
		visual.position.x += entrance_offset
	host.modulate.a = 0.0
	host.rotation = 0.1
	host._entrance_tween = host.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	host._entrance_tween.tween_interval(delay)
	host._entrance_tween.set_parallel(true)
	for visual in visuals:
		host._entrance_tween.tween_property(
			visual,
			"position",
			host._entrance_home_positions[visual],
			0.28
		)
	host._entrance_tween.tween_property(host, "modulate:a", 1.0, 0.18)
	host._entrance_tween.tween_property(host, "rotation", 0.0, 0.24)
	host._entrance_tween.set_parallel(false)
	host._entrance_tween.tween_callback(host._finish_entrance_animation)


static func play_draw_in_place(host: PlayingCard, delay: float) -> void:
	host.modulate.a = 0.0
	var tween := host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.tween_property(host, "modulate:a", 1.0, 0.14)


static func play_wandering_entrance(
	host: PlayingCard,
	index: int,
	destination: Vector2,
	screen_size: Vector2,
	delay: float
) -> void:
	host.free_range_card = true
	host.wandering_enabled = false
	host.set_selectable(false)
	host._entrance_unlock_pending = true
	var destination_center := destination + host.size * 0.5
	var edge_distances := [
		destination_center.x,
		screen_size.x - destination_center.x,
		destination_center.y,
		screen_size.y - destination_center.y,
	]
	var closest_edge := edge_distances.find(edge_distances.min())
	match closest_edge:
		0:
			host.global_position = Vector2(-host.size.x - 12.0, destination.y)
		1:
			host.global_position = Vector2(screen_size.x + 12.0, destination.y)
		2:
			host.global_position = Vector2(destination.x, -host.size.y - 12.0)
		_:
			host.global_position = Vector2(destination.x, screen_size.y + 12.0)
	host.modulate.a = 0.0
	host.rotation = -0.12 if closest_edge == 0 or closest_edge == 3 else 0.12
	host._entrance_animation_running = true
	host._entrance_tween = host.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	host._entrance_tween.tween_interval(delay)
	host._entrance_tween.tween_property(host, "global_position", destination, 0.28)
	host._entrance_tween.parallel().tween_property(host, "modulate:a", 1.0, 0.18)
	host._entrance_tween.parallel().tween_property(host, "rotation", 0.0, 0.24)
	host._entrance_tween.tween_callback(func() -> void:
		host._entrance_animation_running = false
		host.enable_wandering(index, true)
		host._complete_entrance_interaction()
	)


static func materialize_entrance_for_drag(host: PlayingCard) -> void:
	if not host._entrance_animation_running:
		return
	var visual_global_position := host.visual_root.global_position
	if host._entrance_tween != null and host._entrance_tween.is_valid():
		host._entrance_tween.kill()
	if not host._entrance_home_positions.is_empty():
		host.global_position = (
			visual_global_position
			- (host._entrance_home_positions[host.visual_root] as Vector2)
		)
		for visual in host._entrance_home_positions:
			(visual as Control).position = host._entrance_home_positions[visual]
	host._entrance_home_positions.clear()
	host._entrance_animation_running = false
	host._entrance_unlock_pending = false
	host.rotation = 0.0
	host.modulate.a = 1.0


static func finish_entrance_animation(host: PlayingCard) -> void:
	for visual in host._entrance_home_positions:
		(visual as Control).position = host._entrance_home_positions[visual]
	host._entrance_home_positions.clear()
	host._entrance_animation_running = false
	host._complete_entrance_interaction()


static func finish_entrance_immediately(host: PlayingCard) -> void:
	if not host._entrance_animation_running:
		return
	if host._entrance_tween != null and host._entrance_tween.is_valid():
		host._entrance_tween.kill()
	for visual in host._entrance_home_positions:
		(visual as Control).position = host._entrance_home_positions[visual]
	host._entrance_home_positions.clear()
	host._entrance_animation_running = false
	host.modulate.a = 1.0
	host.rotation = 0.0
	host._complete_entrance_interaction()


static func complete_entrance_interaction(host: PlayingCard) -> void:
	if not host._entrance_unlock_pending:
		return
	host._entrance_unlock_pending = false
	host.set_selectable(true)
	host.entrance_became_interactive.emit(host)


static func play_wandering_exit(host: PlayingCard, screen_size: Vector2, delay: float) -> float:
	host.wandering_enabled = false
	host.set_selectable(false)
	host.cancel_drag_timers()
	host._cancel_flip_animation()
	if host._visual_tween != null and host._visual_tween.is_valid():
		host._visual_tween.kill()
	var center := host.global_position + host.size * 0.5
	var edge_distances := [
		center.x,
		screen_size.x - center.x,
		center.y,
		screen_size.y - center.y,
	]
	var closest_edge := edge_distances.find(edge_distances.min())
	var destination := host.global_position
	var spin := 0.0
	var side_bias := -1.0 if center.x < screen_size.x * 0.5 else 1.0
	match closest_edge:
		0:
			destination = Vector2(-host.size.x - 18.0, host.global_position.y - 12.0)
			spin = -0.44
		1:
			destination = Vector2(screen_size.x + 18.0, host.global_position.y - 12.0)
			spin = 0.44
		2:
			destination = Vector2(host.global_position.x + side_bias * 18.0, -host.size.y - 18.0)
			spin = side_bias * 0.38
		_:
			destination = Vector2(
				host.global_position.x + side_bias * 18.0,
				screen_size.y + 18.0
			)
			spin = side_bias * 0.38
	var lift_position := host.global_position + Vector2(0.0, -5.0)
	var pop_duration := 0.08
	var exit_duration := 0.34
	var tween := host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.tween_property(
		host,
		"global_position",
		lift_position,
		pop_duration
	)
	tween.parallel().tween_property(host, "scale", Vector2(1.08, 1.08), pop_duration)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(host, "global_position", destination, exit_duration)
	tween.parallel().tween_property(host, "modulate:a", 0.0, exit_duration * 0.78)
	tween.parallel().tween_property(host, "rotation", spin, exit_duration)
	tween.parallel().tween_property(host, "scale", Vector2(0.72, 0.72), exit_duration)
	return delay + pop_duration + exit_duration


static func flip_down(host: PlayingCard, animated: bool = true) -> void:
	if not host.face_up or host._flip_in_progress:
		return
	if animated:
		host._flip_in_progress = true
		host._flip_original_y = host.position.y
		host._flip_tween = host.create_tween().set_trans(Tween.TRANS_SINE)
		host._flip_tween.tween_property(host, "scale:x", 0.02, 0.07)
		host._flip_tween.parallel().tween_property(host, "position:y", host._flip_original_y - 3.0, 0.07)
		host._flip_tween.tween_callback(func() -> void:
			host.face_up = false
			host._update_appearance()
		)
		host._flip_tween.tween_property(host, "scale:x", 1.0, 0.07)
		host._flip_tween.parallel().tween_property(host, "position:y", host._flip_original_y, 0.07)
		await host._flip_tween.finished
		host.position.y = host._flip_original_y
		host._flip_in_progress = false
	else:
		host.face_up = false
		host._update_appearance()


static func flip_up(host: PlayingCard, animated: bool = true) -> void:
	if host.face_up or host._flip_in_progress:
		return
	if animated:
		host._flip_in_progress = true
		host._flip_original_y = host.position.y
		host._flip_tween = host.create_tween().set_trans(Tween.TRANS_SINE)
		host._flip_tween.tween_property(host, "scale:x", 0.02, 0.07)
		host._flip_tween.tween_callback(func() -> void:
			host.face_up = true
			host._update_appearance()
		)
		host._flip_tween.tween_property(host, "scale:x", 1.0, 0.07)
		await host._flip_tween.finished
		host._flip_in_progress = false
	else:
		host.face_up = true
		host._update_appearance()


static func flash_error(host: PlayingCard) -> void:
	if host._visual_tween != null and host._visual_tween.is_valid():
		host._visual_tween.kill()
	var tween := host.create_tween()
	tween.tween_property(host.face_sprite, "modulate", Color("#F3B2AA"), 0.08)
	tween.tween_property(host.face_sprite, "modulate", Color.WHITE, 0.12)
	tween.tween_callback(func() -> void:
		host.face_sprite.modulate = Color.WHITE
	)
	await tween.finished


static func cancel_flip_animation(host: PlayingCard) -> void:
	if host._flip_tween != null and host._flip_tween.is_valid():
		host._flip_tween.kill()
	if host._flip_in_progress:
		host.position.y = host._flip_original_y
		host.scale.x = 1.0
	host._flip_in_progress = false


static func animate_pose(host: PlayingCard, target_scale: Vector2, y_offset: float) -> void:
	if host._visual_tween != null and host._visual_tween.is_valid():
		host._visual_tween.kill()
	host._visual_tween = host.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	host._visual_tween.tween_property(host, "scale", target_scale, 0.12)
	host._visual_tween.tween_property(host.face_sprite, "position:y", y_offset, 0.12)
	host._visual_tween.tween_property(host.back_sprite, "position:y", y_offset, 0.12)
	host._visual_tween.tween_property(
		host.value_label, "position:y", host._value_font_offset.y + y_offset, 0.12
	)
