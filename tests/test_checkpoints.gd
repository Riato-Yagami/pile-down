extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	assert(game.get_checkpoint_bonus_choice_count(10) == 2)
	assert(game.get_checkpoint_bonus_choice_count(20) == 4)
	assert(game.get_checkpoint_bonus_choice_count(30) == 7)

	var snapshot := CheckpointSnapshot.new()
	snapshot.checkpoint_id = 1
	snapshot.start_round = DifficultySettings.CHECKPOINT_INTERVAL
	snapshot.pile_count = 2
	snapshot.hand_size = 2
	snapshot.start_value = 5
	snapshot.turn_time = 4.0
	snapshot.difficulty_droughts = {
		&"pile": 1, &"hand": 2, &"start_value": 3, &"time": 4,
	}
	snapshot.unlocked_endless = false
	var premature := CheckpointSnapshot.from_dictionary(snapshot.to_dictionary())
	premature.checkpoint_id = 2
	premature.start_round = DifficultySettings.CHECKPOINT_INTERVAL * 2
	game._pending_checkpoint_snapshot = premature
	assert(not game._unlock_completed_checkpoint(premature.start_round))
	assert(not game.unlocked_checkpoints.has(2))
	game._pending_checkpoint_snapshot = snapshot
	assert(not game._unlock_completed_checkpoint(DifficultySettings.CHECKPOINT_INTERVAL - 1))
	assert(game.unlocked_checkpoints.is_empty())
	assert(game._unlock_completed_checkpoint(DifficultySettings.CHECKPOINT_INTERVAL))
	assert(game.unlocked_checkpoints.has(1))
	var saved: Dictionary = game._checkpoint_value(game.checkpoint_snapshots, 1, {})
	assert(int(saved.start_round) == DifficultySettings.CHECKPOINT_INTERVAL)
	assert(int(saved.pile_count) == 2)

	var damaged_snapshot := CheckpointSnapshot.from_dictionary(snapshot.to_dictionary())
	damaged_snapshot.checkpoint_id = 2
	damaged_snapshot.start_round = DifficultySettings.CHECKPOINT_INTERVAL * 2
	game._pending_checkpoint_snapshot = damaged_snapshot
	game.checkpoint_segment_damage_count = 1
	assert(not game._unlock_completed_checkpoint(damaged_snapshot.start_round))
	assert(not game.unlocked_checkpoints.has(2))
	# Passing the previously unlocked checkpoint resets the flawless section.
	assert(not game._unlock_completed_checkpoint(snapshot.start_round))
	assert(game.checkpoint_segment_damage_count == 0)
	game._pending_checkpoint_snapshot = damaged_snapshot
	assert(game._unlock_completed_checkpoint(damaged_snapshot.start_round))
	assert(game.unlocked_checkpoints.has(2))

	var replacement := snapshot.to_dictionary()
	replacement.pile_count = 4
	game._pending_checkpoint_snapshot = CheckpointSnapshot.from_dictionary(replacement)
	assert(not game._unlock_completed_checkpoint(DifficultySettings.CHECKPOINT_INTERVAL))
	var preserved: Dictionary = game._checkpoint_value(game.checkpoint_snapshots, 1, {})
	assert(int(preserved.pile_count) == 2)

	game.current_checkpoint_id = 1
	assert(game._update_checkpoint_high_score(12) == "ROUND")
	game.current_checkpoint_id = 2
	assert(game._update_checkpoint_high_score(11).is_empty())
	assert(game._update_checkpoint_high_score(14) == "ROUND")
	assert(game.checkpoint_best_rounds_left == DifficultySettings.TOTAL_ROUNDS - 13)
	game.checkpoint_uses_endless_progression = true
	assert(game._update_checkpoint_high_score(DifficultySettings.TOTAL_ROUNDS + 2) == "ROUND")
	assert(game.checkpoint_endless_best_round == DifficultySettings.TOTAL_ROUNDS + 2)

	var legacy := snapshot.to_dictionary()
	legacy.checkpoint_id = 1
	legacy.start_round = DifficultySettings.CHECKPOINT_INTERVAL * 5
	game.checkpoint_snapshots = {1: legacy}
	game.unlocked_checkpoints.assign([1])
	assert(game._normalise_checkpoint_ids())
	assert(game.unlocked_checkpoints.has(1))
	assert(game.unlocked_checkpoints.has(5))
	var first_checkpoint: Dictionary = game._checkpoint_value(
		game.checkpoint_snapshots, 1, {}
	)
	assert(int(first_checkpoint.start_round) == DifficultySettings.CHECKPOINT_INTERVAL)
	var migrated: Dictionary = game._checkpoint_value(game.checkpoint_snapshots, 5, {})
	assert(int(migrated.start_round) == DifficultySettings.CHECKPOINT_INTERVAL * 5)

	game.newly_unlocked_checkpoints.assign([1, 5])
	game.overlay_details.text = "[center]SCORE[/center]"
	game._append_new_checkpoint_summary()
	assert(not game.overlay_details.text.contains("NEW CHECKPOINT"))
	assert(game.overlay_unlocks.visible)
	assert(game.overlay_unlocks.text.contains("NEW[/color] CHECKPOINTS:"))
	assert(game.overlay_unlocks.text.contains("1 + 5"))
	game.newly_unlocked_checkpoints.assign([1])
	game._append_new_checkpoint_summary()
	assert(game.overlay_unlocks.text.contains("NEW[/color] CHECKPOINT: 1"))
	assert(not game.overlay_unlocks.text.contains("CHECKPOINTS"))
	game.newly_discovered_bonuses.assign([&"open_book"])
	game.newly_encountered_rules.assign([&"shell_game"])
	game.newly_unlocked_achievements.assign([&"max_piles"])
	game._append_new_progression_summary()
	assert(not game.overlay_unlocks.text.contains("NEW PROGRESSION"))
	assert(game.overlay_unlocks.text.contains("icons/bonuses.png"))
	assert(game.overlay_unlocks.text.contains(
		"+ [color=#4D82C2]NEW[/color] [img=16x16]"
	))
	assert(game.overlay_unlocks.text.contains("OPEN BOOK"))
	assert(game.overlay_unlocks.text.contains("icons/rules.png"))
	assert(game.overlay_unlocks.text.contains("SHELL GAME"))
	assert(game.overlay_unlocks.text.contains("icons/trophies.png"))
	assert(game.overlay_unlocks.text.contains("STACK OVERFLOW"))
	game.unread_progression_pages.clear()
	game._mark_progression_page_unread(ProgressionMenu.Page.HIGHSCORES)
	game._mark_progression_page_unread(ProgressionMenu.Page.BONUSES)
	assert(not game.unread_progression_pages.has(ProgressionMenu.Page.HIGHSCORES))
	assert(game.progression_notification.visible)
	game.progression_menu.open(game._progression_snapshot())
	assert(not game.progression_menu._page_badges[ProgressionMenu.Page.HIGHSCORES].visible)
	assert(game.progression_menu._page_badges[ProgressionMenu.Page.BONUSES].visible)
	game.progression_menu.page_buttons[ProgressionMenu.Page.BONUSES].pressed.emit()
	assert(not game.progression_menu._page_badges[ProgressionMenu.Page.BONUSES].visible)
	assert(not game.progression_notification.visible)
	assert(game.overlay_back_button.z_index > 0)

	print("Checkpoint tests passed.")
	game.queue_free()
	quit()
