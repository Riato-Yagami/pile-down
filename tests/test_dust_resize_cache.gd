extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var dust := DustPool.new()
	root.add_child(dust)
	dust.setup(12, false)
	dust.particles[0]["anchor"] = Vector2(7, 11)
	dust.emit_wave(Vector2(20, 20))
	dust.resize_to_viewport(12)
	assert(dust.particles[0]["anchor"] == Vector2(7, 11), "Unchanged bounds rebuilt particles")
	assert(dust.waves.size() == 1, "Unchanged bounds discarded an active wave")
	dust.resize_to_viewport(20)
	assert(dust.particles.size() == 20)
	assert(dust.waves.is_empty())
	root.size += Vector2i(100, 80)
	await process_frame
	dust.resize_to_viewport(20)
	assert(dust._bounds == dust.get_viewport_rect().size)
	assert(dust.particles.size() == 20)
	# An explicit rebuild must still honor updated style/settings at equal size.
	dust.setup(20, true, 3.0, Color.RED)
	assert(dust.debug_visible and dust.viscosity == 3.0 and dust.particle_color == Color.RED)
	dust.free()
	print("Dust resize cache tests passed.")
	quit()
