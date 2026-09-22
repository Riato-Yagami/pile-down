extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	await process_frame
	_capture("screenshot-01-menu.png")

	game.splash.visible = false
	game.pile_count = 4
	game.hand_size = 3
	game.start_value = 6
	game.turn_time = 5.0
	game.round_number = DifficultySettings.TOTAL_ROUNDS
	game.run_time_label.visible = false
	game.bonus_manager.begin_run()
	game.background_manager.start_run(game.cosmetic_rng)
	game.start_round()
	await _wait_until_unlocked(game)
	await create_timer(0.25).timeout
	_capture("screenshot-02-gameplay.png")

	var announcement_rules: Array[SpecialRuleData] = []
	for rule in SpecialRuleRegistry.create_all_rules():
		if rule.id in [&"floor_is_lava", &"hot_potatoes"]:
			announcement_rules.append(rule)
	game.special_rule_manager.announcement.show_rules(announcement_rules)
	await create_timer(0.3).timeout
	_capture("screenshot-03-special-rules.png")
	game.special_rule_manager.announcement.visible = false

	var bonus_choices: Array[BonusData] = []
	for bonus in BonusRegistry.create_all():
		if bonus.id in [&"quick_peek", &"wild_card"]:
			bonus_choices.append(bonus)
	game.bonus_manager.selection.present(bonus_choices, [1, 1])
	await create_timer(0.3).timeout
	_capture("screenshot-04-bonus-selection.png")
	game.bonus_manager.selection.visible = false

	game.overlay_high_score.visible = false
	game.overlay_title.text = "[center]12 ROUNDS LEFT[/center]"
	game.overlay_details.text = "[center]in 04:37[/center]"
	game.overlay_button.text = "REPLAY"
	game._show_game_over_overlay(false)
	await process_frame
	_capture("screenshot-05-game-over.png")

	game.queue_free()
	quit()


func _wait_until_unlocked(game: GameManager) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)


func _capture(file_name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.resize(512, 640, Image.INTERPOLATE_NEAREST)
	var error := image.save_png(
		ProjectSettings.globalize_path("res://publishing/%s" % file_name)
	)
	assert(error == OK)
