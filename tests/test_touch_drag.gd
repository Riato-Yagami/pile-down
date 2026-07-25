extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game.start_game()
	var deadline := Time.get_ticks_msec() + 10000
	while game.input_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not game.input_locked)

	var card := game.hand_manager.current_cards[0]
	var touch_position := card.global_position + card.size * 0.5
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = touch_position
	press.pressed = true
	card._on_face_input(press)
	assert(game.selected_card == card)
	assert(card.dragging)
	assert(card.drag_target.is_equal_approx(touch_position))

	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = touch_position + Vector2(0.0, -48.0)
	game._input(drag)
	assert(card.drag_target.is_equal_approx(drag.position))

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = drag.position
	release.pressed = false
	game._input(release)
	await create_timer(0.4).timeout
	assert(not card.dragging)

	print("Touch drag integration test passed.")
	game.queue_free()
	await process_frame
	quit()
