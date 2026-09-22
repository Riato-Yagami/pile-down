extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var achievements := AchievementRegistry.create_all()
	var active: Dictionary = {}
	var counts: Dictionary = {}
	var closed_categories: Array[StringName] = []
	var category: StringName = &""
	var previous := 0
	for data in achievements:
		assert(not active.has(data.id))
		assert(data.difficulty >= 1 and data.difficulty <= 10)
		if data.category != category:
			assert(not closed_categories.has(data.category))
			closed_categories.append(category)
			category = data.category
			previous = 0
		assert(data.difficulty >= previous)
		previous = data.difficulty
		active[data.id] = data
		counts[data.id] = 0
	assert(not active.has(&"complete_no_looking_back"))
	var groups: Array = [FontRegistry.create_all(), ColorPaletteRegistry.create_all(), ChallengeRegistry.create_all()]
	for group: Array in groups:
		previous = -1
		var ids: Array[StringName] = []
		for data: Data in group:
			assert(not data.id.is_empty() and not ids.has(data.id))
			ids.append(data.id)
			var rank := ProgressionOrdering.unlock_difficulty(data)
			assert(rank >= previous)
			previous = rank
			var required: AchievementData = data.required_achievement
			if rank == 0:
				assert(required == null)
				continue
			assert(required != null and active.has(required.id))
			counts[required.id] += 1
			if data is ChallengeData:
				assert(data.id != &"no_looking_back")
				assert(required.id != &"challenge_accepted" and required.id != &"all_achievements")
				assert(not String(required.id).begins_with("complete_"))
	for id in counts:
		assert(counts[id] == 1, "Expected one distinct reward for %s, got %s" % [id, counts[id]])
	var font_catalog := ProgressionFontCatalog.new()
	var achievement_catalog := ProgressionAchievementCatalog.new()
	assert(font_catalog.get_available_fonts() == groups[0])
	assert(font_catalog.get_available_palettes() == groups[1])
	assert(achievement_catalog.get_achievements() == achievements)
	font_catalog.free()
	achievement_catalog.free()
	# Requirements remain resource-backed when difficulty is edited later.
	var easy := AchievementData.new(&"easy")
	var hard := AchievementData.new(&"hard")
	easy.difficulty = 2
	hard.difficulty = 8
	var first := ColorPaletteData.new(&"a", "", [], false, hard)
	var second := ColorPaletteData.new(&"b", "", [], false, easy)
	var rewards := [first, second]
	ProgressionOrdering.sort_unlockables(rewards)
	assert(rewards == [second, first])
	hard.difficulty = 1
	ProgressionOrdering.sort_unlockables(rewards)
	assert(rewards == [first, second])
	# Existing achievements grant newly associated rewards without losing old ones.
	var config := ConfigFile.new()
	config.set_value("progression", "unlocked_achievements", [&"first_round", &"deja_vu_full_activation"])
	config.set_value("progression", "unlocked_fonts", [&"vcr", &"tiny5"])
	config.set_value("progression", "unlocked_palettes", [&"arcade", &"pastel"])
	assert(config.save(AchievementManager.SAVE_PATH) == OK)
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	await process_frame
	assert(game.font_manager.unlocked.has(&"press_start_2p"))
	assert(game.font_manager.unlocked.has(&"tiny5"))
	assert(game.palette_manager.unlocked.has(&"rgb"))
	assert(game.palette_manager.unlocked.has(&"pastel"))
	assert(game.achievement_manager.definitions == achievements)
	assert(game.font_manager.definitions == groups[0])
	assert(game.palette_manager.definitions == groups[1])
	assert(game.challenge_manager.definitions == groups[2])
	game.queue_free()
	await process_frame
	print("Progression reward coverage and ordering tests passed.")
	quit()
