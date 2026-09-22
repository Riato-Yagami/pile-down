extends SceneTree
## Plays complete runs through the normal placement/animation pipeline.
## Run with --fixed-fps 20 (or 60 for finer sampling): time is active game time,
## not the wall-clock achievement timer. The solver has perfect memory;
## decision_delay models recognition + pointer travel, not human playtesting.

const GameScene := preload("res://resources/scenes/Game.tscn")
var game: GameManager
var active_seconds := 0.0
var actions := 0
var measuring := false


func _init() -> void:
	call_deferred("_run")


func _process(delta: float) -> bool:
	if measuring and is_instance_valid(game) and game.run_pause_started_msec < 0:
		active_seconds += delta
	return false


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var delay := float(args[0]) if not args.is_empty() else 0.9
	var seed_label := args[1] if args.size() > 1 else "PACE-01"
	var take_bonuses := args.size() > 2 and args[2] == "bonuses"
	game = GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.visible = false
	active_seconds = 0.0
	measuring = true
	game.start_game(false, null, false, seed_label)
	var reported_round := 0
	var frames_without_action := 0
	while not game.overlay.visible:
		await process_frame
		frames_without_action += 1
		if frames_without_action > 3600:
			push_error("Benchmark stalled at round %d" % game.run_completed_rounds)
			quit(1)
			return
		if game.run_completed_rounds > reported_round:
			reported_round = game.run_completed_rounds
			print("PACE seed=%s delay=%.2f round=%d seconds=%.2f actions=%d" % [
				seed_label, delay, reported_round, active_seconds, actions])
		# Default baseline needs no lucky automatic-placement build. Optional
		# "bonuses" takes the first offer, without rerolling or granting bonuses.
		if game.bonus_selection.visible and game.bonus_selection.skip_button.visible:
			if take_bonuses:
				if not game.bonus_selection.first_choice.disabled:
					print("BONUS %s" % game.bonus_selection.first_choice.text)
					await game.bonus_selection._choose(0)
			else:
				game.bonus_selection._skip()
			continue
		if game.bonus_selection.visible and game.bonus_selection.rule_choices.visible:
			var first_rule := game.bonus_selection.rule_choices.get_child(0) as Button
			if not first_rule.disabled:
				await game.bonus_selection._choose_rule(0)
			continue
		if game.input_locked or game.hand_manager.current_cards.is_empty():
			continue
		await create_timer(delay).timeout
		if game.input_locked:
			continue
		var card: PlayingCard
		var target: MemoryPile
		for candidate in game.hand_manager.current_cards:
			for pile in game.piles:
				if not pile.completed and (candidate.is_joker or pile.can_accept(candidate.card_value)):
					card = candidate
					target = pile
					break
			if card != null:
				break
		if card == null:
			continue
		game._on_card_drag_started(card)
		if game.selected_card != card:
			continue
		game._place_selected_card(target)
		actions += 1
		frames_without_action = 0
	measuring = false
	print("RESULT seed=%s delay=%.2f rounds=%d seconds=%.2f actions=%d mistakes=%d bonuses=%s" % [
		seed_label, delay, game.run_completed_rounds, active_seconds, actions,
		game.run_mistake_count, game.bonus_manager.active_levels()])
	var success := game.run_completed_rounds == DifficultySettings.MAX_ROUNDS
	game.queue_free()
	await process_frame
	quit(0 if success else 1)
