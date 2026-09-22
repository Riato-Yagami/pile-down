extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var challenges := ChallengeRegistry.create_all()
	var manager := AchievementManager.new()
	root.add_child(manager)
	var emitted: Array[StringName] = []
	manager.achievement_unlocked.connect(
		func(data: AchievementData) -> void: emitted.append(data.id)
	)
	var completed: Array[StringName] = []
	for challenge in challenges:
		var achievement_id := StringName("complete_%s" % challenge.id)
		assert(manager.find(achievement_id) != null,
			"Missing active completion achievement for %s" % challenge.id)
		completed.append(challenge.id)
		manager.record_challenge_completion(challenge.id, completed, challenges)
		assert(manager.unlocked.has(achievement_id))
		assert(emitted.count(achievement_id) == 1)
		manager.record_challenge_completion(challenge.id, completed, challenges)
		assert(emitted.count(achievement_id) == 1)
		assert(manager.unlocked.has(&"challenge_accepted") == (completed.size() == challenges.size()))
	assert(emitted.size() == challenges.size() + 1)
	var restored := AchievementManager.new()
	restored.load_progress()
	assert(restored.unlocked == manager.unlocked)
	restored.free()
	manager.queue_free()
	await process_frame
	print("Challenge completion achievement tests passed.")
	quit()
