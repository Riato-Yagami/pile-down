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
	assert(game.sticky_fingers_controller.cursor_enabled)

	game.round_modifiers.sticky_fingers_enabled = true
	var sticky_card := game.hand_manager.current_cards[0]
	var rejected_card := game.hand_manager.current_cards[1]
	var rejected_parent := rejected_card.get_parent()
	game._on_card_selected(sticky_card)
	game._on_card_drag_started(sticky_card)
	sticky_card.keep_attached_to_pointer()
	game.hand_manager.finish_all_card_entrances(sticky_card)
	game.hand_manager.lock_all_cards_except(sticky_card)
	var original_placeholder := game.drag_placeholder
	var original_child_count := game.hand_container.get_child_count()
	var hand_positions: Dictionary = {}
	for card in game.hand_manager.current_cards:
		if card != sticky_card:
			hand_positions[card] = card.global_position

	var rejected_click := InputEventMouseButton.new()
	rejected_click.button_index = MOUSE_BUTTON_LEFT
	rejected_click.pressed = true
	rejected_click.position = rejected_card.global_position + rejected_card.size * 0.5
	rejected_card._on_face_input(rejected_click)
	assert(game.selected_card == sticky_card)
	assert(game.drag_placeholder == original_placeholder)
	assert(rejected_card.get_parent() == rejected_parent)
	assert(not rejected_card.dragging)
	assert(not rejected_card.selectable)

	var repeated_click := InputEventMouseButton.new()
	repeated_click.button_index = MOUSE_BUTTON_LEFT
	repeated_click.pressed = true
	repeated_click.position = sticky_card.global_position + sticky_card.size * 0.5
	sticky_card._on_face_input(repeated_click)
	sticky_card._on_face_input(repeated_click)
	assert(game.drag_placeholder == original_placeholder)
	assert(game.hand_container.get_child_count() == original_child_count)

	await create_timer(0.25).timeout
	assert(rejected_card.rotation == 0.0)
	for card in hand_positions:
		assert(
			(card as PlayingCard).global_position.is_equal_approx(
				hand_positions[card] as Vector2
			)
		)
		assert(not (card as PlayingCard)._entrance_animation_running)
		assert((card as PlayingCard)._entrance_home_positions.is_empty())
		assert(not (card as PlayingCard).selectable)
	print("Sticky hand lock integration test passed.")
	game.queue_free()
	quit()
