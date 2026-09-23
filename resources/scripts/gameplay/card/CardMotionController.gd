class_name CardMotionController
extends RefCounted


static func process(card: PlayingCard, delta: float) -> void:
	_update_joker(card, delta)
	_update_wandering(card, delta)
	_update_drag(card, delta)


static func _update_joker(card: PlayingCard, delta: float) -> void:
	if not card.is_joker:
		return
	card._joker_phase = fmod(card._joker_phase + delta * 0.35, 1.0)
	var palette_position := card._joker_phase * card._tile_colors.size()
	var first_index := int(floor(palette_position)) % card._tile_colors.size()
	var second_index := (first_index + 1) % card._tile_colors.size()
	var joker_color := card._tile_colors[first_index].lerp(
		card._tile_colors[second_index], fmod(palette_position, 1.0)
	)
	var joker_material := card.face_sprite.material as ShaderMaterial
	joker_material.set_shader_parameter("tile_color", joker_color)
	card.value_label.add_theme_color_override("font_color", joker_color)


static func _update_wandering(card: PlayingCard, delta: float) -> void:
	if not card.wandering_enabled or card.dragging:
		return
	card.wandering_phase += delta * card.wandering_speed
	card.global_position = (
		card.wandering_origin
		+ Vector2(
			sin(card.wandering_phase),
			sin(card.wandering_phase * 1.7 + card.card_value)
		) * card.wandering_radius
	).round()


static func _update_drag(card: PlayingCard, delta: float) -> void:
	if not card.dragging:
		if not card.drag_timer.is_stopped():
			card.drag_timer.stop()
			card.drag_timer_ring.visible = false
		return
	if not card.drag_timer.is_stopped():
		card.drag_timer_ring.ratio = (
			card.drag_timer.time_left / maxf(card.drag_timer.wait_time, 0.001)
		)
	var previous := card.global_position
	if card.touch_index >= 0:
		card.update_touch_drag(card.drag_target)
		return
	# Mirror Match can invert either axis, so the grabbed point must be
	# transformed instead of treated as a simple position offset.
	var drag_parent := card.get_parent() as CanvasItem
	if drag_parent != null:
		var pointer_in_parent := (
			drag_parent.get_global_transform().affine_inverse() * card.drag_target
		)
		var grab_offset := card.get_transform().basis_xform(card._pointer_offset)
		var desired_position := pointer_in_parent - grab_offset
		card.position = card.position.lerp(
			desired_position, minf(delta * 20.0, 1.0)
		)
	else:
		var grab_offset := card.get_global_transform().basis_xform(card._pointer_offset)
		var desired_position := card.drag_target - grab_offset
		card.global_position = card.global_position.lerp(
			desired_position, minf(delta * 20.0, 1.0)
		)
	var velocity := (card.drag_target - card._last_target) / maxf(delta, 0.001)
	card.rotation = lerpf(
		card.rotation,
		clampf(velocity.x * 0.00004, -0.07, 0.07),
		minf(delta * 12.0, 1.0)
	)
	card._last_target = card.drag_target
	if previous.distance_to(card.global_position) > 0.1:
		card.move_to_front()
