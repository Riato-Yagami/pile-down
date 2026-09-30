extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _tap(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)


func _run() -> void:
	create_timer(15.0).timeout.connect(func() -> void: quit(1))
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.splash.hide()
	game.gameplay_layer.show()
	game.bonus_manager._add_or_upgrade(BonusRegistry.get_bonus(&"safety_net"))
	game.bonus_manager.safety_net_available = false
	game.bonus_manager._refresh_bar()
	await process_frame
	await process_frame
	var badge := game.active_bonus_bar.get_child(0) as ActiveBonusBadge
	assert(badge.modulate.a == 1.0)
	var point := badge.get_global_rect().get_center()
	_tap(point)
	await process_frame
	await process_frame
	assert(game.bonus_manager.active_description.visible)
	_tap(point)
	await process_frame
	assert(not game.bonus_manager.active_description.visible)
	_tap(point)
	await process_frame
	await process_frame
	assert(game.bonus_manager.active_description.visible)
	_tap(Vector2(10, 10))
	assert(not game.bonus_manager.active_description.visible)
	_tap(point)
	game.bonus_manager.set_descriptions_enabled(false)
	await process_frame
	assert(not game.bonus_manager.active_description.visible)
	assert(not badge._touch_open)
	game.queue_free()
	await process_frame
	print("Bonus touch tests passed.")
	quit()
