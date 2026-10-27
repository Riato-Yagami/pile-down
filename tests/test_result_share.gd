extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(35).timeout.connect(func(): quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.game_mode = GameManager.GameMode.STANDARD
	game.round_number = 30
	game.run_seed_label = "SHARE-TEST"
	for index in 4:
		var pile := preload("res://resources/scenes/gameplay/Pile.tscn").instantiate() as MemoryPile
		game.piles_board.add_child(pile)
		pile.setup(index, 5)
		pile.position = Vector2((index % 2) * 44, (index / 2) * 44)
		pile.current_value = [3, 2, 0, 5][index]
		pile.completed = index == 2
		if pile.completed:
			pile.hide()
		game.piles.append(pile)
	for value in [1, 3, 0]:
		var card := preload("res://resources/scenes/gameplay/Card.tscn").instantiate() as PlayingCard
		game.hand_container.add_child(card)
		card.setup(value)
		card.set_joker(value == 0)
		game.hand_manager.current_cards.append(card)
	var empty_piles: Array[MemoryPile] = []
	assert(ResultShare.capture_tiles(empty_piles).contains("—"))
	var now := Time.get_ticks_msec()
	game.game_started_msec = now - 2672
	game.run_pause_started_msec = now
	game.run_paused_msec = 0
	await game._finish_game(false)
	var end := game.overlay as EndScreen
	assert(end.share_message.contains("30"))
	assert(end.share_message.contains("2 s 672 ms"))
	assert(end.share_message.contains(ResultShare.ITCH_URL))
	assert(end.share_message.contains(ResultShare.GOOGLE_PLAY_URL))
	assert(not end.share_message.contains("[center]"))
	assert(end.share_message.contains("3️⃣2️⃣\n" + ResultShare.EMPTY_TILE + "5️⃣"))
	assert(not end.share_message.contains("1️⃣3️⃣🃏"))
	assert(not end.share_message.contains("PLATEAU") and not end.share_message.contains("MAIN"))
	assert(not end.share_message.contains("itch.io :") and not end.share_message.contains("Google Play :"))
	assert(end.share_message.begins_with(".Pile Down.\n\n3️⃣2️⃣"))
	assert(end.share_message.find("3️⃣2️⃣") < end.share_message.find("30"))
	assert(not end.share_button.disabled)
	var copied: Array[String] = []
	end.copy_share_result(func(message: String): copied.append(message))
	assert(copied == [end.share_message])
	assert(end.share_button.texture_normal == end.COPIED_ICON)
	var saved := end.share_message
	game.round_number = 29
	game.piles[0].current_value = 1
	game.hand_manager.current_cards[0].card_value = 9
	assert(end.share_message == saved, "Share uses the displayed result snapshot")
	await create_timer(1.0).timeout
	assert(end.share_button.texture_normal == end.SHARE_ICON)
	game.round_number = 0
	await game._finish_game(true)
	assert(end.share_message.contains(TranslationServer.translate("%d ROUNDS LEFT") % 0))
	game.queue_free()
	await process_frame
	for viewport_size in [Vector2i(256, 320), Vector2i(636, 323), Vector2i(752, 640)]:
		root.size = viewport_size
		var popup := preload("res://resources/scenes/ui/EndScreen.tscn").instantiate() as EndScreen
		root.add_child(popup)
		popup.high_score.hide()
		popup.progression.hide()
		popup.set_share_result("30 MANCHES\nRESTANTES", "en 2 s 672 ms")
		popup.seed_display.set_seed("0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz")
		for expanded in [false, true]:
			popup.seed_display._set_highlight(expanded)
			await create_timer(0.3).timeout
			assert(popup.panel.get_global_rect().encloses(popup.share_button.get_global_rect()))
			assert(not popup.share_button.get_global_rect().intersects(popup.seed_display.get_global_rect()))
			assert(popup.share_button.global_position.x > popup.seed_display.global_position.x)
			assert(popup.share_button.get_global_rect().end.y <= popup.panel.get_global_rect().end.y)
		popup.seed_display.hide()
		await process_frame
		assert(popup.share_button.is_visible_in_tree())
		popup.queue_free()
		await process_frame
	print("Result sharing tests passed: result/time/links, copy feedback, snapshot and footer layout.")
	quit()
