extends SceneTree


class CountingDust extends DustPool:
	var resize_calls := 0

	func resize_to_viewport(pool_size: int) -> void:
		resize_calls += 1
		super.resize_to_viewport(pool_size)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	var game := main.get_node("GameCenter/Game") as GameManager
	for frame in 5:
		await process_frame
	game.dust_pool.queue_free()
	var counter := CountingDust.new()
	game.get_node("Artwork").add_child(counter)
	game.dust_pool = counter
	counter.setup(game._dust_particle_target_count(), false)
	for frame in 3:
		await process_frame
	counter.resize_calls = 0
	for request in 50:
		game._resize_dust_distribution()
	assert(counter.resize_calls == 0)
	await process_frame
	await process_frame
	assert(counter.resize_calls == 1, "Repeated notifications were not coalesced")
	assert(not game._viewport_effects_resize_pending)
	for dimensions in [Vector2i(900, 640), Vector2i(600, 900), Vector2i(1200, 720)]:
		root.size = dimensions
		game._resize_dust_distribution()
	for frame in 5:
		await process_frame
	assert(counter._bounds == game.get_viewport_rect().size)
	assert(counter.particles.size() == game._dust_particle_target_count())
	assert(not game._viewport_effects_resize_pending)
	game._resize_dust_distribution()
	main.queue_free()
	await process_frame
	await process_frame
	print("Resize coalescing tests passed.")
	quit()
