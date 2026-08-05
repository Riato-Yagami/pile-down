extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sequence := SkippableSequence.new()
	sequence.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(sequence)
	await process_frame

	var animated := Control.new()
	sequence.add_child(animated)
	animated.modulate.a = 0.0
	var tween := animated.create_tween()
	tween.tween_property(animated, "modulate:a", 1.0, 10.0)
	sequence.begin(tween)
	assert(sequence.visible)
	assert(sequence.can_skip)
	assert(sequence.mouse_filter == Control.MOUSE_FILTER_STOP)
	sequence.skip_to_end()
	assert(is_equal_approx(animated.modulate.a, 1.0))
	sequence.finish()
	assert(not sequence.visible)
	assert(not sequence.can_skip)

	# Interactive screens leave skipping disabled even if they share the base.
	animated.modulate.a = 0.0
	var protected_tween := animated.create_tween()
	protected_tween.tween_property(animated, "modulate:a", 1.0, 10.0)
	sequence.active_tween = protected_tween
	sequence.skip_to_end()
	assert(is_equal_approx(animated.modulate.a, 0.0))
	protected_tween.kill()

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert(sequence._is_skip_event(click))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	assert(not sequence._is_skip_event(escape))

	sequence.queue_free()
	print("Skippable sequence tests passed.")
	quit()
