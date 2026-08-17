extends SceneTree

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const GAME_SCENE := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager := ChallengeManager.new()
	var shared := manager.find(&"shared_clock")
	var conveyor := manager.find(&"conveyor_belt")
	var boss := manager.find(&"boss_rush")
	var commit := manager.find(&"no_looking_back")
	assert(shared != null and conveyor != null and boss != null and commit != null)
	for data in [shared, conveyor, boss, commit]:
		assert(data.start_round == 5)
		assert(data.target_round == 20)
		assert(data.allow_endless)
	assert(manager.modifiers_for(shared).shared_round_clock)
	assert(manager.modifiers_for(shared).shared_clock_seconds_per_hand > 0.0)
	assert(manager.modifiers_for(conveyor).conveyor_hand)
	assert(manager.modifiers_for(conveyor).conveyor_speed > 0.0)
	assert(manager.modifiers_for(conveyor).disabled_bonuses.has(&"redraw"))
	assert(manager.modifiers_for(conveyor).disabled_special_rules.has(&"free_range_cards"))
	assert(manager.modifiers_for(boss).force_special_rules_every_round)
	assert(manager.modifiers_for(commit).commit_selected_cards)
	assert(manager.modifiers_for(commit).hide_selected_card_value)
	assert(manager.modifiers_for(commit).disabled_special_rules.has(&"blind_delivery"))
	assert(manager.modifiers_for(commit).disabled_special_rules.has(&"sticky_fingers"))

	var shared_time := Difficulty.estimate_shared_round_time(2, 5, 2, 5.0)
	assert(is_equal_approx(shared_time, 25.0))
	assert(Difficulty.required_tiles_to_complete_round(3, 5) == 15)
	assert(Difficulty.estimate_required_hands(15, 4) == 4)
	assert(Difficulty.estimate_shared_round_time(1, 1, 4, 1.0) == 8.0)
	assert(Difficulty.boss_rush_rule_count(5, 5, 20, false) == 2)
	assert(Difficulty.boss_rush_rule_count(9, 5, 20, false) == 3)
	assert(Difficulty.boss_rush_rule_count(13, 5, 20, false) == 4)
	assert(
		Difficulty.boss_rush_rule_count(17, 5, 20, false)
		== Difficulty.MAX_COMBINED_RULES
	)
	assert(
		Difficulty.boss_rush_rule_count(5, 5, 20, true)
		== Difficulty.MAX_COMBINED_RULES
	)
	assert(Difficulty.get_conveyor_speed(999) == Difficulty.CONVEYOR_MAX_SPEED)

	var timer := CountdownManager.new()
	root.add_child(timer)
	timer.start_countdown(20.0)
	timer.add_time(5.0)
	assert(timer.time_left > 24.0)
	var preserved := timer.time_left
	timer.stop_countdown()
	timer.resume_countdown()
	assert(timer.running)
	assert(timer.time_left <= preserved and timer.time_left > 24.0)
	timer.queue_free()

	var achievement_manager := AchievementManager.new()
	root.add_child(achievement_manager)
	var summary := RunSummary.new()
	achievement_manager._on_round_completed(
		summary, 1, [&"free_range_cards", &"hot_potatoes"]
	)
	assert(achievement_manager.unlocked.has(&"free_range_hot_potatoes"))
	achievement_manager._on_round_completed(
		summary, 1, [&"blind_delivery", &"sticky_fingers"]
	)
	assert(achievement_manager.unlocked.has(&"blind_delivery_sticky_fingers"))
	achievement_manager.queue_free()
	await process_frame

	# Shared Clock keeps one budget when a new hand starts and recovers after a
	# non-lethal timeout.
	shared.disabled_rules.assign(Difficulty.ENABLED_SPECIAL_RULES)
	shared.start_round = 1
	shared.target_round = 2
	var game := GAME_SCENE.instantiate() as GameManager
	root.add_child(game)
	game.splash.visible = false
	game.start_game(false, shared, false)
	var deadline := Time.get_ticks_msec() + 5000
	while not game.timer_manager.running and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(game.challenge_modifiers.shared_round_clock)
	assert(game.timer_manager.running)
	var shared_budget := game.timer_manager.time_left
	game._start_turn_countdown()
	assert(game.timer_manager.time_left <= shared_budget)
	assert(game.timer_manager.time_left > shared_budget - 0.25)
	var time_before_mistake := game.timer_manager.time_left
	game._handle_mistake(game.piles[0])
	await process_frame
	assert(not game.timer_manager.running)
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	assert(not game.timer_manager.running)
	var next_card := game.hand_manager.current_cards[0] as PlayingCard
	next_card.drag_target = next_card.get_global_rect().get_center()
	game._on_card_drag_started(next_card)
	assert(game.selected_card == next_card)
	assert(next_card.dragging)
	await game._on_card_drag_released(next_card, Vector2(-100.0, -100.0))
	deadline = Time.get_ticks_msec() + 5000
	while not game.timer_manager.running and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(game.timer_manager.running)
	assert(absf(game.timer_manager.time_left - time_before_mistake) < 0.1)
	game.bonus_manager.grant_starting_bonuses({&"redraw": 1})
	game.bonus_manager.redraws_left = 1
	var time_before_reload := game.timer_manager.time_left
	game._on_redraw_pressed()
	await process_frame
	deadline = Time.get_ticks_msec() + 5000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	assert(absf(
		game.timer_manager.time_left
		- (time_before_reload + Difficulty.SHARED_CLOCK_RELOAD_TIME_BONUS)
	) < 0.1)
	game.timer_manager.time_left = 0.0
	await game._on_time_expired()
	assert(game.mistakes_left == 0)
	assert(not game.timer_manager.running)
	game._achievement_notifications_enabled = false
	await process_frame
	game.queue_free()
	await process_frame

	# Boss Rush selection respects compatibility and changes the draw when
	# alternatives exist.
	var rule_manager := SpecialRuleManager.new()
	var first_boss_rules := rule_manager.select_special_rules(20, 4)
	assert(not first_boss_rules.is_empty())
	for index in first_boss_rules.size():
		assert(rule_manager._is_compatible(
			first_boss_rules[index], first_boss_rules.slice(0, index), 20
		))
	var second_boss_rules := rule_manager.select_special_rules(20, 4)
	var first_ids: Array[StringName] = []
	var second_ids: Array[StringName] = []
	for rule in first_boss_rules:
		first_ids.append(rule.id)
	for rule in second_boss_rules:
		second_ids.append(rule.id)
	assert(first_ids != second_ids or second_ids.size() < 2)

	# No Looking Back hides and retains a committed card, while a forced return
	# clears the commit.
	commit.start_round = 1
	commit.target_round = 2
	commit.disabled_rules.assign(Difficulty.ENABLED_SPECIAL_RULES)
	game = GAME_SCENE.instantiate() as GameManager
	root.add_child(game)
	game.splash.visible = false
	game.start_game(false, commit, false)
	deadline = Time.get_ticks_msec() + 5000
	while game.hand_manager.current_cards.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	var committed_card := game.hand_manager.current_cards[0]
	committed_card.drag_target = committed_card.get_global_rect().get_center()
	game._on_card_drag_started(committed_card)
	assert(committed_card.hidden_by_commit)
	assert(not committed_card.face_up)
	game._on_card_drag_released(committed_card, Vector2(1.0, 1.0))
	assert(committed_card.drag_state == PlayingCard.DragState.LOCKED_OUT)
	committed_card.request_forced_return(PlayingCard.ForcedReturnReason.HOT_POTATO)
	deadline = Time.get_ticks_msec() + 3000
	while committed_card.hidden_by_commit and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not committed_card.hidden_by_commit)
	game._achievement_notifications_enabled = false
	await process_frame
	game.queue_free()
	await process_frame

	# Conveyor cards move, leave without damage and the anti-softlock threshold
	# forces a useful spawn.
	conveyor.start_round = 1
	conveyor.target_round = 2
	conveyor.disabled_rules.assign(Difficulty.ENABLED_SPECIAL_RULES)
	game = GAME_SCENE.instantiate() as GameManager
	root.add_child(game)
	game.splash.visible = false
	game.start_game(false, conveyor, false)
	deadline = Time.get_ticks_msec() + 5000
	while not game._conveyor_active and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(game._conveyor_active)
	var conveyor_card := game.hand_manager.current_cards[0]
	assert(not game._conveyor_left_to_right)
	assert(conveyor_card.global_position.x > game.get_viewport_rect().size.x)
	assert(is_equal_approx(
		conveyor_card.get_global_rect().get_center().y,
		game.hand_tray.get_global_rect().get_center().y
		+ Difficulty.CONVEYOR_CARD_VERTICAL_OFFSET
	))
	var previous_position := conveyor_card.global_position
	game._process_conveyor(0.5)
	assert(conveyor_card.global_position != previous_position)
	assert(conveyor_card.global_position.x < previous_position.x)
	var cards_before_continuous_spawn := game.hand_manager.current_cards.size()
	var conveyor_speed := Difficulty.get_conveyor_speed(
		game._progression_round(), game.challenge_modifiers.conveyor_speed
	)
	game._process_conveyor(
		Difficulty.CONVEYOR_MIN_CARD_SPACING * 2.1 / conveyor_speed
	)
	assert(game.hand_manager.current_cards.size() >= cards_before_continuous_spawn + 2)
	var mistakes_before_exit := game.mistakes_left
	conveyor_card.global_position.x = -conveyor_card.size.x
	var y_before_exit_turn := conveyor_card.global_position.y
	game._process_conveyor(0.01)
	assert(game.mistakes_left == mistakes_before_exit)
	assert(conveyor_card.has_meta(&"conveyor_exiting_down"))
	game._process_conveyor(0.5)
	assert(conveyor_card.global_position.y > y_before_exit_turn)
	conveyor_card.global_position.y = (
		game.get_viewport_rect().size.y + conveyor_card.size.y + 1.0
	)
	game._process_conveyor(0.01)
	assert(not game.hand_manager.current_cards.has(conveyor_card))
	game._conveyor_unplayable_spawns = conveyor.conveyor_guaranteed_interval
	var forced_card := game._spawn_conveyor_card()
	assert(game._playable_values().has(forced_card.card_value))
	var abandoned_card := game._spawn_conveyor_card()
	var abandoned_slot := abandoned_card.global_position
	var cards_before_pickup := game.hand_manager.current_cards.size()
	abandoned_card.drag_target = abandoned_card.get_global_rect().get_center()
	game._on_card_drag_started(abandoned_card)
	assert(game.hand_manager.current_cards.size() == cards_before_pickup + 1)
	var slot_replacement: PlayingCard = game.hand_manager.current_cards.back()
	assert(slot_replacement != abandoned_card)
	assert(slot_replacement.global_position == abandoned_slot)
	var mistakes_before_abandon := game.mistakes_left
	await game._on_card_drag_released(abandoned_card, Vector2(-100.0, -100.0))
	assert(game.mistakes_left == mistakes_before_abandon)
	assert(not game.hand_manager.current_cards.has(abandoned_card))
	var rejected_card := game._spawn_conveyor_card()
	var wrong_value := (game._playable_values()[0] + 1) % maxi(game.start_value, 2)
	if game._playable_values().has(wrong_value):
		wrong_value = (wrong_value + 1) % maxi(game.start_value, 2)
	rejected_card.card_value = wrong_value
	rejected_card.drag_target = rejected_card.get_global_rect().get_center()
	game._on_card_drag_started(rejected_card)
	var mistakes_before_rejection := game.mistakes_left
	await game._on_card_drag_released(
		rejected_card,
		game.piles[0].get_global_rect().get_center()
	)
	assert(game.mistakes_left == mistakes_before_rejection - 1)
	assert(not game.hand_manager.current_cards.has(rejected_card))
	game._achievement_notifications_enabled = false
	await process_frame
	game.queue_free()
	await process_frame
	print("New challenge mode tests passed.")
	quit()
