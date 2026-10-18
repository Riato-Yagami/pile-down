extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")

class LinksTestGame:
	extends GameManager
	var open_requests: Array[String] = []
	var open_result := OK
	func _open_external_link(url: String, link_id: StringName = &"") -> void:
		GameMenuPresenterScript.open_external_link(self, url, link_id, _open_browser)
	func _open_browser(url: String) -> int:
		open_requests.append(url)
		return open_result


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(25.0).timeout.connect(func() -> void: quit(1))
	var config := SaveConfig.load_current()
	config.set_value("graphics", "screen_size_mode", "classic")
	assert(config.save(SaveConfig.PATH) == OK)
	var scene := GameScene.instantiate()
	scene.set_script(LinksTestGame)
	var game := scene as LinksTestGame
	root.add_child(game)
	game._achievement_notifications_enabled = false
	var manager := game.achievement_manager
	assert(manager.find(&"coffee_break") != null)
	var buttons: Dictionary = {}
	for child in game.links_options.get_children():
		if child is Button:
			buttons[child.text] = child
	assert(buttons.has("KO-FI"))
	var notifications := {"count": 0}
	manager.achievement_unlocked.connect(func(data: AchievementData) -> void:
		if data.id == &"coffee_break":
			notifications.count += 1
	)
	# Menu actions must remain available after an achievement-disabled seeded run.
	manager.configure_run(RunSummary.Mode.CHALLENGE, true, false)
	assert(not manager.can_unlock(&"max_hand"))
	game.open_result = ERR_CANT_OPEN
	buttons["KO-FI"].pressed.emit()
	assert(not manager.unlocked.has(&"coffee_break"))
	game.open_result = OK
	buttons["JUELS.DEV"].pressed.emit()
	buttons["ITCH.IO"].pressed.emit()
	assert(not manager.unlocked.has(&"coffee_break"))
	buttons["KO-FI"].pressed.emit()
	buttons["KO-FI"].pressed.emit()
	assert(game.open_requests.back() == "https://ko-fi.com/juels")
	assert(manager.unlocked.has(&"coffee_break"))
	assert(notifications.count == 1)
	assert(manager.unlock_dates.has(&"coffee_break"))
	assert(not manager.can_unlock(&"max_hand"), "The menu must not change run eligibility")
	config = SaveConfig.load_current()
	assert(String(config.get_value("graphics", "screen_size_mode")) == "classic")
	var restored := AchievementManager.new()
	root.add_child(restored)
	restored.load_progress()
	assert(restored.unlocked.has(&"coffee_break"))
	assert(restored.unlock_dates[&"coffee_break"] == manager.unlock_dates[&"coffee_break"])
	# Visiting Ko-fi can also complete the collection when it is the final missing item.
	restored.unlocked.erase(&"coffee_break")
	for data in restored.definitions:
		if data.id not in [&"all_achievements", &"coffee_break"]:
			restored.unlock(data.id, false)
	assert(not restored.unlocked.has(&"all_achievements"))
	restored.configure_run(RunSummary.Mode.CHALLENGE, true, false)
	restored.external_link_opened.emit(&"kofi")
	assert(restored.unlocked.has(&"coffee_break"))
	assert(restored.unlocked.has(&"all_achievements"))
	game.queue_free()
	restored.queue_free()
	await process_frame
	print("Ko-fi achievement tests passed.")
	quit()
