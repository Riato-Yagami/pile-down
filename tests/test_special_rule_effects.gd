extends SceneTree

const PileScene := preload("res://resources/scenes/Pile.tscn")
const CardScene := preload("res://resources/scenes/Card.tscn")
const FlashlightScene := preload("res://resources/scenes/FlashlightOverlay.tscn")
const TinyRegularFont := preload("res://resources/fonts/Tiny5-Regular.ttf")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Control.new()
	stage.size = Vector2(256.0, 320.0)
	root.add_child(stage)

	var down_pile := PileScene.instantiate() as MemoryPile
	stage.add_child(down_pile)
	down_pile.setup(0, 5, RoundModifiers.StackDirection.DOWN, false)
	assert(down_pile.current_value == 5)
	assert(down_pile.expected_value() == 4)
	assert(down_pile.can_accept(4))
	down_pile.place(4)
	assert(not down_pile.is_complete_value())
	down_pile.enable_regeneration(1.0)
	assert(down_pile.regeneration_ring != null)
	assert(is_equal_approx(down_pile.regeneration_ring.ratio, 1.0))
	assert(not down_pile.regeneration_ring.visible)
	await down_pile.hide_value(false)
	assert(down_pile.regeneration_ring.visible)
	await down_pile.reveal_value_temporarily(0.01)
	assert(not down_pile.face_up)
	down_pile.current_value = down_pile.start_value
	down_pile._refresh()
	assert(not down_pile.regeneration_ring.visible)
	down_pile.disable_regeneration()

	var up_pile := PileScene.instantiate() as MemoryPile
	stage.add_child(up_pile)
	up_pile.setup(1, 5, RoundModifiers.StackDirection.UP, true)
	assert(up_pile.current_value == 0)
	assert(up_pile.expected_value() == 1)
	assert(up_pile.can_accept(1))
	up_pile.place(1)
	assert(up_pile.value_label.text == "I")
	up_pile.current_value = 8
	up_pile._refresh()
	assert(up_pile.value_label.text == "VIII")
	assert(up_pile.value_label.get_theme_font_size("font_size") == 14)
	assert(up_pile.value_label.get_theme_font("font") == TinyRegularFont)
	up_pile.current_value = 5
	up_pile._refresh()
	assert(up_pile.value_label.get_theme_font_size("font_size") == 20)
	assert(up_pile.is_complete_value())

	var peek_card := CardScene.instantiate() as PlayingCard
	stage.add_child(peek_card)
	peek_card.setup(4, true, true, true)
	assert(not peek_card.face_up)
	await peek_card.flip_up(false)
	assert(peek_card.face_up)
	assert(peek_card.value_label.text == "IV")
	peek_card.card_value = 7
	peek_card._update_appearance()
	assert(peek_card.value_label.text == "VII")
	assert(peek_card.value_label.get_theme_font_size("font_size") == 14)
	assert(peek_card.value_label.get_theme_font("font") == TinyRegularFont)
	peek_card.card_value = 4
	peek_card._update_appearance()
	assert(peek_card.value_label.get_theme_font_size("font_size") == 20)
	var original_y := peek_card.position.y
	for iteration in 4:
		await peek_card.flip_down(true)
		await peek_card.flip_up(true)
		assert(is_equal_approx(peek_card.position.y, original_y))

	var free_range_layer := Control.new()
	stage.add_child(free_range_layer)
	var hand_manager := HandManager.new()
	hand_manager.card_scene = CardScene
	stage.add_child(hand_manager)
	hand_manager.generate_hand(free_range_layer, 3, 5, [4], false, false, false, false)
	assert(hand_manager.current_cards.size() == 3)
	for card in hand_manager.current_cards:
		assert(card.get_parent() == free_range_layer)
	var entrance_card := hand_manager.current_cards[0]
	entrance_card.play_wandering_entrance(
		0,
		Vector2(110.0, 10.0),
		Vector2(256.0, 320.0),
		0.0
	)
	assert(entrance_card.global_position.y < 0.0)
	await create_timer(0.35).timeout
	assert(entrance_card.wandering_enabled)
	assert(is_equal_approx(entrance_card.modulate.a, 1.0))
	entrance_card.global_position = Vector2(110.0, 80.0)
	entrance_card.enable_wandering(1, true)
	var continuous_position := entrance_card.global_position
	await process_frame
	assert(entrance_card.global_position.distance_to(continuous_position) < 2.0)
	var discarded_cards := hand_manager.current_cards.duplicate()
	await hand_manager.discard_hand(free_range_layer)
	await process_frame
	for card in discarded_cards:
		assert(not is_instance_valid(card))

	hand_manager.generate_hand(
		free_range_layer, 3, 5, [4], false, false, false, false,
		true, false, null, 0.0, true
	)
	assert(hand_manager.current_cards.size() == 3)
	assert(
		hand_manager.current_cards.filter(
			func(card: PlayingCard) -> bool: return card.is_joker
		).size() == 1
	)
	await hand_manager.discard_hand(free_range_layer)
	assert(hand_manager.current_cards.size() == 1)
	assert(hand_manager.current_cards[0].is_joker)
	hand_manager.generate_hand(
		free_range_layer, 3, 5, [4], false, false, false, false,
		false, false, null, 1.0, false
	)
	assert(hand_manager.current_cards.size() == 3)
	assert(
		hand_manager.current_cards.filter(
			func(card: PlayingCard) -> bool: return card.is_joker
		).size() == 2
	)
	var used_joker := hand_manager.current_cards.filter(
		func(card: PlayingCard) -> bool: return card.is_joker
	).front() as PlayingCard
	used_joker.confirm_drop()
	await hand_manager.discard_hand(free_range_layer)
	assert(hand_manager.current_cards.size() == 1)
	assert(hand_manager.current_cards[0].is_joker)
	await hand_manager.discard_hand(free_range_layer, null, false)
	assert(hand_manager.current_cards.is_empty())

	var flashlight := FlashlightScene.instantiate() as FlashlightOverlay
	stage.add_child(flashlight)
	assert(
		is_equal_approx(
			flashlight.flashlight_radius,
			DifficultySettings.LIGHTS_OUT_RADIUS
		)
	)
	flashlight.close_in()
	assert(flashlight.visible)
	assert(flashlight.animated_radius > flashlight.flashlight_radius)
	await create_timer(0.7).timeout
	assert(is_equal_approx(flashlight.animated_radius, flashlight.flashlight_radius))
	await flashlight.open_out()
	assert(not flashlight.visible)

	stage.queue_free()
	print("Special Rule effect tests passed.")
	quit()
