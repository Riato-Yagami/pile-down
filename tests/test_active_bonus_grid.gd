extends SceneTree

const GAME_SCENE := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate() as GameManager
	root.add_child(game)
	# Keep this layout test independent from the user's debug-locked bonuses.
	game.bonus_manager.active.clear()
	game.bonus_manager._refresh_bar()
	for index in 9:
		game.bonus_manager._add_or_upgrade(
			game.bonus_manager.definitions[index]
		)
	await process_frame
	assert(game.active_bonus_bar.visible)
	assert(game.active_bonus_bar.columns == 6)
	assert(game.active_bonus_bar.get_child_count() == 9)
	var first := game.active_bonus_bar.get_child(0) as ActiveBonusBadge
	assert(first.text.length() == 2)
	assert(first._acronym("BRING A FRIEND") == "BAF")
	assert(first._acronym("REDRAW") == "RE")
	var colliding_definitions: Array[BonusData] = [
		BonusData.new(&"open_book", "OPEN BOOK"),
		BonusData.new(&"old_book", "OLD BOOK"),
		BonusData.new(&"open_box", "OPEN BOX"),
	]
	var unique_acronyms := ActiveBonusBadge.build_unique_acronyms(colliding_definitions)
	assert(unique_acronyms[&"open_book"] == "OpBoo")
	assert(unique_acronyms[&"old_book"] == "OlB")
	assert(unique_acronyms[&"open_box"] == "OpBox")
	assert(first.get_theme_stylebox("normal") is StyleBoxTexture)
	var deja_vu := BonusRegistry.get_bonus(&"deja_vu")
	first.description_requested.emit(deja_vu.description)
	await process_frame
	await process_frame
	await process_frame
	assert(game.bonus_manager.active_description.visible)
	assert(game.bonus_manager.active_description_text.text == deja_vu.description)
	var description_rect := game.bonus_manager.active_description.get_global_rect()
	var viewport_size := game.bonus_manager.active_description.get_viewport_rect().size
	var viewport_width := viewport_size.x
	assert(description_rect.size.x <= viewport_width * 0.5)
	assert(description_rect.size.y < viewport_size.y - 8.0)
	assert(description_rect.position.x >= 0.0)
	assert(description_rect.end.x <= viewport_width)
	first.description_hidden.emit()
	assert(not game.bonus_manager.active_description.visible)
	assert(deja_vu.description.contains("matching card"))
	assert(deja_vu.description.contains("compatible piles"))
	var second := game.active_bonus_bar.get_child(1) as ActiveBonusBadge
	assert(first.position.x > second.position.x)
	game.bonus_manager._add_or_upgrade(game.bonus_manager.definitions[0])
	await process_frame
	first = game.active_bonus_bar.get_child(0) as ActiveBonusBadge
	assert(first.text.contains(" "))
	assert(first.text.ends_with("II"))
	var ninth := game.active_bonus_bar.get_child(8) as ActiveBonusBadge
	assert(ninth.position.y > first.position.y)
	assert(
		game.active_bonus_bar.get_global_rect().end.y
		<= game.hand_tray.get_global_rect().position.y
	)
	game.queue_free()
	await process_frame
	print("Active bonus grid test passed.")
	quit()
