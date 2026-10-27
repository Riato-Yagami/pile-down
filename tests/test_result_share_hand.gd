extends "res://tests/test_seed_replay.gd"


func _run() -> void:
	create_timer(75).timeout.connect(func(): quit(1))
	for scenario in ["timeout", "checkpoint", "playable_discard"]:
		var game := GameScene.instantiate() as GameManager
		root.add_child(game)
		game.splash.hide()
		game.special_rule_manager.suppress_next_announcement = true
		game.start_game(false, null, false, "SHARE-HAND-" + scenario, {}, [&"snake"],
			{"pile_count": 2, "hand_size": 3, "start_value": 5, "turn_time": 100.0})
		await _wait_for_hand(game)
		game.snake_rule_controller.set_process(false)
		game.timer_manager.stop_countdown()
		game.hand_manager.finish_all_card_entrances()
		game.mistakes_left = 1
		var card := game.hand_manager.current_cards[0]
		card.card_value = 0
		game.hand_manager.current_cards[1].card_value = 3
		game.hand_manager.current_cards[2].set_joker(true)
		if scenario == "checkpoint":
			game.game_mode = GameManager.GameMode.CHECKPOINT
			game.current_checkpoint_id = 1
		if scenario == "playable_discard":
			game.hand_manager.current_cards.erase(card)
			game.hand_manager.track_discarding_card(card)
		game.selected_card = card
		var before := ResultShare.capture_tiles(game.piles)
		assert(not before.contains("🃏") and not before.contains("MAIN"))
		await game._handle_mistake(null if scenario == "timeout" else game.piles[0], scenario == "timeout", true)
		var end := game.overlay as EndScreen
		assert(game.overlay.visible)
		assert(end.share_message.contains(" s "))
		assert(not end.share_message.contains("PARTIE PAR ÉTAPES"))
		assert(end.share_message.contains(before), "Final board snapshot was lost: " + scenario)
		assert(game.hand_manager.current_cards.is_empty(), "Exercise the real death discard")
		var snapshot := end.share_message
		await create_timer(0.4).timeout
		assert(end.share_message == snapshot)
		game.start_game(false, null, false, "NEXT-RUN", {}, [&"snake"], {"pile_count": 1})
		assert(end.pending_tile_snapshot.is_empty(), "A new run must clear the previous death snapshot")
		await _wait_for_hand(game)
		game.queue_free()
		await process_frame
	print("Share snapshot passed: board only, timeout, checkpoint loss, discarded selection and reset.")
	quit()
