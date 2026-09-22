extends SceneTree

const Warmup := preload("res://resources/scripts/effects/RenderWarmup.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var host := Control.new()
	root.add_child(host)
	Warmup.run(host)
	if DisplayServer.get_name() == "headless":
		assert(host.get_child_count() == 0)
	else:
		assert(host.get_child_count() == 1)
		var viewport := host.get_child(0) as SubViewport
		assert(viewport != null)
		assert(viewport.render_target_update_mode == SubViewport.UPDATE_ONCE)
		var temporary: WeakRef = weakref(viewport)
		await RenderingServer.frame_post_draw
		await process_frame
		await process_frame
		assert(host.get_child_count() == 0)
		assert(temporary.get_ref() == null, "Warmup viewport was retained")
	# Closing the scene before its first render must also cancel cleanup safely.
	Warmup.run(host)
	host.free()
	await process_frame
	await process_frame
	print("Render warmup lifecycle tests passed.")
	quit()
