extends SceneTree

const CardScene := preload("res://resources/scenes/Card.tscn")
const PileScene := preload("res://resources/scenes/Pile.tscn")
const LavaScene := preload("res://resources/scenes/LavaZone.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry_rules := SpecialRuleRegistry.create_all_rules()
	var expected_ids: Array[StringName] = [
		&"musical_stacks",
		&"sticky_fingers",
		&"hot_potatoes",
		&"blind_delivery",
		&"mirror_match",
		&"sudden_death",
		&"grace_period",
		&"colorblind",
		&"floor_is_lava",
	]
	for expected_id in expected_ids:
		var found := false
		for rule in registry_rules:
			if rule.id == expected_id:
				found = true
				break
		assert(found)

	var modifiers := RoundModifiers.new()
	var context := RoundContext.new(20, modifiers)
	for rule in registry_rules:
		if expected_ids.has(rule.id):
			rule.activate(context)
	assert(modifiers.musical_stacks_enabled)
	assert(modifiers.sticky_fingers_enabled)
	assert(modifiers.hot_potatoes_enabled)
	assert(
		is_equal_approx(
			modifiers.hot_potato_drag_duration,
			DifficultySettings.STICKY_HOT_POTATO_DURATION
		)
	)
	assert(modifiers.blind_delivery_enabled)
	assert(modifiers.mirror_match_enabled)
	assert(modifiers.mirror_horizontal or modifiers.mirror_vertical)
	assert(modifiers.maximum_mistakes_override == 1)
	assert(modifiers.grace_period_enabled)
	assert(modifiers.colorblind_enabled)
	assert(modifiers.floor_is_lava_enabled)
	for index in range(registry_rules.size() - 1, -1, -1):
		if expected_ids.has(registry_rules[index].id):
			registry_rules[index].deactivate(context)
	assert(not modifiers.musical_stacks_enabled)
	assert(modifiers.maximum_mistakes_override == -1)

	var hot_rule: SpecialRuleData
	var sticky_rule: SpecialRuleData
	for rule in registry_rules:
		if rule.id == &"hot_potatoes":
			hot_rule = rule
		elif rule.id == &"sticky_fingers":
			sticky_rule = rule
	var hot_only_modifiers := RoundModifiers.new()
	var hot_only_context := RoundContext.new(20, hot_only_modifiers)
	hot_rule.activate(hot_only_context)
	assert(
		is_equal_approx(
			hot_only_modifiers.hot_potato_drag_duration,
			DifficultySettings.HOT_POTATO_DURATION
		)
	)
	sticky_rule.activate(hot_only_context)
	assert(
		is_equal_approx(
			hot_only_modifiers.hot_potato_drag_duration,
			DifficultySettings.STICKY_HOT_POTATO_DURATION
		)
	)

	var stage := Control.new()
	stage.size = Vector2(256, 320)
	root.add_child(stage)

	var mirror_controller := MirrorMatchRuleController.new()
	stage.add_child(mirror_controller)
	var mirror_modifiers := RoundModifiers.new()
	mirror_modifiers.mirror_horizontal = true
	mirror_modifiers.mirror_vertical = true
	mirror_controller.begin_round(stage, mirror_modifiers)
	assert(stage.scale.is_equal_approx(Vector2(-1, -1)))
	mirror_controller.end_round(stage)
	assert(stage.scale.is_equal_approx(Vector2.ONE))

	var blind_modifiers := RoundModifiers.new()
	blind_modifiers.blind_delivery_enabled = true
	var blind_card := CardScene.instantiate() as PlayingCard
	stage.add_child(blind_card)
	blind_card.position = Vector2(100, 100)
	blind_card.setup(3, true, false, false, blind_modifiers)
	blind_card.hidden_by_blind_delivery = true
	blind_card.flip_down(false)
	blind_card._on_mouse_exited()
	await create_timer(0.16).timeout
	assert(blind_card.face_up)
	blind_card._on_mouse_entered()
	blind_card.prepare_external_drag()
	blind_card._on_mouse_exited()
	blind_card.begin_external_drag(blind_card.global_position + Vector2(8, 8))
	assert(blind_card.hidden_by_blind_delivery)
	assert(not blind_card.face_up)
	await create_timer(0.2).timeout
	assert(not blind_card.face_up)
	await blind_card.animate_return(blind_card.global_position, 0.01)
	assert(not blind_card.hidden_by_blind_delivery)
	assert(blind_card.face_up)

	var combined_blind_modifiers := RoundModifiers.new()
	combined_blind_modifiers.blind_delivery_enabled = true
	combined_blind_modifiers.hover_reveal_enabled = true
	var combined_blind_card := CardScene.instantiate() as PlayingCard
	stage.add_child(combined_blind_card)
	combined_blind_card.position = Vector2(140, 100)
	combined_blind_card.setup(
		4,
		true,
		true,
		false,
		combined_blind_modifiers
	)
	assert(not combined_blind_card.face_up)
	combined_blind_card._on_mouse_entered()
	await create_timer(0.16).timeout
	assert(combined_blind_card.face_up)
	combined_blind_card.prepare_external_drag()
	combined_blind_card.begin_external_drag(
		combined_blind_card.global_position + Vector2(8, 8)
	)
	assert(not combined_blind_card.face_up)

	var colorblind_modifiers := RoundModifiers.new()
	colorblind_modifiers.colorblind_enabled = true
	var gray_card := CardScene.instantiate() as PlayingCard
	stage.add_child(gray_card)
	gray_card.setup(4, true, false, false, colorblind_modifiers)
	var card_color: Color = (
		(gray_card.face_sprite.material as ShaderMaterial)
		.get_shader_parameter("tile_color")
	)
	assert(card_color.is_equal_approx(Color("#8B8B8B")))

	var hot_modifiers := RoundModifiers.new()
	hot_modifiers.hot_potatoes_enabled = true
	hot_modifiers.hot_potato_drag_duration = 0.05
	var hot_card := CardScene.instantiate() as PlayingCard
	stage.add_child(hot_card)
	hot_card.setup(3, true, false, false, hot_modifiers)
	var forced_reason := [PlayingCard.ForcedReturnReason.NONE]
	hot_card.forced_return_requested.connect(
		func(_card: PlayingCard, reason: int) -> void:
			forced_reason[0] = reason
	)
	hot_card.begin_external_drag(Vector2(20, 20))
	await create_timer(0.08).timeout
	assert(forced_reason[0] == PlayingCard.ForcedReturnReason.HOT_POTATO)

	var piles: Array[MemoryPile] = []
	for index in 3:
		var pile := PileScene.instantiate() as MemoryPile
		stage.add_child(pile)
		pile.setup(index, 5)
		pile.position = Vector2(index * 40.0, 80.0)
		piles.append(pile)
	var original_positions: Array[Vector2] = []
	for pile in piles:
		original_positions.append(pile.position)
	var pile_manager := PileManager.new()
	stage.add_child(pile_manager)
	pile_manager.configure(stage, piles, original_positions)
	await pile_manager.rotate_active_piles(1)
	assert(piles[0].position.is_equal_approx(original_positions[1]))
	assert(piles[1].position.is_equal_approx(original_positions[2]))
	assert(piles[2].position.is_equal_approx(original_positions[0]))
	piles[1].completed = true
	piles[1].visible = false
	await pile_manager.rotate_active_piles(1)
	assert(piles[0].position.is_equal_approx(original_positions[2]))
	assert(piles[2].position.is_equal_approx(original_positions[1]))

	var grid_piles: Array[MemoryPile] = []
	for index in 9:
		var grid_pile := PileScene.instantiate() as MemoryPile
		stage.add_child(grid_pile)
		grid_pile.setup(index, 5)
		grid_pile.position = Vector2((index % 3) * 40.0, (index / 3) * 40.0)
		grid_piles.append(grid_pile)
	pile_manager.configure(stage, grid_piles, [])
	var perimeter := pile_manager._get_perimeter_piles()
	assert(perimeter == [
		grid_piles[0],
		grid_piles[1],
		grid_piles[2],
		grid_piles[5],
		grid_piles[8],
		grid_piles[7],
		grid_piles[6],
		grid_piles[3],
	])
	assert(not perimeter.has(grid_piles[4]))

	var timer := CountdownManager.new()
	stage.add_child(timer)
	var timer_visible := [true]
	timer.timer_visibility_requested.connect(
		func(visible: bool) -> void:
			timer_visible[0] = visible
	)
	timer.start_countdown(0.2, 0.05)
	assert(not timer_visible[0])
	await create_timer(0.03).timeout
	assert(timer.time_left < 0.2)
	await create_timer(0.04).timeout
	assert(timer_visible[0])
	timer.start_countdown(0.2, 0.1)
	assert(not timer_visible[0])
	timer.stop_countdown()
	assert(not timer_visible[0])

	var lava := LavaScene.instantiate() as LavaZone
	stage.add_child(lava)
	lava.position = Vector2(100, 100)
	lava.zone_size = Vector2(40, 20)
	assert(lava.contains_global_point(Vector2(100, 100)))
	assert(not lava.contains_global_point(Vector2(70, 100)))
	lava.enabled = false
	assert(not lava.contains_global_point(Vector2(100, 100)))

	print("New special rules tests passed.")
	stage.queue_free()
	await process_frame
	quit()
