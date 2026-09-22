extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(512, 640)
	for cycle in 3:
		var cursor := CustomCursor.new()
		root.add_child(cursor)
		await process_frame
		await process_frame
		assert(CustomCursor._cursor_scale == 2)
		assert(CustomCursor._base_cursor.get_width() == CustomCursor.BASE_CURSOR.get_width() * 2)
		var generated: WeakRef = weakref(CustomCursor._base_cursor)
		CustomCursor.set_sticky_cursor_enabled(true)
		CustomCursor.set_holding_card(true)
		root.size = Vector2i(600, 700)
		cursor._refresh_cursor()
		assert(CustomCursor._base_cursor == generated.get_ref())
		root.size = Vector2i(768, 960)
		cursor._refresh_cursor()
		assert(CustomCursor._cursor_scale == 3)
		assert(CustomCursor._base_cursor.get_width() == CustomCursor.BASE_CURSOR.get_width() * 3)
		assert(CustomCursor._holding_card and CustomCursor._sticky_enabled)
		root.size = Vector2i(512, 640)
		cursor._refresh_cursor()
		cursor.queue_free()
		await process_frame
		await process_frame
		assert(generated.get_ref() == null, "Generated cursor outlives its scene")
		assert(CustomCursor._cursor_scale == 0)
		assert(not CustomCursor._holding_card)
		assert(not CustomCursor._sticky_enabled)
	print("Cursor lifecycle tests passed.")
	quit()
