extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("Pixelation rendering test skipped: requires a real renderer.")
		quit()
		return
	root.size = Vector2i(1024, 1280)
	root.content_scale_size = Vector2i(256, 320)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var stage := Control.new()
	root.add_child(stage)
	# A ramp lets us measure the sampled block centers in the actual image.
	for x in 256:
		var stripe := ColorRect.new()
		stripe.position = Vector2(x, 0)
		stripe.size = Vector2(1, 320)
		stripe.color = Color(float(x) / 255.0, 0, 0)
		stage.add_child(stripe)
	var overlay := preload("res://resources/scenes/special_rules/PixelationOverlay.tscn").instantiate() as PixelationOverlay
	root.add_child(overlay)
	overlay.transition_duration = 0.0
	var block_size := int(DifficultySettings.PIXELATION_PIXEL_SIZE)
	overlay.show_pixelation(float(block_size))
	var samples: Array[PackedFloat32Array] = []
	for mode in [Window.CONTENT_SCALE_MODE_VIEWPORT, Window.CONTENT_SCALE_MODE_CANVAS_ITEMS]:
		root.content_scale_mode = mode
		for frame in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		assert(rendered != null and not rendered.is_empty())
		var row := PackedFloat32Array()
		var render_scale := float(rendered.get_width()) / 256.0
		for x in 256:
			row.append(rendered.get_pixel(int((x + 0.5) * render_scale), rendered.get_height() / 2).r)
		for block in int(256 / block_size):
			for offset in range(1, block_size):
				assert(absf(row[block * block_size] - row[block * block_size + offset]) < 0.005, "Every block must span %s game pixels in mode %s" % [block_size, mode])
		samples.append(row)
	for x in 256:
		assert(absf(samples[0][x] - samples[1][x]) < 0.01, "Rendering modes must sample the same logical blocks")
	stage.queue_free()
	overlay.queue_free()
	print("Pixelation rendered block sizes match in both modes.")
	quit()
