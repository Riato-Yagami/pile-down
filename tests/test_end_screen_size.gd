extends SceneTree

const EndScene := preload("res://resources/scenes/ui/EndScreen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(636, 323)
	var popup := EndScene.instantiate() as EndScreen
	root.add_child(popup)
	popup.high_score.hide()
	popup.progression.hide()
	var title := popup.content.get_node("OverlayTitle") as RichTextLabel
	var details := popup.content.get_node("OverlayDetails") as RichTextLabel
	title.text = "[center]46 ROUNDS LEFT[/center]"
	details.text = "[center]in 1 min 27 s 015 ms[/center]"
	popup.seed_display.set_seed("-3044123456789")
	for frame in 12:
		await process_frame
	var normal_height := popup.panel.size.y
	# A tall text measurement must not persist once the result text settles.
	details.text = "ONE\nTWO\nTHREE\nFOUR\nFIVE\nSIX\nSEVEN\nEIGHT"
	for frame in 12:
		await process_frame
	assert(popup.panel.size.y > normal_height)
	details.text = "[center]in 2 s 345 ms[/center]"
	for frame in 12:
		await process_frame
	assert(is_equal_approx(popup.panel.size.y, normal_height),
		"Popup kept stale height: %s instead of %s" % [popup.panel.size.y, normal_height])
	assert(popup.panel.size.y < popup.size.y)
	popup.queue_free()
	await process_frame
	print("End screen size tests passed.")
	quit()
