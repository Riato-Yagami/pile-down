extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	game.progression_button.pressed.emit()
	assert(game.progression_menu.visible)
	var snapshot := game._progression_snapshot()
	assert((snapshot.achievements as Array).size() == AchievementRegistry.create_all().size())
	assert((snapshot.bonuses as Array).size() == BonusRegistry.create_all().size())
	assert(
		(snapshot.special_rules as Array).size()
		== SpecialRuleRegistry.create_all_rules().size()
	)
	assert((snapshot.fonts as Array).size() == FontRegistry.create_all().size())
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	assert(game._handle_global_shortcut(escape))
	assert(not game.progression_menu.visible)
	game.queue_free()
	print("Progression game integration tests passed.")
	quit()
