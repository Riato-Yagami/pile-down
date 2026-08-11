extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

	var vertical_mirror := RoundModifiers.new()
	vertical_mirror.mirror_vertical = true
	game.mirror_match_controller.end_round(game)
	game.mirror_match_controller.begin_round(game, vertical_mirror)
	await process_frame

	for generation in 6:
		game.lava_rule_controller.generate(
			20,
			game.piles,
			game.hand_container,
			game.timer_ring,
			game.lava_layer,
			game.rng
		)
		assert(not game.lava_rule_controller.zones.is_empty())
		for lava_zone in game.lava_rule_controller.zones:
			var lava_point := lava_zone.get_global_transform() * Vector2(12.0, 12.0)
			var safe_point := lava_zone.get_global_transform() * Vector2(
				game.lava_layer.size.x * 0.5,
				game.lava_layer.size.y * 0.55
			)
			assert(lava_zone.contains_global_point(lava_point))
			assert(not lava_zone.contains_global_point(safe_point))
			for protected_pile in game.piles:
				_assert_control_safe(lava_zone, protected_pile)
			for protected_card in game.hand_manager.current_cards:
				_assert_control_safe(lava_zone, protected_card)
		game.lava_rule_controller.clear()

	var pile := game.piles[0] as MemoryPile
	var pile_center := pile.get_global_transform() * (pile.size * 0.5)
	assert(game._pile_at(pile_center) == pile)

	var card := game.hand_manager.current_cards[0]
	var touch_position := card.get_global_rect().abs().get_center()
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = touch_position
	press.pressed = true
	game._input(press)
	assert(game.selected_card == card)
	assert(not card.dragging)
	assert(card.touch_state == PlayingCard.TouchState.REVEALED)
	assert(game._card_touch_index == 0)

	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = touch_position + Vector2(0.0, 48.0)
	var position_before_drag := card.get_global_rect().abs().get_center()
	game._input(drag)
	assert(not card.dragging)
	await create_timer(card.touch_drag_delay + 0.03).timeout
	assert(card.dragging)
	assert(card.touch_state == PlayingCard.TouchState.DRAGGING)
	assert(card.drag_target.is_equal_approx(drag.position))
	for frame in 3:
		await process_frame
	var position_after_drag := card.get_global_rect().abs().get_center()
	assert(position_after_drag.distance_to(position_before_drag) > 5.0)

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = drag.position
	release.pressed = false
	game._input(release)
	await create_timer(0.4).timeout
	assert(not card.dragging)

	print("Touch drag integration test passed.")
	game.queue_free()
	await process_frame
	quit()


func _assert_control_safe(lava_zone: LavaZone, control: Control) -> void:
	var transform := control.get_global_transform()
	var points: Array[Vector2] = [
		transform * Vector2.ZERO,
		transform * Vector2(control.size.x, 0.0),
		transform * control.size,
		transform * Vector2(0.0, control.size.y),
		transform * (control.size * 0.5),
	]
	for point in points:
		assert(not lava_zone.contains_global_point(point))
