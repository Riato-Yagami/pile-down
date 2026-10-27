extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game._achievement_notifications_enabled = false
	var styles := game.value_style_manager
	assert(ValueStyleManager.CATALOG.enabled_data.size() == 4)
	assert(not styles.select(&"dots"))
	assert(not styles.select(&"letters"))
	assert(not styles.select(&"roman"))
	var achievements := game.achievement_manager
	achievements.configure_run(RunSummary.Mode.NORMAL)
	achievements._on_special_rule_round_completed([&"roman_holiday"], [])
	achievements._on_special_rule_round_completed([&"merry_go_stack"], [])
	assert(not achievements.unlocked.has(&"circus_maximus"), "Separate rounds must not count as a combo")
	achievements.configure_run(RunSummary.Mode.NORMAL, true)
	achievements._on_special_rule_round_completed([&"roman_holiday", &"merry_go_stack"], [])
	assert(not styles.select(&"roman"), "Seeded runs follow achievement eligibility")
	achievements.configure_run(RunSummary.Mode.NORMAL)
	achievements._on_special_rule_round_completed([&"roman_holiday", &"merry_go_stack"], [])
	assert(achievements.unlocked.has(&"circus_maximus"))
	assert(styles.select(&"roman"))
	game.max_discovered_tile_value = 9
	game.hand_manager.clear_hand(game.hand_container)
	for index in 2:
		game.hand_manager._create_card(game.hand_container, 0, true, false, false, game.round_modifiers, false, false)
	assert(not styles.select(&"dots"), "Two jokers do not unlock dots")
	achievements.configure_run(RunSummary.Mode.NORMAL, true)
	game.hand_manager._create_card(game.hand_container, 0, true, false, false, game.round_modifiers, false, false)
	assert(not styles.select(&"dots"), "Seeded runs follow achievement eligibility")
	game.hand_manager.clear_hand(game.hand_container)
	achievements.configure_run(RunSummary.Mode.NORMAL)
	for index in 2:
		game.hand_manager._create_card(game.hand_container, 0, true, false, false, game.round_modifiers, false, false)
	assert(not styles.select(&"dots"), "Jokers from different hands are not accumulated")
	game.hand_manager._create_card(game.hand_container, 0, true, false, false, game.round_modifiers, false, false)
	assert(achievements.unlocked.has(&"joker_trio"))
	assert(styles.select(&"dots"))
	assert(styles.select(&"roman"))
	var menu := game.progression_menu
	menu.open(game._progression_snapshot())
	menu._show_page(ProgressionMenu.Page.FONTS)
	(menu.cosmetic_lists as CustomisationTabs).select_tab(2, false)
	assert(menu.values_content.get_child(1).disabled)
	assert(not menu.values_content.get_child(3).disabled)
	var label := menu.font_preview.get_child(8).get_child(0) as Label
	assert(label.text == "VII")
	assert(label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= maxf(label.size.x, 32.0))
	var challenges := game.challenge_manager
	assert(not challenges.definitions.is_empty())
	game.start_game(false, challenges.definitions[0])
	assert(challenges.started.has(challenges.definitions[0].id), "Launching a challenge records it immediately")
	for index in challenges.definitions.size() - 1:
		challenges.record_start(challenges.definitions[index])
	achievements.record_challenge_starts(challenges.started, challenges.definitions)
	assert(not achievements.unlocked.has(&"a_to_z"))
	challenges.record_start(challenges.definitions[-1])
	achievements.record_challenge_starts(challenges.started, challenges.definitions)
	assert(achievements.unlocked.has(&"a_to_z"))
	assert(styles.select(&"letters"))
	var reloaded := ValueStyleManager.new()
	reloaded.load_progress()
	assert(reloaded.selected_style == &"letters")
	assert(reloaded.select(&"roman"))
	assert(reloaded.select(&"dots"))
	reloaded.free()
	var history := ChallengeManager.new()
	history.load_progress()
	assert(history.started.size() == challenges.definitions.size())
	history.record_start(history.definitions[0])
	assert(history.started.size() == challenges.definitions.size(), "Repeated launches do not add progress")
	var config := SaveConfig.load_current()
	config.erase_section_key("challenges", "started")
	var legacy_scores := {}
	for challenge in challenges.definitions:
		legacy_scores[challenge.id] = 0
	config.set_value("challenges", "highscores", legacy_scores)
	config.save(SaveConfig.PATH)
	history.load_progress()
	assert(history.started.size() == challenges.definitions.size(), "Legacy recorded runs count as launches")
	assert(not ChallengeManager.is_valid_progress_value("started", [42]))
	history.free()
	game.queue_free()
	await process_frame
	await process_frame
	print("Value style resources, combo eligibility, challenge launches, selection and persistence passed.")
	quit()
