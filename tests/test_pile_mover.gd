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
	var pile := game.piles[0] as MemoryPile
	assert(pile.face.mouse_default_cursor_shape == Control.CURSOR_ARROW)

	for definition in game.bonus_manager.definitions:
		if definition.id == &"pile_mover":
			game.bonus_manager._add_or_upgrade(definition)
			break
	assert(pile.face.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND)
	game.mirror_match_controller.end_round(game)
	game.round_modifiers.floor_is_lava_enabled = false
	game.lava_rule_controller.clear()
	for other in game.piles:
		if other != pile:
			other.completed = true
			other.visible = false
	var original_position := pile.position
	var pointer := pile.global_position + pile.size * 0.5
	game._on_pile_drag_requested(pile, pointer)
	assert(game.moving_pile == pile)
	var desired_global_position := game.piles_board.global_position + Vector2(6.0, 6.0)
	game._moving_pile_pointer = desired_global_position + game._moving_pile_offset
	await process_frame
	assert(game._is_valid_pile_position(pile))
	game._finish_pile_move()
	assert(pile.position != original_position)
	var first_valid_position := pile.position

	var second_pointer := pile.global_position + pile.size * 0.5
	game._on_pile_drag_requested(pile, second_pointer)
	assert(game.moving_pile == pile)
	game._moving_pile_pointer = Vector2(-100.0, -100.0)
	await process_frame
	game._finish_pile_move()
	assert(pile.position != first_valid_position)
	assert(game._is_valid_pile_position(pile))

	# Debug help occupies the lower-left visually but must not make that side
	# of the hand more restrictive than the right side.
	game.debug_help.visible = true
	pile.global_position = Vector2(
		3.0,
		game.hand_tray.global_position.y - pile.size.y - 2.0
	)
	assert(game._is_valid_pile_position(pile))

	# Timer and debug-only bonus text are informational overlays and do not
	# reserve board space.
	pile.global_position = game.timer_ring.global_position
	assert(game._is_valid_pile_position(pile))
	game.active_bonus_bar.visible = true
	game.active_bonus_bar.size = pile.size
	game.active_bonus_bar.global_position = Vector2(44.0, 4.0)
	pile.global_position = game.active_bonus_bar.global_position
	assert(game._is_valid_pile_position(pile))
	pile.global_position = game.round_panel.global_position
	assert(game._is_valid_pile_position(pile))

	for mirror_scale in [Vector2(-1.0, 1.0), Vector2(1.0, -1.0), Vector2(-1.0, -1.0)]:
		game.scale = mirror_scale
		var mirrored_origin := pile.position
		var mirrored_pointer := pile.get_global_transform() * (pile.size * 0.5)
		game._on_pile_drag_requested(pile, mirrored_pointer)
		assert(game.moving_pile == pile)
		game._moving_pile_pointer = mirrored_pointer + Vector2(24.0, 18.0)
		await process_frame
		game._finish_pile_move()
		assert(pile.position != mirrored_origin)
		assert(game._is_valid_pile_position(pile))
	game.scale = Vector2.ONE

	# A touch release may arrive at a newer coordinate than the last drag
	# event. The dedicated touch path keeps the exact grabbed local point
	# under the tracked finger and uses its final coordinate.
	pile.position = Vector2(80.0, 80.0)
	var touch_start := pile.get_global_transform() * (pile.size * 0.5)
	var touch_press := InputEventScreenTouch.new()
	touch_press.index = 7
	touch_press.position = touch_start
	touch_press.pressed = true
	game._input(touch_press)
	assert(game.moving_pile == pile)
	assert(game._pile_touch_index == 7)

	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 7
	touch_drag.position = Vector2(170.0, 180.0)
	game._input(touch_drag)
	var grabbed_global := (
		pile.get_global_transform() * game._pile_touch_local_grab
	)
	assert(grabbed_global.is_equal_approx(touch_drag.position))

	var touch_release := InputEventScreenTouch.new()
	touch_release.index = 7
	touch_release.position = Vector2(210.0, 210.0)
	touch_release.pressed = false
	game._input(touch_release)
	assert(game.moving_pile == null)
	grabbed_global = pile.get_global_transform() * game._pile_touch_local_grab
	assert(grabbed_global.distance_to(touch_release.position) <= 1.0)

	print("Pile Mover integration test passed.")
	game.queue_free()
	await process_frame
	quit()
