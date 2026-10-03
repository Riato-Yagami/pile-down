extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.start_game(false, null, false, "COLOR-LIFECYCLE", {}, [], {
		"pile_count": 2, "hand_size": 3, "start_value": 5, "turn_time": 20.0,
	})
	while game.input_locked:
		await process_frame
	await create_timer(0.4).timeout
	game.timer_manager.stop_countdown()
	var card := game.hand_manager.current_cards[0]
	var other := game.hand_manager.current_cards[1]
	var palette := ColorPaletteRegistry.create_all()[1].normalized_colors()
	card.set_tile_palette(palette)
	other.set_tile_palette(palette)
	card.setup(2)
	other.setup(3)
	var number_color := card.value_label.get_theme_color("font_color")
	var other_number_color := other.value_label.get_theme_color("font_color")
	assert(number_color == GameColors.tile_text_color(palette[2]))
	card.drag_target = card.get_global_rect().get_center()
	game._on_card_drag_started(card)
	assert(card.dragging and card.get_parent() == game.drag_layer)
	assert(card.value_label.get_theme_color("font_color") == number_color,
		"Moving to DragLayer must preserve the palette-derived number color")
	assert(card.face_sprite.material.get_shader_parameter("tile_color") == palette[2])
	card.finish_drag()
	await game._return_card_to_hand(card)
	game.selected_card = null
	assert(card.value_label.get_theme_color("font_color") == number_color)
	game._discard_source_action_active = true
	game._start_discard_current_hand(true, true)
	await create_timer(0.05).timeout
	assert(other.get_parent() == game.drag_layer and other.is_discarding)
	assert(other.value_label.get_theme_color("font_color") == other_number_color,
		"Discard animation must preserve the palette-derived number color")
	assert(DiscardPlayController.claim_on_press(game, other))
	assert(other.value_label.get_theme_color("font_color") == other_number_color)
	game.queue_free()
	await process_frame
	print("Tile and number colors survive dragging, returning, discarding and reclaiming.")
	quit()
