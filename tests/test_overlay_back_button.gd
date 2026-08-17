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
	game.overlay_quit_button.visible = true
	await process_frame
	assert(game.overlay_quit_button.text == "QUIT")
	assert(game.overlay_quit_button.get_parent().name == "OverlayButtons")
	assert(game.overlay_quit_button.get_parent().get_child_count() == 3)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true

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
	print("Overlay quit button test passed.")
	game.queue_free()
	await process_frame
	quit()
