extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	var boss := game.challenge_manager.find(&"boss_rush")
	assert(boss != null)
	assert(not boss.disable_special_rules_on_first_round)
	assert(boss.force_special_rules_every_round)
	assert(boss.forced_special_rule_count == 1)
	game._start_challenge(&"boss_rush", false)
	await _wait_for_hand(game)
	_check_first_round(game, boss)
	await game._restart_current_mode()
	await _wait_for_hand(game)
	_check_first_round(game, boss)
	game.queue_free()
	await process_frame
	print("Boss Rush: first-round rule active from menu and after restart.")
	quit()

func _check_first_round(game: GameManager, boss: ChallengeData) -> void:
	assert(game.current_challenge == boss)
	assert(game._progression_round() == boss.start_round)
	assert(not game.special_rule_manager.disable_rules_on_challenge_first_round)
	assert(game.special_rule_manager.active_rules.size() == 1)

func _wait_for_hand(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while (game.splash.visible or game.input_locked or game.hand_manager.current_cards.is_empty()) and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.splash.visible and not game.input_locked)
	assert(not game.hand_manager.current_cards.is_empty())
