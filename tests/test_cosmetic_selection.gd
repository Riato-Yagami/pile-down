extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	for id in [&"arcade_crt", &"monochrome"]:
		if not game.palette_manager.unlocked.has(id):
			game.palette_manager.unlocked.append(id)
	game._on_progression_palette_selected(&"arcade_crt")
	game.splash.hide()
	game.start_game()
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)
	_check_tiles(game)
	game._on_progression_palette_selected(&"monochrome")
	_check_tiles(game)
	game.timer_manager.stop_countdown()
	var menu := game.progression_menu
	menu.open(game._progression_snapshot())
	menu._show_page(ProgressionMenu.Page.FONTS)
	await process_frame
	await process_frame
	for list in [menu.fonts_content, menu.palettes_content]:
		var checked := 0
		for child in list.get_children():
			var button := child as Button
			if button == null or not button.button_pressed:
				continue
			checked += 1
			button.grab_focus()
			for pressed in [true, false]:
				var event := InputEventAction.new()
				event.action = &"ui_accept"
				event.pressed = pressed
				root.push_input(event)
			assert(button.button_pressed)
		assert(checked == 1)
	game.queue_free()
	await process_frame
	print("Cosmetic selection tests passed.")
	quit()


func _check_tiles(game: GameManager) -> void:
	var expected := game.palette_manager.find(
		game.palette_manager.selected_palette
	).normalized_colors()
	assert(not game.hand_manager.current_cards.is_empty())
	assert(not game.piles.is_empty())
	for card in game.hand_manager.current_cards:
		assert(card._tile_colors == expected)
		card.setup(card.card_value)
		var material := card.face_sprite.material as ShaderMaterial
		assert(material.get_shader_parameter("tile_color").is_equal_approx(
			expected[card.card_value % expected.size()]
		))
	for pile in game.piles:
		assert(pile._tile_colors == expected)
