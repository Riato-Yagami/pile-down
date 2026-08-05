extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	assert(not game.back_button.visible)
	assert(game.back_button.z_index > 0)
	assert(game._start_transition_elements().has(game.back_button))
	game.splash.visible = false
	game.overlay.visible = true
	game.overlay_back_button.visible = true
	await process_frame
	assert(game.overlay_back_button.get_parent() == game.overlay_panel)
	var click_position := game.overlay_back_button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = click_position
	press.pressed = true
	assert(game._is_overlay_back_pointer_event(press))
	press.position = Vector2.ZERO
	assert(not game._is_overlay_back_pointer_event(press))

	game.overlay.visible = false
	game.back_button.visible = true
	var gameplay_click := game.back_button.get_global_rect().get_center()
	press.position = gameplay_click
	assert(game._is_gameplay_back_pointer_event(press))
	press.position = Vector2.ZERO
	assert(not game._is_gameplay_back_pointer_event(press))
	var motion := InputEventMouseMotion.new()
	motion.position = gameplay_click
	game._update_gameplay_back_hover(motion)
	assert(game.back_button.material != null)
	motion.position = Vector2.ZERO
	game._update_gameplay_back_hover(motion)
	assert(game.back_button.material == null)
	print("Overlay ESC button test passed.")
	game.queue_free()
	await process_frame
	quit()
