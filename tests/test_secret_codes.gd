extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	var achievements := AchievementManager.new()
	var beta := load("res://resources/data/secrets/00_beta.tres") as SecretCodeData
	var early := load("res://resources/data/secrets/01_earlybird.tres") as SecretCodeData
	var now := int(Time.get_unix_time_from_datetime_string("2026-10-24T12:00:00"))
	assert(not beta.is_eligible(achievements, now))
	achievements.unlocked.append(&"first_round")
	assert(not beta.is_eligible(achievements, now))
	achievements.unlock_dates[&"first_round"] = "2026-10-21 00:00:00"
	assert(not beta.is_eligible(achievements, now))
	achievements.unlock_dates[&"first_round"] = "2026-10-20 23:59:59"
	assert(beta.is_eligible(achievements, now))
	assert(early.is_eligible(achievements, int(Time.get_unix_time_from_datetime_string("2026-12-31T23:59:59"))))
	assert(not early.is_eligible(achievements, int(Time.get_unix_time_from_datetime_string("2027-01-01T00:00:00"))))
	achievements.free()

	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.font_manager.unlocked.erase(&"comic_relief_hd")
	game.font_manager.unlocked.erase(&"liberation_sans")
	game.achievement_manager.unlocked.clear()
	game.achievement_manager.unlock_dates.clear()
	assert(not _has_font(game, &"comic_relief_hd"))
	assert(not _has_font(game, &"liberation_sans"))
	game._open_challenge_selection()
	var selection := game.challenge_selection
	var seed_before := game.run_seed_label
	selection._seed_input.text = "piledown-beta"
	selection._play_seed()
	assert(game.run_seed_label == seed_before)
	assert(selection.visible)
	assert(not game.font_manager.unlocked.has(&"comic_relief_hd"))
	game.achievement_manager.unlocked.append(&"first_round")
	game.achievement_manager.unlock_dates[&"first_round"] = "2026-10-20 23:59:59"
	selection._seed_input.text = "  PileDown-Beta  "
	selection._play_seed()
	assert(game.run_seed_label == seed_before and selection.visible)
	assert(game.font_manager.unlocked.has(&"comic_relief_hd"))
	assert(_has_font(game, &"comic_relief_hd"))
	assert(not _has_font(game, &"liberation_sans"))
	var count := game.font_manager.unlocked.size()
	selection._play_seed()
	assert(game.font_manager.unlocked.size() == count)
	assert(not SecretCodeManager.redeem(game, "ordinary-seed"))
	# Exercise both accepted rewards while remaining independent of the wall clock.
	var saved_expiry := early.expires_at
	early.expires_at = "2999-01-01T00:00:00"
	selection._seed_input.text = "earlybird"
	selection._play_seed()
	early.expires_at = saved_expiry
	assert(game.run_seed_label == seed_before and selection.visible)
	assert(game.font_manager.unlocked.has(&"liberation_sans"))
	assert(_has_font(game, &"liberation_sans"))
	assert(game.font_manager.select(&"comic_relief_hd"))
	game._apply_tile_font()
	var hd := game.font_manager.find(&"comic_relief_hd")
	var pixel := game.font_manager.find(&"liberation_sans")
	assert(hd.display_name == "COMIC RELIEF")
	assert(hd.font != pixel.font)
	assert(pixel.display_name == "LIBERATION SANS")
	assert(hd.get_render_font() == hd.font)
	var scalable := FontData.new()
	scalable.font = hd.font
	scalable.hd = true
	assert(scalable.get_render_font() != scalable.font)
	assert((scalable.get_render_font() as FontFile).multichannel_signed_distance_field)
	assert(hd.get_render_font().get_string_size("0123456789?JIV", HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x > 0)
	assert(pixel.get_render_font() != pixel.font)
	assert((pixel.get_render_font() as FontFile).multichannel_signed_distance_field)
	var restored := FontManager.new()
	restored.load_progress()
	assert(restored.unlocked.has(&"comic_relief_hd"))
	assert(restored.selected_font == &"comic_relief_hd")
	restored.free()
	var config := SaveConfig.load_current()
	config.set_value("progression", "unlocked_fonts", [&"comic_relief_hd", &"comic_relief_pixel"])
	config.set_value("settings", "selected_font", &"comic_relief_pixel")
	assert(config.save(SaveConfig.PATH) == OK)
	var migrated := FontManager.new()
	migrated.load_progress()
	assert(migrated.unlocked.has(&"liberation_sans"))
	assert(not migrated.unlocked.has(&"comic_relief_pixel"))
	assert(migrated.selected_font == &"liberation_sans")
	migrated.free()
	await process_frame
	assert(game.achievement_popup.visible)
	await process_frame
	await process_frame
	var popup_icon := game.achievement_popup.get_node("Center/Content/Icon") as TextureRect
	assert(popup_icon.texture == preload("res://resources/materials/icons/fonts.tres"))
	var panel := game.achievement_popup.get_node("Center") as PanelContainer
	assert(panel.get_theme_stylebox("panel") is StyleBoxTexture)
	assert(game.achievement_popup.get_global_rect().encloses(game.achievement_popup_title.get_global_rect()))
	game._achievement_notification_queue.clear()
	while game._achievement_notification_active:
		await process_frame
	game.start_game(false, null, false, "SECRET-FONT-RENDER")
	while game.input_locked or game.hand_manager.current_cards.is_empty():
		await process_frame
	for card in game.hand_manager.current_cards:
		assert(card._value_font == hd.get_render_font())
	for pile in game.piles:
		assert(pile._value_font == hd.get_render_font())
	game.queue_free()
	await process_frame
	print("Secret code dates, seed interception, popup, hidden rewards, persistence and HD tests passed.")
	quit()


func _has_font(game: GameManager, id: StringName) -> bool:
	for entry in ProgressionSnapshotBuilder.fonts(game):
		if entry.id == id:
			return true
	return false
